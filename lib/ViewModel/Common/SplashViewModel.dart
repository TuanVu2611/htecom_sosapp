// ignore_for_file: file_names

import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/AuthUserEntity.dart';
import 'package:hcmu_sos/Navigator/AppRoute.dart';
import 'package:hcmu_sos/Service/AuthSessionService.dart';
import 'package:hcmu_sos/Service/StaffLocationUpdateService.dart';

class SplashViewModel extends GetxController {
  SplashViewModel({AuthSessionService? authSessionService})
    : _authSessionService = authSessionService ?? AuthSessionService();

  final AuthSessionService _authSessionService;

  @override
  void onReady() {
    super.onReady();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));

    final user = await _authSessionService.restoreSession();
    if (user == null) {
      Get.offAllNamed(AppRoute.login);
      return;
    }

    _openDashboard(user);
  }

  void _openDashboard(AuthUserEntity user) {
    StaffLocationUpdateService.instance.startIfStaff(user);
    switch (user.role) {
      case AuthUserRole.student:
        Get.offAllNamed(AppRoute.studentDashboard);
      case AuthUserRole.staff:
        Get.offAllNamed(AppRoute.staffDashboard);
    }
  }
}
