import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Repository/AuthRepository.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';
import 'package:hcmu_sos/Theme/AppTypography.dart';
import 'package:hcmu_sos/Utils/Utils.dart';

class ChangePassViewModel extends GetxController {
  ChangePassViewModel({required this.authRepository});

  final AuthRepository authRepository;

  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isSubmitting = false.obs;
  final obscureCurrentPassword = true.obs;
  final obscureNewPassword = true.obs;
  final obscureConfirmPassword = true.obs;

  Future<void> changePassword() async {
    if (isSubmitting.value) return;

    final validationError = _validatePassword();
    if (validationError != null) {
      Utils.showSnackbar(
        title: 'auth.changePassword'.tr,
        content: validationError.tr,
      );
      return;
    }

    isSubmitting.value = true;
    try {
      await authRepository.changePassword(
        currentPassword: currentPasswordController.text.trim(),
        newPassword: newPasswordController.text.trim(),
      );

      await _showPasswordChangedDialog();
    } catch (e) {
      Utils.showSnackbar(
        title: 'auth.changePassword'.tr,
        content: e is ApiException ? e.message : 'auth.changePasswordFailed'.tr,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  void toggleCurrentPasswordVisibility() {
    obscureCurrentPassword.toggle();
  }

  void toggleNewPasswordVisibility() {
    obscureNewPassword.toggle();
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.toggle();
  }

  Future<void> _showPasswordChangedDialog() {
    return Get.dialog<void>(
      _PasswordChangedDialog(
        onOk: () {
          Get.back<void>();
          Get.back<void>();
        },
      ),
      barrierDismissible: false,
    );
  }

  String? _validatePassword() {
    final currentPassword = currentPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (currentPassword.isEmpty) {
      return 'auth.validation.currentPasswordRequired';
    }

    if (newPassword.isEmpty) {
      return 'auth.validation.newPasswordRequired';
    }

    if (newPassword.length < 8) {
      return 'auth.validation.passwordTooShort';
    }

    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d).+$').hasMatch(newPassword)) {
      return 'auth.validation.passwordWeak';
    }

    if (confirmPassword.isEmpty) {
      return 'auth.validation.confirmPasswordRequired';
    }

    if (newPassword != confirmPassword) {
      return 'auth.validation.confirmNewPasswordMismatch';
    }

    if (currentPassword == newPassword) {
      return 'auth.validation.newPasswordSameAsOld';
    }

    return null;
  }

  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}

class _PasswordChangedDialog extends StatelessWidget {
  const _PasswordChangedDialog({required this.onOk});

  final VoidCallback onOk;

  static const Color _primaryColor = Color(0xFF29306F);
  static const Color _successColor = Color(0xFF2FA866);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 34),
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 26,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8EF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD6F0E0), width: 6),
              ),
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: _successColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'auth.passwordChangedSuccess'.tr,
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle.copyWith(
                color: _primaryColor,
                fontSize: AppFontSizes.xl,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'auth.passwordChangedDescription'.tr,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: const Color(0xFF626878),
                fontSize: AppFontSizes.base,
                height: 1.42,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton(
                onPressed: onOk,
                style: FilledButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                  textStyle: AppTextStyles.bodyStrong.copyWith(
                    fontSize: AppFontSizes.md,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                child: Text('common.ok'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
