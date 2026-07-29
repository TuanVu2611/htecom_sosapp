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
import 'package:hcmu_sos/ViewModel/Staff/StaffHomeViewModel.dart';
import 'package:image_picker/image_picker.dart';

class StaffInfoViewModel extends GetxController {
  final ImagePicker _imagePicker = ImagePicker();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  final user = Rxn<AuthUserEntity>();
  final avatarBytes = Rxn<Uint8List>();
  final avatarFileName = RxnString();
  final avatarMimeType = RxnString();
  final isLoading = false.obs;
  final isEditing = false.obs;
  final isSaving = false.obs;
  final errorMessage = RxnString();

  AuthUserEntity? _editingSnapshot;

  @override
  void onInit() {
    super.onInit();
    _fillFromUser(AuthSessionStorage.getUser());
    refreshProfile();
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
        title: 'Thông tin cán bộ',
        content: 'Không thể chọn ảnh đại diện.',
      );
    }
  }

  Future<void> saveProfile() async {
    if (!isEditing.value || isSaving.value) {
      return;
    }

    final validationError = _validationError();
    if (validationError != null) {
      Utils.showSnackbar(title: 'Thông tin cán bộ', content: validationError);
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
          message: response.message ?? 'Không thể cập nhật thông tin.',
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
        title: 'Thông tin cán bộ',
        content: 'Cập nhật thông tin thành công.',
      );
    } on ApiException catch (error) {
      Utils.showSnackbar(title: 'Thông tin cán bộ', content: error.message);
    } catch (_) {
      Utils.showSnackbar(
        title: 'Thông tin cán bộ',
        content: 'Không thể cập nhật thông tin.',
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> refreshProfile() async {
    if (isLoading.value || isEditing.value) {
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;
    try {
      final refreshedUser = await AuthSessionService().getCurrentUser();
      _fillFromUser(refreshedUser);
      _refreshProfileConsumers();
    } on ApiException catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value = 'Khong the tai thong tin nhan vien.';
    } finally {
      isLoading.value = false;
    }
  }

  void _fillFromUser(AuthUserEntity? value) {
    user.value = value;
    nameController.text = value?.displayName ?? '';
    emailController.text = value?.email ?? '';
    phoneController.text = value?.phone ?? '';
  }

  void _refreshProfileConsumers() {
    if (Get.isRegistered<MenuViewModel>()) {
      Get.find<MenuViewModel>().refreshCurrentUser();
    }
    if (Get.isRegistered<StaffHomeViewModel>()) {
      Get.find<StaffHomeViewModel>().refreshCurrentUser();
    }
  }

  String? _validationError() {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();

    if (name.isEmpty) {
      return 'Vui lòng nhập họ và tên.';
    }
    if (!_hasAtLeastTwoWords(name)) {
      return Get.locale?.languageCode == 'en'
          ? 'Full name must contain at least 2 words.'
          : 'Họ và tên cần có ít nhất 2 từ.';
    }
    if (phone.isEmpty) {
      return 'Vui lòng nhập số điện thoại.';
    }
    if (email.isEmpty) {
      return 'Vui lòng nhập email.';
    }
    if (!GetUtils.isEmail(email)) {
      return 'Email không hợp lệ.';
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
    emailController.dispose();
    phoneController.dispose();
    super.onClose();
  }
}
