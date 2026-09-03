// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/InstitutionEntity.dart';
import 'package:hcmu_sos/Theme/AppTypography.dart';
import 'package:hcmu_sos/ViewModel/Common/Auth/RegisterViewModel.dart';

class RegisterView extends GetWidget<RegisterViewModel> {
  const RegisterView({super.key});

  static const Color _primaryColor = Color(0xFF29306F);
  static const Color _mutedTextColor = Color(0xFF6F717C);
  static const Color _borderColor = Color(0xFFE2E4EC);
  static const Color _uploadFillColor = Color(0xFFFAFAFC);
  static const Color _errorColor = Color(0xFFD92D20);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Obx(
        () => controller.step.value == RegisterStep.verifyOtp
            ? _RegisterOtpStep(controller: controller)
            : Scaffold(
                backgroundColor: Colors.white,
                body: SafeArea(
                  bottom: false,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = constraints.biggest;
                      final compact = size.height < 760;
                      final horizontalPadding = size.width < 390 ? 16.0 : 28.0;

                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          compact ? 18 : 42,
                          horizontalPadding,
                          compact ? 22 : 32,
                        ),
                        child: _RegisterFormStep(
                          controller: controller,
                          compact: compact,
                          size: size,
                        ),
                      );
                    },
                  ),
                ),
              ),
      ),
    );
  }
}

class _RegisterFormStep extends StatelessWidget {
  const _RegisterFormStep({
    required this.controller,
    required this.compact,
    required this.size,
  });

