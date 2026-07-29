// ignore_for_file: file_names

import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/StaffHomeEntity.dart';
import 'package:hcmu_sos/Repository/StaffSosRepository.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';
import 'package:hcmu_sos/Utils/Utils.dart';

class SOSListViewModel extends GetxController {
  SOSListViewModel({StaffSosRepository? sosRepository})
    : _sosRepository = sosRepository ?? StaffSosRepository();

  final StaffSosRepository _sosRepository;

  final sosItems = <StaffActiveSosEntity>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final errorMessage = RxnString();
  final total = 0.obs;

  int _page = 1;
  static const int _pageSize = 20;

  bool get canLoadMore => sosItems.length < total.value;

  @override
  void onInit() {
    super.onInit();
    sosItems.assignAll(_readInitialSosItems());
  }

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
      final result = await _sosRepository.listActiveSos(
        page: 1,
        pageSize: _pageSize,
      );
      _page = result.page;
      total.value = result.total;
      sosItems.assignAll(result.items);
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      Utils.showSnackbar(title: 'SOS khẩn cấp', content: error.message);
    } catch (_) {
      const message = 'Không thể tải danh sách SOS.';
      errorMessage.value = message;
      Utils.showSnackbar(title: 'SOS khẩn cấp', content: message);
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
      final result = await _sosRepository.listActiveSos(
        page: _page + 1,
        pageSize: _pageSize,
      );
      _page = result.page;
      total.value = result.total;
      sosItems.addAll(result.items);
    } on ApiException catch (error) {
      Utils.showSnackbar(title: 'SOS khẩn cấp', content: error.message);
    } catch (_) {
      Utils.showSnackbar(
        title: 'SOS khẩn cấp',
        content: 'Không thể tải thêm SOS.',
      );
    } finally {
      isLoadingMore.value = false;
    }
  }

  List<StaffActiveSosEntity> _readInitialSosItems() {
    final args = Get.arguments;
    if (args is List<StaffActiveSosEntity>) {
      return args;
    }
    if (args is Iterable) {
      return args.whereType<StaffActiveSosEntity>().toList();
    }
    if (args is Map) {
      final value = args['items'] ?? args['active_sos'] ?? args['activeSos'];
      if (value is List<StaffActiveSosEntity>) {
        return value;
      }
      if (value is Iterable) {
        return value.whereType<StaffActiveSosEntity>().toList();
      }
    }
    return const <StaffActiveSosEntity>[];
  }
}
