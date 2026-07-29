// ignore_for_file: file_names

import 'package:hcmu_sos/Entity/AuthUserEntity.dart';
import 'package:hcmu_sos/Entity/SupportRequestEntity.dart';
import 'package:hcmu_sos/Utils/ApiAssetUrl.dart';

class StaffHomeEntity {
  const StaffHomeEntity({
    required this.profile,
    required this.summary,
    required this.activeSos,
    required this.tasks,
    required this.unreadMessageCount,
    required this.isAvailable,
  });

  final AuthUserEntity? profile;
  final StaffHomeSummaryEntity summary;
  final List<StaffActiveSosEntity> activeSos;
  final List<SupportRequestEntity> tasks;
  final int unreadMessageCount;
  final bool isAvailable;

  factory StaffHomeEntity.fromJson(Object? json) {
    final data = _asMap(json);
    final profileData = _asMap(data['profile']);
    final rawActiveSos = data['active_sos'];
    final rawTasks = data['tasks'];
    return StaffHomeEntity(
      profile: _profileFromJson(data['profile']),
      summary: StaffHomeSummaryEntity.fromJson(data['summary']),
      activeSos: rawActiveSos is List
          ? rawActiveSos.map(StaffActiveSosEntity.fromJson).toList()
          : <StaffActiveSosEntity>[],
      tasks: rawTasks is List
          ? rawTasks.map(SupportRequestEntity.fromJson).toList()
          : <SupportRequestEntity>[],
      unreadMessageCount: _asInt(data['unread_message_count']),
      isAvailable: _availabilityFromJson(data, profileData),
    );
  }

  static bool _availabilityFromJson(
    Map<String, dynamic> data,
    Map<String, dynamic> profileData,
  ) {
    final value =
        data['is_active'] ??
        data['is_available'] ??
        data['available'] ??
        data['staff_active'] ??
        profileData['is_active'] ??
        profileData['is_available'] ??
        profileData['available'] ??
        profileData['staff_active'] ??
        _asMap(profileData['settings'])['staff_active'] ??
        _asMap(profileData['staff_work'])['staff_active'];
    if (value == null) {
      return true;
    }
    return _asBool(value);
  }

  static AuthUserEntity? _profileFromJson(Object? json) {
    if (json == null || json == false) {
      return null;
    }
    final data = _asMap(json);
    return AuthUserEntity(
      id: _asString(data['id']) ?? '',
      displayName: _asString(data['name']) ?? '',
      role: AuthUserRole.staff,
      phone: _asString(data['phone']),
      email: _asString(data['email']),
      avatarUrl: ApiAssetUrl.resolve(_asString(data['avatar_url'])),
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

  static double? _asDouble(Object? value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static bool _asBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.toLowerCase();
      return normalized == 'true' ||
          normalized == '1' ||
          normalized == 'yes' ||
          normalized == 'y';
    }
    return false;
  }

  static String? _asString(Object? value) {
    if (value == null || value == false) {
      return null;
    }
    return value.toString();
  }

  static DateTime? _asDateTime(Object? value) {
    final raw = _asString(value);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw)?.toLocal();
  }
}

class StaffHomeSummaryEntity {
  const StaffHomeSummaryEntity({
    required this.pending,
    required this.processing,
    required this.completed,
  });

  final int pending;
  final int processing;
  final int completed;

  factory StaffHomeSummaryEntity.fromJson(Object? json) {
    final data = StaffHomeEntity._asMap(json);
    return StaffHomeSummaryEntity(
      pending: StaffHomeEntity._asInt(data['pending']),
      processing: StaffHomeEntity._asInt(data['in_progress']),
      completed: StaffHomeEntity._asInt(data['done']),
    );
  }

  static const empty = StaffHomeSummaryEntity(
    pending: 0,
    processing: 0,
    completed: 0,
  );
}

class StaffActiveSosEntity {
  const StaffActiveSosEntity({
    required this.id,
    required this.status,
    this.location,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.assignedStaff,
    this.reporter,
    this.student,
    this.checklist = const <RequestChecklistEntity>[],
    this.timeline = const <StaffSosTimelineEntity>[],
  });

  final int id;
  final String status;
  final String? location;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final AssignedStaffEntity? assignedStaff;
  final StaffSosReporterEntity? reporter;
  final RequestStudentEntity? student;
  final List<RequestChecklistEntity> checklist;
  final List<StaffSosTimelineEntity> timeline;

