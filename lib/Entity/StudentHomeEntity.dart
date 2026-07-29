// ignore_for_file: file_names

import 'package:hcmu_sos/Entity/AuthUserEntity.dart';
import 'package:hcmu_sos/Entity/SupportRequestEntity.dart';
import 'package:hcmu_sos/Utils/ApiAssetUrl.dart';

class StudentHomeEntity {
  const StudentHomeEntity({
    required this.user,
    required this.summary,
    required this.latestRequests,
    required this.unreadNotificationCount,
    this.sos,
  });

  final AuthUserEntity? user;
  final StudentHomeSummaryEntity summary;
  final List<SupportRequestEntity> latestRequests;
  final int unreadNotificationCount;
  final Object? sos;

  factory StudentHomeEntity.fromJson(Object? json) {
    final data = _asMap(json);
    final rawRequests = data['latest_requests'];
    return StudentHomeEntity(
      user: _userFromJson(data['user']),
      summary: StudentHomeSummaryEntity.fromJson(data['summary']),
      latestRequests: rawRequests is List
          ? rawRequests.map(SupportRequestEntity.fromJson).toList()
          : <SupportRequestEntity>[],
      unreadNotificationCount: _asInt(data['unread_notification_count']),
      sos: data['sos'],
    );
  }

  static AuthUserEntity? _userFromJson(Object? json) {
    if (json == null || json == false) {
      return null;
    }
    final data = _asMap(json);
    return AuthUserEntity(
      id: _asString(data['id']) ?? '',
      displayName: _asString(data['name']) ?? '',
      role: AuthUserRole.student,
      studentCode: _asString(data['student_code']),
      email: _asString(data['email']),
      avatarUrl: ApiAssetUrl.resolve(_asString(data['avatar_url'])),
    );
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

  static String? _asString(Object? value) {
    if (value == null || value == false) {
      return null;
    }
    return value.toString();
  }
}

class StudentHomeSummaryEntity {
  const StudentHomeSummaryEntity({
    required this.pending,
    required this.processing,
    required this.completed,
    required this.cancelled,
  });

  final int pending;
  final int processing;
  final int completed;
  final int cancelled;

  factory StudentHomeSummaryEntity.fromJson(Object? json) {
    final data = StudentHomeEntity._asMap(json);
    return StudentHomeSummaryEntity(
      pending: StudentHomeEntity._asInt(data['pending']),
      processing: StudentHomeEntity._asInt(data['in_progress']),
      completed: StudentHomeEntity._asInt(data['done']),
      cancelled: StudentHomeEntity._asInt(data['rejected']),
    );
  }

  static const empty = StudentHomeSummaryEntity(
    pending: 0,
    processing: 0,
    completed: 0,
    cancelled: 0,
  );
}
