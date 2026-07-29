// ignore_for_file: file_names

import 'package:hcmu_sos/Entity/StaffHomeEntity.dart';
import 'package:hcmu_sos/Entity/SupportRequestEntity.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';

class StaffSosListResult {
  const StaffSosListResult({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<StaffActiveSosEntity> items;
  final int total;
  final int page;
  final int pageSize;
}

class StaffSosRepository {
  StaffSosRepository({ApiCaller? apiCaller})
    : _apiCaller = apiCaller ?? ApiCaller.getInstance();

  final ApiCaller _apiCaller;

  Future<StaffActiveSosEntity> getSosDetail(int sosId) async {
    final response = await _apiCaller.getBase<Object?>('requests/$sosId', null);

    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Could not load SOS detail.',
        code: response.code,
        data: response.raw,
      );
    }

    final detail = SupportRequestDetailEntity.fromJson(response.data);
    return _mapRequestDetailToSos(detail);
  }

  Future<StaffSosListResult> listActiveSos({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    final response = await _apiCaller.getBase<Object?>(
      'staff/sos/active',
      <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
      },
    );

    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Could not load active SOS.',
        code: response.code,
        data: response.raw,
      );
    }

    final data = _asMap(response.data);
    final rawItems = data['items'];
    return StaffSosListResult(
      items: rawItems is List
          ? rawItems.map(StaffActiveSosEntity.fromJson).toList()
          : const <StaffActiveSosEntity>[],
      total: _asInt(data['total']),
      page: page,
      pageSize: pageSize,
    );
  }

  Future<void> updateSos({
    required int sosId,
    required String status,
    String? note,
    List<int>? imageFileIds,
  }) async {
    final trimmedNote = note?.trim();
    final response = await _apiCaller.requestBase<Object?>(
      'staff/sos/$sosId',
      method: ApiMethod.patch,
      body: <String, dynamic>{
        'status': status,
        'note': trimmedNote == null || trimmedNote.isEmpty ? null : trimmedNote,
        'image_file_ids': imageFileIds,
      },
    );

    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Could not update SOS.',
        code: response.code,
        data: response.raw,
      );
    }
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

  StaffActiveSosEntity _mapRequestDetailToSos(
    SupportRequestDetailEntity detail,
  ) {
    return StaffActiveSosEntity(
      id: detail.id,
      status: _requestStatusCode(detail.status),
      location: detail.location?.text,
      latitude: detail.location?.latitude,
      longitude: detail.location?.longitude,
      createdAt: detail.createdAt,
      assignedStaff: detail.assignedStaff,
      reporter: detail.reporter == null
          ? null
          : StaffSosReporterEntity(
              id: 0,
              name: detail.reporter?.name ?? '',
              phone: detail.reporter?.phone,
              email: detail.reporter?.email,
              avatarUrl: null,
            ),
      student: detail.student,
      checklist: detail.checklist,
      timeline: detail.timeline
          .map(
            (step) => StaffSosTimelineEntity(
              status: step.status,
              label: step.label,
              date: step.date,
              reached: step.reached,
            ),
          )
          .toList(),
    );
  }

  String _requestStatusCode(SupportRequestStatus status) {
    return switch (status) {
      SupportRequestStatus.pending => 'pending',
      SupportRequestStatus.inProgress => 'in_progress',
      SupportRequestStatus.reopened => 'reopened',
      SupportRequestStatus.done => 'done',
      SupportRequestStatus.rejected => 'rejected',
    };
  }
}
