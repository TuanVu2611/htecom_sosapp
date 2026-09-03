// ignore_for_file: file_names

import 'package:dio/dio.dart';
import 'package:hcmu_sos/Entity/AuthSessionEntity.dart';
import 'package:hcmu_sos/Entity/AuthUserEntity.dart';
import 'package:hcmu_sos/Entity/InstitutionEntity.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';
import 'package:hcmu_sos/Service/AuthSessionService.dart';

abstract class AuthRepository {
  Future<AuthSessionEntity> loginWithUsernamePassword({
    required String studentCode,
    required String password,
    required bool rememberLogin,
  });

  Future<AuthSessionEntity> loginWithSchoolSsoToken({required String ssoToken});

  Future<AuthSessionEntity> loginWithMicrosoft365Token({
    required String microsoft365Token,
  });

  Future<RegisterOtpRequestResult> registerStudent({
    required String fullName,
    required String phone,
    required String email,
    required String cccd,
    required String studentCode,
    required int schoolId,
    required int studentCardFrontFileId,
    required int studentCardBackFileId,
    int? nationalCardFrontId,
    int? nationalCardBackId,
    required String password,
    required String confirmPassword,
  });

  Future<void> verifyRegisterOtp({required int requestId, required String otp});

  Future<List<InstitutionEntity>> getInstitutions({bool forceRefresh = false});

  Future<PasswordResetOtpRequestResult> requestPasswordResetOtp({
    required String account,
  });

  Future<PasswordResetOtpVerifyResult> verifyPasswordResetOtp({
    required int requestId,
    required String otp,
  });

  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  });

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> deactivateAccount({required String password});
}

class PasswordResetOtpRequestResult {
  const PasswordResetOtpRequestResult({
    required this.requestId,
    required this.expiredIn,
    required this.maskedReceiver,
  });

  final int requestId;
  final int expiredIn;
  final String maskedReceiver;
}

class PasswordResetOtpVerifyResult {
  const PasswordResetOtpVerifyResult({
    required this.resetToken,
    required this.expiredIn,
  });

  final String resetToken;
  final int expiredIn;
}

class RegisterOtpRequestResult {
  const RegisterOtpRequestResult({
    required this.requestId,
    required this.expiredIn,
    required this.maskedReceiver,
  });

  final int requestId;
  final int expiredIn;
  final String maskedReceiver;
}

class MockAuthRepository implements AuthRepository {
  const MockAuthRepository();

  @override
  Future<AuthSessionEntity> loginWithUsernamePassword({
    required String studentCode,
    required String password,
    required bool rememberLogin,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));

