// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/AuthUserEntity.dart';
import 'package:hcmu_sos/Entity/StaffPerformanceEntity.dart';
import 'package:hcmu_sos/Localization/LocaleManager.dart';
import 'package:hcmu_sos/Navigator/AppRoute.dart';
import 'package:hcmu_sos/Repository/AuthRepository.dart';
import 'package:hcmu_sos/Repository/StaffPerformanceRepository.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';
import 'package:hcmu_sos/Service/AuthSessionStorage.dart';
import 'package:hcmu_sos/Service/StaffLocationUpdateService.dart';
import 'package:hcmu_sos/Utils/Utils.dart';

class MenuViewModel extends GetxController {
  MenuViewModel({
    StaffPerformanceRepository? performanceRepository,
    AuthRepository? authRepository,
  }) : _performanceRepository =
           performanceRepository ?? StaffPerformanceRepository(),
       _authRepository = authRepository ?? ApiAuthRepository();

  final StaffPerformanceRepository _performanceRepository;
  final AuthRepository _authRepository;

  final pushNotificationsEnabled = true.obs;
  final nearbySosAlertsEnabled = true.obs;
  final profileUser = Rxn<AuthUserEntity>();
  final staffPerformance = StaffPerformanceEntity.empty.obs;
  final isLoadingPerformance = false.obs;
  final isDeactivatingAccount = false.obs;
  final performanceErrorMessage = RxnString();

  AuthUserEntity? get currentUser =>
      profileUser.value ?? AuthSessionStorage.getUser();

  bool get isStaff => currentUser?.role == AuthUserRole.staff;
  bool get isStudent => currentUser?.role == AuthUserRole.student;
  bool get canDeactivateAccount => isStudent && GetPlatform.isIOS;

  List<Locale> get supportedLocales => LocaleManager.supportedLocales;

  String get languageLabel {
    return languageLabelFor(Get.locale ?? LocaleManager.fallbackLocale);
  }

  String languageLabelFor(Locale locale) {
    if (locale.languageCode == LocaleManager.english.languageCode) {
      return 'English';
    }
    return 'Tiếng Việt';
  }

  bool isCurrentLocale(Locale locale) {
    final current = Get.locale ?? LocaleManager.fallbackLocale;
    return current.languageCode == locale.languageCode &&
        current.countryCode == locale.countryCode;
  }

  @override
  void onInit() {
    super.onInit();
    refreshCurrentUser();
    _syncSettingsFromProfile();
    loadStaffPerformanceIfNeeded();
  }

  void refreshCurrentUser() {
    profileUser.value = AuthSessionStorage.getUser();
  }

  Future<void> loadStaffPerformanceIfNeeded() async {
    if (!isStaff || isLoadingPerformance.value) {
      return;
    }

    isLoadingPerformance.value = true;
    performanceErrorMessage.value = null;
    try {
      final now = DateTime.now();
      final fromDate = DateTime(now.year, now.month);
      final toDate = DateTime(now.year, now.month + 1, 0);
      staffPerformance.value = await _performanceRepository.getPerformance(
        fromDate: fromDate,
        toDate: toDate,
        period: 'month',
      );
    } on ApiException catch (error) {
      performanceErrorMessage.value = error.message;
    } catch (_) {
      performanceErrorMessage.value = 'Không thể tải thống kê hiệu suất.';
    } finally {
      isLoadingPerformance.value = false;
    }
  }

  Future<void> togglePushNotifications(bool value) async {
    final previous = pushNotificationsEnabled.value;
    pushNotificationsEnabled.value = value;
    await AuthSessionStorage.updateUserSettings(pushEnabled: value);
    final success = await _updateSettingsOnServer(pushEnabled: value);
    if (!success) {
      pushNotificationsEnabled.value = previous;
      await AuthSessionStorage.updateUserSettings(pushEnabled: previous);
    }
  }

  Future<void> toggleNearbySosAlerts(bool value) async {
    final previous = nearbySosAlertsEnabled.value;
    nearbySosAlertsEnabled.value = value;
    await AuthSessionStorage.updateUserSettings(sosSoundEnabled: value);
    final success = await _updateSettingsOnServer(sosSoundEnabled: value);
    if (!success) {
      nearbySosAlertsEnabled.value = previous;
      await AuthSessionStorage.updateUserSettings(sosSoundEnabled: previous);
    }
  }

  Future<void> changeLanguage(Locale locale) async {
    await LocaleManager.changeLocale(locale);
    await AuthSessionStorage.updateUserSettings(language: locale.languageCode);
    await _updateSettingsOnServer(language: locale.languageCode);
    update();
  }

  Future<void> logout() async {
    await _notifyLogoutOnServer();
    await _clearLocalSessionAndNavigate();
  }

