// ignore_for_file: file_names

import 'package:hcmu_sos/Entity/AuthSessionEntity.dart';
import 'package:hcmu_sos/Entity/AuthUserEntity.dart';
import 'package:hcmu_sos/Utils/StorageManager.dart';

class AuthSessionStorage {
  AuthSessionStorage._();

  static const String _accessTokenKey = 'auth.access_token';
  static const String _refreshTokenKey = 'auth.refresh_token';
  static const String _expiresAtKey = 'auth.expires_at';
  static const String _tokenTypeKey = 'auth.token_type';
  static const String _rememberLoginKey = 'auth.remember_login';
  static const String _userKey = 'auth.user';

  static Future<void> saveSession(
    AuthSessionEntity session, {
    required bool rememberLogin,
  }) async {
    await StorageManager.setSecureString(_accessTokenKey, session.accessToken);
    await StorageManager.setSecureString(
      _refreshTokenKey,
      session.refreshToken,
    );
    if (session.expiresIn != null) {
      final expiresAt = DateTime.now()
          .add(Duration(seconds: session.expiresIn!))
          .millisecondsSinceEpoch;
      await StorageManager.setInt(_expiresAtKey, expiresAt);
    }
    if (session.tokenType != null) {
      await StorageManager.setString(_tokenTypeKey, session.tokenType!);
    }
    await StorageManager.setBool(_rememberLoginKey, rememberLogin);
    await saveUser(session.user);
  }

  static Future<void> saveUser(AuthUserEntity user) async {
    await StorageManager.setJson(_userKey, _userToJson(user));
  }

  static Future<void> updateUserSettings({
    bool? pushEnabled,
    bool? sosSoundEnabled,
    String? language,
    bool? darkMode,
    bool? workTime,
    bool? supportArea,
  }) async {
    final user = getUser();
    if (user == null) {
      return;
    }

    final settings = AuthUserSettingsEntity(
      pushEnabled: pushEnabled ?? user.settings.pushEnabled,
      sosSoundEnabled: sosSoundEnabled ?? user.settings.sosSoundEnabled,
      language: language ?? user.settings.language,
      darkMode: darkMode ?? user.settings.darkMode,
      workTime: workTime ?? user.settings.workTime,
      supportArea: supportArea ?? user.settings.supportArea,
    );

    await saveUser(user.copyWith(settings: settings));
  }

  static Future<String?> getAccessToken() {
    return StorageManager.getSecureString(_accessTokenKey);
  }

  static Future<String?> getRefreshToken() {
    return StorageManager.getSecureString(_refreshTokenKey);
  }

  static int? getExpiresAt() {
    return StorageManager.getInt(_expiresAtKey);
  }

