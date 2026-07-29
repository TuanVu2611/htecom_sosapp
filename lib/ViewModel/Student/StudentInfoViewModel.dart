// ignore_for_file: file_names

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/AuthUserEntity.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';
import 'package:hcmu_sos/Service/AuthSessionService.dart';
import 'package:hcmu_sos/Service/AuthSessionStorage.dart';
import 'package:hcmu_sos/Utils/Utils.dart';
import 'package:hcmu_sos/ViewModel/Common/MenuViewModel.dart';
import 'package:hcmu_sos/ViewModel/Student/StudentHomeViewModel.dart';
import 'package:image_picker/image_picker.dart';

class StudentInfoViewModel extends GetxController {
  final ImagePicker _imagePicker = ImagePicker();

  final nameController = TextEditingController();
  final studentCodeController = TextEditingController();
  final cccdController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  final user = Rxn<AuthUserEntity>();
  final avatarBytes = Rxn<Uint8List>();
  final avatarFileName = RxnString();
  final avatarMimeType = RxnString();
  final isEditing = false.obs;
  final isSaving = false.obs;

  AuthUserEntity? _editingSnapshot;

  @override
  void onInit() {
    super.onInit();
    _fillFromUser(AuthSessionStorage.getUser());
  }

  void startEditing() {
    if (isSaving.value) {
      return;
    }
    _editingSnapshot = user.value;
    isEditing.value = true;
  }

  void cancelEditing() {
    if (isSaving.value) {
      return;
    }
    _fillFromUser(_editingSnapshot ?? user.value);
    avatarBytes.value = null;
    avatarFileName.value = null;
    avatarMimeType.value = null;
    isEditing.value = false;
  }

  Future<void> pickAvatar() async {
    if (!isEditing.value) {
      return;
    }

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (image == null) {
        return;
      }
      avatarBytes.value = await image.readAsBytes();
      avatarFileName.value = image.name;
      avatarMimeType.value =
          image.mimeType ?? _mimeTypeFromFileName(image.name);
    } catch (_) {
      Utils.showSnackbar(
        title: 'student.info.title'.tr,
        content: 'student.info.avatarPickFailed'.tr,
      );
    }
  }

  Future<void> saveProfile() async {
    if (!isEditing.value || isSaving.value) {
      return;
    }

    final validationError = _validationError();
    if (validationError != null) {
      Utils.showSnackbar(
        title: 'student.info.title'.tr,
        content: validationError.tr,
      );
      return;
    }

    isSaving.value = true;
    try {
      final selectedAvatarBytes = avatarBytes.value;
      int? avatarFileId;
      if (selectedAvatarBytes != null) {
        avatarFileId = await Utils.uploadFile(
          bytes: selectedAvatarBytes,
          fileName: avatarFileName.value ?? 'avatar.jpg',
          mimeType: avatarMimeType.value ?? 'image/jpeg',
          purpose: 'avatar',
        );
      }

      final response = await ApiCaller.getInstance()
          .postBase<Object?>('user/update_profile', <String, dynamic>{
            'name': nameController.text.trim(),
            'phone': phoneController.text.trim(),
            'email': emailController.text.trim(),
            'avatar_file_id': avatarFileId,
          });

      if (!response.success) {
        throw ApiException(
          message: response.message ?? 'student.info.updateFailed'.tr,
          code: response.code,
          data: response.raw,
        );
      }

      final refreshedUser = await AuthSessionService().getCurrentUser();
      _fillFromUser(refreshedUser);
      _refreshProfileConsumers();
      avatarBytes.value = null;
      avatarFileName.value = null;
      avatarMimeType.value = null;
      _editingSnapshot = refreshedUser;
      isEditing.value = false;
      Utils.showSnackbar(
        title: 'student.info.title'.tr,
        content: 'student.info.updateSuccess'.tr,
      );
    } on ApiException catch (error) {
      Utils.showSnackbar(
        title: 'student.info.title'.tr,
        content: error.message,
      );
    } catch (_) {
      Utils.showSnackbar(
        title: 'student.info.title'.tr,
        content: 'student.info.updateFailed'.tr,
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> refreshProfile() async {
    if (isSaving.value || isEditing.value) {
      return;
    }

    try {
      final refreshedUser = await AuthSessionService().getCurrentUser();
      _fillFromUser(refreshedUser);
      _editingSnapshot = refreshedUser;
      _refreshProfileConsumers();
    } catch (_) {}
  }

  void _fillFromUser(AuthUserEntity? value) {
    user.value = value;
    nameController.text = value?.displayName ?? '';
    studentCodeController.text = value?.studentCode ?? '';
    cccdController.text = value?.cccd ?? '';
    emailController.text = value?.email ?? '';
    phoneController.text = value?.phone ?? '';
  }

  void _refreshProfileConsumers() {
    if (Get.isRegistered<MenuViewModel>()) {
      Get.find<MenuViewModel>().refreshCurrentUser();
    }
    if (Get.isRegistered<StudentHomeViewModel>()) {
      Get.find<StudentHomeViewModel>().refreshCurrentUser();
    }
  }

  String? _validationError() {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();

    if (name.isEmpty) {
      return 'student.info.validation.nameRequired';
    }
    if (!_hasAtLeastTwoWords(name)) {
      return 'student.info.validation.nameInvalid';
    }
    if (phone.isEmpty) {
      return 'student.info.validation.phoneRequired';
    }
    if (email.isEmpty) {
      return 'student.info.validation.emailRequired';
    }
    if (!GetUtils.isEmail(email)) {
      return 'student.info.validation.emailInvalid';
    }
    return null;
  }

  bool _hasAtLeastTwoWords(String value) {
    return value
            .split(RegExp(r'\s+'))
            .where((word) => word.isNotEmpty)
            .length >=
        2;
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

  @override
  void onClose() {
    nameController.dispose();
    studentCodeController.dispose();
    cccdController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.onClose();
  }
}
