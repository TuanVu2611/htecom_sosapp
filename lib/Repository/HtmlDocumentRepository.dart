// ignore_for_file: file_names

import 'package:hcmu_sos/Entity/HtmlDocumentEntity.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';

class HtmlDocumentRepository {
  HtmlDocumentRepository({ApiCaller? apiCaller})
    : _apiCaller = apiCaller ?? ApiCaller.getInstance();

  final ApiCaller _apiCaller;

  Future<HtmlDocumentEntity> getDocument(String endpoint) async {
    final response = await _apiCaller.getBase<HtmlDocumentEntity>(
      endpoint,
      null,
      decoder: HtmlDocumentEntity.fromJson,
    );

    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Could not load document.',
        data: response.raw,
      );
    }

    return response.data;
  }
}
