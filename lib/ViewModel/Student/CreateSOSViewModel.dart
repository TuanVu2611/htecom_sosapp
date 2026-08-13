// ignore_for_file: file_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Repository/SosTrackingRepository.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';
import 'package:hcmu_sos/Service/StudentSosTrackingService.dart';
import 'package:hcmu_sos/Theme/AppTypography.dart';
import 'package:hcmu_sos/Utils/Utils.dart';

enum CreateSOSState { ready, holding, sent }

class CreateSOSViewModel extends GetxController with WidgetsBindingObserver {
  CreateSOSViewModel({SosTrackingRepository? sosTrackingRepository})
    : _sosTrackingRepository =
          sosTrackingRepository ?? SosTrackingRepository();

  static const int holdSeconds = 5;

  final SosTrackingRepository _sosTrackingRepository;

  final state = CreateSOSState.ready.obs;
  final holdProgress = 0.0.obs;
  final remainingSeconds = holdSeconds.obs;
  final isSubmitting = false.obs;
  final isCancelling = false.obs;
  final sentSosId = RxnInt();

  Timer? _holdTimer;
  Timer? _reverseTimer;
  DateTime? _holdStartedAt;
  bool _shouldRetryLocationOnResume = false;

  @override
  void onReady() {
    super.onReady();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_restoreCurrentSosState());
  }

  void startHolding() {
    if (state.value != CreateSOSState.ready || isSubmitting.value) return;

    _reverseTimer?.cancel();

    _holdStartedAt = DateTime.now();
    remainingSeconds.value = holdSeconds;
    state.value = CreateSOSState.holding;

    _holdTimer?.cancel();
    _holdTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      final startedAt = _holdStartedAt;
      if (startedAt == null) return;

      final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
      final progress = (elapsedMs / (holdSeconds * 1000)).clamp(0.0, 1.0);

      holdProgress.value = progress;
      remainingSeconds.value = (holdSeconds - (elapsedMs / 1000).floor()).clamp(
        0,
        holdSeconds,
      );

      if (progress >= 1) {
        _holdTimer?.cancel();
        createSOS();
      }
    });
  }

  void cancelHolding() {
    if (state.value != CreateSOSState.holding || isSubmitting.value) return;

    _holdTimer?.cancel();
    _holdStartedAt = null;
    state.value = CreateSOSState.ready;
    remainingSeconds.value = holdSeconds;

    _reverseTimer?.cancel();

    final startProgress = holdProgress.value;
    const durationMs = 260;
    const tickMs = 16;
    var elapsedMs = 0;

    _reverseTimer = Timer.periodic(const Duration(milliseconds: tickMs), (
      timer,
    ) {
      elapsedMs += tickMs;

      final t = (elapsedMs / durationMs).clamp(0.0, 1.0);
      final eased = Curves.easeOutCubic.transform(t);

      holdProgress.value = startProgress * (1 - eased);

      if (t >= 1) {
        timer.cancel();
        holdProgress.value = 0;
      }
    });
  }

  Future<void> createSOS() async {
    if (isSubmitting.value) return;

    isSubmitting.value = true;

    try {
      final hasLocationAccess = await _ensureLocationAccess();
      if (!hasLocationAccess) {
        resetToReady();
        return;
      }

      final position = await _currentPositionOrNull();
      if (position == null) {
        throw ApiException(message: 'location.currentUnavailable'.tr);
      }

      final response = await ApiCaller.getInstance().postBase<Object?>(
        'sos',
        <String, dynamic>{
          'latitude': position?.latitude,
          'longitude': position?.longitude,
          'note': null,
        },
      );

      if (!response.success) {
        throw ApiException(
          message: response.message ?? 'sos.createFailed'.tr,
          code: response.code,
          data: response.raw,
        );
      }

      sentSosId.value =
          _extractSosId(response.data) ?? _extractSosId(response.raw);
      final sosId = sentSosId.value;
      if (sosId != null && sosId > 0) {
        await StudentSosTrackingService.instance.startTracking(
          sosId,
          syncImmediately: true,
        );
      }
      await _notifySosSent();
      state.value = CreateSOSState.sent;
    } on ApiException catch (error) {
      resetToReady();
      Utils.showSnackbar(title: 'sos.title'.tr, content: error.message);
    } catch (_) {
      resetToReady();
      Utils.showSnackbar(title: 'sos.title'.tr, content: 'sos.createFailed'.tr);
    } finally {
      isSubmitting.value = false;
      holdProgress.value = 0;
      remainingSeconds.value = holdSeconds;
    }
  }

  Future<void> cancelSentSOS() async {
    if (isCancelling.value) return;

    final sosId = sentSosId.value;
    if (sosId == null || sosId <= 0) {
      resetToReady();
      return;
    }

    isCancelling.value = true;

    try {
      final response = await ApiCaller.getInstance().postBase<Object?>(
        'sos/$sosId/cancel',
        null,
      );

      if (!response.success) {
        throw ApiException(
          message: response.message ?? 'sos.cancelFailed'.tr,
          code: response.code,
          data: response.raw,
        );
      }

      resetToReady();
      StudentSosTrackingService.instance.stop();
      Utils.showSnackbar(
        title: 'sos.title'.tr,
        content: 'sos.cancelSuccess'.tr,
      );
    } on ApiException catch (error) {
      Utils.showSnackbar(title: 'sos.title'.tr, content: error.message);
    } catch (_) {
      Utils.showSnackbar(title: 'sos.title'.tr, content: 'sos.cancelFailed'.tr);
    } finally {
      isCancelling.value = false;
    }
  }

  void resetToReady() {
    _holdTimer?.cancel();
    _reverseTimer?.cancel();
    _holdStartedAt = null;
    state.value = CreateSOSState.ready;
    holdProgress.value = 0;
    remainingSeconds.value = holdSeconds;
    isSubmitting.value = false;
    isCancelling.value = false;
    sentSosId.value = null;
  }

  Future<Position?> _currentPositionOrNull() async {
    try {
      final hasLocationAccess = await _ensureLocationAccess(
        showMessageOnFailure: false,
      );
      if (!hasLocationAccess) {
        return null;
      }

      return Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> _ensureLocationAccess({
    bool showMessageOnFailure = true,
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (showMessageOnFailure) {
        await _showLocationDialog(
          title: 'sos.title'.tr,
          message: 'location.serviceDisabled'.tr,
          actionLabel: 'location.openServiceSettings'.tr,
          onConfirm: Geolocator.openLocationSettings,
        );
      }
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (showMessageOnFailure) {
        await _showLocationDialog(
          title: 'sos.title'.tr,
          message: 'location.permissionRequired'.tr,
          actionLabel: 'location.openAppSettings'.tr,
          onConfirm: Geolocator.openAppSettings,
        );
      }
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      if (showMessageOnFailure) {
        await _showLocationDialog(
          title: 'sos.title'.tr,
          message: 'location.permissionRequired'.tr,
          actionLabel: 'location.openAppSettings'.tr,
          onConfirm: Geolocator.openAppSettings,
        );
      }
      return false;
    }

    return true;
  }

  Future<void> _showLocationDialog({
    required String title,
    required String message,
    required String actionLabel,
    required Future<bool> Function() onConfirm,
  }) async {
    if (Get.isDialogOpen == true) {
      return;
    }

    await Get.dialog<void>(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x220F172A),
                blurRadius: 28,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Color(0xFFDC2626),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.title.copyWith(
                        color: const Color(0xFF111827),
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                message,
                style: AppTextStyles.body.copyWith(
                  color: const Color(0xFF4B5563),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7280),
                        side: const BorderSide(color: Color(0xFFD9DFEA)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Get.back<void>(),
                      child: Text(
                        'common.cancel'.tr,
                        style: AppTextStyles.button.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF29306F),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        _shouldRetryLocationOnResume = true;
                        Get.back<void>();
                        await onConfirm();
                      },
                      child: Text(
                        actionLabel,
                        style: AppTextStyles.button.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  int? _extractSosId(Object? data) {
    if (data is Map<String, dynamic>) {
      return _extractSosIdFromMap(data);
    }
    if (data is Map) {
      return _extractSosIdFromMap(data);
    }
    return _asInt(data);
  }

  int? _extractSosIdFromMap(Map<dynamic, dynamic> data) {
    final directId = _asInt(data['id'] ?? data['sos_id']);
    if (directId != null) return directId;

    final sos = data['sos'];
    if (sos is Map) {
      return _extractSosIdFromMap(sos);
    }

    final request = data['request'];
    if (request is Map) {
      return _extractSosIdFromMap(request);
    }

    return null;
  }

  int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  Future<void> _notifySosSent() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {
      // Haptics are best-effort and should never block the SOS flow.
    }
  }

  Future<void> _restoreCurrentSosState() async {
    state.value = CreateSOSState.ready;
    try {
      final status = await _sosTrackingRepository.getCurrentSosStatus();
      if (status != null && status.canTrack) {
        sentSosId.value = status.sosId;
        state.value = CreateSOSState.sent;
        return;
      }
    } catch (_) {
      // Keep the SOS panel usable even if the restore check fails.
    }

    sentSosId.value = null;
    state.value = CreateSOSState.ready;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _holdTimer?.cancel();
    _reverseTimer?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_shouldRetryLocationOnResume) {
      return;
    }

    _shouldRetryLocationOnResume = false;
    unawaited(_currentPositionOrNull());
  }
}
