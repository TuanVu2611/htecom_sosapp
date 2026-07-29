// ignore_for_file: file_names

import 'package:hcmu_sos/Entity/StaffPerformanceEntity.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';

class StaffPerformanceRepository {
  StaffPerformanceRepository({ApiCaller? apiCaller})
    : _apiCaller = apiCaller ?? ApiCaller.getInstance();

  final ApiCaller _apiCaller;

  Future<StaffPerformanceEntity> getPerformance({
    required DateTime fromDate,
    required DateTime toDate,
    String period = 'month',
  }) async {
    final response = await _apiCaller.getBase<Object?>(
      'staff/performance',
      <String, dynamic>{
        'from_date': _formatDate(fromDate),
        'to_date': _formatDate(toDate),
        'period': period,
      },
    );

    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Could not load staff performance.',
        code: response.code,
        data: response.raw,
      );
    }

    return StaffPerformanceEntity.fromJson(response.data);
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
