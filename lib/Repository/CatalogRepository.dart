// ignore_for_file: file_names

import 'package:hcmu_sos/Entity/IncidentTypeEntity.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';

class CatalogRepository {
  CatalogRepository({ApiCaller? apiCaller})
    : _apiCaller = apiCaller ?? ApiCaller.getInstance();

  final ApiCaller _apiCaller;
  List<IncidentTypeEntity>? _incidentTypesCache;

  Future<List<IncidentTypeEntity>> getIncidentTypes({
    bool forceRefresh = false,
  }) async {
    final cached = _incidentTypesCache;
    if (!forceRefresh && cached != null) {
      return cached;
    }

    final response = await _apiCaller.getBase<Object?>(
      'catalog/incident_types',
      null,
    );
    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Could not load incident types.',
        code: response.code,
        data: response.raw,
      );
    }

    final data = _asMap(response.data);
    final rawItems = data['items'];
    final items = rawItems is List
        ? rawItems.map(IncidentTypeEntity.fromJson).toList()
        : <IncidentTypeEntity>[];
    _incidentTypesCache = items;
    return items;
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
}
