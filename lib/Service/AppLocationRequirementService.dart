// ignore_for_file: file_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/AuthUserEntity.dart';
import 'package:hcmu_sos/Theme/AppTypography.dart';
import 'package:hcmu_sos/Utils/StorageManager.dart';

class AppLocationRequirementService with WidgetsBindingObserver {
  AppLocationRequirementService._();

  static final AppLocationRequirementService instance =
      AppLocationRequirementService._();

  bool _observerAttached = false;
  bool _isSupportedRole = false;
  String? _consentKey;
  int _generation = 0;
  Future<bool>? _consentDecision;
  Future<bool>? _pendingCheck;

  void startForUser(AuthUserEntity user) {
    stop();
    _consentKey = 'location_update_consent_v1_${user.id}';
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
    _generation++;
    _consentKey = null;
    _consentDecision = null;
    _pendingCheck = null;
    if (_observerAttached) {
      WidgetsBinding.instance.removeObserver(this);
      _observerAttached = false;
    }
  }

  Future<bool> checkLocationStatus({bool showDialog = true}) {
    return _pendingCheck ??= _checkLocationStatus(showDialog: showDialog);
  }

  Future<bool> _checkLocationStatus({required bool showDialog}) async {
    final generation = _generation;
    try {
      return await _checkLocationAccess(showDialog, generation);
    } finally {
      if (generation == _generation) _pendingCheck = null;
    }
  }

  Future<bool> _checkLocationAccess(bool showDialog, int generation) async {
    if (!_isSupportedRole) return false;
    final accepted = await (_consentDecision ??= _requestConsent(generation));
    if (!accepted || generation != _generation || !_isSupportedRole) {
      return false;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (generation != _generation) return false;
    if (!serviceEnabled) {
      if (showDialog) {
        await _showEnableLocationDialog();
      }
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (generation != _generation) return false;
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (generation != _generation) return false;

    if (permission == LocationPermission.denied) {
      if (showDialog) {
        await _showPermissionDialog();
      }
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      if (showDialog) await _showPermissionDialog();
      return false;
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<bool> _requestConsent(int generation) async {
    final key = _consentKey;
    if (key == null) return false;
    if (StorageManager.getBool(key) == true) return true;

    // Login/session restoration navigates to the dashboard in this frame.
    await WidgetsBinding.instance.endOfFrame;
    if (generation != _generation || !_isSupportedRole) return false;
    if (Get.isDialogOpen == true) return false;

    final accepted = await _showLocationDialog(
      title: 'location.disclosureTitle'.tr,
      message: 'location.disclosureMessage'.tr,
      actionLabel: 'location.disclosureAccept'.tr,
      cancelLabel: 'location.disclosureLater'.tr,
    );
    if (generation != _generation || !accepted) return false;
    return StorageManager.setBool(key, true);
  }

  Future<void> _showEnableLocationDialog() async {
    await _showLocationDialog(
      message: 'location.appRequireEnabled'.tr,
      actionLabel: 'location.openServiceSettings'.tr,
      onConfirm: () async {
        await Geolocator.openLocationSettings();
      },
    );
  }

  Future<void> _showPermissionDialog() async {
    await _showLocationDialog(
      message: 'location.appPermissionRequired'.tr,
      actionLabel: 'location.openAppSettings'.tr,
      onConfirm: () async {
        await Geolocator.openAppSettings();
      },
    );
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

    unawaited(checkLocationStatus(showDialog: true));
  }
}
