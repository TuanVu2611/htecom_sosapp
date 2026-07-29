// ignore_for_file: file_names

class InstitutionEntity {
  const InstitutionEntity({
    required this.id,
    required this.name,
    required this.code,
  });

  final int id;
  final String name;
  final String code;

  factory InstitutionEntity.fromJson(Object? json) {
    final data = _asMap(json);
    return InstitutionEntity(
      id: _asInt(data['id']),
      name: _asString(data['name']),
      code: _asString(data['code']),
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
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _asString(Object? value) {
    return value?.toString() ?? '';
  }
}
