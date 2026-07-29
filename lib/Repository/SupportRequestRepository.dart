// ignore_for_file: file_names

import 'package:hcmu_sos/Entity/SupportRequestEntity.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';

class SupportRequestListResult {
  const SupportRequestListResult({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<SupportRequestEntity> items;
  final int total;
  final int page;
  final int pageSize;
}

class SupportRequestRepository {
  SupportRequestRepository({ApiCaller? apiCaller})
    : _apiCaller = apiCaller ?? ApiCaller.getInstance();

  final ApiCaller _apiCaller;

  Future<void> createRequest({
    required int incidentTypeId,
    required String title,
    required String description,
    required String priority,
    required String locationText,
    required double latitude,
    required double longitude,
    required List<int> imageFileIds,
  }) async {
    final response = await _apiCaller
        .postBase<Object?>('requests', <String, dynamic>{
          'incident_type_id': incidentTypeId,
          'title': title,
          'description': description,
          'priority': priority,
          'location_text': locationText,
          'latitude': latitude,
          'longitude': longitude,
          'image_file_ids': imageFileIds,
        });

    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Could not create request.',
        code: response.code,
        data: response.raw,
      );
    }
  }

  Future<SupportRequestListResult> listRequests({
    String role = 'student',
    String status = 'all',
    String? keyword,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiCaller
        .getBase<Object?>('requests', <String, dynamic>{
          'role': role,
          'status': status,
          if (keyword != null && keyword.trim().isNotEmpty)
            'keyword': keyword.trim(),
          'page': page,
          'page_size': pageSize,
        });
    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Could not load requests.',
        code: response.code,
        data: response.raw,
      );
    }

    final data = _asMap(response.data);
    final rawItems = data['items'];
    final items = rawItems is List
        ? rawItems.map(SupportRequestEntity.fromJson).toList()
        : <SupportRequestEntity>[];

    final pagination = _paginationMap(data);

    final responsePage = _asInt(pagination['page'] ?? data['page']);
    final responsePageSize = _asInt(
      pagination['page_size'] ?? pagination['pageSize'] ?? data['page_size'],
    );

    return SupportRequestListResult(
      items: items,
      total: _asInt(pagination['total'] ?? data['total']),
      page: responsePage == 0 ? page : responsePage,
      pageSize: responsePageSize == 0 ? pageSize : responsePageSize,
    );
  }

  Future<SupportRequestDetailEntity> getRequestDetail(int requestId) async {
    final response = await _apiCaller.getBase<Object?>(
      'requests/$requestId',
      null,
    );
    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Could not load request detail.',
        code: response.code,
        data: response.raw,
      );
    }

    return SupportRequestDetailEntity.fromJson(response.data);
  }

  Future<void> rateRequest({
    required int requestId,
    required int rating,
    String? comment,
  }) async {
    final response = await _apiCaller.postBase<Object?>(
      'requests/$requestId/rate',
      <String, dynamic>{'rating': rating, 'comment': comment?.trim() ?? ''},
    );
    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Could not submit rating.',
        code: response.code,
        data: response.raw,
      );
    }
  }

  Future<void> updateRequestStatus({
    required int requestId,
    required String status,
    String? reason,
  }) async {
    final response = await _apiCaller.requestBase<Object?>(
      'requests/$requestId/status',
      method: ApiMethod.put,
      body: <String, dynamic>{'status': status, 'reason': reason?.trim()},
    );
    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Could not update request status.',
        code: response.code,
        data: response.raw,
      );
    }
  }

  Future<StaffTransferOptionsEntity> getStaffTransferOptions({
    required int requestId,
  }) async {
    final response = await _apiCaller.getBase<Object?>(
      'staff/transfer/options',
      <String, dynamic>{'request_id': requestId},
    );
    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Could not load transfer options.',
        code: response.code,
        data: response.raw,
      );
    }

    return StaffTransferOptionsEntity.fromJson(response.data);
  }

  Future<void> transferStaffRequest({
    required int requestId,
    int? departmentId,
    int? targetStaffId,
    required String reason,
  }) async {
    final response = await _apiCaller
        .postBase<Object?>('staff/transfer', <String, dynamic>{
          'request_id': requestId,
          'department_id': departmentId,
          'target_staff_id': targetStaffId,
          'reason': reason.trim(),
        });
    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Could not transfer request.',
        code: response.code,
        data: response.raw,
      );
    }
  }

  Future<void> rejectStaffRequest({
    required int requestId,
    required String reason,
  }) async {
    final response = await _apiCaller.postBase<Object?>(
      'staff/requests/$requestId/reject',
      <String, dynamic>{'reason': reason.trim()},
    );
    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Could not reject request.',
        code: response.code,
        data: response.raw,
      );
    }
  }

  Future<void> completeStaffRequest({
    required int requestId,
    required String acceptanceNote,
    required List<int> acceptanceImageIds,
  }) async {
    final response = await _apiCaller.postBase<Object?>(
      'staff/requests/$requestId/complete',
      <String, dynamic>{
        'acceptance_note': acceptanceNote.trim(),
        'acceptance_image_ids': acceptanceImageIds,
      },
    );
    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Could not complete request.',
        code: response.code,
        data: response.raw,
      );
    }
  }

  Future<void> updateStaffRequestChecklist({
    required int requestId,
    required List<Map<String, dynamic>> checklist,
  }) async {
    final response = await _apiCaller.postBase<Object?>(
      'staff/requests/$requestId/checklist',
      <String, dynamic>{'checklist': checklist},
    );

    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Could not update checklist.',
        code: response.code,
        data: response.raw,
      );
    }
  }

  static Map<String, dynamic> _paginationMap(Map<String, dynamic> data) {
    final pagination = data['pagination'] ?? data['meta'] ?? data['metadata'];
    if (pagination is Map<String, dynamic>) {
      return pagination;
    }
    if (pagination is Map) {
      return pagination.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
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
