// ignore_for_file: file_names

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/AuthSessionEntity.dart';
import 'package:hcmu_sos/Entity/AuthUserEntity.dart';
import 'package:hcmu_sos/Navigator/AppRoute.dart';
import 'package:hcmu_sos/Repository/AuthRepository.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';
import 'package:hcmu_sos/Service/AuthSessionService.dart';
import 'package:hcmu_sos/Service/AuthSessionStorage.dart';
import 'package:hcmu_sos/Service/FcmService.dart';
import 'package:hcmu_sos/Service/Microsoft365AuthService.dart';
import 'package:hcmu_sos/Service/StaffLocationUpdateService.dart';
import 'package:hcmu_sos/Service/StudentSosTrackingService.dart';
import 'package:hcmu_sos/Utils/Utils.dart';

class LoginViewModel extends GetxController {
  LoginViewModel({
    required this.authRepository,
    Microsoft365AuthService? microsoft365AuthService,
  }) : microsoft365AuthService =
           microsoft365AuthService ?? Microsoft365AuthService();

  final AuthRepository authRepository;
  final Microsoft365AuthService microsoft365AuthService;
  final studentCodeController = TextEditingController();
  final passwordController = TextEditingController();

  final rememberLogin = true.obs;
  final obscurePassword = true.obs;
  final isLoggingIn = false.obs;

  void toggleRememberLogin() {
    rememberLogin.toggle();
  }

  void togglePasswordVisibility() {
    obscurePassword.toggle();
  }

  Future<void> loginWithUsernamePassword() async {
    if (isLoggingIn.value) {
      return;
    }

    isLoggingIn.value = true;
    try {
      final session = await authRepository.loginWithUsernamePassword(
        studentCode: studentCodeController.text.trim(),
        password: passwordController.text,
        rememberLogin: rememberLogin.value,
      );
      await _saveSessionWithRecovery(
        session,
        rememberLogin: rememberLogin.value,
      );
      unawaited(FcmService.instance.registerCurrentToken(force: true));
      final profileUser = await _loadProfileAfterLogin() ?? session.user;
      _openDashboard(profileUser);
    } on ApiException catch (error) {
      Utils.showSnackbar(title: 'auth.login'.tr, content: error.message);
    } catch (error, stackTrace) {
      developer.log(
        'Login failed after auth request',
        name: 'LoginViewModel',
        error: error,
        stackTrace: stackTrace,
      );
      Utils.showSnackbar(
        title: 'auth.login'.tr,
        content: _unexpectedLoginMessage(error),
      );
    } finally {
      isLoggingIn.value = false;
    }
  }

  Future<void> loginWithSchoolSso() async {
    if (isLoggingIn.value) {
      return;
    }

    isLoggingIn.value = true;
    try {
      final ssoToken = await _getSchoolSsoToken();
      final session = await authRepository.loginWithSchoolSsoToken(
        ssoToken: ssoToken,
      );
      _openDashboard(session.user);
    } finally {
      isLoggingIn.value = false;
    }
  }

  void forgotPassword() {
    Get.toNamed(AppRoute.forgotPassword);
  }

  Future<void> loginWithMicrosoft365() async {
    if (isLoggingIn.value) {
      return;
    }

    isLoggingIn.value = true;
    try {
      final microsoft365Token = await _getMicrosoft365Token();

      final session = await authRepository.loginWithMicrosoft365Token(
        microsoft365Token: microsoft365Token,
      );
      printLongText('Microsoft 365 Token: ' + session.accessToken);
      await _saveSessionWithRecovery(session, rememberLogin: true);
      unawaited(FcmService.instance.registerCurrentToken(force: true));
      final profileUser = await _loadProfileAfterLogin() ?? session.user;
      _openDashboard(profileUser);
    } on Microsoft365AuthConfigurationException {
      Utils.showSnackbar(
        title: 'auth.staffLoginWith'.tr,
        content: 'auth.m365ConfigMissing'.tr,
      );
    } on Microsoft365AuthTokenException {
      Utils.showSnackbar(
        title: 'auth.staffLoginWith'.tr,
        content: 'auth.m365TokenMissing'.tr,
      );
    } on FlutterAppAuthUserCancelledException {
      // User closed the Microsoft sign-in screen.
    } on ApiException catch (error) {
      Utils.showSnackbar(
        title: 'auth.staffLoginWith'.tr,
        content: error.message,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Microsoft 365 login failed after auth request',
        name: 'LoginViewModel',
        error: error,
        stackTrace: stackTrace,
      );
      Utils.showSnackbar(
        title: 'auth.staffLoginWith'.tr,
        content: _unexpectedLoginMessage(error),
      );
    } finally {
      isLoggingIn.value = false;
    }
  }

  void register() {
    Get.toNamed(AppRoute.register);
  }

  void _openDashboard(AuthUserEntity user) {
    StaffLocationUpdateService.instance.startIfStaff(user);
    unawaited(StudentSosTrackingService.instance.startIfStudent(user));
    switch (user.role) {
      case AuthUserRole.student:
        Get.offAllNamed(AppRoute.studentDashboard);
      case AuthUserRole.staff:
        Get.offAllNamed(AppRoute.staffDashboard);
    }
  }

  Future<AuthUserEntity?> _loadProfileAfterLogin() async {
    try {
      return await AuthSessionService().getCurrentUser();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveSessionWithRecovery(
    AuthSessionEntity session, {
    required bool rememberLogin,
  }) async {
    try {
      await AuthSessionStorage.saveSession(
        session,
        rememberLogin: rememberLogin,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Could not save auth session. Retrying after clearing storage.',
        name: 'LoginViewModel',
        error: error,
        stackTrace: stackTrace,
      );
      await AuthSessionStorage.clearSession();
      await AuthSessionStorage.saveSession(
        session,
        rememberLogin: rememberLogin,
      );
    }
  }

  String _unexpectedLoginMessage(Object error) {
    final message = error.toString();
    if (message.trim().isEmpty) {
      return 'auth.loginFailed'.tr;
    }
    return message;
  }

  Future<String> _getSchoolSsoToken() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return 'mock_school_sso_token';
  }

  Future<String> _getMicrosoft365Token() async {
    return microsoft365AuthService.signInAndGetAccessToken();
  }

  void printLongText(String text) {
    const int chunkSize = 800;

    for (int i = 0; i < text.length; i += chunkSize) {
      int end = (i + chunkSize < text.length) ? i + chunkSize : text.length;

      print(text.substring(i, end));
    }
  }

  @override
  void onClose() {
    studentCodeController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
