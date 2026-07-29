// ignore_for_file: file_names

import 'dart:convert';
import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Navigator/AppRoute.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';
import 'package:hcmu_sos/Service/AuthSessionStorage.dart';
import 'package:hcmu_sos/ViewModel/Common/MenuViewModel.dart';
import 'package:hcmu_sos/ViewModel/Common/NotifyViewModel.dart';
import 'package:hcmu_sos/ViewModel/Staff/SOSDetailViewModel.dart';
import 'package:hcmu_sos/ViewModel/Staff/SOSListViewModel.dart';
import 'package:hcmu_sos/ViewModel/Staff/StaffHomeViewModel.dart';
import 'package:hcmu_sos/ViewModel/Staff/StaffInfoViewModel.dart';
import 'package:hcmu_sos/ViewModel/Staff/StaffTaskViewModel.dart';
import 'package:hcmu_sos/ViewModel/Staff/StaffTicketDetailViewModel.dart';
import 'package:hcmu_sos/ViewModel/Student/CommentTicketViewModel.dart';
import 'package:hcmu_sos/ViewModel/Student/HistoryViewModel.dart';
import 'package:hcmu_sos/ViewModel/Student/StudentHomeViewModel.dart';
import 'package:hcmu_sos/ViewModel/Student/StudentInfoViewModel.dart';
import 'package:hcmu_sos/ViewModel/Student/TicketDetailViewModel.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  FcmService.logRemoteMessage(message, source: 'background');
}

class FcmService {
  FcmService._();

  static final FcmService instance = FcmService._();

  String? _lastRegisteredToken;
  bool _isRegisteringToken = false;
  bool _initialized = false;

  static void logRemoteMessage(
    RemoteMessage message, {
    required String source,
  }) {
    final payload = <String, dynamic>{
      'source': source,
      'messageId': message.messageId,
      'messageType': message.messageType,
      'from': message.from,
      'category': message.category,
      'collapseKey': message.collapseKey,
      'threadId': message.threadId,
      'sentTime': message.sentTime?.toIso8601String(),
      'ttl': message.ttl,
      'notification': message.notification == null
          ? null
          : <String, dynamic>{
              'title': message.notification?.title,
              'body': message.notification?.body,
            },
      'data': message.data,
    };
    final encoded = const JsonEncoder.withIndent('  ').convert(payload);
    developer.log(encoded, name: 'FcmService');
    debugPrint('FCM[$source]');
    debugPrint(encoded);
  }

