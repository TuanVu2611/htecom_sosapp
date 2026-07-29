// ignore_for_file: file_names

import 'package:hcmu_sos/Entity/NotificationEntity.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';

class NotificationListResult {
  const NotificationListResult({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.unreadCount,
  });

  final List<NotificationEntity> items;
  final int total;
  final int page;
  final int pageSize;
  final int unreadCount;
}

class NotificationRepository {
  NotificationRepository({ApiCaller? apiCaller})
    : _apiCaller = apiCaller ?? ApiCaller.getInstance();

  final ApiCaller _apiCaller;

  Future<NotificationListResult> listNotifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiCaller.getBase<Object?>(
      'notifications',
      <String, dynamic>{'page': page, 'page_size': pageSize},
    );

    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Could not load notifications.',
        code: response.code,
        data: response.raw,
      );
    }

    final data = _asMap(response.data);
    final rawItems = data['items'];
    return NotificationListResult(
      items: rawItems is List
          ? rawItems.map(NotificationEntity.fromJson).toList()
          : const <NotificationEntity>[],
      total: _asInt(data['total']),
      page: page,
      pageSize: pageSize,
      unreadCount: _asInt(data['unread_count']),
    );
  }

  Future<void> markRead({int? notificationId, bool all = false}) async {
    final response = await _apiCaller.postBase<Object?>(
      'notifications/mark-read',
      <String, dynamic>{'notification_id': notificationId, 'all': all},
    );

    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Could not update notifications.',
        code: response.code,
        data: response.raw,
      );
    }
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
}
