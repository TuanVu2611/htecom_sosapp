// ignore_for_file: file_names

import 'package:hcmu_sos/Entity/StaffHomeEntity.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';

class StaffHomeRepository {
  StaffHomeRepository({ApiCaller? apiCaller})
    : _apiCaller = apiCaller ?? ApiCaller.getInstance();

  final ApiCaller _apiCaller;

  Future<StaffHomeEntity> getHome() async {
    final response = await _apiCaller.getBase<Object?>('staff/home', null);
    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Could not load staff home.',
        code: response.code,
        data: response.raw,
      );
    }

    return StaffHomeEntity.fromJson(response.data);
  }

  Future<void> updateAvailability({required bool isActive}) async {
    final response = await _apiCaller.postBase<Object?>(
      'staff/availability',
      <String, dynamic>{'is_active': isActive ? 1 : 0},
    );
    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Could not update availability.',
        code: response.code,
        data: response.raw,
      );
    }
  }
}
