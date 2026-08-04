// ignore_for_file: file_names

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/IncidentTypeEntity.dart';
import 'package:hcmu_sos/Repository/CatalogRepository.dart';
import 'package:hcmu_sos/Repository/LocationLookupRepository.dart';
import 'package:hcmu_sos/Repository/PendingTicketRepository.dart';
import 'package:hcmu_sos/Repository/SupportRequestRepository.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';
import 'package:hcmu_sos/Service/PendingTicketSyncService.dart';
import 'package:hcmu_sos/Utils/Utils.dart';
import 'package:image_picker/image_picker.dart';

enum TicketPriority { normal, high, urgent }

enum TicketSubmitResult { createdOnline, queuedOffline, failed }

const int maxTicketAttachments = 3;
const int maxTicketAttachmentBytes = 5 * 1024 * 1024;

class TicketImageAttachment {
  const TicketImageAttachment({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;
}

class CreateTicketViewModel extends GetxController {
  CreateTicketViewModel({
    CatalogRepository? catalogRepository,
    LocationLookupRepository? locationLookupRepository,
    SupportRequestRepository? requestRepository,
    PendingTicketRepository? pendingTicketRepository,
    PendingTicketSyncService? pendingTicketSyncService,
  }) : _catalogRepository = catalogRepository ?? CatalogRepository(),
       _locationLookupRepository =
           locationLookupRepository ?? LocationLookupRepository(),
       _requestRepository = requestRepository ?? SupportRequestRepository(),
       _pendingTicketRepository =
           pendingTicketRepository ?? PendingTicketRepository(),
       _pendingTicketSyncService =
           pendingTicketSyncService ?? PendingTicketSyncService.instance;

  final CatalogRepository _catalogRepository;
  final LocationLookupRepository _locationLookupRepository;
  final SupportRequestRepository _requestRepository;
  final PendingTicketRepository _pendingTicketRepository;
  final PendingTicketSyncService _pendingTicketSyncService;
  final ImagePicker _imagePicker = ImagePicker();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();

  final incidentTypes = <IncidentTypeEntity>[].obs;
  final selectedIncidentType = Rxn<IncidentTypeEntity>();
  final selectedPriority = TicketPriority.normal.obs;
  final attachments = <TicketImageAttachment>[].obs;
  final latitude = 10.762622.obs;
  final longitude = 106.660172.obs;
  final isLoadingCatalog = false.obs;
  final isLocating = false.obs;
  final isResolvingLocationText = false.obs;
  final isSubmitting = false.obs;

  Timer? _locationLookupDebounce;
  bool _isApplyingAutoLocationText = false;
  bool _hasManualLocationOverride = false;
  String? _lastAutoResolvedLocationText;
  int _locationLookupRequestId = 0;

  @override
  void onInit() {
    super.onInit();
    locationController.addListener(_handleLocationTextChanged);
    loadIncidentTypes();
    loadCurrentLocation();
  }

  Future<void> loadIncidentTypes({bool forceRefresh = false}) async {
    if (isLoadingCatalog.value) {
      return;
    }

    isLoadingCatalog.value = true;
    try {
      final items = await _catalogRepository.getIncidentTypes(
        forceRefresh: forceRefresh,
      );
      incidentTypes.assignAll(items);
      if (selectedIncidentType.value == null && items.isNotEmpty) {
        selectedIncidentType.value = items.first;
      }
    } on ApiException catch (error) {
      Utils.showSnackbar(
        title: 'ticket.create.title'.tr,
        content: error.message,
      );
    } catch (_) {
      Utils.showSnackbar(
        title: 'ticket.create.title'.tr,
        content: 'ticket.error.incidentTypes'.tr,
      );
    } finally {
      isLoadingCatalog.value = false;
    }
  }

  Future<void> loadCurrentLocation() async {
    if (isLocating.value) {
      return;
    }

    isLocating.value = true;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      updateLocation(
        position.latitude,
        position.longitude,
        forceRefreshAddress: true,
      );
    } finally {
      isLocating.value = false;
    }
  }

  void selectIncidentType(IncidentTypeEntity incidentType) {
    selectedIncidentType.value = incidentType;
  }

  void selectPriority(TicketPriority priority) {
    selectedPriority.value = priority;
  }

  void updateLocation(
    double nextLatitude,
    double nextLongitude, {
    bool forceRefreshAddress = false,
  }) {
    latitude.value = nextLatitude.clamp(-85.0, 85.0).toDouble();
    longitude.value = nextLongitude.clamp(-180.0, 180.0).toDouble();
    _scheduleLocationLookup(forceOverride: forceRefreshAddress);
  }

  Future<void> pickImages() async {
    final remainingSlots = maxTicketAttachments - attachments.length;
    if (remainingSlots <= 0) {
      return;
    }

    try {
      final images = <XFile>[];
      if (remainingSlots == 1) {
        final image = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1600,
        );
        if (image != null) {
          images.add(image);
        }
      } else {
        images.addAll(
          await _imagePicker.pickMultiImage(
            imageQuality: 85,
            maxWidth: 1600,
            limit: remainingSlots,
          ),
        );
      }
      if (images.isEmpty) {
        return;
      }

      final nextAttachments = <TicketImageAttachment>[];
      final availableSlots = maxTicketAttachments - attachments.length;
      var hasOversizedImage = false;
      for (final image in images.take(availableSlots)) {
        final bytes = await image.readAsBytes();
        if (bytes.lengthInBytes > maxTicketAttachmentBytes) {
          hasOversizedImage = true;
          continue;
        }

        nextAttachments.add(
          TicketImageAttachment(
            bytes: bytes,
            fileName: image.name,
            mimeType: image.mimeType ?? _mimeTypeFromFileName(image.name),
          ),
        );
      }
      attachments.addAll(nextAttachments);
      if (hasOversizedImage) {
        Utils.showSnackbar(
          title: 'ticket.create.title'.tr,
          content: 'ticket.validation.photoTooLarge'.tr,
        );
      }
    } catch (_) {
      Utils.showSnackbar(
        title: 'ticket.create.title'.tr,
        content: 'auth.imagePickFailed'.tr,
      );
    }
  }