  static String? getTokenType() {
    return StorageManager.getString(_tokenTypeKey);
  }

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    int? expiresIn,
    String? tokenType,
  }) async {
    await StorageManager.setSecureString(_accessTokenKey, accessToken);
    await StorageManager.setSecureString(_refreshTokenKey, refreshToken);
    if (expiresIn != null) {
      final expiresAt = DateTime.now()
          .add(Duration(seconds: expiresIn))
          .millisecondsSinceEpoch;
      await StorageManager.setInt(_expiresAtKey, expiresAt);
    }
    if (tokenType != null) {
      await StorageManager.setString(_tokenTypeKey, tokenType);
    }
  }

  static bool getRememberLogin() {
    return StorageManager.getBool(_rememberLoginKey, defaultValue: false) ??
        false;
  }

  static AuthUserEntity? getUser() {
    final data = StorageManager.getJson<Map<String, dynamic>>(
      _userKey,
      decoder: (json) {
        if (json is Map<String, dynamic>) {
          return json;
        }
        if (json is Map) {
          return json.map((key, value) => MapEntry(key.toString(), value));
        }
        return <String, dynamic>{};
      },
    );
    if (data == null || data.isEmpty) {
      return null;
    }

    final role = data['role']?.toString();
    return AuthUserEntity(
      id: data['id']?.toString() ?? '',
      displayName: data['displayName']?.toString() ?? '',
      role: role == AuthUserRole.staff.name
          ? AuthUserRole.staff
          : AuthUserRole.student,
      availableRoles: _rolesFromJson(data['availableRoles']),
      phone: data['phone']?.toString(),
      studentCode: data['studentCode']?.toString(),
      staffCode: data['staffCode']?.toString(),
      email: data['email']?.toString(),
      avatarUrl: data['avatarUrl']?.toString(),
      schoolId: data['schoolId']?.toString(),
      schoolName: data['schoolName']?.toString(),
      displayCode: data['displayCode']?.toString(),
      cccd: data['cccd']?.toString(),
      studentCardNumber: data['studentCardNumber']?.toString(),
      major: data['major']?.toString(),
      roomBuilding: data['roomBuilding']?.toString(),
      ktxArea: data['ktxArea']?.toString(),
      department: data['department']?.toString(),
      departmentName: data['departmentName']?.toString(),
      ktxDepartmentName: data['ktxDepartmentName']?.toString(),
      staffActive: data['staffActive'] is bool
          ? data['staffActive'] as bool
          : null,
      studentCard: _cardFromJson(data['studentCard']),
      nationalCard: _cardFromJson(data['nationalCard']),
      staffWork: _staffWorkFromJson(data['staffWork']),
      staffStatistics: _staffStatisticsFromJson(data['staffStatistics']),
      settings: _settingsFromJson(data['settings']),
      isVerified: data['isVerified'] == true,
      isBlocked: data['isBlocked'] == true,
    );
  }

  static Map<String, dynamic> _userToJson(AuthUserEntity user) {
    return <String, dynamic>{
      'id': user.id,
      'displayName': user.displayName,
      'role': user.role.name,
      'availableRoles': user.availableRoles.map((role) => role.name).toList(),
      'phone': user.phone,
      'studentCode': user.studentCode,
      'staffCode': user.staffCode,
      'email': user.email,
      'avatarUrl': user.avatarUrl,
      'schoolId': user.schoolId,
      'schoolName': user.schoolName,
      'displayCode': user.displayCode,
      'cccd': user.cccd,
      'studentCardNumber': user.studentCardNumber,
      'major': user.major,
      'roomBuilding': user.roomBuilding,
      'ktxArea': user.ktxArea,
      'department': user.department,
      'departmentName': user.departmentName,
      'ktxDepartmentName': user.ktxDepartmentName,
      'staffActive': user.staffActive,
      'studentCard': _cardToJson(user.studentCard),
      'nationalCard': _cardToJson(user.nationalCard),
      'staffWork': _staffWorkToJson(user.staffWork),
      'staffStatistics': _staffStatisticsToJson(user.staffStatistics),
      'settings': <String, dynamic>{
        'pushEnabled': user.settings.pushEnabled,
        'sosSoundEnabled': user.settings.sosSoundEnabled,
        'language': user.settings.language,
        'darkMode': user.settings.darkMode,
        'workTime': user.settings.workTime,
        'supportArea': user.settings.supportArea,
      },
      'isVerified': user.isVerified,
      'isBlocked': user.isBlocked,
    };
  }

  static AuthUserCardEntity? _cardFromJson(Object? value) {
    if (value is! Map) {
      return null;
    }
    final data = value.map((key, value) => MapEntry(key.toString(), value));
    return AuthUserCardEntity(
      frontFileId: _asInt(data['frontFileId']),
      frontUrl: data['frontUrl']?.toString(),
      backFileId: _asInt(data['backFileId']),
      backUrl: data['backUrl']?.toString(),
    );
  }

  static Map<String, dynamic>? _cardToJson(AuthUserCardEntity? value) {
    if (value == null) {
      return null;
    }
    return <String, dynamic>{
      'frontFileId': value.frontFileId,
      'frontUrl': value.frontUrl,
      'backFileId': value.backFileId,
      'backUrl': value.backUrl,
    };
  }

  static AuthUserStaffWorkEntity? _staffWorkFromJson(Object? value) {
    if (value is! Map) {
      return null;
    }
    final data = value.map((key, value) => MapEntry(key.toString(), value));
    return AuthUserStaffWorkEntity(
      employeeCode: data['employeeCode']?.toString(),
      departmentName: data['departmentName']?.toString(),
      ktxDepartmentName: data['ktxDepartmentName']?.toString(),
      department: data['department']?.toString(),
      jobTitle: data['jobTitle']?.toString(),
      employeeTypeLabel: data['employeeTypeLabel']?.toString(),
      statusLabel: data['statusLabel']?.toString(),
      zone: data['zone']?.toString(),
      rating: _asDouble(data['rating']),
      roleLabel: data['roleLabel']?.toString(),
      staffActive: data['staffActive'] is bool
          ? data['staffActive'] as bool
          : null,
    );
  }

  static Map<String, dynamic>? _staffWorkToJson(
    AuthUserStaffWorkEntity? value,
  ) {
    if (value == null) {
      return null;
    }
    return <String, dynamic>{
      'employeeCode': value.employeeCode,
      'departmentName': value.departmentName,
      'ktxDepartmentName': value.ktxDepartmentName,
      'department': value.department,
      'jobTitle': value.jobTitle,
      'employeeTypeLabel': value.employeeTypeLabel,
      'statusLabel': value.statusLabel,
      'zone': value.zone,
      'rating': value.rating,
      'roleLabel': value.roleLabel,
      'staffActive': value.staffActive,
    };
  }

  static AuthUserStaffStatisticsEntity? _staffStatisticsFromJson(
    Object? value,
  ) {
    if (value is! Map) {
      return null;
    }
    final data = value.map((key, value) => MapEntry(key.toString(), value));
    return AuthUserStaffStatisticsEntity(
      completed: _asInt(data['completed']) ?? 0,
      totalAssigned: _asInt(data['totalAssigned']) ?? 0,
      completionRate: _asDouble(data['completionRate']) ?? 0,
      performanceRate: _asDouble(data['performanceRate']) ?? 0,
      avgProcessingTimeMinutes:
          _asDouble(data['avgProcessingTimeMinutes']) ?? 0,
      ratingAvg: _asDouble(data['ratingAvg']),
    );
  }

  static Map<String, dynamic>? _staffStatisticsToJson(
    AuthUserStaffStatisticsEntity? value,
  ) {
    if (value == null) {
      return null;
    }
    return <String, dynamic>{
      'completed': value.completed,
      'totalAssigned': value.totalAssigned,
      'completionRate': value.completionRate,
      'performanceRate': value.performanceRate,
      'avgProcessingTimeMinutes': value.avgProcessingTimeMinutes,
      'ratingAvg': value.ratingAvg,
    };
  }

  static AuthUserSettingsEntity _settingsFromJson(Object? value) {
    if (value is! Map) {
      return const AuthUserSettingsEntity();
    }
    final data = value.map((key, value) => MapEntry(key.toString(), value));
    return AuthUserSettingsEntity(
      pushEnabled: _asBool(data['pushEnabled'], defaultValue: true),
      sosSoundEnabled: _asBool(data['sosSoundEnabled'], defaultValue: true),
      language: data['language']?.toString(),
      darkMode: _asBool(data['darkMode']),
      workTime: _asBool(data['workTime']),
      supportArea: _asBool(data['supportArea']),
    );
  }

  static List<AuthUserRole> _rolesFromJson(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value
        .map((role) => role?.toString())
        .whereType<String>()
        .map(
          (role) => role == AuthUserRole.staff.name
              ? AuthUserRole.staff
              : AuthUserRole.student,
        )
        .toList();
  }

  static int? _asInt(Object? value) {
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

  static double? _asDouble(Object? value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static bool _asBool(Object? value, {bool defaultValue = false}) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true' || normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == '0') {
        return false;
      }
    }
    return defaultValue;
  }

  static Future<void> clearSession() async {
    await StorageManager.removeSecure(_accessTokenKey);
    await StorageManager.removeSecure(_refreshTokenKey);
    await StorageManager.remove(_expiresAtKey);
    await StorageManager.remove(_tokenTypeKey);
    await StorageManager.remove(_rememberLoginKey);
    await StorageManager.remove(_userKey);
  }
}
