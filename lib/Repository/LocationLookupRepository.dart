// ignore_for_file: file_names

import 'package:dio/dio.dart';
import 'package:get/get.dart';

class LocationLookupRepository {
  LocationLookupRepository({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      sendTimeout: const Duration(seconds: 12),
      responseType: ResponseType.json,
      headers: const {
        'Accept': 'application/json',
        'User-Agent': 'HCMU_SOS/1.0.0',
      },
    );
  }

  final Dio _dio;

  Future<String?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.get<Object?>(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: <String, dynamic>{
          'format': 'jsonv2',
          'lat': latitude,
          'lon': longitude,
          'zoom': 18,
          'addressdetails': 1,
          'accept-language': _languageCode,
        },
      );

      final data = response.data;
      if (data is! Map) {
        return null;
      }

      final address = data['address'];
      if (address is Map) {
        final formattedAddress = _buildFormattedAddress(address);
        if (formattedAddress != null && formattedAddress.isNotEmpty) {
          return formattedAddress;
        }
      }

      final displayName = data['display_name']?.toString().trim();
      if (displayName != null && displayName.isNotEmpty) {
        return _sanitizeDisplayName(displayName);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String get _languageCode {
    final locale = Get.locale;
    final languageCode = locale?.languageCode.trim();
    if (languageCode == null || languageCode.isEmpty) {
      return 'vi';
    }
    return languageCode;
  }

  String? _buildFormattedAddress(Map address) {
    final line1 = _mergeParts([address['house_number'], address['road']]);

    final segments = <String>[
      if (line1.isNotEmpty) line1,
      _firstNonEmpty([
        address['neighbourhood'],
        address['suburb'],
        address['quarter'],
        address['hamlet'],
        address['village'],
      ]),
      _firstNonEmpty([
        address['city_district'],
        address['borough'],
        address['district'],
      ]),
      _firstNonEmpty([
        address['city'],
        address['town'],
        address['county'],
        address['state'],
      ]),
    ].where((item) => item.isNotEmpty).toList();

    if (segments.isEmpty) {
      return null;
    }

    return segments.join(', ');
  }

  String _sanitizeDisplayName(String value) {
    return value
        .replaceAll(RegExp(r',\s*\d{4,6}(?=,|$)'), '')
        .replaceAll(RegExp(r'^\s*,\s*'), '')
        .replaceAll(RegExp(r'\s+,'), ',')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }

  String _mergeParts(List<Object?> values) {
    return values
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .join(' ');
  }

  String _firstNonEmpty(List<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }
}