  Future<void> init() async {
    if (_initialized) {
      return;
    }

    await _ensureFirebaseInitialized();
    _initialized = true;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    try {
      await _requestPermission();
      await _configureForegroundPresentation();
      await registerCurrentToken();
      _listenTokenRefresh();
      _listenMessages();
      await _handleInitialMessage();
    } catch (error, stackTrace) {
      developer.log(
        'FCM setup failed',
        name: 'FcmService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _requestPermission() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    developer.log(
      'Notification permission: ${settings.authorizationStatus.name}',
      name: 'FcmService',
    );
  }

  Future<void> _configureForegroundPresentation() {
    return FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> registerCurrentToken({bool force = false}) async {
    try {
      await _ensureFirebaseInitialized();
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        return;
      }
      await _registerDeviceToken(token, force: force);
    } catch (error, stackTrace) {
      developer.log(
        'Could not register current FCM token',
        name: 'FcmService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _listenTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      developer.log('FCM token refreshed: $token', name: 'FcmService');
      _registerDeviceToken(token);
    });
  }

  Future<void> _registerDeviceToken(String token, {bool force = false}) async {
    if (_isRegisteringToken || (!force && _lastRegisteredToken == token)) {
      return;
    }

    final accessToken = await AuthSessionStorage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      developer.log(
        'Skip FCM token registration: no access token yet',
        name: 'FcmService',
      );
      return;
    }

    _isRegisteringToken = true;
    try {
      final response = await ApiCaller.getInstance().postBase<Object?>(
        'notifications/device-token',
        <String, dynamic>{'token': token},
      );
      if (!response.success) {
        throw ApiException(
          message: response.message ?? 'Could not register FCM token.',
          code: response.code,
          data: response.raw,
        );
      }
      _lastRegisteredToken = token;
      developer.log('FCM token registered', name: 'FcmService');
    } catch (error, stackTrace) {
      developer.log(
        'FCM token registration failed',
        name: 'FcmService',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _isRegisteringToken = false;
    }
  }

  void _listenMessages() {
    FirebaseMessaging.onMessage.listen((message) async {
      logRemoteMessage(message, source: 'foreground');
      await _refreshTargetsForForegroundMessage(message);
      _showUnreadNotificationBadgeOnDashboard();
      final notification = message.notification;
      if (notification != null) {
        Get.snackbar(
          notification.title ?? 'Thong bao',
          notification.body ?? '',
          snackPosition: SnackPosition.TOP,
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      logRemoteMessage(message, source: 'opened_app');
      _openNotificationTarget(message);
    });
  }

  Future<void> _handleInitialMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) {
      logRemoteMessage(message, source: 'initial_message');
      _openNotificationTarget(message);
    }
  }

  Future<void> _ensureFirebaseInitialized() async {
    if (Firebase.apps.isNotEmpty) {
      return;
    }
    await Firebase.initializeApp();
  }

  void _openNotificationTarget(RemoteMessage message) {
    if (Get.currentRoute != AppRoute.notifications) {
      Get.toNamed(AppRoute.notifications);
    }
  }

  Future<void> _refreshTargetsForForegroundMessage(
    RemoteMessage message,
  ) async {
    try {
      _refreshNotificationsIfVisible();

      final category = _normalizedCategory(message);
      switch (category) {
        case 'incident':
          await _refreshIncidentTargets(message);
        case 'chat':
          await _refreshChatTargets(message);
        case 'sos':
          await _refreshSosTargets(message);
        case 'account':
          await _refreshAccountTargets();
        default:
          break;
      }
    } catch (error, stackTrace) {
      developer.log(
        'FCM foreground refresh failed',
        name: 'FcmService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _refreshNotificationsIfVisible() {
    if (Get.currentRoute == AppRoute.notifications &&
        Get.isRegistered<NotifyViewModel>()) {
      Get.find<NotifyViewModel>().loadFirstPage();
    }
  }

  void _showUnreadNotificationBadgeOnDashboard() {
    if (Get.currentRoute == AppRoute.studentDashboard &&
        Get.isRegistered<StudentHomeViewModel>()) {
      Get.find<StudentHomeViewModel>().showUnreadNotificationBadge();
    }

    if (Get.currentRoute == AppRoute.staffDashboard &&
        Get.isRegistered<StaffHomeViewModel>()) {
      Get.find<StaffHomeViewModel>().showUnreadNotificationBadge();
    }
  }

  Future<void> _refreshIncidentTargets(RemoteMessage message) async {
    final refId =
        _payloadInt(message.data['ref_id']) ??
        _payloadInt(message.data['incident_id']) ??
        _payloadInt(message.data['id']);

    if (Get.currentRoute == AppRoute.studentDashboard) {
      if (Get.isRegistered<StudentHomeViewModel>()) {
        await Get.find<StudentHomeViewModel>().loadHome();
      }
      if (Get.isRegistered<HistoryViewModel>()) {
        await Get.find<HistoryViewModel>().loadRequests();
      }
    }

    if (Get.currentRoute == AppRoute.staffDashboard) {
      if (Get.isRegistered<StaffHomeViewModel>()) {
        await Get.find<StaffHomeViewModel>().loadHome();
      }
      if (Get.isRegistered<TaskViewModel>()) {
        await Get.find<TaskViewModel>().loadTasks();
      }
    }

    if (refId == null || refId <= 0) {
      return;
    }

    if (Get.currentRoute == AppRoute.ticketDetail &&
        Get.isRegistered<TicketDetailViewModel>()) {
      final controller = Get.find<TicketDetailViewModel>();
      if (controller.requestId == refId) {
        await controller.loadDetail();
      }
    }

    if (Get.currentRoute == AppRoute.staffTicketDetail &&
        Get.isRegistered<StaffTicketDetailViewModel>()) {
      final controller = Get.find<StaffTicketDetailViewModel>();
      if (controller.requestId == refId) {
        await controller.loadDetail();
      }
    }
  }

  Future<void> _refreshChatTargets(RemoteMessage message) async {
    final threadId =
        _payloadInt(message.data['ref_id']) ??
        _payloadInt(message.data['incident_id']) ??
        _payloadInt(message.data['thread_id']) ??
        _payloadInt(message.data['id']);
    final messageId = _payloadInt(message.data['message_id']);

    if (threadId == null || threadId <= 0) {
      return;
    }

    if (Get.currentRoute == AppRoute.commentTicket &&
        Get.isRegistered<CommentTicketViewModel>()) {
      final controller = Get.find<CommentTicketViewModel>();
      if (controller.threadId == threadId) {
        await controller.syncIncomingMessage(expectedMessageId: messageId);
      }
    }
  }

  Future<void> _refreshSosTargets(RemoteMessage message) async {
    final refId =
        _payloadInt(message.data['ref_id']) ??
        _payloadInt(message.data['incident_id']) ??
        _payloadInt(message.data['id']);

    if (Get.currentRoute == AppRoute.staffDashboard &&
        Get.isRegistered<StaffHomeViewModel>()) {
      await Get.find<StaffHomeViewModel>().loadHome();
    }

    if (Get.currentRoute == AppRoute.staffSosList &&
        Get.isRegistered<SOSListViewModel>()) {
      await Get.find<SOSListViewModel>().loadFirstPage();
    }

    if (refId == null || refId <= 0) {
      return;
    }

    if (Get.currentRoute == AppRoute.staffSosDetail &&
        Get.isRegistered<SOSDetailViewModel>()) {
      final controller = Get.find<SOSDetailViewModel>();
      if (controller.sos.value?.id == refId) {
        await controller.refreshDetail();
      }
    }
  }

  Future<void> _refreshAccountTargets() async {
    if (Get.isRegistered<MenuViewModel>()) {
      Get.find<MenuViewModel>().refreshCurrentUser();
    }

    if (Get.currentRoute == AppRoute.studentDashboard &&
        Get.isRegistered<StudentHomeViewModel>()) {
      await Get.find<StudentHomeViewModel>().loadHome();
    }

    if (Get.currentRoute == AppRoute.staffDashboard &&
        Get.isRegistered<StaffHomeViewModel>()) {
      await Get.find<StaffHomeViewModel>().loadHome();
    }

    if (Get.currentRoute == AppRoute.studentInfo &&
        Get.isRegistered<StudentInfoViewModel>()) {
      await Get.find<StudentInfoViewModel>().refreshProfile();
    }

    if (Get.currentRoute == AppRoute.staffInfo &&
        Get.isRegistered<StaffInfoViewModel>()) {
      await Get.find<StaffInfoViewModel>().refreshProfile();
    }
  }

  String _normalizedCategory(RemoteMessage message) {
    final category = (message.data['category'] ?? message.category ?? '')
        .toString()
        .trim()
        .toLowerCase();

    return switch (category) {
      'incident' || 'request' => 'incident',
      'chat' || 'message' => 'chat',
      'sos' => 'sos',
      'account' => 'account',
      _ => category,
    };
  }

  int? _payloadInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}
