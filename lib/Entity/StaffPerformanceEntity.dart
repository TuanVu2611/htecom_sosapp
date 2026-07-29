// ignore_for_file: file_names

class StaffPerformanceEntity {
  const StaffPerformanceEntity({
    required this.completionRate,
    required this.totalAssigned,
    required this.completed,
    required this.avgProcessingTimeHours,
    required this.ratingAvg,
    this.chart = const <StaffPerformanceChartEntity>[],
  });

  final double completionRate;
  final int totalAssigned;
  final int completed;
  final double avgProcessingTimeHours;
  final double ratingAvg;
  final List<StaffPerformanceChartEntity> chart;

  factory StaffPerformanceEntity.fromJson(Object? json) {
    final data = _asMap(json);
    final rawChart = data['chart'];
    return StaffPerformanceEntity(
      completionRate: _asDouble(data['completion_rate']),
      totalAssigned: _asInt(data['total_assigned']),
      completed: _asInt(data['completed']),
      avgProcessingTimeHours: _asDouble(data['avg_processing_time_hours']),
      ratingAvg: _asDouble(data['rating_avg']),
      chart: rawChart is List
          ? rawChart.map(StaffPerformanceChartEntity.fromJson).toList()
          : const <StaffPerformanceChartEntity>[],
    );
  }

  static const empty = StaffPerformanceEntity(
    completionRate: 0,
    totalAssigned: 0,
    completed: 0,
    avgProcessingTimeHours: 0,
    ratingAvg: 0,
  );

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

  static double _asDouble(Object? value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }
}

class StaffPerformanceChartEntity {
  const StaffPerformanceChartEntity({
    required this.period,
    required this.assigned,
    required this.completed,
    required this.avgTimeHours,
  });

  final String period;
  final int assigned;
  final int completed;
  final double avgTimeHours;

  factory StaffPerformanceChartEntity.fromJson(Object? json) {
    final data = StaffPerformanceEntity._asMap(json);
    return StaffPerformanceChartEntity(
      period: data['period']?.toString() ?? '',
      assigned: StaffPerformanceEntity._asInt(data['assigned']),
      completed: StaffPerformanceEntity._asInt(data['completed']),
      avgTimeHours: StaffPerformanceEntity._asDouble(data['avg_time_hours']),
    );
  }
}
