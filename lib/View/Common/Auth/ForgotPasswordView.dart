// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Theme/AppTypography.dart';
import 'package:hcmu_sos/ViewModel/Common/Auth/ForgotPasswordViewModel.dart';

class ForgotPasswordView extends GetWidget<ForgotPasswordViewModel> {
  const ForgotPasswordView({super.key});

  static const Color _primaryColor = Color(0xFF29306F);
  static const Color _mutedTextColor = Color(0xFF6F717C);
  static const Color _borderColor = Color(0xFFE2E4EC);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.step.value == ForgotPasswordStep.success) {
        return const _ForgotPasswordSuccessView();
      }

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
                final horizontalPadding = size.width < 390 ? 28.0 : 34.0;

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
                          horizontalPadding,
                          compact ? 50 : 76,
                          horizontalPadding,
                          bannerHeight + 24,
                        ),
                        child: Obx(() => _buildStepContent(compact)),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    });
  }

  Widget _buildStepContent(bool compact) {
    switch (controller.step.value) {
      case ForgotPasswordStep.requestOtp:
        return _RequestOtpStep(compact: compact);
      case ForgotPasswordStep.verifyOtp:
        return _VerifyOtpStep(compact: compact);
      case ForgotPasswordStep.resetPassword:
        return _ResetPasswordStep(compact: compact);
      case ForgotPasswordStep.success:
        return const SizedBox.shrink();
    }
  }
}

class _RequestOtpStep extends GetWidget<ForgotPasswordViewModel> {
  const _RequestOtpStep({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AuthTitle(
          title: 'auth.forgotPasswordTitle'.tr,
          subtitle: 'auth.forgotPasswordDescription'.tr,
        ),
        SizedBox(height: compact ? 72 : 116),
        _FieldLabel(label: 'auth.account'.tr),
        const SizedBox(height: 8),
        _AuthTextField(
          controller: controller.accountController,
          hintText: 'auth.inputPlaceholder'.tr,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 20),
        Obx(
          () => _PrimaryButton(
            label: 'auth.submitRequest'.tr,
            onPressed: controller.isSubmitting.value
                ? null
                : controller.requestOtp,
          ),
        ),
      ],
    );
  }
}

