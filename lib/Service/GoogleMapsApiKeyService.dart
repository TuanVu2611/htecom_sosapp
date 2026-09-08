// ignore_for_file: file_names

import 'package:flutter/services.dart';

class GoogleMapsApiKeyService {
  GoogleMapsApiKeyService._();

  static final GoogleMapsApiKeyService instance = GoogleMapsApiKeyService._();
  static const _channel = MethodChannel('hcmu_sos/google_maps');

  String? _cachedApiKey;

  Future<String?> getApiKey() async {
    final cached = _cachedApiKey;
    if (cached != null) {
      return cached;
    }

    try {
      final key = await _channel.invokeMethod<String>('getApiKey');
      final normalized = key?.trim();
      if (normalized == null ||
          normalized.isEmpty ||
          normalized.startsWith(r'$(')) {
        return null;
      }
      _cachedApiKey = normalized;
      return normalized;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
