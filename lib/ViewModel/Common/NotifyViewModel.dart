// ignore_for_file: file_names

import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/AuthUserEntity.dart';
import 'package:hcmu_sos/Entity/NotificationEntity.dart';
import 'package:hcmu_sos/Navigator/AppRoute.dart';
import 'package:hcmu_sos/Repository/NotificationRepository.dart';
import 'package:hcmu_sos/Repository/StaffSosRepository.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';
import 'package:hcmu_sos/Service/AuthSessionStorage.dart';
import 'package:hcmu_sos/Utils/Utils.dart';
import 'package:hcmu_sos/ViewModel/Staff/StaffHomeViewModel.dart';
import 'package:hcmu_sos/ViewModel/Student/StudentHomeViewModel.dart';

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
  final unreadCount = 0.obs;

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
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;
    try {
      final result = await _notificationRepository.listNotifications(
        page: 1,
        pageSize: _pageSize,
      );
      _page = result.page;
      total.value = result.total;
      unreadCount.value = result.unreadCount;
      notifications.assignAll(result.items);
      _syncHomeUnreadCount();
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      Utils.showSnackbar(title: 'Thông báo', content: error.message);
    } catch (_) {
      const message = 'Không thể tải danh sách thông báo.';
      errorMessage.value = message;
      Utils.showSnackbar(title: 'Thông báo', content: message);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !canLoadMore) {
      return;
    }

    isLoadingMore.value = true;
    try {
      final result = await _notificationRepository.listNotifications(
        page: _page + 1,
        pageSize: _pageSize,
      );
      _page = result.page;
      total.value = result.total;
      unreadCount.value = result.unreadCount;
      notifications.addAll(result.items);
      _syncHomeUnreadCount();
    } on ApiException catch (error) {
      Utils.showSnackbar(title: 'Thông báo', content: error.message);
    } catch (_) {
      Utils.showSnackbar(
        title: 'Thông báo',
        content: 'Không thể tải thêm thông báo.',
      );
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> markRead(NotificationEntity item) async {
    if (item.isRead || isMarkingRead.value) {
      return;
    }

    isMarkingRead.value = true;
    try {
      await _notificationRepository.markRead(notificationId: item.id);
      _replaceNotification(item.id, item.copyWith(isRead: true));
      if (unreadCount.value > 0) {
        unreadCount.value--;
      }
      _syncHomeUnreadCount();
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

    isMarkingRead.value = true;
    try {
      await _notificationRepository.markRead(all: true);
      notifications.assignAll(
        notifications.map((item) => item.copyWith(isRead: true)).toList(),
      );
      unreadCount.value = 0;
      _syncHomeUnreadCount();
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

  void _syncHomeUnreadCount() {
    final count = unreadCount.value;
    if (Get.isRegistered<StudentHomeViewModel>()) {
      Get.find<StudentHomeViewModel>().updateUnreadNotificationCount(count);
    }
    if (Get.isRegistered<StaffHomeViewModel>()) {
      Get.find<StaffHomeViewModel>().updateUnreadNotificationCount(count);
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