  factory StaffActiveSosEntity.fromJson(Object? json) {
    final data = StaffHomeEntity._asMap(json);
    final locationData = StaffHomeEntity._asMap(data['location']);
    final rawTimeline = data['timeline'];
    return StaffActiveSosEntity(
      id: StaffHomeEntity._asInt(data['sos_id'] ?? data['id']),
      status: StaffHomeEntity._asString(data['status']) ?? '',
      location:
          StaffHomeEntity._asString(data['location_text']) ??
          StaffHomeEntity._asString(data['address']) ??
          StaffHomeEntity._asString(locationData['text']) ??
          StaffHomeEntity._asString(locationData['address']) ??
          StaffHomeEntity._asString(data['location']),
      latitude:
          StaffHomeEntity._asDouble(data['latitude']) ??
          StaffHomeEntity._asDouble(data['lat']) ??
          StaffHomeEntity._asDouble(locationData['latitude']) ??
          StaffHomeEntity._asDouble(locationData['lat']),
      longitude:
          StaffHomeEntity._asDouble(data['longitude']) ??
          StaffHomeEntity._asDouble(data['lng']) ??
          StaffHomeEntity._asDouble(data['long']) ??
          StaffHomeEntity._asDouble(locationData['longitude']) ??
          StaffHomeEntity._asDouble(locationData['lng']) ??
          StaffHomeEntity._asDouble(locationData['long']),
      createdAt: StaffHomeEntity._asDateTime(data['created_at']),
      assignedStaff:
          data['assigned_staff'] == null || data['assigned_staff'] == false
          ? null
          : AssignedStaffEntity.fromJson(data['assigned_staff']),
      reporter: data['reporter'] == null || data['reporter'] == false
          ? null
          : StaffSosReporterEntity.fromJson(data['reporter']),
      student: data['student'] == null || data['student'] == false
          ? null
          : RequestStudentEntity.fromJson(data['student']),
      checklist: data['checklist'] is List
          ? (data['checklist'] as List)
                .map(RequestChecklistEntity.fromJson)
                .toList()
          : const <RequestChecklistEntity>[],
      timeline: rawTimeline is List
          ? rawTimeline.map(StaffSosTimelineEntity.fromJson).toList()
          : const <StaffSosTimelineEntity>[],
    );
  }

  StaffActiveSosEntity copyWith({
    String? status,
    List<RequestChecklistEntity>? checklist,
    List<StaffSosTimelineEntity>? timeline,
  }) {
    return StaffActiveSosEntity(
      id: id,
      status: status ?? this.status,
      location: location,
      latitude: latitude,
      longitude: longitude,
      createdAt: createdAt,
      assignedStaff: assignedStaff,
      reporter: reporter,
      student: student,
      checklist: checklist ?? this.checklist,
      timeline: timeline ?? this.timeline,
    );
  }
}

class StaffSosTimelineEntity {
  const StaffSosTimelineEntity({
    required this.status,
    required this.label,
    required this.reached,
    this.date,
  });

  final String status;
  final String label;
  final DateTime? date;
  final bool reached;

  factory StaffSosTimelineEntity.fromJson(Object? json) {
    final data = StaffHomeEntity._asMap(json);
    return StaffSosTimelineEntity(
      status: StaffHomeEntity._asString(data['status']) ?? '',
      label: StaffHomeEntity._asString(data['label']) ?? '',
      date: StaffHomeEntity._asDateTime(data['date']),
      reached: StaffHomeEntity._asBool(data['reached']),
    );
  }

  StaffSosTimelineEntity copyWith({DateTime? date, bool? reached}) {
    return StaffSosTimelineEntity(
      status: status,
      label: label,
      date: date ?? this.date,
      reached: reached ?? this.reached,
    );
  }
}

class StaffSosReporterEntity {
  const StaffSosReporterEntity({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.avatarUrl,
  });

  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String? avatarUrl;

  factory StaffSosReporterEntity.fromJson(Object? json) {
    final data = StaffHomeEntity._asMap(json);
    return StaffSosReporterEntity(
      id: StaffHomeEntity._asInt(data['id']),
      name: StaffHomeEntity._asString(data['name']) ?? '',
      phone: StaffHomeEntity._asString(data['phone']),
      email: StaffHomeEntity._asString(data['email']),
      avatarUrl: ApiAssetUrl.resolve(
        StaffHomeEntity._asString(data['avatar_url']),
      ),
    );
  }
}
