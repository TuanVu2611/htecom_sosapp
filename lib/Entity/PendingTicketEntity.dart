// ignore_for_file: file_names

enum PendingTicketStatus { pending, syncing, failed }

class PendingTicketAttachmentEntity {
  const PendingTicketAttachmentEntity({
    required this.filePath,
    required this.fileName,
    required this.mimeType,
  });

  final String filePath;
  final String fileName;
  final String mimeType;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'file_path': filePath,
      'file_name': fileName,
      'mime_type': mimeType,
    };
  }

  factory PendingTicketAttachmentEntity.fromJson(Object? json) {
    final data = _asMap(json);
    return PendingTicketAttachmentEntity(
      filePath: _asString(data['file_path']),
      fileName: _asString(data['file_name']),
      mimeType: _asString(data['mime_type']),
    );
  }
}

class PendingTicketEntity {
  const PendingTicketEntity({
    required this.localId,
    required this.incidentTypeId,
    required this.title,
    required this.description,
    required this.priority,
    required this.locationText,
    required this.latitude,
    required this.longitude,
    required this.attachments,
    required this.createdAt,
    this.status = PendingTicketStatus.pending,
    this.retryCount = 0,
    this.lastError,
  });

  final String localId;
  final int incidentTypeId;
  final String title;
  final String description;
  final String priority;
  final String locationText;
  final double latitude;
  final double longitude;
  final List<PendingTicketAttachmentEntity> attachments;
  final DateTime createdAt;
  final PendingTicketStatus status;
  final int retryCount;
  final String? lastError;

  PendingTicketEntity copyWith({
    PendingTicketStatus? status,
    int? retryCount,
    String? lastError,
  }) {
    return PendingTicketEntity(
      localId: localId,
      incidentTypeId: incidentTypeId,
      title: title,
      description: description,
      priority: priority,
      locationText: locationText,
      latitude: latitude,
      longitude: longitude,
      attachments: attachments,
      createdAt: createdAt,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'local_id': localId,
      'incident_type_id': incidentTypeId,
      'title': title,
      'description': description,
      'priority': priority,
      'location_text': locationText,
      'latitude': latitude,
      'longitude': longitude,
      'attachments': attachments.map((item) => item.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'status': status.name,
      'retry_count': retryCount,
      'last_error': lastError,
    };
  }

  factory PendingTicketEntity.fromJson(Object? json) {
    final data = _asMap(json);
    final rawAttachments = data['attachments'];
    final attachments = rawAttachments is List
        ? rawAttachments.map(PendingTicketAttachmentEntity.fromJson).toList()
        : <PendingTicketAttachmentEntity>[];

    return PendingTicketEntity(
      localId: _asString(data['local_id']),
      incidentTypeId: _asInt(data['incident_type_id']),
      title: _asString(data['title']),
      description: _asString(data['description']),
      priority: _asString(data['priority']),
      locationText: _asString(data['location_text']),
      latitude: _asDouble(data['latitude']),
      longitude: _asDouble(data['longitude']),
      attachments: attachments,
      createdAt:
          DateTime.tryParse(_asString(data['created_at'])) ?? DateTime.now(),
      status: _statusFromString(_asString(data['status'])),
      retryCount: _asInt(data['retry_count']),
      lastError: _nullableString(data['last_error']),
    );
  }

  static PendingTicketStatus _statusFromString(String value) {
    return PendingTicketStatus.values.firstWhere(
      (item) => item.name == value,
      orElse: () => PendingTicketStatus.pending,
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

String _asString(Object? value) {
  return value?.toString() ?? '';
}

String? _nullableString(Object? value) {
  final text = value?.toString();
  return text == null || text.isEmpty ? null : text;
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _asDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