  Future<bool> deactivateAccount({required String password}) async {
    if (!canDeactivateAccount || isDeactivatingAccount.value) {
      return false;
    }

    final normalizedPassword = password.trim();
    if (normalizedPassword.isEmpty) {
      Utils.showSnackbar(
        title: 'auth.deactivateAccount'.tr,
        content: 'auth.deactivateAccountPasswordRequired'.tr,
      );
      return false;
    }

    isDeactivatingAccount.value = true;
    try {
      await _authRepository.deactivateAccount(password: normalizedPassword);
      await _clearLocalSessionAndNavigate();
      Future<void>.delayed(const Duration(milliseconds: 120), () {
        Utils.showSnackbar(
          title: 'auth.deactivateAccount'.tr,
          content: 'auth.deactivateAccountSuccess'.tr,
        );
      });
      return true;
    } on ApiException catch (error) {
      Utils.showSnackbar(
        title: 'auth.deactivateAccount'.tr,
        content: error.message,
      );
      return false;
    } catch (_) {
      Utils.showSnackbar(
        title: 'auth.deactivateAccount'.tr,
        content: 'auth.deactivateAccountFailed'.tr,
      );
      return false;
    } finally {
      isDeactivatingAccount.value = false;
    }
  }

  Future<void> openAccountInfo() async {
    await Get.toNamed(isStaff ? AppRoute.staffInfo : AppRoute.studentInfo);
    refreshCurrentUser();
  }

  Future<void> openStaffPerformance() async {
    await loadStaffPerformanceIfNeeded();
    await Get.toNamed(
      AppRoute.staffPerformance,
      arguments: staffPerformance.value,
    );
  }

  Future<void> openTermsOfUse(String title) async {
    await Get.toNamed(
      AppRoute.htmlDocument,
      arguments: <String, String>{
        'title': title,
        'endpoint': 'legal/get_terms',
      },
    );
  }

  Future<void> openGuidelinesOfUse(String title) async {
    await Get.toNamed(
      AppRoute.htmlDocument,
      arguments: <String, String>{'title': title, 'endpoint': 'instruction'},
    );
  }

  void unavailable(String title) {
    Utils.showSnackbar(
      title: title,
      content: 'Tính năng này sẽ được bổ sung sau.',
    );
  }

  void _syncSettingsFromProfile() {
    final settings = currentUser?.settings;
    if (settings == null) {
      return;
    }

    pushNotificationsEnabled.value = settings.pushEnabled;
    nearbySosAlertsEnabled.value = settings.sosSoundEnabled;

    if (LocaleManager.hasSavedLocale) {
      return;
    }

    final locale = _localeFromLanguage(settings.language);
    if (locale != null && !isCurrentLocale(locale)) {
      LocaleManager.applyLocale(locale);
      update();
    }
  }

  Future<bool> _updateSettingsOnServer({
    bool? pushEnabled,
    bool? sosSoundEnabled,
    String? language,
  }) async {
    final settings = currentUser?.settings;
    try {
      final response = await ApiCaller.getInstance()
          .postBase<Object?>('user/update_settings', <String, dynamic>{
            'push_enabled': pushEnabled ?? settings?.pushEnabled,
            'sos_sound_enabled': sosSoundEnabled ?? settings?.sosSoundEnabled,
            'language': language ?? settings?.language,
          });

      if (!response.success) {
        throw ApiException(
          message: response.message ?? 'Request failed.',
          code: response.code,
          data: response.raw,
        );
      }
      return true;
    } on ApiException catch (error) {
      Utils.showSnackbar(title: 'page.menu'.tr, content: error.message);
      return false;
    } catch (_) {
      Utils.showSnackbar(title: 'page.menu'.tr, content: 'Request failed.');
      return false;
    }
  }

  Future<void> _notifyLogoutOnServer() async {
    try {
      final refreshToken = await AuthSessionStorage.getRefreshToken();
      final response = await ApiCaller.getInstance().postBase<Object?>(
        'auth/logout',
        <String, dynamic>{'refresh_token': refreshToken},
      );

      if (!response.success) {
        throw ApiException(
          message: response.message ?? 'Logout request failed.',
          code: response.code,
          data: response.raw,
        );
      }
    } catch (_) {
      // Always continue with local logout even if the server request fails.
    }
  }

  Future<void> _clearLocalSessionAndNavigate() async {
    StaffLocationUpdateService.instance.stop();
    await AuthSessionStorage.clearSession();
    Get.offAllNamed(AppRoute.login);
  }

  Locale? _localeFromLanguage(String? language) {
    switch (language?.toLowerCase()) {
      case 'vi':
      case 'vi_vn':
        return LocaleManager.vietnamese;
      case 'en':
      case 'en_us':
        return LocaleManager.english;
      default:
        return null;
    }
  }
}
