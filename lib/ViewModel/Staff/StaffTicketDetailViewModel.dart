// ignore_for_file: file_names

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/SupportRequestEntity.dart';
import 'package:hcmu_sos/Repository/SupportRequestRepository.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';
import 'package:hcmu_sos/Utils/Utils.dart';
import 'package:image_picker/image_picker.dart';

const int maxStaffAcceptanceImages = 3;
const int maxStaffAcceptanceImageBytes = 5 * 1024 * 1024;

class StaffAcceptanceImageDraft {
  const StaffAcceptanceImageDraft({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;
}

class StaffTicketDetailViewModel extends GetxController {
  StaffTicketDetailViewModel({SupportRequestRepository? requestRepository})
    : _requestRepository = requestRepository ?? SupportRequestRepository();

  final SupportRequestRepository _requestRepository;
  final ImagePicker _imagePicker = ImagePicker();

  final acceptanceController = TextEditingController();
  final isLoading = false.obs;
  final isUpdatingStatus = false.obs;
  final isSubmittingAcceptance = false.obs;
  final isLoadingTransferOptions = false.obs;
  final isSubmittingTransfer = false.obs;
  final isRejectingRequest = false.obs;
  final isUpdatingChecklist = false.obs;
  final errorMessage = RxnString();
  final detail = Rxn<SupportRequestDetailEntity>();
  final transferOptions = Rxn<StaffTransferOptionsEntity>();
  final acceptanceImages = <StaffAcceptanceImageDraft>[].obs;

  int? requestId;

  @override
  void onInit() {
    super.onInit();
    requestId = _readRequestId();
  }

  @override
  void onReady() {
    super.onReady();
    loadDetail();
  }

  Future<void> loadDetail() async {
    final id = requestId;
    if (id == null || id <= 0 || isLoading.value) {
      if (id == null || id <= 0) {
        Utils.showSnackbar(
          title: 'ticket.detail.title'.tr,
          content: 'staff.ticket.missingId'.tr,
        );
      }
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;
    try {
      detail.value = await _requestRepository.getRequestDetail(id);
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      Utils.showSnackbar(
        title: 'ticket.detail.title'.tr,
        content: error.message,
      );
    } catch (_) {
      errorMessage.value = 'staff.ticket.loadFailed'.tr;
      Utils.showSnackbar(
        title: 'ticket.detail.title'.tr,
        content: 'staff.ticket.loadFailed'.tr,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateStatus({
    required String status,
    String? reason,
    String successMessage = 'staff.ticket.updateSuccess',
  }) async {
    final id = requestId;
    if (id == null || id <= 0 || isUpdatingStatus.value) {
      return false;
    }

    isUpdatingStatus.value = true;
    try {
      await _requestRepository.updateRequestStatus(
        requestId: id,
        status: status,
        reason: reason,
      );
      await loadDetail();
      Utils.showSnackbar(
        title: 'ticket.detail.title'.tr,
        content: successMessage.tr,
      );
      return true;
    } on ApiException catch (error) {
      Utils.showSnackbar(
        title: 'ticket.detail.title'.tr,
        content: error.message,
      );
      return false;
    } catch (_) {
      Utils.showSnackbar(
        title: 'ticket.detail.title'.tr,
        content: 'staff.ticket.updateFailed'.tr,
      );
      return false;
    } finally {
      isUpdatingStatus.value = false;
    }
  }

  Future<StaffTransferOptionsEntity?> loadTransferOptions({
    bool force = false,
  }) async {
    final id = requestId;
    if (id == null || id <= 0 || isLoadingTransferOptions.value) {
      return transferOptions.value;
    }
    if (!force && transferOptions.value != null) {
      return transferOptions.value;
    }

    isLoadingTransferOptions.value = true;
    try {
      final options = await _requestRepository.getStaffTransferOptions(
        requestId: id,
      );
      transferOptions.value = options;
      return options;
    } on ApiException catch (error) {
      Utils.showSnackbar(
        title: 'staff.ticket.transferTitle'.tr,
        content: error.message,
      );
      return null;
    } catch (_) {
      Utils.showSnackbar(
        title: 'staff.ticket.transferTitle'.tr,
        content: 'staff.ticket.transferOptionsFailed'.tr,
      );
      return null;
    } finally {
      isLoadingTransferOptions.value = false;
    }
  }

  Future<bool> transferRequest({
    int? departmentId,
    int? targetStaffId,
    required String reason,
  }) async {
    final id = requestId;
    final normalizedReason = reason.trim();
    if (id == null || id <= 0 || isSubmittingTransfer.value) {
      return false;
    }
    if (targetStaffId == null && departmentId == null) {
      Utils.showSnackbar(
        title: 'staff.ticket.transferTitle'.tr,
        content: 'staff.ticket.transferTargetRequired'.tr,
      );
      return false;
    }
    if (normalizedReason.isEmpty) {
      Utils.showSnackbar(
        title: 'staff.ticket.transferTitle'.tr,
        content: 'staff.ticket.transferReasonRequired'.tr,
      );
      return false;
    }

    isSubmittingTransfer.value = true;
    try {
      await _requestRepository.transferStaffRequest(
        requestId: id,
        departmentId: departmentId,
        targetStaffId: targetStaffId,
        reason: normalizedReason,
      );
      await loadDetail();
      return true;
    } on ApiException catch (error) {
      Utils.showSnackbar(
        title: 'staff.ticket.transferTitle'.tr,
        content: error.message,
      );
      return false;
    } catch (_) {
      Utils.showSnackbar(
        title: 'staff.ticket.transferTitle'.tr,
        content: 'staff.ticket.transferFailed'.tr,
      );
      return false;
    } finally {
      isSubmittingTransfer.value = false;
    }
  }

  Future<bool> rejectRequest({required String reason}) async {
    final id = requestId;
    final normalizedReason = reason.trim();
    if (id == null || id <= 0 || isRejectingRequest.value) {
      return false;
    }
    if (normalizedReason.isEmpty) {
      Utils.showSnackbar(
        title: 'staff.ticket.rejectTitle'.tr,
        content: 'staff.ticket.rejectReasonRequired'.tr,
      );
      return false;
    }

    isRejectingRequest.value = true;
    try {
      await _requestRepository.rejectStaffRequest(
        requestId: id,
        reason: normalizedReason,
      );
      await loadDetail();
      return true;
    } on ApiException catch (error) {
      Utils.showSnackbar(
        title: 'staff.ticket.rejectTitle'.tr,
        content: error.message,
      );
      return false;
    } catch (_) {
      Utils.showSnackbar(
        title: 'staff.ticket.rejectTitle'.tr,
        content: 'staff.ticket.rejectFailed'.tr,
      );
      return false;
    } finally {
      isRejectingRequest.value = false;
    }
  }

  Future<void> pickAcceptanceImages() async {
    final remainingSlots = maxStaffAcceptanceImages - acceptanceImages.length;
    if (remainingSlots <= 0) {
      return;
    }

    try {
      final pickedImages = <XFile>[];
      if (remainingSlots == 1) {
        final image = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1600,
        );
        if (image != null) {
          pickedImages.add(image);
        }
      } else {
        pickedImages.addAll(
          await _imagePicker.pickMultiImage(
            imageQuality: 85,
            maxWidth: 1600,
            limit: remainingSlots,
          ),
        );
      }

      var hasOversizedImage = false;
      final drafts = <StaffAcceptanceImageDraft>[];
      for (final image in pickedImages.take(remainingSlots)) {
        final bytes = await image.readAsBytes();
        if (bytes.lengthInBytes > maxStaffAcceptanceImageBytes) {
          hasOversizedImage = true;
          continue;
        }
        drafts.add(
          StaffAcceptanceImageDraft(
            bytes: bytes,
            fileName: image.name,
            mimeType: image.mimeType ?? _mimeTypeFromFileName(image.name),
          ),
        );
      }
      acceptanceImages.addAll(drafts);
      if (hasOversizedImage) {
        Utils.showSnackbar(
          title: 'ticket.detail.acceptance'.tr,
          content: 'staff.ticket.acceptancePhotoTooLarge'.tr,
        );
      }
    } catch (_) {
      Utils.showSnackbar(
        title: 'ticket.detail.acceptance'.tr,
        content: 'staff.ticket.acceptancePickFailed'.tr,
      );
    }
  }

  void removeAcceptanceImage(StaffAcceptanceImageDraft draft) {
    acceptanceImages.remove(draft);
  }

  Future<bool> updateChecklist({
    required List<Map<String, dynamic>> checklist,
  }) async {
    final id = requestId;
    if (id == null || id <= 0 || isUpdatingChecklist.value) {
      return false;
    }

    final normalizedChecklist = checklist
        .where((item) => item['id'] != null)
        .map(
          (item) => <String, dynamic>{
            'id': item['id'],
            'name': (item['name'] as String?)?.trim() ?? '',
            'is_done': item['is_done'] == true,
            'check_date': item['check_date'],
            'sequence': item['sequence'] ?? 0,
          },
        )
        .toList();

    isUpdatingChecklist.value = true;
    try {
      await _requestRepository.updateStaffRequestChecklist(
        requestId: id,
        checklist: normalizedChecklist,
      );
      await loadDetail();
      Utils.showSnackbar(
        title: 'staff.ticket.processingGuide'.tr,
        content: 'staff.ticket.checklistUpdateSuccess'.tr,
      );
      return true;
    } on ApiException catch (error) {
      Utils.showSnackbar(
        title: 'staff.ticket.processingGuide'.tr,
        content: error.message,
      );
      return false;
    } catch (_) {
      Utils.showSnackbar(
        title: 'staff.ticket.processingGuide'.tr,
        content: 'staff.ticket.checklistUpdateFailed'.tr,
      );
      return false;
    } finally {
      isUpdatingChecklist.value = false;
    }
  }

  Future<bool> completeRequest() async {
    if (isSubmittingAcceptance.value) {
      return false;
    }
    final id = requestId;
    final acceptanceNote = acceptanceController.text.trim();
    if (id == null || id <= 0) {
      return false;
    }
    if (acceptanceNote.isEmpty) {
      Utils.showSnackbar(
        title: 'ticket.detail.acceptance'.tr,
        content: 'staff.ticket.acceptanceRequired'.tr,
      );
      return false;
    }

    isSubmittingAcceptance.value = true;
    try {
      final acceptanceImageIds = <int>[];
      for (final image in acceptanceImages) {
        acceptanceImageIds.add(
          await Utils.uploadFile(
            bytes: image.bytes,
            fileName: image.fileName,
            mimeType: image.mimeType,
            purpose: 'acceptance_image',
          ),
        );
      }

      await _requestRepository.completeStaffRequest(
        requestId: id,
        acceptanceNote: acceptanceNote,
        acceptanceImageIds: acceptanceImageIds,
      );
      acceptanceController.clear();
      acceptanceImages.clear();
      await loadDetail();
      Utils.showSnackbar(
        title: 'ticket.detail.title'.tr,
        content: 'staff.ticket.completeSuccess'.tr,
      );
      return true;
    } on ApiException catch (error) {
      Utils.showSnackbar(
        title: 'ticket.detail.title'.tr,
        content: error.message,
      );
      return false;
    } catch (_) {
      Utils.showSnackbar(
        title: 'ticket.detail.title'.tr,
        content: 'staff.ticket.completeFailed'.tr,
      );
      return false;
    } finally {
      isSubmittingAcceptance.value = false;
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

  int? _readRequestId() {
    final args = Get.arguments;
    if (args is int) {
      return args;
    }
    if (args is String) {
      return int.tryParse(args);
    }
    if (args is Map) {
      final value = args['id'] ?? args['request_id'] ?? args['requestId'];
      if (value is int) {
        return value;
      }
      if (value is String) {
        return int.tryParse(value);
      }
    }
    final param = Get.parameters['id'] ?? Get.parameters['request_id'];
    return param == null ? null : int.tryParse(param);
  }

  @override
  void onClose() {
    acceptanceController.dispose();
    super.onClose();
  }
}
