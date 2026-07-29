// ignore_for_file: file_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/IncidentTypeEntity.dart';
import 'package:hcmu_sos/Entity/SupportRequestEntity.dart';
import 'package:hcmu_sos/Repository/CatalogRepository.dart';
import 'package:hcmu_sos/Repository/StaffAssignmentRepository.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';
import 'package:hcmu_sos/Utils/Utils.dart';

enum StaffTaskStatusFilter {
  all,
  pending,
  inProgress,
  reopened,
  done,
  rejected,
}

enum StaffTaskPriorityFilter { all, normal, high, urgent }

class TaskViewModel extends GetxController {
  TaskViewModel({
    StaffAssignmentRepository? assignmentRepository,
    CatalogRepository? catalogRepository,
  }) : _assignmentRepository =
           assignmentRepository ?? StaffAssignmentRepository(),
       _catalogRepository = catalogRepository ?? CatalogRepository();

  final StaffAssignmentRepository _assignmentRepository;
  final CatalogRepository _catalogRepository;

  static const int _firstPage = 1;
  static const int _pageSize = 20;

  final searchController = TextEditingController();
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final errorMessage = RxnString();
  final tasks = <SupportRequestEntity>[].obs;
  final incidentTypes = <IncidentTypeEntity>[].obs;
  final statusFilter = StaffTaskStatusFilter.all.obs;
  final priorityFilter = StaffTaskPriorityFilter.all.obs;
  final selectedIncidentType = Rxn<IncidentTypeEntity>();
  final selectedRating = RxnInt();
  final keyword = ''.obs;
  final filterCounts = <String, int>{}.obs;
  final currentPage = _firstPage.obs;
  final totalTasks = 0.obs;
  final hasMoreTasks = false.obs;
  Timer? _searchDebounce;

  List<SupportRequestEntity> get filteredTasks => tasks;

  bool get hasActiveFilters =>
      statusFilter.value != StaffTaskStatusFilter.all ||
      priorityFilter.value != StaffTaskPriorityFilter.all ||
      selectedIncidentType.value != null ||
      selectedRating.value != null;

  String get statusQuery => statusQueryFor(statusFilter.value);

  String get priorityQuery => priorityQueryFor(priorityFilter.value);

  String statusQueryFor(StaffTaskStatusFilter filter) {
    return switch (filter) {
      StaffTaskStatusFilter.all => 'all',
      StaffTaskStatusFilter.pending => 'pending',
      StaffTaskStatusFilter.inProgress => 'in_progress',
      StaffTaskStatusFilter.reopened => 'reopened',
      StaffTaskStatusFilter.done => 'done',
      StaffTaskStatusFilter.rejected => 'rejected',
    };
  }

  String priorityQueryFor(StaffTaskPriorityFilter filter) {
    return switch (filter) {
      StaffTaskPriorityFilter.all => 'all',
      StaffTaskPriorityFilter.normal => 'normal',
      StaffTaskPriorityFilter.high => 'high',
      StaffTaskPriorityFilter.urgent => 'urgent',
    };
  }

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
    loadTasks();
  }

  Future<void> applyFilters({
    required StaffTaskStatusFilter status,
    required StaffTaskPriorityFilter priority,
    required IncidentTypeEntity? incidentType,
    required int? rating,
  }) async {
    statusFilter.value = status;
    priorityFilter.value = priority;
    selectedIncidentType.value = incidentType;
    selectedRating.value = rating;
    await loadTasks();
  }

  Future<void> clearFilters() async {
    if (!hasActiveFilters) {
      return;
    }
    statusFilter.value = StaffTaskStatusFilter.all;
    priorityFilter.value = StaffTaskPriorityFilter.all;
    selectedIncidentType.value = null;
    selectedRating.value = null;
    await loadTasks();
  }

  Future<void> submitSearch() async {
    _searchDebounce?.cancel();
    final nextKeyword = searchController.text.trim();
    if (keyword.value == nextKeyword) {
      return;
    }
    keyword.value = nextKeyword;
    await loadTasks();
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
    await loadTasks();
  }

  Future<void> loadTasks() async {
    if (isLoading.value) {
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;
    try {
      final results = await Future.wait([
        _assignmentRepository.listAssignments(
          status: statusQuery,
          priority: priorityQuery,
          rating: selectedRating.value,
          incidentTypeId: selectedIncidentType.value?.id,
          keyword: keyword.value,
          page: _firstPage,
          pageSize: _pageSize,
        ),
        _catalogRepository.getIncidentTypes(),
      ]);

      final taskResult = results[0] as StaffAssignmentListResult;
      final types = results[1] as List<IncidentTypeEntity>;
      tasks.assignAll(taskResult.items);
      incidentTypes.assignAll(types);
      filterCounts.assignAll(taskResult.filters);
      currentPage.value = taskResult.page;
      totalTasks.value = taskResult.total;
      hasMoreTasks.value = _hasMore(
        taskResult,
        loadedCount: taskResult.items.length,
      );
    } on ApiException catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value = 'Không thể tải danh sách công việc.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreTasks() async {
    if (isLoading.value ||
        isLoadingMore.value ||
        !hasMoreTasks.value ||
        tasks.isEmpty) {
      return;
    }

    isLoadingMore.value = true;
    try {
      final nextPage = currentPage.value + 1;
      final result = await _assignmentRepository.listAssignments(
        status: statusQuery,
        priority: priorityQuery,
        rating: selectedRating.value,
        incidentTypeId: selectedIncidentType.value?.id,
        keyword: keyword.value,
        page: nextPage,
        pageSize: _pageSize,
      );

      final loadedCount = tasks.length + result.items.length;
      tasks.addAll(result.items);
      filterCounts.assignAll(result.filters);
      currentPage.value = result.page == 0 ? nextPage : result.page;
      totalTasks.value = result.total;
      hasMoreTasks.value = _hasMore(result, loadedCount: loadedCount);
    } on ApiException catch (error) {
      Utils.showSnackbar(title: 'page.staffTask'.tr, content: error.message);
    } catch (_) {
      Utils.showSnackbar(
        title: 'page.staffTask'.tr,
        content: 'Không thể tải thêm công việc.',
      );
    } finally {
      isLoadingMore.value = false;
    }
  }

  bool _hasMore(StaffAssignmentListResult result, {required int loadedCount}) {
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
