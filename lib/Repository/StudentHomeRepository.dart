// ignore_for_file: file_names

import 'package:hcmu_sos/Entity/StudentHomeEntity.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';

class StudentHomeRepository {
  StudentHomeRepository({ApiCaller? apiCaller})
    : _apiCaller = apiCaller ?? ApiCaller.getInstance();

  final ApiCaller _apiCaller;

  Future<StudentHomeEntity> getHome() async {
    final response = await _apiCaller.getBase<Object?>('student/home', null);
    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Could not load student home.',
        code: response.code,
        data: response.raw,
      );
    }

    return StudentHomeEntity.fromJson(response.data);
  }
}
