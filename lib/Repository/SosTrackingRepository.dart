// ignore_for_file: file_names

import 'package:hcmu_sos/Entity/SosTrackingEntity.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';

class SosTrackingRepository {
  SosTrackingRepository({ApiCaller? apiCaller})
    : _apiCaller = apiCaller ?? ApiCaller.getInstance();

  final ApiCaller _apiCaller;

  Future<SosCurrentStatusEntity?> getCurrentSosStatus({int? sosId}) async {
    final response = await _apiCaller.getBase<Object?>(
      'sos/status',
      sosId == null ? null : <String, dynamic>{'sos_id': sosId},
    );

    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Could not load SOS status.',
        code: response.code,
        data: response.raw,
      );
    }

    final data = _asMapOrNull(response.data);
    if (data == null || data.isEmpty) {
      return null;
    }

    return SosCurrentStatusEntity.fromJson(data);
  }

  Future<SosLiveLocationEntity?> updateSosLocation({
    required int sosId,
    required double latitude,
    required double longitude,
    String? locationText,
  }) async {
    final response = await _apiCaller.postBase<Object?>(
      'sos/$sosId/location',
      <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        'location_text': locationText,
      },
    );

    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Could not update SOS location.',
        code: response.code,
        data: response.raw,
      );
    }

    final data = _asMapOrNull(response.data);
    if (data == null || data.isEmpty) {
      return null;
    }

    return SosLiveLocationEntity.fromJson(data);
  }

  Future<SosLiveLocationEntity> getSosLocation(int sosId) async {
    final response = await _apiCaller.getBase<Object?>(
      'sos/$sosId/location',
      null,
    );

    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Could not load SOS location.',
        code: response.code,
        data: response.raw,
      );
    }

    final data = _asMapOrNull(response.data);
    if (data == null || data.isEmpty) {
      throw ApiException(message: 'SOS location data is empty.');
    }

    return SosLiveLocationEntity.fromJson(data);
  }

  static Map<String, dynamic>? _asMapOrNull(Object? value) {
    if (value == null || value == false) {
      return null;
    }
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }
}