class _VerifyOtpStep extends GetWidget<ForgotPasswordViewModel> {
  const _VerifyOtpStep({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(
          () => _AuthTitle(
            title: 'auth.verifyOtp'.tr,
            subtitle: 'auth.verifyOtpDescription'.tr,
            highlight: controller.maskedReceiver.value,
          ),
        ),
        SizedBox(height: compact ? 72 : 116),
        _FieldLabel(label: 'auth.otpCode'.tr),
        const SizedBox(height: 8),
        _AuthTextField(
          controller: controller.otpController,
          hintText: 'auth.inputPlaceholder'.tr,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 20),
        Obx(
          () => _PrimaryButton(
            label: 'auth.next'.tr,
            onPressed: controller.isSubmitting.value
                ? null
                : controller.verifyOtp,
          ),
        ),
        const SizedBox(height: 28),
        Center(
          child: Obx(
            () => Text(
              controller.formattedCountdown,
              style: AppTextStyles.h3.copyWith(
                color: ForgotPasswordView._primaryColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Mã OTP chỉ có hiệu lực trong thời gian còn lại.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: ForgotPasswordView._mutedTextColor,
              fontSize: AppFontSizes.md,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _ResetPasswordStep extends GetWidget<ForgotPasswordViewModel> {
  const _ResetPasswordStep({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AuthTitle(title: 'auth.createNewPassword'.tr),
        SizedBox(height: compact ? 92 : 146),
        _FieldLabel(label: 'auth.newPasswordRequired'.tr),
        const SizedBox(height: 8),
        Obx(
          () => _AuthTextField(
            controller: controller.newPasswordController,
            hintText: 'auth.inputPlaceholder'.tr,
            obscureText: controller.obscureNewPassword.value,
            suffixIcon: controller.obscureNewPassword.value
                ? Icons.lock_outline_rounded
                : Icons.lock_open_rounded,
            onSuffixTap: controller.toggleNewPasswordVisibility,
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: 18),
        _FieldLabel(label: 'auth.confirmNewPasswordRequired'.tr),
        const SizedBox(height: 8),
        Obx(
          () => _AuthTextField(
            controller: controller.confirmPasswordController,
            hintText: 'auth.inputPlaceholder'.tr,
            obscureText: controller.obscureConfirmPassword.value,
            suffixIcon: controller.obscureConfirmPassword.value
                ? Icons.lock_outline_rounded
                : Icons.lock_open_rounded,
            onSuffixTap: controller.toggleConfirmPasswordVisibility,
            textInputAction: TextInputAction.done,
          ),
        ),
        const SizedBox(height: 20),
        Obx(
          () => _PrimaryButton(
            label: 'auth.saveChanges'.tr,
            onPressed: controller.isSubmitting.value
                ? null
                : controller.resetPassword,
          ),
        ),
      ],
    );
  }
}

class _ForgotPasswordSuccessView extends GetWidget<ForgotPasswordViewModel> {
  const _ForgotPasswordSuccessView();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: ForgotPasswordView._primaryColor,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              final compact = size.height < 760;

              return Stack(
                children: [
                  const Positioned.fill(
                    child: _AnimatedEntrance(
                      delay: Duration.zero,
                      duration: Duration(milliseconds: 850),
                      beginOffset: Offset.zero,
                      child: _SuccessBackground(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: compact ? 48 : 72),
                        _AnimatedEntrance(
                          delay: const Duration(milliseconds: 80),
                          beginOffset: const Offset(0, 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: Text(
                              'auth.passwordChangedSuccess'.tr,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.h3.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                              ),
                            ),
                          ),
                        ),
                        Spacer(flex: compact ? 2 : 3),
                        _AnimatedEntrance(
                          delay: const Duration(milliseconds: 180),
                          duration: const Duration(milliseconds: 720),
                          beginScale: 0.88,
                          beginOffset: const Offset(0, 18),
                          child: Container(
                            width: (size.width * 0.58).clamp(190.0, 236.0),
                            height: (size.width * 0.46).clamp(154.0, 190.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.10),
                                  blurRadius: 28,
                                  offset: const Offset(0, 18),
                                ),
                              ],
                            ),
                            child: Center(
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.94, end: 1),
                                duration: const Duration(milliseconds: 1050),
                                curve: Curves.elasticOut,
                                builder: (context, scale, child) {
                                  return Transform.scale(
                                    scale: scale,
                                    child: child,
                                  );
                                },
                                child: Image.asset(
                                  'assets/image/image_changepass_success.png',
                                  width: (size.width * 0.36).clamp(
                                    128.0,
                                    164.0,
                                  ),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: compact ? 48 : 62),
                        _AnimatedEntrance(
                          delay: const Duration(milliseconds: 360),
                          beginOffset: const Offset(0, 14),
                          child: SizedBox(
                            width: (size.width * 0.54).clamp(170.0, 216.0),
                            height: 50,
                            child: FilledButton(
                              onPressed: controller.backToLogin,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor:
                                    ForgotPasswordView._primaryColor,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                textStyle: AppTextStyles.button.copyWith(
                                  fontSize: AppFontSizes.md,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              child: Text('auth.login'.tr),
                            ),
                          ),
                        ),
                        Spacer(flex: compact ? 3 : 4),
                      ],
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

class _AnimatedEntrance extends StatelessWidget {
  const _AnimatedEntrance({
    required this.child,
    this.delay = const Duration(milliseconds: 120),
    this.duration = const Duration(milliseconds: 620),
    this.beginOffset = const Offset(0, 20),
    this.beginScale = 1,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset beginOffset;
  final double beginScale;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: delay + duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final delayedValue = _delayedProgress(value);
        final offset = Offset.lerp(beginOffset, Offset.zero, delayedValue)!;
        final scale = beginScale + (1 - beginScale) * delayedValue;

        return Opacity(
          opacity: delayedValue,
          child: Transform.translate(
            offset: offset,
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: child,
    );
  }

  double _delayedProgress(double value) {
    if (delay == Duration.zero) {
      return value;
    }

    final totalMs = delay.inMilliseconds + duration.inMilliseconds;
    final delayPortion = delay.inMilliseconds / totalMs;
    if (value <= delayPortion) {
      return 0;
    }

    final normalized = (value - delayPortion) / (1 - delayPortion);
    return Curves.easeOutCubic.transform(normalized.clamp(0, 1));
  }
}

class _SuccessBackground extends StatelessWidget {
  const _SuccessBackground();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ForgotPasswordView._primaryColor,
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -80,
            child: _BackgroundCircle(
              size: 260,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Positioned(
            top: 118,
            left: -118,
            child: _BackgroundCircle(
              size: 260,
              color: const Color(0xFF5660B7).withValues(alpha: 0.28),
            ),
          ),
          Positioned(
            right: -110,
            bottom: -130,
            child: _BackgroundCircle(
              size: 320,
              color: const Color(0xFF1F255C).withValues(alpha: 0.42),
            ),
          ),
          Positioned(
            left: 28,
            right: 28,
            top: 150,
            child: Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundCircle extends StatelessWidget {
  const _BackgroundCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _AuthTitle extends StatelessWidget {
  const _AuthTitle({required this.title, this.subtitle, this.highlight});

  final String title;
  final String? subtitle;
  final String? highlight;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.h3.copyWith(
              color: ForgotPasswordView._primaryColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 12),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: ForgotPasswordView._mutedTextColor,
                fontSize: AppFontSizes.md,
                height: 1.35,
              ),
            ),
          ],
          if (highlight != null && highlight!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              highlight!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyStrong.copyWith(
                color: const Color(0xFF33343C),
                fontSize: AppFontSizes.lg,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
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
        color: const Color(0xFF33343C),
        fontSize: AppFontSizes.md,
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.suffixIcon,
    this.onSuffixTap,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textInputAction: textInputAction,
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
          suffixIcon: suffixIcon == null
              ? null
              : IconButton(
                  onPressed: onSuffixTap,
                  icon: Icon(
                    suffixIcon,
                    color: ForgotPasswordView._primaryColor,
                    size: 23,
                  ),
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: ForgotPasswordView._borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: ForgotPasswordView._primaryColor,
              width: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: ForgotPasswordView._primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          textStyle: AppTextStyles.button.copyWith(
            fontSize: AppFontSizes.md,
            fontWeight: FontWeight.w800,
          ),
        ),
        child: Text(label),
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
