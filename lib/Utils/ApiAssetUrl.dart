// ignore_for_file: file_names

import 'package:hcmu_sos/Global/GlobalValue.dart';

class ApiAssetUrl {
  const ApiAssetUrl._();

  static String? resolve(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) {
      return value;
    }
    final baseUrl = GlobalValue.baseUrlMedia;
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final normalizedPath = value.startsWith('/') ? value.substring(1) : value;
    return '$normalizedBase$normalizedPath';
  }
}