    return AuthSessionEntity(
      accessToken: 'mock_student_access_token',
      refreshToken: 'mock_student_refresh_token',
      user: AuthUserEntity(
        id: 'student_mock_001',
        displayName: 'Mock Student',
        role: AuthUserRole.student,
        studentCode: studentCode.isEmpty ? 'SV000001' : studentCode,
      ),
    );
  }

  @override
  Future<AuthSessionEntity> loginWithSchoolSsoToken({
    required String ssoToken,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));

    return const AuthSessionEntity(
      accessToken: 'mock_school_sso_access_token',
      refreshToken: 'mock_school_sso_refresh_token',
      user: AuthUserEntity(
        id: 'student_sso_mock_001',
        displayName: 'Mock SSO Student',
        role: AuthUserRole.student,
        studentCode: 'SSO000001',
      ),
    );
  }

  @override
  Future<AuthSessionEntity> loginWithMicrosoft365Token({
    required String microsoft365Token,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));

    return const AuthSessionEntity(
      accessToken: 'mock_staff_access_token',
      refreshToken: 'mock_staff_refresh_token',
      user: AuthUserEntity(
        id: 'staff_mock_001',
        displayName: 'Mock Staff',
        role: AuthUserRole.staff,
        email: 'staff@hcmu.edu.vn',
      ),
    );
  }

  @override
  Future<RegisterOtpRequestResult> registerStudent({
    required String fullName,
    required String phone,
    required String email,
    required String cccd,
    required String studentCode,
    required int schoolId,
    required int studentCardFrontFileId,
    required int studentCardBackFileId,
    int? nationalCardFrontId,
    int? nationalCardBackId,
    required String password,
    required String confirmPassword,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 550));
    return RegisterOtpRequestResult(
      requestId: 1,
      expiredIn: 300,
      maskedReceiver: email,
    );
  }

  @override
  Future<void> verifyRegisterOtp({
    required int requestId,
    required String otp,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  @override
  Future<List<InstitutionEntity>> getInstitutions({
    bool forceRefresh = false,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return const <InstitutionEntity>[];
  }

  @override
  Future<PasswordResetOtpRequestResult> requestPasswordResetOtp({
    required String account,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return PasswordResetOtpRequestResult(
      requestId: 1,
      expiredIn: 300,
      maskedReceiver: account,
    );
  }

  @override
  Future<PasswordResetOtpVerifyResult> verifyPasswordResetOtp({
    required int requestId,
    required String otp,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return const PasswordResetOtpVerifyResult(
      resetToken: 'mock_reset_token',
      expiredIn: 600,
    );
  }

  @override
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
  }

  @override
  Future<void> deactivateAccount({required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
  }
}

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({ApiCaller? apiCaller, AuthRepository? fallbackRepository})
    : _apiCaller = apiCaller ?? ApiCaller.getInstance(),
      _fallbackRepository = fallbackRepository ?? const MockAuthRepository();

  final ApiCaller _apiCaller;
  final AuthRepository _fallbackRepository;
  List<InstitutionEntity>? _institutionsCache;

  @override
  Future<AuthSessionEntity> loginWithUsernamePassword({
    required String studentCode,
    required String password,
    required bool rememberLogin,
  }) async {
    final response = await _apiCaller.postBase<Object?>(
      'auth/login',
      <String, dynamic>{'login': studentCode, 'password': password},
      options: Options(extra: <String, dynamic>{'skipAuth': true}),
    );
    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Login failed.',
        code: response.code,
        data: response.raw,
      );
    }

    return AuthSessionService.sessionFromLoginData(
      _asStringKeyMap(response.data),
    );
  }

  @override
  Future<AuthSessionEntity> loginWithSchoolSsoToken({
    required String ssoToken,
  }) {
    return _fallbackRepository.loginWithSchoolSsoToken(ssoToken: ssoToken);
  }

  @override
  Future<AuthSessionEntity> loginWithMicrosoft365Token({
    required String microsoft365Token,
  }) async {
    final response = await _apiCaller.postBase<Object?>(
      'auth/m365/login',
      <String, dynamic>{'id_token': microsoft365Token},
      options: Options(extra: <String, dynamic>{'skipAuth': true}),
    );

    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Microsoft 365 login failed.',
        code: response.code,
        data: response.raw,
      );
    }

    return AuthSessionService.sessionFromLoginData(
      _asStringKeyMap(response.data),
    );
  }

  @override
  Future<RegisterOtpRequestResult> registerStudent({
    required String fullName,
    required String phone,
    required String email,
    required String cccd,
    required String studentCode,
    required int schoolId,
    required int studentCardFrontFileId,
    required int studentCardBackFileId,
    int? nationalCardFrontId,
    int? nationalCardBackId,
    required String password,
    required String confirmPassword,
  }) async {
    final payload = <String, dynamic>{
          'full_name': fullName,
          'phone': phone,
          'email': email,
          'cccd': cccd,
          'student_code': studentCode,
          'school_id': schoolId,
          'student_card_front_file_id': studentCardFrontFileId,
          'student_card_back_file_id': studentCardBackFileId,
          'password': password,
          'confirm_password': confirmPassword,
        };
    if (nationalCardFrontId != null) {
      payload['national_card_front_id'] = nationalCardFrontId;
    }
    if (nationalCardBackId != null) {
      payload['national_card_back_id'] = nationalCardBackId;
    }

    final response = await _apiCaller.postBase<Object?>(
      'auth/register',
      payload,
      options: Options(extra: <String, dynamic>{'skipAuth': true}),
    );

    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Register failed.',
        code: response.code,
        data: response.raw,
      );
    }

    final data = _asStringKeyMap(response.data);
    return RegisterOtpRequestResult(
      requestId: _asInt(data['request_id']),
      expiredIn: _asInt(data['expired_in']),
      maskedReceiver: _asString(data['masked_receiver']) ?? '',
    );
  }

  @override
  Future<void> verifyRegisterOtp({
    required int requestId,
    required String otp,
  }) async {
    final response = await _apiCaller.postBase<Object?>(
      'auth/register_verify_otp',
      <String, dynamic>{'request_id': requestId, 'otp': otp.trim()},
      options: Options(extra: <String, dynamic>{'skipAuth': true}),
    );
    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Could not verify register OTP.',
        code: response.code,
        data: response.raw,
      );
    }
  }

  @override
  Future<List<InstitutionEntity>> getInstitutions({
    bool forceRefresh = false,
  }) async {
    final cached = _institutionsCache;
    if (!forceRefresh && cached != null) {
      return cached;
    }

    final response = await _apiCaller.getBase<Object?>(
      'institutions',
      null,
      options: Options(extra: <String, dynamic>{'skipAuth': true}),
    );
    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Could not load institutions.',
        code: response.code,
        data: response.raw,
      );
    }

    final data = _asStringKeyMap(response.data);
    final rawItems = data['items'];
    final items = rawItems is List
        ? rawItems.map(InstitutionEntity.fromJson).toList()
        : <InstitutionEntity>[];
    _institutionsCache = items;
    return items;
  }

  @override
  Future<PasswordResetOtpRequestResult> requestPasswordResetOtp({
    required String account,
  }) async {
    final response = await _apiCaller.postBase<Object?>(
      'auth/forgot_password_send_otp',
      <String, dynamic>{'email_or_phone': account.trim()},
      options: Options(extra: <String, dynamic>{'skipAuth': true}),
    );
    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Could not send OTP.',
        code: response.code,
        data: response.raw,
      );
    }

    final data = _asStringKeyMap(response.data);
    return PasswordResetOtpRequestResult(
      requestId: _asInt(data['request_id']),
      expiredIn: _asInt(data['expired_in']),
      maskedReceiver: _asString(data['masked_receiver']) ?? '',
    );
  }

  @override
  Future<PasswordResetOtpVerifyResult> verifyPasswordResetOtp({
    required int requestId,
    required String otp,
  }) async {
    final response = await _apiCaller.postBase<Object?>(
      'auth/forgot_password_verify_otp',
      <String, dynamic>{'request_id': requestId, 'otp': otp.trim()},
      options: Options(extra: <String, dynamic>{'skipAuth': true}),
    );
    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Could not verify OTP.',
        code: response.code,
        data: response.raw,
      );
    }

    final data = _asStringKeyMap(response.data);
    return PasswordResetOtpVerifyResult(
      resetToken: _asString(data['reset_token']) ?? '',
      expiredIn: _asInt(data['expired_in']),
    );
  }

  @override
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await _apiCaller.postBase<Object?>(
      'auth/forgot_password_reset',
      <String, dynamic>{
        'reset_token': resetToken,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      },
      options: Options(extra: <String, dynamic>{'skipAuth': true}),
    );
    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Could not reset password.',
        code: response.code,
        data: response.raw,
      );
    }
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

  static String? _asString(Object? value) {
    if (value == null || value == false) {
      return null;
    }
    return value.toString();
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

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _apiCaller
        .postBase<Object?>('auth/change_password', <String, dynamic>{
          'old_password': currentPassword,
          'new_password': newPassword,
          'confirm_password': newPassword,
        });

    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Change password failed.',
        code: response.code,
        data: response.raw,
      );
    }
  }

  @override
  Future<void> deactivateAccount({required String password}) async {
    final response = await _apiCaller.postBase<Object?>(
      'auth/deactivate',
      <String, dynamic>{'password': password},
    );

    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Deactivate account failed.',
        code: response.code,
        data: response.raw,
      );
    }
  }
}
