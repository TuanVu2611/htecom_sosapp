// ignore_for_file: file_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/AuthUserEntity.dart';
import 'package:hcmu_sos/Theme/AppTypography.dart';

class AppLocationRequirementService with WidgetsBindingObserver {
  AppLocationRequirementService._();

  static final AppLocationRequirementService instance =
      AppLocationRequirementService._();

  bool _observerAttached = false;
  bool _isSupportedRole = false;
  bool _dialogRequestedByService = false;

  void startForUser(AuthUserEntity user) {
    _isSupportedRole =
        user.role == AuthUserRole.student || user.role == AuthUserRole.staff;
    if (!_isSupportedRole) {
      stop();
      return;
    }

    _attachObserverIfNeeded();
    unawaited(checkLocationStatus(showDialog: true));
  }

  void stop() {
    _isSupportedRole = false;
    _dialogRequestedByService = false;
    if (_observerAttached) {
      WidgetsBinding.instance.removeObserver(this);
      _observerAttached = false;
    }
  }

  Future<void> checkLocationStatus({bool showDialog = true}) async {
    if (!_isSupportedRole) {
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (showDialog) {
        await _showEnableLocationDialog();
      }
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (showDialog) {
        await _showPermissionDialog();
      }
      return;
    }

    if (permission == LocationPermission.deniedForever && showDialog) {
      await _showPermissionDialog();
      return;
    }

    if (!showDialog) {
      return;
    }
  }

  Future<void> _showEnableLocationDialog() async {
    await _showLocationDialog(
      message: 'location.appRequireEnabled'.tr,
      actionLabel: 'location.openServiceSettings'.tr,
      onConfirm: () async {
        _dialogRequestedByService = true;
        await Geolocator.openLocationSettings();
      },
    );
  }

  Future<void> _showPermissionDialog() async {
    await _showLocationDialog(
      message: 'location.appPermissionRequired'.tr,
      actionLabel: 'location.openAppSettings'.tr,
      onConfirm: () async {
        _dialogRequestedByService = true;
        await Geolocator.openAppSettings();
      },
    );
  }

  Future<void> _showLocationDialog({
    required String message,
    required String actionLabel,
    required Future<void> Function() onConfirm,
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
                      'location.dialogTitle'.tr,
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

  void _attachObserverIfNeeded() {
    if (_observerAttached) {
      return;
    }

    WidgetsBinding.instance.addObserver(this);
    _observerAttached = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isSupportedRole || state != AppLifecycleState.resumed) {
      return;
    }

    _dialogRequestedByService = false;
    unawaited(checkLocationStatus(showDialog: true));
  }
}
