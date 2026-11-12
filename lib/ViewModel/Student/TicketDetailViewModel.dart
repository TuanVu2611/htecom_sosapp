// ignore_for_file: file_names

import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/SupportRequestEntity.dart';
import 'package:hcmu_sos/Repository/SupportRequestRepository.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';
import 'package:hcmu_sos/Service/AuthSessionStorage.dart';
import 'package:hcmu_sos/Utils/Utils.dart';

class TicketDetailViewModel extends GetxController {
  TicketDetailViewModel({
    SupportRequestRepository? requestRepository,
    String? Function()? currentUserId,
  }) : _requestRepository = requestRepository ?? SupportRequestRepository(),
       _currentUserId =
           currentUserId ?? (() => AuthSessionStorage.getUser()?.id);

  final SupportRequestRepository _requestRepository;
  final String? Function() _currentUserId;

  final isLoading = false.obs;
  final isSubmittingRating = false.obs;
  final errorMessage = RxnString();
  final detail = Rxn<SupportRequestDetailEntity>();

  int? requestId;
  bool _openRatingRequested = false;

  bool get isOwnSos {
    final request = detail.value;
    if (request == null || !request.isSos) return false;
    final studentId = request.student?.id;
    final userId = int.tryParse(_currentUserId()?.trim() ?? '');
    return studentId != null && studentId > 0 && userId == studentId;
  }

  // Missing ownership information must not grant owner-only SOS actions.
  bool get canAccessOwnerFeatures {
    final request = detail.value;
    return request != null && (!request.isSos || isOwnSos);
  }

  bool get canRate =>
      canAccessOwnerFeatures &&
      detail.value?.status == SupportRequestStatus.done &&
      !((detail.value?.rating?.rating ?? 0) > 0 ||
          (detail.value?.rating?.comment?.trim().isNotEmpty ?? false));

  @override
  void onInit() {
    super.onInit();
    requestId = _readRequestId();
    _openRatingRequested = _readOpenRatingRequested();
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
          title: 'ticket.detail'.tr,
          content: 'ticket.detail.errorMissingId'.tr,
        );
      }
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;
    try {
      detail.value = await _requestRepository.getRequestDetail(id);
    } on ApiException catch (error) {
      Utils.showSnackbar(title: 'ticket.detail'.tr, content: error.message);
    } catch (_) {
      Utils.showSnackbar(
        title: 'ticket.detail'.tr,
        content: 'ticket.detail.errorLoadFailed'.tr,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> submitRating({required int rating, String? comment}) async {
    final id = requestId;
    if (id == null || id <= 0 || isSubmittingRating.value || !canRate) {
      return false;
    }
    if (rating < 1 || rating > 5) {
      Utils.showSnackbar(
        title: 'ticket.detail.rating'.tr,
        content: 'ticket.rating.required'.tr,
      );
      return false;
    }

    isSubmittingRating.value = true;
    try {
      await _requestRepository.rateRequest(
        requestId: id,
        rating: rating,
        comment: comment,
      );
      await loadDetail();
      Utils.showSnackbar(
        title: 'ticket.detail.rating'.tr,
        content: 'ticket.rating.success'.tr,
      );
      return true;
    } on ApiException catch (error) {
      Utils.showSnackbar(
        title: 'ticket.detail.rating'.tr,
        content: error.message,
      );
      return false;
    } catch (_) {
      Utils.showSnackbar(
        title: 'ticket.detail.rating'.tr,
        content: 'ticket.rating.failed'.tr,
      );
      return false;
    } finally {
      isSubmittingRating.value = false;
    }
  }

  bool takeOpenRatingRequest() {
    if (!_openRatingRequested) {
      return false;
    }
    _openRatingRequested = false;
    return canRate;
  }

  bool _readOpenRatingRequested() {
    final args = Get.arguments;
    if (args is! Map) {
      return false;
    }
    final value = args['open_rating'] ?? args['openRating'];
    return value == true || value == 1 || value == '1' || value == 'true';
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
}
