// ignore_for_file: file_names

import 'package:hcmu_sos/Entity/SupportRequestEntity.dart';

class SosCurrentStatusEntity {
  const SosCurrentStatusEntity({
    required this.sosId,
    required this.status,
    required this.isActive,
    required this.hasActiveSos,
    this.createdAt,
    this.assignedStaff,
    this.student,
    this.timeline = const <RequestTimelineEntity>[],
    this.location,
  });

  final int sosId;
  final String status;
  final bool isActive;
  final bool hasActiveSos;
  final DateTime? createdAt;
  final AssignedStaffEntity? assignedStaff;
  final RequestStudentEntity? student;
  final List<RequestTimelineEntity> timeline;
  final RequestLocationEntity? location;

  bool get canTrack => sosId > 0 && isActive && hasActiveSos;

  factory SosCurrentStatusEntity.fromJson(Object? json) {
    final data = _asMap(json);
    return SosCurrentStatusEntity(
      sosId: _asInt(data['sos_id'] ?? data['id']),
      status: _asString(data['status']) ?? '',
      isActive: _asBool(data['is_active']),
      hasActiveSos: _asBool(data['has_active_sos']),
      createdAt: _asDateTime(data['created_at']),
      assignedStaff:
          data['assigned_staff'] == null || data['assigned_staff'] == false
          ? null
          : AssignedStaffEntity.fromJson(data['assigned_staff']),
      student: data['student'] == null || data['student'] == false
          ? null
          : RequestStudentEntity.fromJson(data['student']),
      timeline: _asList(
        data['timeline'],
      ).map(RequestTimelineEntity.fromJson).toList(),
      location:
          data['location'] == null || data['location'] == false
          ? null
          : RequestLocationEntity.fromJson(data['location']),
    );
  }
}

class SosLiveLocationEntity {
  const SosLiveLocationEntity({
    required this.sosId,
    required this.status,
    required this.isActive,
    this.requestId,
    this.code,
    this.isSos = true,
    this.updated = true,
    this.location,
    this.updatedAt,
  });

  final int sosId;
  final int? requestId;
  final String? code;
  final bool isSos;
  final String status;
  final bool isActive;
  final bool updated;
  final RequestLocationEntity? location;
  final DateTime? updatedAt;

  factory SosLiveLocationEntity.fromJson(Object? json) {
    final data = _asMap(json);
    return SosLiveLocationEntity(
      sosId: _asInt(data['sos_id'] ?? data['id']),
      requestId: _asIntOrNull(data['request_id']),
      code: _asString(data['code']),
      isSos: data['is_sos'] != false,
      status: _asString(data['status']) ?? '',
      isActive: _asBool(data['is_active'], defaultValue: true),
      updated: _asBool(data['updated'], defaultValue: true),
      location:
          data['location'] == null || data['location'] == false
          ? null
          : RequestLocationEntity.fromJson(data['location']),
      updatedAt: _asDateTime(data['updated_at']),
    );
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}

List<Object?> _asList(Object? value) {
  return value is List ? value : const <Object?>[];
}

String? _asString(Object? value) {
  if (value == null || value == false) {
    return null;
  }
  return value.toString();
}

int _asInt(Object? value) {
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

int? _asIntOrNull(Object? value) {
  final parsed = _asInt(value);
  return parsed == 0 && value != 0 && value != '0' ? null : parsed;
}

bool _asBool(Object? value, {bool defaultValue = false}) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final normalized = value.toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
  }
  return defaultValue;
}

DateTime? _asDateTime(Object? value) {
  final raw = _asString(value);
  if (raw == null || raw.isEmpty) {
    return null;
  }
  return DateTime.tryParse(raw)?.toLocal();
}
