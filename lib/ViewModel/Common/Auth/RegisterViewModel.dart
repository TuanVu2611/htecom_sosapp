// ignore_for_file: file_names

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/InstitutionEntity.dart';
import 'package:hcmu_sos/Navigator/AppRoute.dart';
import 'package:hcmu_sos/Repository/AuthRepository.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';
import 'package:hcmu_sos/Theme/AppTypography.dart';
import 'package:hcmu_sos/Utils/Utils.dart';
import 'package:image_picker/image_picker.dart';

enum RegisterField {
  fullName,
  phone,
  email,
  cccd,
  studentCode,
  studentCardFront,
  studentCardBack,
  idCardFront,
  idCardBack,
  institution,
  password,
  confirmPassword,
}

enum RegisterStep { form, verifyOtp }

class RegisterViewModel extends GetxController {
  RegisterViewModel({required this.authRepository});

  final AuthRepository authRepository;
  final ImagePicker _imagePicker = ImagePicker();

  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final cccdController = TextEditingController();
  final studentCodeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final focusNodes = <RegisterField, FocusNode>{
    for (final field in RegisterField.values) field: FocusNode(),
  };
  final fieldErrors = <RegisterField, String>{}.obs;

  final institutions = <InstitutionEntity>[].obs;
  final selectedInstitution = Rxn<InstitutionEntity>();
  final idCardFrontImagePath = RxnString();
  final idCardBackImagePath = RxnString();
  final studentCardFrontImagePath = RxnString();
  final studentCardBackImagePath = RxnString();
  final idCardFrontImageName = RxnString();
  final idCardBackImageName = RxnString();
  final studentCardFrontImageName = RxnString();
  final studentCardBackImageName = RxnString();
  final idCardFrontMimeType = RxnString();
  final idCardBackMimeType = RxnString();
  final studentCardFrontMimeType = RxnString();
  final studentCardBackMimeType = RxnString();
  final idCardFrontImageBytes = Rxn<Uint8List>();
  final idCardBackImageBytes = Rxn<Uint8List>();
  final studentCardFrontImageBytes = Rxn<Uint8List>();
  final studentCardBackImageBytes = Rxn<Uint8List>();
  final obscurePassword = true.obs;
  final obscureConfirmPassword = true.obs;
  final isLoadingInstitutions = false.obs;
  final isRegistering = false.obs;
  final isVerifyingOtp = false.obs;
  final step = RegisterStep.form.obs;
  final maskedReceiver = ''.obs;
  final countdownSeconds = 0.obs;
  final otpController = TextEditingController();

  Timer? _countdownTimer;
  int? _registerRequestId;

  String get formattedCountdown {
    final totalSeconds = countdownSeconds.value;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void onInit() {
    super.onInit();
    loadInstitutions();
  }

  Future<void> loadInstitutions({bool forceRefresh = false}) async {
    if (isLoadingInstitutions.value) {
      return;
    }

    isLoadingInstitutions.value = true;
    try {
      final items = await authRepository.getInstitutions(
        forceRefresh: forceRefresh,
      );
      institutions.assignAll(items);
      final selected = selectedInstitution.value;
      if (selected != null && !items.any((item) => item.id == selected.id)) {
        selectedInstitution.value = null;
      }
    } catch (error) {
      Utils.showSnackbar(
        title: 'auth.register'.tr,
        content: error is ApiException
            ? error.message
            : 'auth.institutionsLoadFailed'.tr,
      );
    } finally {
      isLoadingInstitutions.value = false;
    }
  }

  void selectInstitution(InstitutionEntity? institution) {
    selectedInstitution.value = institution;
    if (institution != null) {
      clearFieldError(RegisterField.institution);
    }
  }

  String? errorText(RegisterField field) => fieldErrors[field]?.tr;

  FocusNode focusNode(RegisterField field) => focusNodes[field]!;

  void clearFieldError(RegisterField field) {
    fieldErrors.remove(field);
  }

  void togglePasswordVisibility() {
    obscurePassword.toggle();
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.toggle();
  }

  Future<void> pickIdCardFrontImage() async {
    final image = await _pickImageFromGallery();
    if (image == null) {
      return;
    }

    final bytes = await image.readAsBytes();
    idCardFrontImagePath.value = image.path;
    idCardFrontImageName.value = image.name;
    idCardFrontMimeType.value =
        image.mimeType ?? _mimeTypeFromFileName(image.name);
    idCardFrontImageBytes.value = bytes;
    clearFieldError(RegisterField.idCardFront);
  }

  Future<void> pickIdCardBackImage() async {
    final image = await _pickImageFromGallery();
    if (image == null) {
      return;
    }

    final bytes = await image.readAsBytes();
    idCardBackImagePath.value = image.path;
    idCardBackImageName.value = image.name;
    idCardBackMimeType.value =
        image.mimeType ?? _mimeTypeFromFileName(image.name);
    idCardBackImageBytes.value = bytes;
    clearFieldError(RegisterField.idCardBack);
  }

  Future<void> pickStudentCardFrontImage() async {
    final image = await _pickImageFromGallery();
    if (image == null) {
      return;
    }

    final bytes = await image.readAsBytes();
    studentCardFrontImagePath.value = image.path;
    studentCardFrontImageName.value = image.name;
    studentCardFrontMimeType.value =
        image.mimeType ?? _mimeTypeFromFileName(image.name);
    studentCardFrontImageBytes.value = bytes;
    clearFieldError(RegisterField.studentCardFront);
  }

  Future<void> pickStudentCardBackImage() async {
    final image = await _pickImageFromGallery();
    if (image == null) {
      return;
    }

    final bytes = await image.readAsBytes();
    studentCardBackImagePath.value = image.path;
    studentCardBackImageName.value = image.name;
    studentCardBackMimeType.value =
        image.mimeType ?? _mimeTypeFromFileName(image.name);
    studentCardBackImageBytes.value = bytes;
    clearFieldError(RegisterField.studentCardBack);
  }

  Future<void> register() async {
    if (isRegistering.value) {
      return;
    }

    final validationErrors = _getValidationErrors();
    fieldErrors.assignAll(validationErrors);
    if (validationErrors.isNotEmpty) {
      final firstInvalidField = validationErrors.keys.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final focusNode = focusNodes[firstInvalidField];
        focusNode?.requestFocus();
        final fieldContext = focusNode?.context;
        if (fieldContext != null) {
          Scrollable.ensureVisible(
            fieldContext,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: 0.18,
          );
        }
      });
      return;
    }

