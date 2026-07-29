import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Theme/AppTypography.dart';
import 'package:hcmu_sos/ViewModel/Common/Auth/ChangePassViewModel.dart';

class ChangePassView extends GetWidget<ChangePassViewModel> {
  const ChangePassView({super.key});

  static const Color _primaryColor = Color(0xFF29306F);
  static const Color _textColor = Color(0xFF33343C);
  static const Color _hintColor = Color(0xFF8B8D97);
  static const Color _borderColor = Color(0xFFE2E4EC);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              final compact = size.height < 760;
              final bannerHeight = (size.width * 656 / 1648).clamp(
                126.0,
                206.0,
              );

              return Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _BottomBanner(height: bannerHeight),
                  ),

                  Positioned.fill(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        18,
                        compact ? 30 : 44,
                        18,
                        bannerHeight + 28,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeaderTitle(),

                          SizedBox(height: compact ? 28 : 38),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: _borderColor, width: 1),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0F000000),
                                  blurRadius: 24,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _FieldLabel(
                                  label: 'auth.currentPasswordRequired'.tr,
                                ),
                                const SizedBox(height: 8),
                                Obx(
                                  () => _PasswordTextField(
                                    controller:
                                        controller.currentPasswordController,
                                    obscureText:
                                        controller.obscureCurrentPassword.value,
                                    onSuffixTap: controller
                                        .toggleCurrentPasswordVisibility,
                                  ),
                                ),

                                const SizedBox(height: 18),

                                _FieldLabel(
                                  label: 'auth.newPasswordRequired'.tr,
                                ),
                                const SizedBox(height: 8),
                                Obx(
                                  () => _PasswordTextField(
                                    controller:
                                        controller.newPasswordController,
                                    obscureText:
                                        controller.obscureNewPassword.value,
                                    onSuffixTap:
                                        controller.toggleNewPasswordVisibility,
                                  ),
                                ),

                                const SizedBox(height: 18),

                                _FieldLabel(
                                  label: 'auth.confirmNewPasswordRequired'.tr,
                                ),
                                const SizedBox(height: 8),
                                Obx(
                                  () => _PasswordTextField(
                                    controller:
                                        controller.confirmPasswordController,
                                    obscureText:
                                        controller.obscureConfirmPassword.value,
                                    onSuffixTap: controller
                                        .toggleConfirmPasswordVisibility,
                                    textInputAction: TextInputAction.done,
                                  ),
                                ),

                                const SizedBox(height: 22),

                                Obx(
                                  () => _PrimaryButton(
                                    label: 'auth.saveChanges'.tr,
                                    loading: controller.isSubmitting.value,
                                    onPressed: controller.isSubmitting.value
                                        ? null
                                        : controller.changePassword,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HeaderTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 3,
          left: 0,
          child: IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.chevron_left_rounded, size: 30),
            color: ChangePassView._primaryColor,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          ),
        ),
        Center(
          child: Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F4FA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  color: ChangePassView._primaryColor,
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'auth.changePassword'.tr,
                textAlign: TextAlign.center,
                style: AppTextStyles.h3.copyWith(
                  color: ChangePassView._primaryColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.bodyStrong.copyWith(
        color: ChangePassView._textColor,
        fontSize: AppFontSizes.md,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _PasswordTextField extends StatelessWidget {
  const _PasswordTextField({
    required this.controller,
    required this.obscureText,
    required this.onSuffixTap,
    this.textInputAction = TextInputAction.next,
  });

  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onSuffixTap;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        textInputAction: textInputAction,
        style: AppTextStyles.body.copyWith(
          color: ChangePassView._textColor,
          fontSize: AppFontSizes.md,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: 'auth.inputPlaceholder'.tr,
          hintStyle: AppTextStyles.body.copyWith(
            color: ChangePassView._hintColor,
            fontSize: AppFontSizes.md,
          ),
          suffixIcon: IconButton(
            onPressed: onSuffixTap,
            icon: Icon(
              obscureText
                  ? Icons.lock_outline_rounded
                  : Icons.lock_open_rounded,
              color: ChangePassView._primaryColor,
              size: 21,
            ),
          ),
          filled: true,
          fillColor: const Color(0xFFFAFAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: ChangePassView._borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(
              color: ChangePassView._primaryColor,
              width: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: ChangePassView._primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: ChangePassView._primaryColor.withOpacity(
            0.65,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          textStyle: AppTextStyles.button.copyWith(
            fontSize: AppFontSizes.md,
            fontWeight: FontWeight.w900,
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}

class _BottomBanner extends StatelessWidget {
  const _BottomBanner({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Image.asset(
          'assets/image/Image_login_bottom.png',
          fit: BoxFit.cover,
          alignment: Alignment.bottomCenter,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
