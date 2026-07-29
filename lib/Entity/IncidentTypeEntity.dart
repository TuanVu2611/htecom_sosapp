// ignore_for_file: file_names

import 'package:hcmu_sos/Utils/ApiAssetUrl.dart';

class IncidentTypeEntity {
  const IncidentTypeEntity({
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

  factory IncidentTypeEntity.fromJson(Object? json) {
    final data = _asMap(json);
    return IncidentTypeEntity(
      id: _asInt(data['id']),
      name: _asString(data['name']) ?? '',
      code: _asString(data['code']) ?? '',
      iconUrl: ApiAssetUrl.resolve(_asString(data['icon_url'])),
      parentId: _asNullableInt(data['parent_id']),
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
    return _asNullableInt(value) ?? 0;
  }

  static int? _asNullableInt(Object? value) {
    if (value == null || value == false) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static String? _asString(Object? value) {
    if (value == null || value == false) {
      return null;
    }
    return value.toString();
  }
}
