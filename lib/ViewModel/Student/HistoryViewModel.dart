// ignore_for_file: file_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/IncidentTypeEntity.dart';
import 'package:hcmu_sos/Entity/SupportRequestEntity.dart';
import 'package:hcmu_sos/Repository/CatalogRepository.dart';
import 'package:hcmu_sos/Repository/SupportRequestRepository.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';
import 'package:hcmu_sos/Utils/Utils.dart';

enum RequestHistoryFilter { all, pending, inProgress, reopened, done, rejected }

class HistoryViewModel extends GetxController {
  HistoryViewModel({
    SupportRequestRepository? requestRepository,
    CatalogRepository? catalogRepository,
  }) : _requestRepository = requestRepository ?? SupportRequestRepository(),
       _catalogRepository = catalogRepository ?? CatalogRepository();

  final SupportRequestRepository _requestRepository;
  final CatalogRepository _catalogRepository;

  static const int _firstPage = 1;
  static const int _pageSize = 20;

  final searchController = TextEditingController();
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final errorMessage = RxnString();
  final requests = <SupportRequestEntity>[].obs;
  final incidentTypes = <IncidentTypeEntity>[].obs;
  final selectedFilter = RequestHistoryFilter.all.obs;
  final keyword = ''.obs;
  final currentPage = _firstPage.obs;
  final totalRequests = 0.obs;
  final hasMoreRequests = false.obs;
  Timer? _searchDebounce;

  List<SupportRequestEntity> get filteredRequests => requests;

  String get statusQuery => statusQueryFor(selectedFilter.value);

  String statusQueryFor(RequestHistoryFilter filter) {
    return switch (filter) {
      RequestHistoryFilter.all => 'all',
      RequestHistoryFilter.pending => 'pending',
      RequestHistoryFilter.inProgress => 'in_progress',
      RequestHistoryFilter.reopened => 'reopened',
      RequestHistoryFilter.done => 'done',
      RequestHistoryFilter.rejected => 'rejected',
    };
  }

  String? incidentTypeNameFor(SupportRequestEntity request) {
    final raw = request.incidentType;
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final id = int.tryParse(raw);
    for (final type in incidentTypes) {
      print('');
      if (type.code == raw || type.id == id || type.name == raw) {
        return type.name;
      }
    }
    return raw;
  }

  Future<void> selectFilter(RequestHistoryFilter filter) async {
    if (selectedFilter.value == filter) {
      return;
    }
    selectedFilter.value = filter;
    await loadRequests();
  }

  Future<void> submitSearch() async {
    _searchDebounce?.cancel();
    final nextKeyword = searchController.text.trim();
    if (keyword.value == nextKeyword) {
      return;
    }
    keyword.value = nextKeyword;
    await loadRequests();
  }

  void onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      submitSearch();
    });
  }

  Future<void> clearSearch() async {
    _searchDebounce?.cancel();
    if (searchController.text.isEmpty && keyword.value.isEmpty) {
      return;
    }
    searchController.clear();
    keyword.value = '';
    await loadRequests();
  }

  @override
  void onReady() {
    super.onReady();
    loadRequests();
  }

  Future<void> loadRequests() async {
    if (isLoading.value) {
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;
    try {
      final results = await Future.wait([
        _requestRepository.listRequests(
          role: 'student',
          status: statusQuery,
          keyword: keyword.value,
          page: _firstPage,
          pageSize: _pageSize,
        ),
        _catalogRepository.getIncidentTypes(),
      ]);
      final requestResult = results[0] as SupportRequestListResult;
      final types = results[1] as List<IncidentTypeEntity>;
      requests.assignAll(requestResult.items);
      incidentTypes.assignAll(types);
      currentPage.value = requestResult.page;
      totalRequests.value = requestResult.total;
      hasMoreRequests.value = _hasMore(
        requestResult,
        loadedCount: requestResult.items.length,
      );
    } on ApiException catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value = 'Không thể tải lịch sử yêu cầu.';
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
        status: statusQuery,
        keyword: keyword.value,
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
        title: 'page.studentHistory'.tr,
        content: error.message,
      );
    } catch (_) {
      Utils.showSnackbar(
        title: 'page.studentHistory'.tr,
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

  @override
  void onClose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    super.onClose();
  }
}
