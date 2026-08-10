// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Theme/AppTypography.dart';
import 'package:hcmu_sos/ViewModel/Common/Auth/LoginViewModel.dart';

class LoginView extends GetWidget<LoginViewModel> {
  const LoginView({super.key});

  static const Color _primaryColor = Color(0xFF29306F);
  static const Color _mutedTextColor = Color(0xFF6F717C);
  static const Color _borderColor = Color(0xFFE2E4EC);
  // Total fixed height of the form controls and their vertical spacing.
  // The responsive logo and optional bottom banner are added separately.
  static const double _compactFormHeight = 483;
  static const double _expandedFormHeight = 547;

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
              final logoWidth = (size.width * 0.31).clamp(126.0, 162.0);
              final logoHeight = logoWidth * 74 / 120;
              final bannerHeight = (size.width * 656 / 1648).clamp(
                142.0,
                238.0,
              );
              final expandedRequiredHeight =
                  logoHeight + _expandedFormHeight + bannerHeight + 22;
              final compact = size.height < expandedRequiredHeight;
              final estimatedFormHeight =
                  logoHeight +
                  (compact ? _compactFormHeight : _expandedFormHeight);
              final keyboardVisible =
                  MediaQuery.viewInsetsOf(context).bottom > 0;
              final showBottomBanner =
                  !keyboardVisible &&
                  size.height >=
                      estimatedFormHeight + bannerHeight + (compact ? 16 : 22);
              final bottomContentPadding = showBottomBanner
                  ? bannerHeight + (compact ? 16 : 22)
                  : (compact ? 18.0 : 24.0);
              final horizontalPadding = size.width < 390 ? 22.0 : 28.0;

              return Stack(
                children: [
                  Positioned(
                    key: const ValueKey('login-bottom-banner'),
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Visibility(
                      visible: showBottomBanner,
                      child: _BottomBanner(height: bannerHeight),
                    ),
                  ),
                  Positioned.fill(
                    key: const ValueKey('login-form'),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: bottomContentPadding,
                          ),
                          child: Column(
                            children: [
                              SizedBox(height: compact ? 18 : 30),
                              SvgPicture.asset(
                                'assets/icon/icon_logo.svg',
                                width: logoWidth,
                                fit: BoxFit.contain,
                              ),
                              SizedBox(height: compact ? 18 : 40),
                              _SectionTitle(
                                highlightedText: 'auth.studentLogin'.tr,
                              ),
                              SizedBox(height: compact ? 14 : 20),
                              _LoginTextField(
                                controller: controller.studentCodeController,
                                hintText: 'auth.studentCode'.tr,
                                icon: Icons.person_outline_rounded,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 12),
                              Obx(
                                () => _LoginTextField(
                                  controller: controller.passwordController,
                                  hintText: 'auth.password'.tr,
                                  icon: controller.obscurePassword.value
                                      ? Icons.lock_outline_rounded
                                      : Icons.lock_open_rounded,
                                  obscureText: controller.obscurePassword.value,
                                  onIconTap:
                                      controller.togglePasswordVisibility,
                                  textInputAction: TextInputAction.done,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Obx(
                                () => SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: FilledButton(
                                    onPressed: controller.isLoggingIn.value
                                        ? null
                                        : controller.loginWithUsernamePassword,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _primaryColor,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: _primaryColor
                                          .withValues(alpha: 0.72),
                                      disabledForegroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      textStyle: AppTextStyles.button.copyWith(
                                        fontSize: AppFontSizes.lg,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    child: controller.isLoggingIn.value
                                        ? Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text('auth.login'.tr),
                                            ],
                                          )
                                        : Text('auth.login'.tr),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              LayoutBuilder(
                                builder: (context, rowConstraints) {
                                  final compactActions =
                                      rowConstraints.maxWidth < 330;

                                  final rememberSection = Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Obx(
                                        () => _RememberCheckbox(
                                          value: controller.rememberLogin.value,
                                          onTap: controller.toggleRememberLogin,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          'auth.rememberLogin'.tr,
                                          style: AppTextStyles.body.copyWith(
                                            color: _mutedTextColor,
                                            fontSize: AppFontSizes.md,
                                            height: 1.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );

                                  final forgotButton = TextButton(
                                    onPressed: controller.forgotPassword,
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF33343C),
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 34),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      alignment: compactActions
                                          ? Alignment.centerLeft
                                          : Alignment.centerRight,
                                    ),
                                    child: Text(
                                      'auth.forgotPassword'.tr,
                                      style: AppTextStyles.bodyStrong.copyWith(
                                        fontSize: AppFontSizes.md,
                                        color: const Color(0xFF33343C),
                                      ),
                                    ),
                                  );

                                  if (compactActions) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        rememberSection,
                                        const SizedBox(height: 6),
                                        forgotButton,
                                      ],
                                    );
                                  }

                                  return Row(
                                    children: [
                                      Expanded(child: rememberSection),
                                      const SizedBox(width: 12),
                                      forgotButton,
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 15),
                              _RegisterPrompt(onTap: controller.register),

                              SizedBox(height: compact ? 20 : 30),
                              _SectionTitle(
                                highlightedText: 'auth.staffLoginRole'.tr,
                                normalText: 'auth.loginWith'.tr,
                              ),
                              SizedBox(height: compact ? 14 : 22),
                              _MicrosoftButton(
                                onTap: controller.loginWithMicrosoft365,
                              ),
                              SizedBox(height: compact ? 12 : 18),
                            ],
                          ),
                        ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.highlightedText, this.normalText = ''});

  final String highlightedText;
  final String normalText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE8EAF2), height: 1)),
        Flexible(
          flex: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: highlightedText,
                    style: const TextStyle(color: LoginView._primaryColor),
                  ),
                  if (normalText.isNotEmpty)
                    TextSpan(
                      text: ' $normalText',
                      style: const TextStyle(
                        color: LoginView._mutedTextColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyStrong.copyWith(
                fontSize: AppFontSizes.lg,
                height: 1.2,
              ),
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE8EAF2), height: 1)),
      ],
    );
  }
}

