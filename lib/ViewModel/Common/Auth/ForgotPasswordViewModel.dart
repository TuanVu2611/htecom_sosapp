// ignore_for_file: file_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Repository/AuthRepository.dart';
import 'package:hcmu_sos/Utils/Utils.dart';

enum ForgotPasswordStep { requestOtp, verifyOtp, resetPassword, success }

class ForgotPasswordViewModel extends GetxController {
  ForgotPasswordViewModel({required this.authRepository});

  final AuthRepository authRepository;

  final accountController = TextEditingController();
  final otpController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final step = ForgotPasswordStep.requestOtp.obs;
  final maskedReceiver = ''.obs;
  final countdownSeconds = 30.obs;
  final isSubmitting = false.obs;
  final obscureNewPassword = true.obs;
  final obscureConfirmPassword = true.obs;

  Timer? _countdownTimer;
  int? _requestId;
  String _resetToken = '';

  String get formattedCountdown {
    final totalSeconds = countdownSeconds.value;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> requestOtp() async {
    if (isSubmitting.value) {
      return;
    }

    final account = accountController.text.trim();
    final validationError = _validateAccount(account);
    if (validationError != null) {
      Utils.showSnackbar(
        title: 'auth.forgotPassword'.tr,
        content: validationError.tr,
      );
      return;
    }

    isSubmitting.value = true;
    try {
      final result = await authRepository.requestPasswordResetOtp(
        account: account,
      );
      _requestId = result.requestId;
      maskedReceiver.value = result.maskedReceiver.isNotEmpty
          ? result.maskedReceiver
          : _maskAccount(account);
      otpController.clear();
      step.value = ForgotPasswordStep.verifyOtp;
      _startCountdown(result.expiredIn);
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> verifyOtp() async {
    if (isSubmitting.value) {
      return;
    }

    final otp = otpController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      Utils.showSnackbar(
        title: 'auth.verifyOtp'.tr,
        content: 'auth.validation.otpInvalid'.tr,
      );
      return;
    }

    isSubmitting.value = true;
    try {
      final requestId = _requestId;
      if (requestId == null || requestId <= 0) {
        Utils.showSnackbar(
          title: 'auth.verifyOtp'.tr,
          content: 'auth.forgotPassword'.tr,
        );
        return;
      }

      final result = await authRepository.verifyPasswordResetOtp(
        requestId: requestId,
        otp: otp,
      );
      _resetToken = result.resetToken;
      step.value = ForgotPasswordStep.resetPassword;
      _startCountdown(result.expiredIn);
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> resendOtp() async {
    if (isSubmitting.value || countdownSeconds.value > 0) {
      return;
    }

    otpController.clear();
    await requestOtp();
  }

  Future<void> resetPassword() async {
    if (isSubmitting.value) {
      return;
    }

    final validationError = _validatePassword();
    if (validationError != null) {
      Utils.showSnackbar(
        title: 'auth.createNewPassword'.tr,
        content: validationError.tr,
      );
      return;
    }

    isSubmitting.value = true;
    try {
      if (_resetToken.isEmpty) {
        Utils.showSnackbar(
          title: 'auth.createNewPassword'.tr,
          content: 'auth.forgotPassword'.tr,
        );
        return;
      }
      await authRepository.resetPassword(
        resetToken: _resetToken,
        newPassword: newPasswordController.text,
        confirmPassword: confirmPasswordController.text,
      );
      step.value = ForgotPasswordStep.success;
    } finally {
      isSubmitting.value = false;
    }
  }

  void toggleNewPasswordVisibility() {
    obscureNewPassword.toggle();
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.toggle();
  }

  void backToLogin() {
    Get.back<void>();
  }

  String? _validateAccount(String account) {
    if (account.isEmpty) {
      return 'auth.validation.accountRequired';
    }

    final isEmail = GetUtils.isEmail(account);
    final isPhone = RegExp(r'^(0|\+84)[0-9]{9,10}$').hasMatch(account);
    if (!isEmail && !isPhone) {
      return 'auth.validation.accountInvalid';
    }

    return null;
  }

  String _maskAccount(String account) {
    if (GetUtils.isEmail(account)) {
      final parts = account.split('@');
      final name = parts.first;
      final domain = parts.last;
      final visibleName = name.length <= 2 ? name : name.substring(0, 2);

      return '$visibleName****@$domain';
    }

    final normalizedPhone = account.replaceAll(RegExp(r'\s+'), '');
    if (normalizedPhone.length <= 4) {
      return normalizedPhone;
    }

    return '******${normalizedPhone.substring(normalizedPhone.length - 4)}';
  }

  String? _validatePassword() {
    final password = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (password.isEmpty) {
      return 'auth.validation.passwordRequired';
    }

    if (password.length < 8) {
      return 'auth.validation.passwordTooShort';
    }

    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d).+$').hasMatch(password)) {
      return 'auth.validation.passwordWeak';
    }

    if (confirmPassword.isEmpty) {
      return 'auth.validation.confirmPasswordRequired';
    }

    if (password != confirmPassword) {
      return 'auth.validation.confirmPasswordMismatch';
    }

    return null;
  }

  void _startCountdown(int seconds) {
    _countdownTimer?.cancel();
    countdownSeconds.value = seconds > 0 ? seconds : 0;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdownSeconds.value <= 1) {
        countdownSeconds.value = 0;
        timer.cancel();
        return;
      }

      countdownSeconds.value--;
    });
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    accountController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
