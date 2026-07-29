// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Utils/StorageManager.dart';

class LocaleManager {
  const LocaleManager._();

  static const String _storageKey = 'app_locale';

  static const Locale vietnamese = Locale('vi', 'VN');
  static const Locale english = Locale('en', 'US');
  static const Locale fallbackLocale = vietnamese;
  static const List<Locale> supportedLocales = [vietnamese, english];

  static Locale get initialLocale {
    final savedLocale = StorageManager.getString(_storageKey);
    return _localeFromTag(savedLocale) ?? fallbackLocale;
  }

  static bool get hasSavedLocale => StorageManager.containsKey(_storageKey);

  static Future<void> changeLocale(Locale locale) async {
    await StorageManager.setString(_storageKey, _localeToTag(locale));
    Get.updateLocale(locale);
  }

  static void applyLocale(Locale locale) {
    Get.updateLocale(locale);
  }

  static Locale? _localeFromTag(String? tag) {
    switch (tag) {
      case 'vi_VN':
        return vietnamese;
      case 'en_US':
        return english;
      default:
        return null;
    }
  }

  static String _localeToTag(Locale locale) {
    return '${locale.languageCode}_${locale.countryCode}';
  }
}
