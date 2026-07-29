// ignore_for_file: file_names

import 'package:hcmu_sos/Entity/SupportRequestEntity.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';

class StaffAssignmentListResult {
  const StaffAssignmentListResult({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.filters,
  });

  final List<SupportRequestEntity> items;
  final int total;
  final int page;
  final int pageSize;
  final Map<String, int> filters;
}

class StaffAssignmentRepository {
  StaffAssignmentRepository({ApiCaller? apiCaller})
    : _apiCaller = apiCaller ?? ApiCaller.getInstance();

  final ApiCaller _apiCaller;

  Future<StaffAssignmentListResult> listAssignments({
    String status = 'all',
    String priority = 'all',
    int? rating,
    int? incidentTypeId,
    String? keyword,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParameters = <String, dynamic>{
      if (status != 'all') 'status': status,
      if (priority != 'all') 'priority': priority,
      'page': page,
      'page_size': pageSize,
    };
    if (rating != null) {
      queryParameters['rating'] = rating;
    }
    if (incidentTypeId != null) {
      queryParameters['incident_type_id'] = incidentTypeId;
    }
    if (keyword != null && keyword.trim().isNotEmpty) {
      queryParameters['keyword'] = keyword.trim();
    }

    final response = await _apiCaller.getBase<Object?>(
      'staff/assignments',
      queryParameters,
    );
    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Could not load staff assignments.',
        code: response.code,
        data: response.raw,
      );
    }

    final data = _asMap(response.data);
    final rawItems = data['items'];
    final rawFilters = _asMap(data['filters']);
    final items = rawItems is List
        ? rawItems.map(SupportRequestEntity.fromJson).toList()
        : <SupportRequestEntity>[];

    return StaffAssignmentListResult(
      items: items,
      total: _asInt(data['total']),
      page: _asInt(data['page']) == 0 ? page : _asInt(data['page']),
      pageSize: _asInt(data['page_size']) == 0
          ? pageSize
          : _asInt(data['page_size']),
      filters: rawFilters.map((key, value) => MapEntry(key, _asInt(value))),
    );
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  static int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}