    isRegistering.value = true;
    try {
      final idCardFrontBytes = idCardFrontImageBytes.value;
      final idCardFrontFileId = idCardFrontBytes == null
          ? null
          : await Utils.uploadFile(
              bytes: idCardFrontBytes,
              fileName: idCardFrontImageName.value ?? 'id_card_front.jpg',
              mimeType: idCardFrontMimeType.value ?? 'image/jpeg',
              purpose: 'student_card',
              skipAuth: true,
            );
      final idCardBackBytes = idCardBackImageBytes.value;
      final idCardBackFileId = idCardBackBytes == null
          ? null
          : await Utils.uploadFile(
              bytes: idCardBackBytes,
              fileName: idCardBackImageName.value ?? 'id_card_back.jpg',
              mimeType: idCardBackMimeType.value ?? 'image/jpeg',
              purpose: 'student_card',
              skipAuth: true,
            );
      final studentCardFrontFileId = await Utils.uploadFile(
        bytes: studentCardFrontImageBytes.value!,
        fileName: studentCardFrontImageName.value ?? 'student_card_front.jpg',
        mimeType: studentCardFrontMimeType.value ?? 'image/jpeg',
        purpose: 'student_card',
        skipAuth: true,
      );
      final studentCardBackFileId = await Utils.uploadFile(
        bytes: studentCardBackImageBytes.value!,
        fileName: studentCardBackImageName.value ?? 'student_card_back.jpg',
        mimeType: studentCardBackMimeType.value ?? 'image/jpeg',
        purpose: 'student_card',
        skipAuth: true,
      );

      final otpRequest = await authRepository.registerStudent(
        fullName: fullNameController.text.trim(),
        phone: phoneController.text.trim(),
        email: emailController.text.trim(),
        cccd: cccdController.text.trim(),
        studentCode: studentCodeController.text.trim(),
        schoolId: selectedInstitution.value!.id,
        studentCardFrontFileId: studentCardFrontFileId,
        studentCardBackFileId: studentCardBackFileId,
        nationalCardFrontId: idCardFrontFileId,
        nationalCardBackId: idCardBackFileId,
        password: passwordController.text,
        confirmPassword: confirmPasswordController.text,
      );
      _registerRequestId = otpRequest.requestId;
      maskedReceiver.value = otpRequest.maskedReceiver.isNotEmpty
          ? otpRequest.maskedReceiver
          : emailController.text.trim();
      otpController.clear();
      step.value = RegisterStep.verifyOtp;
      _startCountdown(otpRequest.expiredIn);
    } catch (error) {
      Utils.showSnackbar(
        title: 'auth.register'.tr,
        content: error is ApiException
            ? error.message
            : 'auth.registerFailed'.tr,
      );
    } finally {
      isRegistering.value = false;
    }
  }

  Future<void> verifyOtp() async {
    if (isVerifyingOtp.value) {
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

    final requestId = _registerRequestId;
    if (requestId == null || requestId <= 0) {
      Utils.showSnackbar(
        title: 'auth.verifyOtp'.tr,
        content: 'auth.registerFailed'.tr,
      );
      return;
    }

    isVerifyingOtp.value = true;
    try {
      await authRepository.verifyRegisterOtp(requestId: requestId, otp: otp);
      await _showRegisterSuccessDialog();
    } catch (error) {
      Utils.showSnackbar(
        title: 'auth.verifyOtp'.tr,
        content: error is ApiException
            ? error.message
            : 'auth.registerFailed'.tr,
      );
    } finally {
      isVerifyingOtp.value = false;
    }
  }

  void backToRegisterForm() {
    _countdownTimer?.cancel();
    step.value = RegisterStep.form;
  }

  void openLogin() {
    Get.back<void>();
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

  Future<void> _showRegisterSuccessDialog() {
    return Get.dialog<void>(
      _RegisterSuccessDialog(
        onOk: () {
          Get.back<void>();
          Get.until((route) => route.settings.name == AppRoute.login);
        },
      ),
      barrierDismissible: false,
    );
  }

  Future<XFile?> _pickImageFromGallery() async {
    try {
      return _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
    } catch (_) {
      Utils.showSnackbar(
        title: 'auth.register'.tr,
        content: 'auth.imagePickFailed'.tr,
      );
      return null;
    }
  }

  String _mimeTypeFromFileName(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      _ => 'image/jpeg',
    };
  }

  Map<RegisterField, String> _getValidationErrors() {
    final fullName = fullNameController.text.trim();
    final phoneNumber = phoneController.text.trim();
    final email = emailController.text.trim();
    final cccd = cccdController.text.trim();
    final studentCode = studentCodeController.text.trim();
    final institution = selectedInstitution.value;
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    final errors = <RegisterField, String>{};

    if (fullName.isEmpty) {
      errors[RegisterField.fullName] = 'auth.validation.fullNameRequired';
    } else if (fullName.split(RegExp(r'\s+')).length < 2) {
      errors[RegisterField.fullName] = 'auth.validation.fullNameInvalid';
    }

    if (phoneNumber.isEmpty) {
      errors[RegisterField.phone] = 'auth.validation.phoneRequired';
    } else if (!RegExp(r'^(0|\+84)[0-9]{9,10}$').hasMatch(phoneNumber)) {
      errors[RegisterField.phone] = 'auth.validation.phoneInvalid';
    }

    if (email.isEmpty) {
      errors[RegisterField.email] = 'auth.validation.emailRequired';
    } else if (!GetUtils.isEmail(email)) {
      errors[RegisterField.email] = 'auth.validation.emailInvalid';
    }

    if (cccd.isEmpty) {
      errors[RegisterField.cccd] = 'auth.validation.cccdRequired';
    } else if (!RegExp(r'^[a-zA-Z0-9]{9,30}$').hasMatch(cccd)) {
      errors[RegisterField.cccd] = 'auth.validation.cccdInvalid';
    }

    if (studentCode.isEmpty) {
      errors[RegisterField.studentCode] = 'auth.validation.studentCodeRequired';
    } else if (!RegExp(r'^[A-Za-z0-9_-]{4,20}$').hasMatch(studentCode)) {
      errors[RegisterField.studentCode] = 'auth.validation.studentCodeInvalid';
    }

    if (studentCardFrontImageBytes.value == null) {
      errors[RegisterField.studentCardFront] =
          'auth.validation.studentCardFrontRequired';
    }
    if (studentCardBackImageBytes.value == null) {
      errors[RegisterField.studentCardBack] =
          'auth.validation.studentCardBackRequired';
    }

    if (institution == null ||
        !institutions.any((item) => item.id == institution.id)) {
      errors[RegisterField.institution] = 'auth.validation.schoolRequired';
    }

    if (password.isEmpty) {
      errors[RegisterField.password] = 'auth.validation.passwordRequired';
    }
    // else if (password.length < 8) {
    //   errors[RegisterField.password] = 'auth.validation.passwordTooShort';
    // }
    else if (!RegExp(
      r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,20}$',
    ).hasMatch(password)) {
      errors[RegisterField.password] = 'auth.validation.passwordWeak';
    }

    if (confirmPassword.isEmpty) {
      errors[RegisterField.confirmPassword] =
          'auth.validation.confirmPasswordRequired';
    } else if (password != confirmPassword) {
      errors[RegisterField.confirmPassword] =
          'auth.validation.confirmPasswordMismatch';
    }

    return errors;
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    cccdController.dispose();
    studentCodeController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    otpController.dispose();
    for (final focusNode in focusNodes.values) {
      focusNode.dispose();
    }
    super.onClose();
  }
}

class _RegisterSuccessDialog extends StatelessWidget {
  const _RegisterSuccessDialog({required this.onOk});

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
              'auth.registerSuccess'.tr,
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle.copyWith(
                color: _primaryColor,
                fontSize: AppFontSizes.xl,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'auth.registerPendingApproval'.tr,
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