  void removeImage(TicketImageAttachment attachment) {
    attachments.remove(attachment);
  }

  Future<TicketSubmitResult> submit() async {
    if (isSubmitting.value) {
      return TicketSubmitResult.failed;
    }

    final validationError = _validationError();
    if (validationError != null) {
      Utils.showSnackbar(
        title: 'ticket.create.title'.tr,
        content: validationError.tr,
      );
      return TicketSubmitResult.failed;
    }

    isSubmitting.value = true;
    try {
      if (!await _pendingTicketSyncService.hasNetwork()) {
        return await _queueCurrentTicket();
      }

      await _submitOnline();
      resetForm();
      unawaited(_pendingTicketSyncService.syncPendingTickets());
      return TicketSubmitResult.createdOnline;
    } on ApiException catch (error) {
      if (_shouldQueueOffline(error)) {
        return await _queueCurrentTicket();
      }

      Utils.showSnackbar(
        title: 'ticket.create.title'.tr,
        content: error.message,
      );
      return TicketSubmitResult.failed;
    } catch (_) {
      if (!await _pendingTicketSyncService.hasNetwork()) {
        return await _queueCurrentTicket();
      }

      Utils.showSnackbar(
        title: 'ticket.create.title'.tr,
        content: 'ticket.error.createFailed'.tr,
      );
      return TicketSubmitResult.failed;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> _submitOnline() async {
    final imageFileIds = <int>[];
    for (final attachment in attachments) {
      imageFileIds.add(
        await Utils.uploadFile(
          bytes: attachment.bytes,
          fileName: attachment.fileName,
          mimeType: attachment.mimeType,
          purpose: 'report_image',
        ),
      );
    }

    await _requestRepository.createRequest(
      incidentTypeId: selectedIncidentType.value!.id,
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      priority: priorityValue(selectedPriority.value),
      locationText: locationController.text.trim(),
      latitude: latitude.value,
      longitude: longitude.value,
      imageFileIds: imageFileIds,
    );
  }

  Future<TicketSubmitResult> _queueCurrentTicket() async {
    try {
      await _pendingTicketRepository.enqueue(
        PendingTicketCreateInput(
          incidentTypeId: selectedIncidentType.value!.id,
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          priority: priorityValue(selectedPriority.value),
          locationText: locationController.text.trim(),
          latitude: latitude.value,
          longitude: longitude.value,
          attachments: attachments
              .map(
                (attachment) => PendingTicketAttachmentDraft(
                  bytes: attachment.bytes,
                  fileName: attachment.fileName,
                  mimeType: attachment.mimeType,
                ),
              )
              .toList(),
        ),
      );
      resetForm();
      await _pendingTicketSyncService.refreshState();
      if (await _pendingTicketSyncService.hasNetwork()) {
        unawaited(_pendingTicketSyncService.syncPendingTickets());
      }
      return TicketSubmitResult.queuedOffline;
    } catch (_) {
      Utils.showSnackbar(
        title: 'ticket.create.title'.tr,
        content: 'ticket.error.offlineSaveFailed'.tr,
      );
      return TicketSubmitResult.failed;
    }
  }

  bool _shouldQueueOffline(ApiException error) {
    return error.statusCode == null;
  }

  void resetForm() {
    titleController.clear();
    descriptionController.clear();
    _setLocationTextSilently('');
    _hasManualLocationOverride = false;
    _lastAutoResolvedLocationText = null;
    selectedPriority.value = TicketPriority.normal;
    selectedIncidentType.value = incidentTypes.isEmpty
        ? null
        : incidentTypes.first;
    attachments.clear();
    _scheduleLocationLookup(forceOverride: true);
  }

  String priorityValue(TicketPriority priority) {
    return switch (priority) {
      TicketPriority.normal => 'normal',
      TicketPriority.high => 'high',
      TicketPriority.urgent => 'urgent',
    };
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

  String? _validationError() {
    if (selectedIncidentType.value == null) {
      return 'ticket.validation.incidentType';
    }
    if (titleController.text.trim().isEmpty) {
      return 'ticket.validation.title';
    }
    if (descriptionController.text.trim().isEmpty) {
      return 'ticket.validation.description';
    }
    if (locationController.text.trim().isEmpty) {
      return 'ticket.validation.location';
    }
    if (attachments.isEmpty) {
      return 'ticket.validation.photoRequired';
    }
    return null;
  }

  void _handleLocationTextChanged() {
    if (_isApplyingAutoLocationText) {
      return;
    }

    final text = locationController.text.trim();
    if (text.isEmpty) {
      _hasManualLocationOverride = false;
      _scheduleLocationLookup(forceOverride: true);
      return;
    }

    _hasManualLocationOverride = text != (_lastAutoResolvedLocationText ?? '');
  }

  void _scheduleLocationLookup({bool forceOverride = false}) {
    _locationLookupDebounce?.cancel();
    _locationLookupDebounce = Timer(
      const Duration(milliseconds: 450),
      () => _resolveLocationText(forceOverride: forceOverride),
    );
  }

  Future<void> _resolveLocationText({bool forceOverride = false}) async {
    if (_hasManualLocationOverride && !forceOverride) {
      return;
    }

    final requestId = ++_locationLookupRequestId;
    isResolvingLocationText.value = true;

    try {
      final resolvedText = await _locationLookupRepository.reverseGeocode(
        latitude: latitude.value,
        longitude: longitude.value,
      );

      if (requestId != _locationLookupRequestId) {
        return;
      }

      final nextText = resolvedText?.trim();
      if (nextText == null || nextText.isEmpty) {
        return;
      }

      _lastAutoResolvedLocationText = nextText;
      if (!_hasManualLocationOverride || forceOverride) {
        _setLocationTextSilently(nextText);
        _hasManualLocationOverride = false;
      }
    } finally {
      if (requestId == _locationLookupRequestId) {
        isResolvingLocationText.value = false;
      }
    }
  }

  void _setLocationTextSilently(String value) {
    _isApplyingAutoLocationText = true;
    locationController.value = locationController.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
      composing: TextRange.empty,
    );
    _isApplyingAutoLocationText = false;
  }

  @override
  void onClose() {
    _locationLookupDebounce?.cancel();
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    super.onClose();
  }
}
