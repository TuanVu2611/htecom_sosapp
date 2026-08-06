// ignore_for_file: file_names

import 'dart:async';

import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/SosTrackingEntity.dart';
import 'package:hcmu_sos/Entity/StaffHomeEntity.dart';
import 'package:hcmu_sos/Repository/SosTrackingRepository.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';

class SOSRealtimeMapViewModel extends GetxController {
  SOSRealtimeMapViewModel({SosTrackingRepository? sosTrackingRepository})
    : _sosTrackingRepository =
          sosTrackingRepository ?? SosTrackingRepository();

  static const Duration _pollInterval = Duration(seconds: 5);

  final SosTrackingRepository _sosTrackingRepository;

  final isLoading = true.obs;
  final isActive = true.obs;
  final errorMessage = RxnString();
  final sos = Rxn<StaffActiveSosEntity>();
  final lastUpdatedAt = Rxn<DateTime>();

  Timer? _timer;
  int? _sosId;

  @override
  void onInit() {
    super.onInit();
    final argument = Get.arguments;
    if (argument is StaffActiveSosEntity) {
      sos.value = argument;
      isActive.value = argument.isActive;
      lastUpdatedAt.value = argument.updatedAt;
      _sosId = argument.id;
    } else if (argument is int) {
      _sosId = argument;
    }
  }

  @override
  void onReady() {
    super.onReady();
    if ((_sosId ?? 0) <= 0) {
      errorMessage.value = 'Không xác định được SOS để theo dõi.';
      isLoading.value = false;
      return;
    }

    unawaited(_fetchLatestLocation(showLoading: true));
    _timer = Timer.periodic(_pollInterval, (_) {
      unawaited(_fetchLatestLocation());
    });
  }

  Future<void> refresh() => _fetchLatestLocation(showLoading: false);

  Future<void> _fetchLatestLocation({bool showLoading = false}) async {
    final sosId = _sosId;
    if (sosId == null || sosId <= 0) {
      return;
    }

    if (showLoading) {
      isLoading.value = true;
    }

    try {
      final latest = await _sosTrackingRepository.getSosLocation(sosId);
      _applyLatestLocation(latest);
      errorMessage.value = null;
    } on ApiException catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value = 'Không thể cập nhật vị trí SOS.';
    } finally {
      isLoading.value = false;
    }
  }

  void _applyLatestLocation(SosLiveLocationEntity latest) {
    final current = sos.value;
    isActive.value = latest.isActive;
    lastUpdatedAt.value = latest.updatedAt;
    sos.value = (current ??
            StaffActiveSosEntity(
              id: latest.sosId,
              status: latest.status,
              code: latest.code,
              isActive: latest.isActive,
            ))
        .copyWith(
          status: latest.status,
          code: latest.code,
          isActive: latest.isActive,
          location: latest.location?.text,
          latitude: latest.location?.latitude,
          longitude: latest.location?.longitude,
          updatedAt: latest.updatedAt,
        );

    if (!latest.isActive) {
      _timer?.cancel();
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