  final RegisterViewModel controller;
  final bool compact;
  final Size size;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SvgPicture.asset(
          'assets/icon/icon_logo.svg',
          width: (size.width * 0.31).clamp(118.0, 154.0),
          fit: BoxFit.contain,
        ),
        SizedBox(height: compact ? 18 : 32),
        Text(
          'auth.register'.tr,
          style: AppTextStyles.h3.copyWith(
            color: RegisterView._primaryColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'auth.registerDescription'.tr,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(
            color: RegisterView._mutedTextColor,
            fontSize: AppFontSizes.md,
            height: 1.35,
          ),
        ),
        SizedBox(height: compact ? 18 : 28),
        Obx(
          () => _RegisterTextField(
            controller: controller.fullNameController,
            focusNode: controller.focusNode(RegisterField.fullName),
            hintText: 'auth.fullName'.tr,
            icon: Icons.person_outline_rounded,
            errorText: controller.errorText(RegisterField.fullName),
            onChanged: (_) =>
                controller.clearFieldError(RegisterField.fullName),
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: 9),
        Obx(
          () => _RegisterTextField(
            controller: controller.phoneController,
            focusNode: controller.focusNode(RegisterField.phone),
            hintText: 'auth.phoneNumber'.tr,
            icon: Icons.phone_in_talk_outlined,
            errorText: controller.errorText(RegisterField.phone),
            onChanged: (_) => controller.clearFieldError(RegisterField.phone),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: 9),
        Obx(
          () => _RegisterTextField(
            controller: controller.emailController,
            focusNode: controller.focusNode(RegisterField.email),
            hintText: 'auth.email'.tr,
            icon: Icons.mail_outline_rounded,
            errorText: controller.errorText(RegisterField.email),
            onChanged: (_) => controller.clearFieldError(RegisterField.email),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: 9),
        Obx(
          () => _RegisterTextField(
            controller: controller.cccdController,
            focusNode: controller.focusNode(RegisterField.cccd),
            hintText: 'auth.cccd'.tr,
            icon: Icons.credit_card_rounded,
            errorText: controller.errorText(RegisterField.cccd),
            onChanged: (_) => controller.clearFieldError(RegisterField.cccd),
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: 9),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Obx(
                () => _IdCardUploadCard(
                  label: 'auth.idCardFront'.tr,
                  isOptional: true,
                  imageBytes: controller.idCardFrontImageBytes.value,
                  focusNode: controller.focusNode(RegisterField.idCardFront),
                  errorText: controller.errorText(RegisterField.idCardFront),
                  onTap: controller.pickIdCardFrontImage,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Obx(
                () => _IdCardUploadCard(
                  label: 'auth.idCardBack'.tr,
                  isOptional: true,
                  imageBytes: controller.idCardBackImageBytes.value,
                  focusNode: controller.focusNode(RegisterField.idCardBack),
                  errorText: controller.errorText(RegisterField.idCardBack),
                  onTap: controller.pickIdCardBackImage,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Obx(
          () => _RegisterTextField(
            controller: controller.studentCodeController,
            focusNode: controller.focusNode(RegisterField.studentCode),
            hintText: 'auth.studentId'.tr,
            icon: Icons.badge_outlined,
            errorText: controller.errorText(RegisterField.studentCode),
            onChanged: (_) =>
                controller.clearFieldError(RegisterField.studentCode),
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: 9),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Obx(
                () => _IdCardUploadCard(
                  label: 'auth.studentCardFront'.tr,
                  imageBytes: controller.studentCardFrontImageBytes.value,
                  focusNode: controller.focusNode(
                    RegisterField.studentCardFront,
                  ),
                  errorText: controller.errorText(
                    RegisterField.studentCardFront,
                  ),
                  onTap: controller.pickStudentCardFrontImage,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Obx(
                () => _IdCardUploadCard(
                  label: 'auth.studentCardBack'.tr,
                  imageBytes: controller.studentCardBackImageBytes.value,
                  focusNode: controller.focusNode(
                    RegisterField.studentCardBack,
                  ),
                  errorText: controller.errorText(
                    RegisterField.studentCardBack,
                  ),
                  onTap: controller.pickStudentCardBackImage,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Obx(
          () => _SchoolSelector(
            value: controller.selectedInstitution.value,
            institutions: controller.institutions,
            isLoading: controller.isLoadingInstitutions.value,
            focusNode: controller.focusNode(RegisterField.institution),
            errorText: controller.errorText(RegisterField.institution),
            onRetry: () => controller.loadInstitutions(forceRefresh: true),
            onChanged: controller.selectInstitution,
          ),
        ),
        const SizedBox(height: 9),
        Obx(
          () => _RegisterTextField(
            controller: controller.passwordController,
            focusNode: controller.focusNode(RegisterField.password),
            hintText: 'auth.password'.tr,
            icon: controller.obscurePassword.value
                ? Icons.lock_outline_rounded
                : Icons.lock_open_rounded,
            obscureText: controller.obscurePassword.value,
            errorText: controller.errorText(RegisterField.password),
            onChanged: (_) =>
                controller.clearFieldError(RegisterField.password),
            onIconTap: controller.togglePasswordVisibility,
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: 9),
        Obx(
          () => _RegisterTextField(
            controller: controller.confirmPasswordController,
            focusNode: controller.focusNode(RegisterField.confirmPassword),
            hintText: 'auth.confirmPassword'.tr,
            icon: controller.obscureConfirmPassword.value
                ? Icons.lock_outline_rounded
                : Icons.lock_open_rounded,
            obscureText: controller.obscureConfirmPassword.value,
            errorText: controller.errorText(RegisterField.confirmPassword),
            onChanged: (_) =>
                controller.clearFieldError(RegisterField.confirmPassword),
            onIconTap: controller.toggleConfirmPasswordVisibility,
            textInputAction: TextInputAction.done,
          ),
        ),
        const SizedBox(height: 9),
        Obx(
          () => SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: controller.isRegistering.value
                  ? null
                  : controller.register,
              style: FilledButton.styleFrom(
                backgroundColor: RegisterView._primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
                textStyle: AppTextStyles.button.copyWith(
                  fontSize: AppFontSizes.lg,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: controller.isRegistering.value
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('auth.register'.tr),
                      ],
                    )
                  : Text('auth.register'.tr),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'auth.registerOtpHint'.tr,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(
            color: RegisterView._mutedTextColor,
            fontSize: AppFontSizes.sm,
            height: 1.45,
          ),
        ),
        SizedBox(height: compact ? 18 : 26),
        _LoginPrompt(onTap: controller.openLogin),
      ],
    );
  }
}

class _RegisterOtpStep extends StatelessWidget {
  const _RegisterOtpStep({required this.controller});

  final RegisterViewModel controller;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          controller.backToRegisterForm();
        }
      },
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
              final keyboardVisible =
                  MediaQuery.viewInsetsOf(context).bottom > 0;
              final showBottomBanner = !keyboardVisible;
              final bottomContentPadding = showBottomBanner
                  ? bannerHeight + 24
                  : 24.0;
              final horizontalPadding = size.width < 390 ? 28.0 : 34.0;

              return Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Visibility(
                      visible: showBottomBanner,
                      child: _OtpBottomBanner(height: bannerHeight),
                    ),
                  ),
                  Positioned.fill(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        compact ? 18 : 24,
                        horizontalPadding,
                        bottomContentPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            onPressed: controller.backToRegisterForm,
                            icon: const Icon(
                              Icons.chevron_left_rounded,
                              size: 28,
                            ),
                            color: RegisterView._primaryColor,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                          ),
                          SizedBox(height: compact ? 18 : 36),
                          Center(
                            child: Text(
                              'auth.verifyOtp'.tr,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.h3.copyWith(
                                color: RegisterView._primaryColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: Text(
                              'auth.verifyOtpDescription'.tr,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body.copyWith(
                                color: RegisterView._mutedTextColor,
                                fontSize: AppFontSizes.md,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: Obx(
                              () => Text(
                                controller.maskedReceiver.value,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.subtitle.copyWith(
                                  color: const Color(0xFF161B2C),
                                  fontSize: AppFontSizes.xl,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: compact ? 48 : 76),
                          Text(
                            'auth.otpCode'.tr,
                            style: AppTextStyles.bodyStrong.copyWith(
                              color: const Color(0xFF22242C),
                              fontSize: AppFontSizes.md,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _RegisterTextField(
                            controller: controller.otpController,
                            hintText: 'auth.inputPlaceholder'.tr,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            onChanged: (_) {},
                          ),
                          const SizedBox(height: 20),
                          Obx(
                            () => SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: FilledButton(
                                onPressed: controller.isVerifyingOtp.value
                                    ? null
                                    : controller.verifyOtp,
                                style: FilledButton.styleFrom(
                                  backgroundColor: RegisterView._primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  textStyle: AppTextStyles.button.copyWith(
                                    fontSize: AppFontSizes.lg,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                child: Text('auth.next'.tr),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Center(
                            child: Obx(
                              () => Text(
                                controller.formattedCountdown,
                                style: AppTextStyles.h3.copyWith(
                                  color: RegisterView._primaryColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              'auth.registerOtpCountdownNote'.tr,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body.copyWith(
                                color: RegisterView._mutedTextColor,
                                fontSize: AppFontSizes.md,
                                height: 1.5,
                              ),
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

class _OtpBottomBanner extends StatelessWidget {
  const _OtpBottomBanner({required this.height});

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

class _RegisterTextField extends StatelessWidget {
  const _RegisterTextField({
    required this.controller,
    required this.hintText,
    this.icon,
    this.focusNode,
    this.obscureText = false,
    this.onIconTap,
    this.onChanged,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final IconData? icon;
  final bool obscureText;
  final VoidCallback? onIconTap;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
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
        suffixIcon: icon == null
            ? null
            : IconButton(
                onPressed: onIconTap,
                icon: Icon(icon, color: RegisterView._primaryColor, size: 23),
              ),
        errorText: errorText,
        errorMaxLines: 2,
        errorStyle: AppTextStyles.caption.copyWith(
          color: RegisterView._errorColor,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: Colors.white,
        constraints: const BoxConstraints(minHeight: 50),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: RegisterView._borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(
            color: RegisterView._primaryColor,
            width: 1.3,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(
            color: RegisterView._errorColor,
            width: 1.2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(
            color: RegisterView._errorColor,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _IdCardUploadCard extends StatelessWidget {
  const _IdCardUploadCard({
    required this.label,
    required this.imageBytes,
    required this.focusNode,
    required this.onTap,
    this.isOptional = false,
    this.errorText,
  });

  final String label;
  final Uint8List? imageBytes;
  final FocusNode focusNode;
  final VoidCallback onTap;
  final bool isOptional;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final selected = imageBytes != null;
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          focusNode: focusNode,
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Ink(
            height: 92,
            decoration: BoxDecoration(
              color: RegisterView._uploadFillColor,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: hasError
                    ? RegisterView._errorColor
                    : selected
                    ? RegisterView._primaryColor
                    : RegisterView._borderColor,
                width: hasError || selected ? 1.2 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (selected)
                    Image.memory(
                      imageBytes!,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                    )
                  else
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.photo_camera_outlined,
                          color: RegisterView._primaryColor,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodyStrong.copyWith(
                                  color: RegisterView._primaryColor,
                                  fontSize: AppFontSizes.md,
                                ),
                              ),
                            ),
                            if (isOptional) ...[
                              const SizedBox(width: 4),
                              Text(
                                'auth.optional'.tr,
                                style: AppTextStyles.caption.copyWith(
                                  color: RegisterView._mutedTextColor,
                                  fontSize: AppFontSizes.xs,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  if (selected)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: RegisterView._primaryColor.withValues(
                            alpha: 0.86,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 5,
                          ),
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (selected)
                    const Positioned(
                      top: 6,
                      right: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: RegisterView._primaryColor,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 5),
          Text(
            errorText!,
            style: AppTextStyles.caption.copyWith(
              color: RegisterView._errorColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _SchoolSelector extends StatelessWidget {
  const _SchoolSelector({
    required this.value,
    required this.institutions,
    required this.isLoading,
    required this.focusNode,
    required this.onRetry,
    required this.onChanged,
    this.errorText,
  });

  final InstitutionEntity? value;
  final List<InstitutionEntity> institutions;
  final bool isLoading;
  final FocusNode focusNode;
  final VoidCallback onRetry;
  final ValueChanged<InstitutionEntity?> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 50,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              focusNode: focusNode,
              onTap: () => _openSchoolPicker(context),
              borderRadius: BorderRadius.circular(9),
              child: Ink(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: hasError
                        ? RegisterView._errorColor
                        : RegisterView._borderColor,
                    width: hasError ? 1.2 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          value?.name ?? 'auth.schoolName'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                            color: value == null
                                ? const Color(0xFF7D7F89)
                                : const Color(0xFF22242C),
                            fontSize: AppFontSizes.lg,
                          ),
                        ),
                      ),
                      if (isLoading)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: RegisterView._primaryColor,
                          ),
                        )
                      else
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: RegisterView._primaryColor,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              errorText!,
              style: AppTextStyles.caption.copyWith(
                color: RegisterView._errorColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openSchoolPicker(BuildContext context) async {
    final searchController = TextEditingController();
    final selectedSchool = await showModalBottomSheet<InstitutionEntity>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: false,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = searchController.text.trim().toLowerCase();
            final filteredInstitutions = query.isEmpty
                ? institutions
                : institutions.where((institution) {
                    return institution.name.toLowerCase().contains(query) ||
                        institution.code.toLowerCase().contains(query);
                  }).toList();

            return FractionallySizedBox(
              heightFactor: 0.68,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Material(
                        color: Colors.white,
                        elevation: 1,
                        shadowColor: Colors.transparent,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(bottom: 10),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: RegisterView._borderColor,
                              ),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Center(
                                child: Container(
                                  width: 46,
                                  height: 5,
                                  margin: const EdgeInsets.only(bottom: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD7DAE5),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'auth.schoolName'.tr,
                                  style: AppTextStyles.title.copyWith(
                                    color: RegisterView._primaryColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: searchController,
                        onChanged: (_) => setModalState(() {}),
                        style: AppTextStyles.body.copyWith(
                          color: const Color(0xFF22242C),
                          fontSize: AppFontSizes.md,
                        ),
                        decoration: InputDecoration(
                          hintText: 'auth.searchSchool'.tr,
                          hintStyle: AppTextStyles.body.copyWith(
                            color: const Color(0xFF9AA0B3),
                            fontSize: AppFontSizes.md,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: RegisterView._primaryColor,
                            size: 20,
                          ),
                          suffixIcon: query.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    searchController.clear();
                                    setModalState(() {});
                                  },
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                  ),
                                  color: RegisterView._mutedTextColor,
                                  visualDensity: VisualDensity.compact,
                                ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(9),
                            borderSide: const BorderSide(
                              color: RegisterView._borderColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(9),
                            borderSide: const BorderSide(
                              color: RegisterView._borderColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(9),
                            borderSide: const BorderSide(
                              color: RegisterView._primaryColor,
                              width: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ColoredBox(
                          color: Colors.white,
                          child: _buildSchoolList(
                            context,
                            items: filteredInstitutions,
                            hasQuery: query.isNotEmpty,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (selectedSchool != null) {
      onChanged(selectedSchool);
    }
  }

  Widget _buildSchoolList(
    BuildContext context, {
    required List<InstitutionEntity> items,
    required bool hasQuery,
  }) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: CircularProgressIndicator(color: RegisterView._primaryColor),
        ),
      );
    }

    if (institutions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'auth.institutionsEmpty'.tr,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: RegisterView._mutedTextColor,
                fontSize: AppFontSizes.md,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('common.retry'.tr),
              style: OutlinedButton.styleFrom(
                foregroundColor: RegisterView._primaryColor,
                side: const BorderSide(color: RegisterView._primaryColor),
              ),
            ),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            hasQuery
                ? 'auth.searchSchoolEmpty'.tr
                : 'auth.institutionsEmpty'.tr,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: RegisterView._mutedTextColor,
              fontSize: AppFontSizes.md,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      primary: false,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final institution = items[index];
        final selected = institution.id == value?.id;
        final borderRadius = BorderRadius.circular(9);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  Navigator.of(context).pop(institution);
                }
              });
            },
            borderRadius: borderRadius,
            child: Container(
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFF1F3FF) : Colors.white,
                borderRadius: borderRadius,
                border: Border.all(
                  color: selected
                      ? RegisterView._primaryColor
                      : RegisterView._borderColor,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        institution.name,
                        style: AppTextStyles.body.copyWith(
                          color: const Color(0xFF22242C),
                          fontSize: AppFontSizes.md,
                        ),
                      ),
                    ),
                    if (institution.code.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        institution.code,
                        style: AppTextStyles.caption.copyWith(
                          color: RegisterView._mutedTextColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'auth.haveAccount'.tr,
          style: AppTextStyles.body.copyWith(
            color: RegisterView._mutedTextColor,
            fontSize: AppFontSizes.md,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            'auth.login'.tr,
            style: AppTextStyles.bodyStrong.copyWith(
              color: RegisterView._primaryColor,
              fontSize: AppFontSizes.md,
            ),
          ),
        ),
      ],
    );
  }
}
