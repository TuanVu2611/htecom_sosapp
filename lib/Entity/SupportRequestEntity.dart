// ignore_for_file: file_names

import 'package:hcmu_sos/Utils/ApiAssetUrl.dart';

enum SupportRequestStatus { pending, inProgress, reopened, done, rejected }

enum SupportRequestPriority { normal, high, urgent }

class SupportRequestEntity {
  const SupportRequestEntity({
    required this.id,
    required this.code,
    required this.title,
    required this.status,
    required this.priority,
    this.isSos = false,
    this.incidentType,
    this.locationText,
    this.createdAt,
    this.updatedAt,
    this.assignedStaff,
    this.rating,
  });

  final int id;
  final String code;
  final String title;
  final SupportRequestStatus status;
  final SupportRequestPriority priority;
  final bool isSos;
  final String? incidentType;
  final String? locationText;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final AssignedStaffEntity? assignedStaff;
  final int? rating;

  factory SupportRequestEntity.fromJson(Object? json) {
    final data = _asMap(json);
    final location = _asMapOrNull(data['location']);
    return SupportRequestEntity(
      id: _asInt(data['id']),
      code: _asString(data['code']) ?? '',
      title: _asString(data['title']) ?? '',
      status: _statusFromApi(data['status']),
      priority: _priorityFromApi(data['priority']),
      isSos: data['is_sos'] == true,
      incidentType: data['incident_type'] is Map
          ? _asString(data['incident_type']['name'])
          : _asString(data['incident_type']),
      locationText: _asString(location?['text']),
      createdAt: _asDateTime(data['created_at']),
      updatedAt: _asDateTime(data['updated_at']),
      assignedStaff: data['assigned_staff'] == null
          ? null
          : AssignedStaffEntity.fromJson(data['assigned_staff']),
      rating: _ratingFromApi(data['rating']),
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

  static Map<String, dynamic>? _asMapOrNull(Object? value) {
    if (value == null || value == false) {
      return null;
    }
    return _asMap(value);
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

  static SupportRequestStatus _statusFromApi(Object? value) {
    return switch (_asString(value)?.toLowerCase()) {
      'in_progress' => SupportRequestStatus.inProgress,
      'reopened' => SupportRequestStatus.reopened,
      'done' => SupportRequestStatus.done,
      'rejected' => SupportRequestStatus.rejected,
      _ => SupportRequestStatus.pending,
    };
  }

  static SupportRequestPriority _priorityFromApi(Object? value) {
    return switch (_asString(value)?.toLowerCase()) {
      'high' => SupportRequestPriority.high,
      'urgent' => SupportRequestPriority.urgent,
      _ => SupportRequestPriority.normal,
    };
  }

  static int? _ratingFromApi(Object? value) {
    if (value == null || value == false) {
      return null;
    }
    if (value is Map) {
      final rating = _asInt(value['rating']);
      return rating == 0 ? null : rating;
    }
    final rating = _asInt(value);
    return rating == 0 ? null : rating;
  }
}

class AssignedStaffEntity {
  const AssignedStaffEntity({
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

  factory AssignedStaffEntity.fromJson(Object? json) {
    final data = SupportRequestEntity._asMap(json);
    return AssignedStaffEntity(
      id: SupportRequestEntity._asInt(data['id']),
      name: SupportRequestEntity._asString(data['name']) ?? '',
      phone: SupportRequestEntity._asString(data['phone']),
      email: SupportRequestEntity._asString(data['email']),
      avatarUrl: ApiAssetUrl.resolve(
        SupportRequestEntity._asString(data['avatar_url']),
      ),
    );
  }
}

class StaffTransferOptionsEntity {
  const StaffTransferOptionsEntity({
    this.departments = const [],
    this.staffs = const [],
    this.reasons = const [],
  });

  final List<StaffTransferDepartmentEntity> departments;
  final List<StaffTransferStaffEntity> staffs;
  final List<String> reasons;

  factory StaffTransferOptionsEntity.fromJson(Object? json) {
    final data = SupportRequestEntity._asMap(json);
    return StaffTransferOptionsEntity(
      departments: SupportRequestDetailEntity._list(
        data['departments'],
      ).map(StaffTransferDepartmentEntity.fromJson).toList(),
      staffs: SupportRequestDetailEntity._list(
        data['staffs'],
      ).map(StaffTransferStaffEntity.fromJson).toList(),
      reasons: SupportRequestDetailEntity._list(data['reasons'])
          .map(SupportRequestEntity._asString)
          .whereType<String>()
          .where((reason) => reason.trim().isNotEmpty)
          .toList(),
    );
  }
}

class StaffTransferDepartmentEntity {
  const StaffTransferDepartmentEntity({required this.id, required this.name});

  final int id;
  final String name;

  factory StaffTransferDepartmentEntity.fromJson(Object? json) {
    final data = SupportRequestEntity._asMap(json);
    return StaffTransferDepartmentEntity(
      id: SupportRequestEntity._asInt(data['id']),
      name: SupportRequestEntity._asString(data['name']) ?? '',
    );
  }
}

class StaffTransferStaffEntity {
  const StaffTransferStaffEntity({
    required this.id,
    required this.name,
    this.department,
    this.phone,
    this.avatarUrl,
  });

  final int id;
  final String name;
  final String? department;
  final String? phone;
  final String? avatarUrl;

  factory StaffTransferStaffEntity.fromJson(Object? json) {
    final data = SupportRequestEntity._asMap(json);
    return StaffTransferStaffEntity(
      id: SupportRequestEntity._asInt(data['id']),
      name: SupportRequestEntity._asString(data['name']) ?? '',
      department: SupportRequestEntity._asString(data['department']),
      phone: SupportRequestEntity._asString(data['phone']),
      avatarUrl: ApiAssetUrl.resolve(
        SupportRequestEntity._asString(data['avatar_url']),
      ),
    );
  }
}

class SupportRequestDetailEntity {
  const SupportRequestDetailEntity({
    required this.id,
    required this.code,
    required this.title,
    required this.status,
    required this.priority,
    this.isSos = false,
    this.incidentType,
    this.location,
    this.createdAt,
    this.updatedAt,
    this.assignedStaff,
    this.description,
    this.student,
    this.reporter,
    this.images = const [],
    this.checklist = const [],
    this.cancelReason,
    this.timeline = const [],
    this.rating,
    this.acceptance,
  });

  final int id;
  final String code;
  final String title;
  final SupportRequestStatus status;
  final SupportRequestPriority priority;
  final bool isSos;
  final IncidentTypeSnapshotEntity? incidentType;
  final RequestLocationEntity? location;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final AssignedStaffEntity? assignedStaff;
  final String? description;
  final RequestStudentEntity? student;
  final RequestReporterEntity? reporter;
  final List<RequestImageEntity> images;
  final List<RequestChecklistEntity> checklist;
  final String? cancelReason;
  final List<RequestTimelineEntity> timeline;
  final RequestRatingEntity? rating;
  final RequestAcceptanceEntity? acceptance;

  factory SupportRequestDetailEntity.fromJson(Object? json) {
    final data = SupportRequestEntity._asMap(json);
    return SupportRequestDetailEntity(
      id: SupportRequestEntity._asInt(data['id']),
      code: SupportRequestEntity._asString(data['code']) ?? '',
      title: SupportRequestEntity._asString(data['title']) ?? '',
      status: SupportRequestEntity._statusFromApi(data['status']),
      priority: SupportRequestEntity._priorityFromApi(data['priority']),
      isSos: data['is_sos'] == true,
      incidentType: data['incident_type'] == null
          ? null
          : IncidentTypeSnapshotEntity.fromJson(data['incident_type']),
      location: data['location'] == null
          ? null
          : RequestLocationEntity.fromJson(data['location']),
      createdAt: SupportRequestEntity._asDateTime(data['created_at']),
      updatedAt: SupportRequestEntity._asDateTime(data['updated_at']),
      assignedStaff:
          data['assigned_staff'] == null || data['assigned_staff'] == false
          ? null
          : AssignedStaffEntity.fromJson(data['assigned_staff']),
      description: SupportRequestEntity._asString(data['description']),
      student: data['student'] == null || data['student'] == false
          ? null
          : RequestStudentEntity.fromJson(data['student']),
      reporter: data['reporter'] == null || data['reporter'] == false
          ? null
          : RequestReporterEntity.fromJson(data['reporter']),
      images: _list(data['images']).map(RequestImageEntity.fromJson).toList(),
      checklist: _list(
        data['checklist'],
      ).map(RequestChecklistEntity.fromJson).toList(),
      cancelReason: SupportRequestEntity._asString(data['cancel_reason']),
      timeline: _list(
        data['timeline'],
      ).map(RequestTimelineEntity.fromJson).toList(),
      rating: data['rating'] == null || data['rating'] == false
          ? null
          : RequestRatingEntity.fromJson(data['rating']),
      acceptance: data['acceptance'] == null || data['acceptance'] == false
          ? null
          : RequestAcceptanceEntity.fromJson(data['acceptance']),
    );
  }

  static List<Object?> _list(Object? value) {
    return value is List ? value : const <Object?>[];
  }
}

class IncidentTypeSnapshotEntity {
  const IncidentTypeSnapshotEntity({
    required this.id,
    required this.name,
    required this.code,
    this.iconUrl,
    this.parentId,
  });

  final int id;
  final String name;
  final String code;
  final String? iconUrl;
  final int? parentId;

  factory IncidentTypeSnapshotEntity.fromJson(Object? json) {
    final data = SupportRequestEntity._asMap(json);
    return IncidentTypeSnapshotEntity(
      id: SupportRequestEntity._asInt(data['id']),
      name: SupportRequestEntity._asString(data['name']) ?? '',
      code: SupportRequestEntity._asString(data['code']) ?? '',
      iconUrl: ApiAssetUrl.resolve(
        SupportRequestEntity._asString(data['icon_url']),
      ),
      parentId: data['parent_id'] == null || data['parent_id'] == false
          ? null
          : SupportRequestEntity._asInt(data['parent_id']),
    );
  }
}

class RequestLocationEntity {
  const RequestLocationEntity({this.text, this.latitude, this.longitude});

  final String? text;
  final double? latitude;
  final double? longitude;

  factory RequestLocationEntity.fromJson(Object? json) {
    final data = SupportRequestEntity._asMap(json);
    return RequestLocationEntity(
      text: SupportRequestEntity._asString(data['text']),
      latitude: _asDouble(data['latitude']),
      longitude: _asDouble(data['longitude']),
    );
  }

  static double? _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}

class RequestImageEntity {
  const RequestImageEntity({
    required this.id,
    required this.name,
    this.url,
    this.mimeType,
    this.size,
  });

  final int id;
  final String name;
  final String? url;
  final String? mimeType;
  final int? size;

  factory RequestImageEntity.fromJson(Object? json) {
    final data = SupportRequestEntity._asMap(json);
    return RequestImageEntity(
      id: SupportRequestEntity._asInt(data['id']),
      name: SupportRequestEntity._asString(data['name']) ?? '',
      url: ApiAssetUrl.resolve(SupportRequestEntity._asString(data['url'])),
      mimeType: SupportRequestEntity._asString(data['mime_type']),
      size: data['size'] == null
          ? null
          : SupportRequestEntity._asInt(data['size']),
    );
  }
}

class RequestChecklistEntity {
  const RequestChecklistEntity({
    required this.id,
    required this.name,
    required this.isDone,
    this.checkDate,
    this.sequence = 0,
  });

  final int id;
  final String name;
  final bool isDone;
  final DateTime? checkDate;
  final int sequence;

  factory RequestChecklistEntity.fromJson(Object? json) {
    final data = SupportRequestEntity._asMap(json);
    return RequestChecklistEntity(
      id: SupportRequestEntity._asInt(data['id']),
      name: SupportRequestEntity._asString(data['name']) ?? '',
      isDone: data['is_done'] == true,
      checkDate: SupportRequestEntity._asDateTime(data['check_date']),
      sequence: SupportRequestEntity._asInt(data['sequence']),
    );
  }
}

class RequestTimelineEntity {
  const RequestTimelineEntity({
    required this.status,
    required this.label,
    required this.reached,
    this.date,
  });

  final String status;
  final String label;
  final bool reached;
  final DateTime? date;

  factory RequestTimelineEntity.fromJson(Object? json) {
    final data = SupportRequestEntity._asMap(json);
    return RequestTimelineEntity(
      status: SupportRequestEntity._asString(data['status']) ?? '',
      label: SupportRequestEntity._asString(data['label']) ?? '',
      reached: data['reached'] == true,
      date: SupportRequestEntity._asDateTime(data['date']),
    );
  }
}

class RequestRatingEntity {
  const RequestRatingEntity({
    required this.id,
    required this.rating,
    this.comment,
    this.createdAt,
    this.userId,
  });

  final int id;
  final int rating;
  final String? comment;
  final DateTime? createdAt;
  final int? userId;

  factory RequestRatingEntity.fromJson(Object? json) {
    final data = SupportRequestEntity._asMap(json);
    return RequestRatingEntity(
      id: SupportRequestEntity._asInt(data['id']),
      rating: SupportRequestEntity._asInt(data['rating']),
      comment: SupportRequestEntity._asString(data['comment']),
      createdAt: SupportRequestEntity._asDateTime(data['created_at']),
      userId: data['user_id'] == null
          ? null
          : SupportRequestEntity._asInt(data['user_id']),
    );
  }
}

class RequestAcceptanceEntity {
  const RequestAcceptanceEntity({this.note, this.date, this.images = const []});

  final String? note;
  final DateTime? date;
  final List<RequestImageEntity> images;

  factory RequestAcceptanceEntity.fromJson(Object? json) {
    final data = SupportRequestEntity._asMap(json);
    return RequestAcceptanceEntity(
      note: SupportRequestEntity._asString(data['note']),
      date: SupportRequestEntity._asDateTime(data['date']),
      images: SupportRequestDetailEntity._list(
        data['images'],
      ).map(RequestImageEntity.fromJson).toList(),
    );
  }
}

class RequestStudentEntity {
  const RequestStudentEntity({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.avatarUrl,
    this.studentCode,
    this.school,
    this.isVerified = false,
  });

  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String? avatarUrl;
  final String? studentCode;
  final String? school;
  final bool isVerified;

  factory RequestStudentEntity.fromJson(Object? json) {
    final data = SupportRequestEntity._asMap(json);
    return RequestStudentEntity(
      id: SupportRequestEntity._asInt(data['id']),
      name: SupportRequestEntity._asString(data['name']) ?? '',
      phone: SupportRequestEntity._asString(data['phone']),
      email: SupportRequestEntity._asString(data['email']),
      avatarUrl: ApiAssetUrl.resolve(
        SupportRequestEntity._asString(data['avatar_url']),
      ),
      studentCode: SupportRequestEntity._asString(data['student_code']),
      school: SupportRequestEntity._asString(data['school']),
      isVerified: data['is_verified'] == true,
    );
  }
}

class RequestReporterEntity {
  const RequestReporterEntity({this.name, this.phone, this.email, this.code});

  final String? name;
  final String? phone;
  final String? email;
  final String? code;

  factory RequestReporterEntity.fromJson(Object? json) {
    final data = SupportRequestEntity._asMap(json);
    return RequestReporterEntity(
      name: SupportRequestEntity._asString(data['name']),
      phone: SupportRequestEntity._asString(data['phone']),
      email: SupportRequestEntity._asString(data['email']),
      code: SupportRequestEntity._asString(data['code']),
    );
  }
}
