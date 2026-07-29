// ignore_for_file: file_names

import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/AuthUserEntity.dart';
import 'package:hcmu_sos/Entity/StaffHomeEntity.dart';
import 'package:hcmu_sos/Entity/SupportRequestEntity.dart';
import 'package:hcmu_sos/Repository/StaffHomeRepository.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';
import 'package:hcmu_sos/Service/AuthSessionService.dart';
import 'package:hcmu_sos/Service/AuthSessionStorage.dart';
import 'package:hcmu_sos/Utils/Utils.dart';

class StaffHomeViewModel extends GetxController {
  StaffHomeViewModel({StaffHomeRepository? homeRepository})
    : _homeRepository = homeRepository ?? StaffHomeRepository();

  final StaffHomeRepository _homeRepository;

  final isLoading = false.obs;
  final errorMessage = RxnString();
  final profile = Rxn<AuthUserEntity>();
  final summary = StaffHomeSummaryEntity.empty.obs;
  final activeSos = <StaffActiveSosEntity>[].obs;
  final tasks = <SupportRequestEntity>[].obs;
  final unreadMessageCount = 0.obs;
  final isAvailable = true.obs;
  final isUpdatingAvailability = false.obs;

  AuthUserEntity? get currentUser {
    final reactiveUser = profile.value;
    return AuthSessionStorage.getUser() ?? reactiveUser;
  }

  int get pendingCount => summary.value.pending;

  int get processingCount => summary.value.processing;

  int get completedCount => summary.value.completed;

  int get activeSosCount => activeSos.length;

  @override
  void onReady() {
    super.onReady();
    refreshCurrentUser();
    loadHome();
  }

  void refreshCurrentUser() {
    final user = AuthSessionStorage.getUser();
    profile.value = user;
    final staffActive = user?.staffActive ?? user?.staffWork?.staffActive;
    if (staffActive != null) {
      isAvailable.value = staffActive;
    }
  }

  void showUnreadNotificationBadge() {
    if (unreadMessageCount.value <= 0) {
      unreadMessageCount.value = 1;
    }
  }

  void updateUnreadNotificationCount(int count) {
    unreadMessageCount.value = count < 0 ? 0 : count;
  }

  Future<void> loadHome() async {
    if (isLoading.value) {
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;
    try {
      await _refreshProfileFromServer();
      final home = await _homeRepository.getHome();
      profile.value = _mergeProfile(home.profile);
      summary.value = home.summary;
      activeSos.assignAll(home.activeSos);
      tasks.assignAll(home.tasks);
      unreadMessageCount.value = home.unreadMessageCount;
      isAvailable.value = _availabilityFromCurrentProfile() ?? home.isAvailable;
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      Utils.showSnackbar(title: 'page.staffHome'.tr, content: error.message);
    } catch (_) {
      const message = 'Không thể tải dữ liệu dashboard.';
      errorMessage.value = message;
      Utils.showSnackbar(title: 'page.staffHome'.tr, content: message);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateAvailability(bool value) async {
    if (isUpdatingAvailability.value || isAvailable.value == value) {
      return;
    }

    final previousValue = isAvailable.value;
    isUpdatingAvailability.value = true;
    try {
      await _homeRepository.updateAvailability(isActive: value);
      isAvailable.value = value;
      await _syncAvailabilityProfile(value);
      Utils.showSnackbar(
        title: 'page.staffHome'.tr,
        content: value
            ? 'Đã bật trạng thái làm việc.'
            : 'Đã tắt trạng thái làm việc.',
      );
    } on ApiException catch (error) {
      isAvailable.value = previousValue;
      Utils.showSnackbar(title: 'page.staffHome'.tr, content: error.message);
    } catch (_) {
      isAvailable.value = previousValue;
      Utils.showSnackbar(
        title: 'page.staffHome'.tr,
        content: 'Không thể cập nhật trạng thái làm việc.',
      );
    } finally {
      isUpdatingAvailability.value = false;
    }
  }

  Future<void> _refreshProfileFromServer() async {
    try {
      final refreshedUser = await AuthSessionService().getCurrentUser();
      profile.value = refreshedUser;
      final staffActive =
          refreshedUser.staffActive ?? refreshedUser.staffWork?.staffActive;
      if (staffActive != null) {
        isAvailable.value = staffActive;
      }
    } catch (_) {
      refreshCurrentUser();
    }
  }

  AuthUserEntity? _mergeProfile(AuthUserEntity? homeProfile) {
    final cached = AuthSessionStorage.getUser();
    if (cached == null) {
      return homeProfile;
    }
    if (homeProfile == null) {
      return cached;
    }
    return cached.copyWith(
      displayName: homeProfile.displayName,
      phone: homeProfile.phone,
      email: homeProfile.email,
      avatarUrl: homeProfile.avatarUrl,
    );
  }

  bool? _availabilityFromCurrentProfile() {
    final user = AuthSessionStorage.getUser() ?? profile.value;
    return user?.staffActive ?? user?.staffWork?.staffActive;
  }

  Future<void> _syncAvailabilityProfile(bool value) async {
    try {
      final refreshedUser = await AuthSessionService().getCurrentUser();
      profile.value = refreshedUser;
      final staffActive =
          refreshedUser.staffActive ?? refreshedUser.staffWork?.staffActive;
      if (staffActive != null) {
        isAvailable.value = staffActive;
      }
    } catch (_) {
      final user = AuthSessionStorage.getUser();
      if (user != null) {
        await AuthSessionStorage.saveUser(user.copyWith(staffActive: value));
        profile.value = AuthSessionStorage.getUser();
      }
    }
  }
}
