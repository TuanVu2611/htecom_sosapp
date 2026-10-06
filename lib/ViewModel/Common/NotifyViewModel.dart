import 'dart:async';
// ignore_for_file: file_names

import 'package:hcmu_sos/Service/NotificationUnreadService.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/AuthUserEntity.dart';
import 'package:hcmu_sos/Entity/NotificationEntity.dart';
import 'package:hcmu_sos/Navigator/AppRoute.dart';
import 'package:hcmu_sos/Repository/NotificationRepository.dart';
import 'package:hcmu_sos/Repository/StaffSosRepository.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';
import 'package:hcmu_sos/Service/AuthSessionStorage.dart';
import 'package:hcmu_sos/Utils/Utils.dart';

class NotifyViewModel extends GetxController {
  NotifyViewModel({
    NotificationRepository? notificationRepository,
    StaffSosRepository? staffSosRepository,
  }) : _notificationRepository =
           notificationRepository ?? NotificationRepository(),
       _staffSosRepository = staffSosRepository ?? StaffSosRepository();

  final NotificationRepository _notificationRepository;
  final StaffSosRepository _staffSosRepository;

  final notifications = <NotificationEntity>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final isMarkingRead = false.obs;
  final errorMessage = RxnString();
  final total = 0.obs;
  final unreadCount = NotificationUnreadService.instance.count;

  bool _reloadPending = false;
  int _page = 1;
  static const int _pageSize = 20;

  bool get canLoadMore => notifications.length < total.value;

  @override
  void onReady() {
    super.onReady();
    loadFirstPage();
  }

  Future<void> loadFirstPage() async {
    if (isLoading.value) {
      _reloadPending = true;
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;
    final ticket = NotificationUnreadService.instance.beginRead();
    try {
      final result = await _notificationRepository.listNotifications(
        page: 1,
        pageSize: _pageSize,
      );
      if (!NotificationUnreadService.instance.applyCount(
        result.unreadCount,
        ticket,
      )) {
        _reloadPending = true;
        return;
      }
      _page = result.page;
      total.value = result.total;
      notifications.assignAll(result.items);
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      Utils.showSnackbar(title: 'Thông báo', content: error.message);
    } catch (_) {
      const message = 'Không thể tải danh sách thông báo.';
      errorMessage.value = message;
      Utils.showSnackbar(title: 'Thông báo', content: message);
    } finally {
      isLoading.value = false;
      _reloadIfPending();
    }
  }

  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !canLoadMore) {
      return;
    }