class _LoginTextField extends StatelessWidget {
  const _LoginTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.onIconTap,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final VoidCallback? onIconTap;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        textInputAction: textInputAction,
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        style: AppTextStyles.body.copyWith(
          color: const Color(0xFF22242C),
          fontSize: AppFontSizes.lg,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTextStyles.body.copyWith(
            color: const Color(0xFF7D7F89),
            fontSize: AppFontSizes.lg,
          ),
          suffixIcon: IconButton(
            onPressed: onIconTap,
            icon: Icon(icon, color: LoginView._primaryColor, size: 24),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: LoginView._borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(
              color: LoginView._primaryColor,
              width: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _RememberCheckbox extends StatelessWidget {
  const _RememberCheckbox({required this.value, required this.onTap});

  final bool value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: value ? const Color(0xFFF22B35) : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: value ? const Color(0xFFF22B35) : LoginView._borderColor,
            width: 1.2,
          ),
        ),
        child: value
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 17)
            : null,
      ),
    );
  }
}

class _MicrosoftButton extends StatelessWidget {
  const _MicrosoftButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Ink(
        width: 60,
        height: 60,
        child: Image.asset(
          'assets/icon/icon_ms365.png',
          width: 60,
          height: 60,
          fit: BoxFit.contain,
        ),
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

class _RegisterPrompt extends StatelessWidget {
  const _RegisterPrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8EAF2)),
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 4,
          children: [
            Icon(
              Icons.school_outlined,
              size: 18,
              color: LoginView._primaryColor.withValues(alpha: 0.8),
            ),
            Text(
              'auth.noAccount'.tr.trim(),
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: LoginView._mutedTextColor,
                fontSize: AppFontSizes.md,
              ),
            ),
            Text(
              'auth.register'.tr,
              style: AppTextStyles.bodyStrong.copyWith(
                color: LoginView._primaryColor,
                fontSize: AppFontSizes.md,
                fontWeight: FontWeight.w700,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: LoginView._primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
