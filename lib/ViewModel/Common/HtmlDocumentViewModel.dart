// ignore_for_file: file_names

import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/HtmlDocumentEntity.dart';
import 'package:hcmu_sos/Repository/HtmlDocumentRepository.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';
import 'package:hcmu_sos/Utils/Utils.dart';

class HtmlDocumentViewModel extends GetxController {
  HtmlDocumentViewModel({HtmlDocumentRepository? repository})
    : _repository = repository ?? HtmlDocumentRepository();

  final HtmlDocumentRepository _repository;

  final isLoading = false.obs;
  final errorMessage = RxnString();
  final document = Rxn<HtmlDocumentEntity>();

  late final String endpoint;
  late final String fallbackTitle;

  String get title {
    final loadedTitle = document.value?.title.trim();
    if (loadedTitle != null && loadedTitle.isNotEmpty) {
      return loadedTitle;
    }
    return fallbackTitle;
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      endpoint = args['endpoint']?.toString() ?? 'legal/get_terms';
      fallbackTitle = args['title']?.toString() ?? 'Document';
    } else {
      endpoint = 'legal/get_terms';
      fallbackTitle = 'Document';
    }
  }

  @override
  void onReady() {
    super.onReady();
    loadDocument();
  }

  Future<void> loadDocument() async {
    if (isLoading.value) {
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;
    try {
      document.value = await _repository.getDocument(endpoint);
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      Utils.showSnackbar(title: fallbackTitle, content: error.message);
    } catch (_) {
      errorMessage.value = 'Could not load document.';
      Utils.showSnackbar(title: fallbackTitle, content: errorMessage.value!);
    } finally {
      isLoading.value = false;
    }
  }
}
