// ignore_for_file: file_names

import 'package:dio/dio.dart';
import 'package:hcmu_sos/Entity/AuthSessionEntity.dart';
import 'package:hcmu_sos/Entity/AuthUserEntity.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';
import 'package:hcmu_sos/Service/AuthSessionStorage.dart';
import 'package:hcmu_sos/Service/FcmService.dart';
import 'package:hcmu_sos/Utils/ApiAssetUrl.dart';

enum _RefreshTokenStatus { success, invalid, transientFailure }

class AuthSessionService {
  AuthSessionService({ApiCaller? apiCaller})
    : _apiCaller = apiCaller ?? ApiCaller.getInstance();

  final ApiCaller _apiCaller;

  Future<AuthUserEntity?> restoreSession() async {
    final accessToken = await AuthSessionStorage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    try {
      return await getCurrentUser();
    } on ApiException catch (error) {
      if (error.statusCode != 401) {
        return null;
      }
    } catch (_) {
      return null;
    }

    final refreshStatus = await _refreshTokenStatus();
    if (refreshStatus == _RefreshTokenStatus.invalid) {
      await AuthSessionStorage.clearSession();
      return null;
    }
    if (refreshStatus == _RefreshTokenStatus.transientFailure) {
      return null;
    }

    try {
      return await getCurrentUser();
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await AuthSessionStorage.clearSession();
        return null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> refreshToken() async {
    return (await _refreshTokenStatus()) == _RefreshTokenStatus.success;
  }

  Future<_RefreshTokenStatus> _refreshTokenStatus() async {
    final refreshToken = await AuthSessionStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return _RefreshTokenStatus.invalid;
    }

    try {
      final response = await _apiCaller.client.post<Object?>(
        'auth/token/refresh',
        data: <String, dynamic>{'refresh_token': refreshToken},
        options: Options(
          extra: <String, dynamic>{'skipAuth': true},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final statusCode = response.statusCode;
      if (statusCode == 401 ||
          statusCode == 403 ||
          statusCode == 400 ||
          statusCode == 422) {
        return _RefreshTokenStatus.invalid;
      }
      if (statusCode == null || statusCode < 200 || statusCode >= 300) {
        return _RefreshTokenStatus.transientFailure;
      }

      final envelope = _asStringKeyMap(response.data);
      if (envelope['success'] == false) {
        return _RefreshTokenStatus.invalid;
      }

      final data = _asStringKeyMap(envelope['data']);
      await AuthSessionStorage.saveTokens(
        accessToken: _requiredString(data, 'access_token'),
        refreshToken: _optionalString(data['refresh_token']) ?? refreshToken,
        expiresIn: _optionalInt(data['expires_in']),
        tokenType: _optionalString(data['token_type']),
      );
      await FcmService.instance.registerCurrentToken();
      return _RefreshTokenStatus.success;
    } on ApiException {
      return _RefreshTokenStatus.transientFailure;
    } catch (_) {
      return _RefreshTokenStatus.transientFailure;
    }
  }

  Future<AuthUserEntity> getCurrentUser() async {
    final response = await _apiCaller.getBase<Object?>(
      'user/get_profile',
      null,
    );
    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Could not restore session.',
        code: response.code,
        data: response.raw,
      );
    }

    final data = _asStringKeyMap(response.data);
    final user = data['user'] == null ? data : _asStringKeyMap(data['user']);
    final entity = _userFromMap(user);
    await AuthSessionStorage.saveUser(entity);
    return entity;
  }

  static AuthSessionEntity sessionFromLoginData(Map<String, dynamic> data) {
    final user = _asStringKeyMap(data['user']);
    return AuthSessionEntity(
      accessToken: _requiredString(data, 'access_token'),
      refreshToken: _requiredString(data, 'refresh_token'),
      expiresIn: _optionalInt(data['expires_in']),
      tokenType: _optionalString(data['token_type']),
      user: _userFromMap(user),
    );
  }

  static AuthUserEntity _userFromMap(Map<String, dynamic> user) {
    final school = _optionalMap(user['school']);
    final staffWork = _optionalMap(user['staff_work']);
    final settings = _optionalMap(user['settings']);
    final housingInfo = _optionalMap(user['housing_info']);
    return AuthUserEntity(
      id: _requiredString(user, 'id'),
      displayName:
          _optionalString(user['name']) ??
          _optionalString(user['full_name']) ??
          '',
      role: _roleFromApi(user['role']),
      availableRoles: _rolesFromApi(user['available_roles']),
      phone: _optionalString(user['phone']),
      studentCode:
          _optionalString(user['student_code']) ??
          _optionalString(user['student_card_number']),
      staffCode: _optionalString(user['staff_code']),
      email: _optionalString(user['email']),
      avatarUrl: ApiAssetUrl.resolve(_optionalString(user['avatar_url'])),
      schoolId:
          _optionalString(user['school_record_id']) ??
          _optionalString(school?['id']) ??
          _optionalString(user['school_id']),
      schoolName:
          _optionalString(user['school_name']) ??
          _optionalString(school?['name']) ??
          _optionalString(user['school_id']),
      displayCode: _optionalString(user['display_code']),
      cccd:
          _optionalString(user['cccd']) ??
          _optionalString(user['national_id']) ??
          _optionalString(user['id_card_number']),
      studentCardNumber: _optionalString(user['student_card_number']),
      major:
          _optionalString(user['major']) ??
          _optionalString(user['student_major']),
      roomBuilding:
          _optionalString(housingInfo?['room_building']) ??
          _optionalString(user['room_building']),
      ktxArea:
          _optionalString(housingInfo?['ktx_area']) ??
          _optionalString(user['ktx_area']),
      department:
          _optionalString(user['department']) ??
          _optionalString(staffWork?['department']),
      departmentName:
          _optionalString(user['department_name']) ??
          _optionalString(staffWork?['department_name']),
      ktxDepartmentName:
          _optionalString(user['ktx_department_name']) ??
          _optionalString(staffWork?['ktx_department_name']),
      staffActive:
          _optionalNullableBool(user['staff_active']) ??
          _optionalNullableBool(settings?['staff_active']) ??
          _optionalNullableBool(staffWork?['staff_active']),
      studentCard: _cardFromMap(_optionalMap(user['student_card'])),
      nationalCard: _cardFromMap(_optionalMap(user['national_card'])),
      staffWork: _staffWorkFromMap(staffWork),
      staffStatistics: _staffStatisticsFromMap(
        _optionalMap(user['staff_statistics']),
      ),
      settings: _settingsFromMap(settings),
      isVerified: user['is_verified'] == true,
      isBlocked: user['is_blocked'] == true,
    );
  }

  static AuthUserCardEntity? _cardFromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return null;
    }
    return AuthUserCardEntity(
      frontFileId: _optionalInt(data['front_file_id']),
      frontUrl: ApiAssetUrl.resolve(_optionalString(data['front_url'])),
      backFileId: _optionalInt(data['back_file_id']),
      backUrl: ApiAssetUrl.resolve(_optionalString(data['back_url'])),
    );
  }

  static AuthUserStaffWorkEntity? _staffWorkFromMap(
    Map<String, dynamic>? data,
  ) {
    if (data == null) {
      return null;
    }
    return AuthUserStaffWorkEntity(
      employeeCode: _optionalString(data['employee_code']),
      departmentName: _optionalString(data['department_name']),
      ktxDepartmentName: _optionalString(data['ktx_department_name']),
      department: _optionalString(data['department']),
      jobTitle: _optionalString(data['job_title']),
      employeeTypeLabel: _optionalString(data['employee_type_label']),
      statusLabel: _optionalString(data['status_label']),
      zone: _optionalString(data['zone']),
      rating: _optionalDouble(data['rating']),
      roleLabel: _optionalString(data['role_label']),
      staffActive: _optionalNullableBool(data['staff_active']),
    );
  }

  static AuthUserStaffStatisticsEntity? _staffStatisticsFromMap(
    Map<String, dynamic>? data,
  ) {
    if (data == null) {
      return null;
    }
    return AuthUserStaffStatisticsEntity(
      completed: _optionalInt(data['completed']) ?? 0,
      totalAssigned: _optionalInt(data['total_assigned']) ?? 0,
      completionRate: _optionalDouble(data['completion_rate']) ?? 0,
      performanceRate: _optionalDouble(data['performance_rate']) ?? 0,
      avgProcessingTimeMinutes:
          _optionalDouble(data['avg_processing_time_minutes']) ?? 0,
      ratingAvg: _optionalDouble(data['rating_avg']),
    );
  }

  static AuthUserSettingsEntity _settingsFromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return const AuthUserSettingsEntity();
    }
    return AuthUserSettingsEntity(
      pushEnabled: _optionalBool(data['push_enabled'], defaultValue: true),
      sosSoundEnabled: _optionalBool(
        data['sos_sound_enabled'],
        defaultValue: true,
      ),
      language: _optionalString(data['language']),
      darkMode: _optionalBool(data['dark_mode']),
      workTime: _optionalBool(data['work_time']),
      supportArea: _optionalBool(data['support_area']),
    );
  }

  static Map<String, dynamic> _asStringKeyMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    throw ApiException(
      message: 'Invalid auth response data.',
      code: 'decode_error',
      data: value,
    );
  }

  static String _requiredString(Map<String, dynamic> data, String key) {
    final value = _optionalString(data[key]);
    if (value == null || value.isEmpty) {
      throw ApiException(
        message: 'Missing auth response field: $key.',
        code: 'decode_error',
        data: data,
      );
    }
    return value;
  }

  static String? _optionalString(Object? value) {
    if (value == null || value == false) {
      return null;
    }
    return value.toString();
  }

  static Map<String, dynamic>? _optionalMap(Object? value) {
    if (value == null || value == false) {
      return null;
    }
    return _asStringKeyMap(value);
  }

  static int? _optionalInt(Object? value) {
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

  static double? _optionalDouble(Object? value) {
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

  static AuthUserRole _roleFromApi(Object? value) {
    final role = _optionalString(value)?.toLowerCase();
    if (role == 'staff') {
      return AuthUserRole.staff;
    }
    return AuthUserRole.student;
  }

  static List<AuthUserRole> _rolesFromApi(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value.map(_roleFromApi).toList();
  }

  static bool _optionalBool(Object? value, {bool defaultValue = false}) {
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

  static bool? _optionalNullableBool(Object? value) {
    if (value == null || value == false) {
      return value == false ? false : null;
    }
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
    return null;
  }
}
