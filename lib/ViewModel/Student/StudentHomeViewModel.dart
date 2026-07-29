// ignore_for_file: file_names

import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/AuthUserEntity.dart';
import 'package:hcmu_sos/Entity/IncidentTypeEntity.dart';
import 'package:hcmu_sos/Entity/StudentHomeEntity.dart';
import 'package:hcmu_sos/Entity/SupportRequestEntity.dart';
import 'package:hcmu_sos/Repository/CatalogRepository.dart';
import 'package:hcmu_sos/Repository/StudentHomeRepository.dart';
import 'package:hcmu_sos/Repository/SupportRequestRepository.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';
import 'package:hcmu_sos/Service/AuthSessionStorage.dart';
import 'package:hcmu_sos/Utils/Utils.dart';

class StudentHomeViewModel extends GetxController {
  StudentHomeViewModel({
    StudentHomeRepository? homeRepository,
    SupportRequestRepository? requestRepository,
    CatalogRepository? catalogRepository,
  }) : _homeRepository = homeRepository ?? StudentHomeRepository(),
       _requestRepository = requestRepository ?? SupportRequestRepository(),
       _catalogRepository = catalogRepository ?? CatalogRepository();

  final StudentHomeRepository _homeRepository;
  final SupportRequestRepository _requestRepository;
  final CatalogRepository _catalogRepository;

  static const int _firstPage = 1;
  static const int _pageSize = 20;

  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final errorMessage = RxnString();
  final requests = <SupportRequestEntity>[].obs;
  final incidentTypes = <IncidentTypeEntity>[].obs;
  final summary = StudentHomeSummaryEntity.empty.obs;
  final homeUser = Rxn<AuthUserEntity>();
  final unreadNotificationCount = 0.obs;
  final currentPage = _firstPage.obs;
  final totalRequests = 0.obs;
  final hasMoreRequests = false.obs;

  AuthUserEntity? get currentUser {
    final reactiveUser = homeUser.value;
    return AuthSessionStorage.getUser() ?? reactiveUser;
  }

  int get waitingCount => summary.value.pending;

  int get processingCount => summary.value.processing;

  int get completedCount => summary.value.completed;

  int get cancelledCount => summary.value.cancelled;

  List<SupportRequestEntity> get recentRequests => requests;

  String? incidentTypeNameFor(SupportRequestEntity request) {
    final raw = request.incidentType;
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final id = int.tryParse(raw);
    for (final type in incidentTypes) {
      if (type.code == raw || type.id == id || type.name == raw) {
        return type.name;
      }
    }
    return raw;
  }

  @override
  void onReady() {
    super.onReady();
    refreshCurrentUser();
    loadHome();
  }

  void refreshCurrentUser() {
    homeUser.value = AuthSessionStorage.getUser();
  }

  void showUnreadNotificationBadge() {
    if (unreadNotificationCount.value <= 0) {
      unreadNotificationCount.value = 1;
    }
  }

  void updateUnreadNotificationCount(int count) {
    unreadNotificationCount.value = count < 0 ? 0 : count;
  }

  Future<void> loadHome() async {
    if (isLoading.value) {
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;
    try {
      final results = await Future.wait([
        _homeRepository.getHome(),
        _requestRepository.listRequests(
          role: 'student',
          status: 'all',
          page: _firstPage,
          pageSize: _pageSize,
        ),
        _catalogRepository.getIncidentTypes(),
      ]);
      final home = results[0] as StudentHomeEntity;
      final requestResult = results[1] as SupportRequestListResult;
      final types = results[2] as List<IncidentTypeEntity>;
      requests.assignAll(requestResult.items);
      currentPage.value = requestResult.page == 0
          ? _firstPage
          : requestResult.page;
      totalRequests.value = requestResult.total;
      hasMoreRequests.value = _hasMore(
        requestResult,
        loadedCount: requestResult.items.length,
      );
      incidentTypes.assignAll(types);
      summary.value = home.summary;
      homeUser.value = home.user;
      unreadNotificationCount.value = home.unreadNotificationCount;
    } on ApiException catch (error) {
      Utils.showSnackbar(title: 'student.home'.tr, content: error.message);
    } catch (_) {
      Utils.showSnackbar(
        title: 'student.home'.tr,
        content: 'student.home.loadFailed'.tr,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreRequests() async {
    if (isLoading.value ||
        isLoadingMore.value ||
        !hasMoreRequests.value ||
        requests.isEmpty) {
      return;
    }

    isLoadingMore.value = true;
    try {
      final nextPage = currentPage.value + 1;
      final result = await _requestRepository.listRequests(
        role: 'student',
        status: 'all',
        page: nextPage,
        pageSize: _pageSize,
      );

      final loadedCount = requests.length + result.items.length;
      requests.addAll(result.items);
      currentPage.value = result.page == 0 ? nextPage : result.page;
      totalRequests.value = result.total;
      hasMoreRequests.value = _hasMore(result, loadedCount: loadedCount);
    } on ApiException catch (error) {
      Utils.showSnackbar(
        title: 'student.home.recentRequests'.tr,
        content: error.message,
      );
    } catch (_) {
      Utils.showSnackbar(
        title: 'student.home.recentRequests'.tr,
        content: 'student.home.loadFailed'.tr,
      );
    } finally {
      isLoadingMore.value = false;
    }
  }

  bool _hasMore(SupportRequestListResult result, {required int loadedCount}) {
    if (result.total > 0) {
      return loadedCount < result.total;
    }
    return result.items.length >= result.pageSize && result.pageSize > 0;
  }
}
