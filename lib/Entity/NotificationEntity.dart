// ignore_for_file: file_names

class NotificationEntity {
  const NotificationEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.category,
    required this.isRead,
    this.refModel,
    this.refId,
    this.createdAt,
  });

  final int id;
  final String title;
  final String body;
  final String type;
  final String category;
  final String? refModel;
  final int? refId;
  final bool isRead;
  final DateTime? createdAt;

  factory NotificationEntity.fromJson(Object? json) {
    final data = _asMap(json);
    return NotificationEntity(
      id: _asInt(data['id']),
      title: _asString(data['title']) ?? '',
      body: _asString(data['body']) ?? '',
      type: _asString(data['type']) ?? '',
      category: _asString(data['category']) ?? '',
      refModel: _asString(data['ref_model']),
      refId: _asNullableInt(data['ref_id']),
      isRead: _asBool(data['is_read']),
      createdAt: _asDateTime(data['created_at']),
    );
  }

  NotificationEntity copyWith({bool? isRead}) {
    return NotificationEntity(
      id: id,
      title: title,
      body: body,
      type: type,
      category: category,
      refModel: refModel,
      refId: refId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
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

  static int? _asNullableInt(Object? value) {
    if (value == null || value == false) {
      return null;
    }
    final number = _asInt(value);
    return number == 0 ? null : number;
  }

  static String? _asString(Object? value) {
    if (value == null || value == false) {
      return null;
    }
    return value.toString();
  }

  static bool _asBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return false;
  }

  static DateTime? _asDateTime(Object? value) {
    final raw = _asString(value);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw)?.toLocal();
  }
}
