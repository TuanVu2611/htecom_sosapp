// ignore_for_file: file_names

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/StaffHomeEntity.dart';
import 'package:hcmu_sos/Repository/StaffSosRepository.dart';
import 'package:hcmu_sos/Repository/SupportRequestRepository.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';
import 'package:hcmu_sos/Utils/Utils.dart';
import 'package:image_picker/image_picker.dart';

const int maxSosProgressImages = 3;
const int maxSosProgressImageBytes = 5 * 1024 * 1024;

class SosProgressImageDraft {
  const SosProgressImageDraft({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;
}

class SOSDetailViewModel extends GetxController {
  SOSDetailViewModel({
    StaffSosRepository? sosRepository,
    SupportRequestRepository? requestRepository,
  }) : _sosRepository = sosRepository ?? StaffSosRepository(),
       _requestRepository = requestRepository ?? SupportRequestRepository();

  final StaffSosRepository _sosRepository;
  final SupportRequestRepository _requestRepository;
  final ImagePicker _imagePicker = ImagePicker();
  final noteController = TextEditingController();

  final sos = Rxn<StaffActiveSosEntity>();
  final isUpdating = false.obs;
  final isUpdatingChecklist = false.obs;
  final images = <SosProgressImageDraft>[].obs;

  bool get hasCoordinates =>
      sos.value?.latitude != null && sos.value?.longitude != null;

  @override
  void onInit() {
    super.onInit();
    sos.value = _readSos();
  }

  @override
  void onReady() {
    super.onReady();
    refreshDetail();
  }

  Future<void> refreshDetail() async {
    final current = sos.value;
    if (current == null || current.id <= 0 || isUpdating.value) {
      return;
    }

    try {
      sos.value = await _sosRepository.getSosDetail(current.id);
    } catch (_) {}
  }

  Future<bool> updateStatus(String status) async {
    final item = sos.value;
    if (item == null || item.id <= 0 || isUpdating.value) {
      return false;
    }

    final normalizedStatus = status.trim().toLowerCase();
    if (normalizedStatus == 'rejected' && noteController.text.trim().isEmpty) {
      Utils.showSnackbar(
        title: 'sos.title'.tr,
        content: 'sos.cancelReasonRequired'.tr,
      );
      return false;
    }

    isUpdating.value = true;
    try {
      final imageFileIds = await _uploadImages();
      await _sosRepository.updateSos(
        sosId: item.id,
        status: status,
        note: noteController.text,
        imageFileIds: imageFileIds.isEmpty ? null : imageFileIds,
      );
      sos.value = item.copyWith(
        status: status,
        timeline: _reachedTimeline(item.timeline, status),
      );
      images.clear();
      noteController.clear();
      Utils.showSnackbar(
        title: 'SOS khẩn cấp',
        content: 'Cập nhật tiến trình thành công.',
      );
      return true;
    } on ApiException catch (error) {
      Utils.showSnackbar(title: 'SOS khẩn cấp', content: error.message);
      return false;
    } catch (_) {
      Utils.showSnackbar(
        title: 'SOS khẩn cấp',
        content: 'Không thể cập nhật tiến trình SOS.',
      );
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  Future<bool> updateChecklist({
    required List<Map<String, dynamic>> checklist,
  }) async {
    final item = sos.value;
    if (item == null || item.id <= 0 || isUpdatingChecklist.value) {
      return false;
    }

    final normalizedChecklist = checklist
        .where((entry) => entry['id'] != null)
        .map(
          (entry) => <String, dynamic>{
            'id': entry['id'],
            'name': (entry['name'] as String?)?.trim() ?? '',
            'is_done': entry['is_done'] == true,
            'check_date': entry['check_date'],
            'sequence': entry['sequence'] ?? 0,
          },
        )
        .toList();

    isUpdatingChecklist.value = true;
    try {
      await _requestRepository.updateStaffRequestChecklist(
        requestId: item.id,
        checklist: normalizedChecklist,
      );
      await refreshDetail();
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

  Future<void> pickImages() async {
    final remainingSlots = maxSosProgressImages - images.length;
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
      final drafts = <SosProgressImageDraft>[];
      for (final image in pickedImages.take(remainingSlots)) {
        final bytes = await image.readAsBytes();
        if (bytes.lengthInBytes > maxSosProgressImageBytes) {
          hasOversizedImage = true;
          continue;
        }
        drafts.add(
          SosProgressImageDraft(
            bytes: bytes,
            fileName: image.name,
            mimeType: image.mimeType ?? _mimeTypeFromFileName(image.name),
          ),
        );
      }
      images.addAll(drafts);
      if (hasOversizedImage) {
        Utils.showSnackbar(
          title: 'SOS khẩn cấp',
          content: 'Ảnh vượt quá dung lượng 5MB.',
        );
      }
    } catch (_) {
      Utils.showSnackbar(title: 'SOS khẩn cấp', content: 'Không thể chọn ảnh.');
    }
  }

  void removeImage(SosProgressImageDraft image) {
    images.remove(image);
  }

  Future<List<int>> _uploadImages() async {
    final uploadedIds = <int>[];
    for (final image in images) {
      uploadedIds.add(
        await Utils.uploadFile(
          bytes: image.bytes,
          fileName: image.fileName,
          mimeType: image.mimeType,
          purpose: 'sos_progress',
        ),
      );
    }
    return uploadedIds;
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

  List<StaffSosTimelineEntity> _reachedTimeline(
    List<StaffSosTimelineEntity> timeline,
    String status,
  ) {
    final now = DateTime.now();
    final targetIndex = timeline.indexWhere((step) => step.status == status);
    return timeline.asMap().entries.map((entry) {
      final index = entry.key;
      final step = entry.value;
      final shouldReach = status == 'rejected'
          ? step.status == status
          : targetIndex >= 0 &&
                index <= targetIndex &&
                step.status != 'rejected';
      if (shouldReach) {
        return step.copyWith(reached: true, date: step.date ?? now);
      }
      return step;
    }).toList();
  }

  StaffActiveSosEntity? _readSos() {
    final args = Get.arguments;
    if (args is StaffActiveSosEntity) {
      return args;
    }
    if (args is Map) {
      final item = args['item'] ?? args['sos'];
      if (item is StaffActiveSosEntity) {
        return item;
      }
      return StaffActiveSosEntity.fromJson(args);
    }
    return null;
  }

  @override
  void onClose() {
    noteController.dispose();
    super.onClose();
  }
}
