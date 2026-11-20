// ignore_for_file: file_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/AuthUserEntity.dart';
import 'package:hcmu_sos/Theme/AppTypography.dart';
import 'package:hcmu_sos/Utils/StorageManager.dart';

enum LocationUse { general, sosTracking }

class AppLocationRequirementService with WidgetsBindingObserver {
  AppLocationRequirementService._();

  static final AppLocationRequirementService instance =
      AppLocationRequirementService._();

  AuthUserEntity? _user;
  int _generation = 0;
  bool _autoPromptDeclined = false;
  bool _permissionDeclined = false;
  Future<void>? _queue;
  final Map<LocationUse, Future<bool>> _pending = {};

  int get sessionRevision => _generation;

  bool get _foreground =>
      WidgetsBinding.instance.lifecycleState == null ||
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  void startForUser(AuthUserEntity user) {
    if (_user?.id == user.id && _user?.role == user.role) return;
    stop();
    _user = user;
    WidgetsBinding.instance.addObserver(this);
    unawaited(checkLocationStatus());
  }

  void stop() {
    WidgetsBinding.instance.removeObserver(this);
    _user = null;
    _generation++;
    if (_pending.isEmpty) _queue = null;
    _pending.clear();
    _autoPromptDeclined = false;
    _permissionDeclined = false;
  }

  String? _consentKey(LocationUse use) {
    final user = _user;
    return user == null
        ? null
        : 'location_consent_v2_${user.id}_${user.role.name}_${use.name}';
  }

  bool hasConsent({LocationUse use = LocationUse.general}) {
    final key = _consentKey(use);
    return key != null && StorageManager.getBool(key) == true;
  }

  String _message(LocationUse use) {
    if (use == LocationUse.sosTracking) {
      return 'location.sosDisclosureMessage'.tr;
    }
    return (_user?.role == AuthUserRole.staff
            ? 'location.staffDisclosureMessage'
            : 'location.disclosureMessage')
        .tr;
  }

  // Serialize disclosures and OS permission prompts across all location users.
  // Calls for the same purpose share the in-flight decision.
  Future<bool> checkLocationStatus({
    bool showDialog = true,
    bool userInitiated = false,
    LocationUse use = LocationUse.general,
  }) {
    final existing = _pending[use];
    if (existing != null) return existing;
    final generation = _generation;
    final previous = _queue;
    final result = () async {
      if (previous != null) await previous;
      try {
        if (_user == null || generation != _generation) return false;
        return await _checkAccess(use, generation, showDialog, userInitiated);
      } finally {
        if (generation == _generation) _pending.remove(use);
      }
    }();
    _pending[use] = result;
    _queue = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return result;
  }

  Future<bool> _checkAccess(
    LocationUse use,
    int generation,
    bool showDialog,
    bool userInitiated,
  ) async {
    if (userInitiated) {
      _autoPromptDeclined = false;
      _permissionDeclined = false;
    }
    var permission = await Geolocator.checkPermission();
    if (generation != _generation) return false;
    final needsPermission =
        permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever;
    // Even after consent was saved, a new OS permission request must be
    // immediately preceded by its explanation (e.g. permission was revoked).
    if (!hasConsent(use: use) || needsPermission) {
      if (!showDialog ||
          !_foreground ||
          _autoPromptDeclined ||
          (_permissionDeclined && needsPermission)) {
        return false;
      }
      await WidgetsBinding.instance.endOfFrame;
      if (generation != _generation ||
          !_foreground ||
          Get.isDialogOpen == true) {
        return false;
      }
      final key = _consentKey(use)!;
      final accepted = await _showLocationDialog(
        title: 'location.disclosureTitle'.tr,
        message: _message(use),
        actionLabel: 'location.disclosureAccept'.tr,
        cancelLabel: 'location.disclosureLater'.tr,
      );
      if (generation != _generation) return false;
      if (!accepted) {
        _autoPromptDeclined = true;
        return false;
      }
      if (!await StorageManager.setBool(key, true)) return false;
      if (generation != _generation || !_foreground) return false;
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (generation != _generation) return false;
      } else if (permission == LocationPermission.deniedForever) {
        // The disclosure is shown before taking the user to OS settings too.
        await Geolocator.openAppSettings();
        if (generation == _generation) _permissionDeclined = true;
        return false;
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        _permissionDeclined = true;
        return false;
      }
    }
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      return false;
    }
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (generation != _generation) return false;
    if (!enabled && showDialog && _foreground) {
      await _showLocationDialog(
        message: '${_message(use)}\n\n${'location.serviceDisabled'.tr}',
        actionLabel: 'location.openServiceSettings'.tr,
        onConfirm: () async {
          if (generation == _generation) {
            await Geolocator.openLocationSettings();
          }
        },
      );
    }
    return enabled && generation == _generation && hasConsent(use: use);
  }

  Future<bool> _showLocationDialog({
    required String message,
    required String actionLabel,
    Future<void> Function()? onConfirm,
    String? title,
    String? cancelLabel,
  }) async {
    if (Get.isDialogOpen == true) {
      return false;
    }

    final accepted = await Get.dialog<bool>(
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
          child: SingleChildScrollView(
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
                        color: const Color(0xFFEFF4FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFF29306F),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title ?? 'location.dialogTitle'.tr,
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
                        onPressed: () => Get.back<bool>(result: false),
                        child: Text(
                          cancelLabel ?? 'common.cancel'.tr,
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
                        onPressed: () => Get.back<bool>(result: true),
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
      ),
      barrierDismissible: true,
    );
    if (accepted == true && onConfirm != null) await onConfirm();
    return accepted == true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_user == null || state != AppLifecycleState.resumed) return;
    unawaited(checkLocationStatus());
  }
}
