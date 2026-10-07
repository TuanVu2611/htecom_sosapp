// ignore_for_file: file_names

import 'package:get/get.dart';
import 'package:hcmu_sos/Repository/NotificationRepository.dart';

/// One unread count for the notification list and both dashboards.
class NotificationUnreadService {
  NotificationUnreadService({Future<int> Function()? fetchCount})
    : _fetchCount = fetchCount ?? _loadCount;

  static final instance = NotificationUnreadService();
  final Future<int> Function() _fetchCount;
  final count = 0.obs;
  String? _accountId;
  int _revision = 0;
  int _requestId = 0;
  Future<void>? _refreshing;

  static Future<int> _loadCount() async {
    final result = await NotificationRepository().listNotifications(
      pageSize: 1,
    );
    return result.unreadCount;
  }

  int get revision => _revision;

  void setAccount(String? id) {
    if (_accountId == id) return;
    _accountId = id;
    _revision++;
    _requestId++;
    _refreshing = null;
    count.value = 0;
  }

  void receivedPush() {
    if (_accountId == null) return;
    _revision++;
    count.value++;
  }

  (int, int) beginRead() => (_revision, ++_requestId);

  bool applyCount(int value, (int, int) ticket) {
    if (_accountId == null || ticket != (_revision, _requestId)) return false;
    count.value = value < 0 ? 0 : value;
    return true;
  }

  void readCompleted(int startedAtRevision, {bool all = false}) {
    // A push during mark-read must not be cleared by that older operation.
    if (startedAtRevision == _revision) {
      count.value = all || count.value <= 1 ? 0 : count.value - 1;
    }
    _revision++;
    _refreshing = null;
  }

  Future<void> refresh() {
    if (_accountId == null) return Future<void>.value();
    if (_refreshing != null) return _refreshing!;
    late final Future<void> pending;
    pending = _refresh().whenComplete(() {
      if (identical(_refreshing, pending)) _refreshing = null;
    });
    _refreshing = pending;
    return pending;
  }

  Future<void> _refresh() async {
    final ticket = beginRead();
    try {
      applyCount(await _fetchCount(), ticket);
    } catch (_) {
      // Keep the current badge on network errors; no user-facing error.
    }
  }
}
