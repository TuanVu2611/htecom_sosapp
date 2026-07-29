// ignore_for_file: file_names

import 'package:hcmu_sos/Service/ApiCaller.dart';

class StaffLocationRepository {
  StaffLocationRepository({ApiCaller? apiCaller})
    : _apiCaller = apiCaller ?? ApiCaller.getInstance();

  final ApiCaller _apiCaller;

  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    final response = await _apiCaller.postBase<Object?>(
      'profile/update_location',
      <String, dynamic>{
        'lat': latitude,
        'lng': longitude,
        'accuracy': accuracy,
      },
    );

    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Could not update staff location.',
        code: response.code,
        data: response.raw,
      );
    }
  }
}