    isLoadingMore.value = true;
    final ticket = NotificationUnreadService.instance.beginRead();
    try {
      final result = await _notificationRepository.listNotifications(
        page: _page + 1,
        pageSize: _pageSize,
      );
      if (!NotificationUnreadService.instance.applyCount(
        result.unreadCount,
        ticket,
      )) {
        _reloadPending = true;
        return;
      }
      _page = result.page;
      total.value = result.total;
      notifications.addAll(result.items);
    } on ApiException catch (error) {
      Utils.showSnackbar(title: 'Thông báo', content: error.message);
    } catch (_) {
      Utils.showSnackbar(
        title: 'Thông báo',
        content: 'Không thể tải thêm thông báo.',
      );
    } finally {
      isLoadingMore.value = false;
      _reloadIfPending();
    }
  }

  void _reloadIfPending() {
    if (_reloadPending &&
        !isClosed &&
        !isLoading.value &&
        !isLoadingMore.value) {
      _reloadPending = false;
      unawaited(loadFirstPage());
    }
  }

  Future<void> markRead(NotificationEntity item) async {
    if (item.isRead || isMarkingRead.value) {
      return;
    }

    final revision = NotificationUnreadService.instance.revision;
    isMarkingRead.value = true;
    try {
      await _notificationRepository.markRead(notificationId: item.id);
      _replaceNotification(item.id, item.copyWith(isRead: true));
      NotificationUnreadService.instance.readCompleted(revision);
      unawaited(NotificationUnreadService.instance.refresh());
    } on ApiException catch (error) {
      Utils.showSnackbar(title: 'Thông báo', content: error.message);
    } catch (_) {
      Utils.showSnackbar(
        title: 'Thông báo',
        content: 'Không thể đánh dấu thông báo đã đọc.',
      );
    } finally {
      isMarkingRead.value = false;
    }
  }

  Future<void> markAllRead() async {
    if (unreadCount.value <= 0 || isMarkingRead.value) {
      return;
    }

    final revision = NotificationUnreadService.instance.revision;
    isMarkingRead.value = true;
    try {
      await _notificationRepository.markRead(all: true);
      notifications.assignAll(
        notifications.map((item) => item.copyWith(isRead: true)).toList(),
      );
      NotificationUnreadService.instance.readCompleted(revision, all: true);
      unawaited(NotificationUnreadService.instance.refresh());
    } on ApiException catch (error) {
      Utils.showSnackbar(title: 'Thông báo', content: error.message);
    } catch (_) {
      Utils.showSnackbar(
        title: 'Thông báo',
        content: 'Không thể đánh dấu tất cả thông báo đã đọc.',
      );
    } finally {
      isMarkingRead.value = false;
    }
  }

  Future<void> openNotification(NotificationEntity item) async {
    if (!item.isRead) {
      await markRead(item);
    }

    final currentUser = AuthSessionStorage.getUser();
    final route = _routeForNotification(item, currentUser?.role);
    if (route == null) {
      Utils.showSnackbar(
        title: 'Thông báo',
        content: 'Không thể mở nội dung của thông báo này.',
      );
      return;
    }

    try {
      switch (route) {
        case _NotificationRoute.ticketDetail:
          await Get.toNamed(AppRoute.ticketDetail, arguments: item.refId);
        case _NotificationRoute.staffTicketDetail:
          await Get.toNamed(AppRoute.staffTicketDetail, arguments: item.refId);
        case _NotificationRoute.commentTicket:
          await Get.toNamed(
            AppRoute.commentTicket,
            arguments: <String, dynamic>{'thread_id': item.refId},
          );
        case _NotificationRoute.staffSosDetail:
          final refId = item.refId;
          if (refId == null || refId <= 0) {
            _showMissingTargetMessage();
            return;
          }
          final sos = await _staffSosRepository.getSosDetail(refId);
          await Get.toNamed(AppRoute.staffSosDetail, arguments: sos);
        case _NotificationRoute.studentInfo:
          await Get.toNamed(AppRoute.studentInfo);
        case _NotificationRoute.staffInfo:
          await Get.toNamed(AppRoute.staffInfo);
      }
    } on ApiException catch (error) {
      Utils.showSnackbar(title: 'Thông báo', content: error.message);
    } catch (_) {
      Utils.showSnackbar(
        title: 'Thông báo',
        content: 'Không thể mở nội dung của thông báo này.',
      );
    }
  }

  void _replaceNotification(int id, NotificationEntity next) {
    final index = notifications.indexWhere((item) => item.id == id);
    if (index >= 0) {
      notifications[index] = next;
    }
  }

  _NotificationRoute? _routeForNotification(
    NotificationEntity item,
    AuthUserRole? role,
  ) {
    final category = item.category.trim().toLowerCase();
    switch (category) {
      case 'incident':
        if (item.refId == null || item.refId! <= 0) {
          return null;
        }
        return role == AuthUserRole.staff
            ? _NotificationRoute.staffTicketDetail
            : _NotificationRoute.ticketDetail;
      case 'sos':
        if (item.refId == null || item.refId! <= 0) {
          return null;
        }
        return role == AuthUserRole.staff
            ? _NotificationRoute.staffSosDetail
            : null;
      case 'chat':
        if (item.refId == null || item.refId! <= 0) {
          return null;
        }
        return _NotificationRoute.commentTicket;
      case 'account':
        return role == AuthUserRole.staff
            ? _NotificationRoute.staffInfo
            : _NotificationRoute.studentInfo;
      default:
        return null;
    }
  }

  void _showMissingTargetMessage() {
    Utils.showSnackbar(
      title: 'Thông báo',
      content: 'Không tìm thấy nội dung liên kết của thông báo này.',
    );
  }
}

enum _NotificationRoute {
  ticketDetail,
  staffTicketDetail,
  commentTicket,
  staffSosDetail,
  studentInfo,
  staffInfo,
}
