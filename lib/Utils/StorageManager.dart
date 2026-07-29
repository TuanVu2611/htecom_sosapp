// ignore_for_file: file_names

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageManager {
  StorageManager._();

  static SharedPreferences? _preferences;

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static Future<void> init() async {
    _preferences ??= await SharedPreferences.getInstance();
  }

  static SharedPreferences get _prefs {
    final prefs = _preferences;
    if (prefs == null) {
      throw StateError(
        'StorageManager is not initialized. Call StorageManager.init() when the app starts.',
      );
    }
    return prefs;
  }

  static Future<bool> setString(String key, String value) {
    return _prefs.setString(key, value);
  }

  static String? getString(String key, {String? defaultValue}) {
    return _prefs.getString(key) ?? defaultValue;
  }

  static Future<bool> setInt(String key, int value) {
    return _prefs.setInt(key, value);
  }

  static int? getInt(String key, {int? defaultValue}) {
    return _prefs.getInt(key) ?? defaultValue;
  }

  static Future<bool> setDouble(String key, double value) {
    return _prefs.setDouble(key, value);
  }

  static double? getDouble(String key, {double? defaultValue}) {
    return _prefs.getDouble(key) ?? defaultValue;
  }

  static Future<bool> setBool(String key, bool value) {
    return _prefs.setBool(key, value);
  }

  static bool? getBool(String key, {bool? defaultValue}) {
    return _prefs.getBool(key) ?? defaultValue;
  }

  static Future<bool> setStringList(String key, List<String> value) {
    return _prefs.setStringList(key, value);
  }

  static List<String> getStringList(
    String key, {
    List<String> defaultValue = const [],
  }) {
    return _prefs.getStringList(key) ?? defaultValue;
  }

  static Future<bool> setJson(String key, Object value) {
    return _prefs.setString(key, jsonEncode(value));
  }

  static T? getJson<T>(
    String key, {
    T Function(Object? json)? decoder,
    T? defaultValue,
  }) {
    final value = _prefs.getString(key);
    if (value == null || value.isEmpty) {
      return defaultValue;
    }

    final decoded = jsonDecode(value);
    if (decoder != null) {
      return decoder(decoded);
    }
    if (decoded is T) {
      return decoded;
    }
    return defaultValue;
  }

  static bool containsKey(String key) {
    return _prefs.containsKey(key);
  }

  static Future<bool> remove(String key) {
    return _prefs.remove(key);
  }

  static Future<bool> clear() {
    return _prefs.clear();
  }

  static Future<void> setSecureString(String key, String value) {
    return _secureStorage.write(key: key, value: value);
  }

  static Future<String?> getSecureString(
    String key, {
    String? defaultValue,
  }) async {
    return await _secureStorage.read(key: key) ?? defaultValue;
  }

  static Future<void> setSecureJson(String key, Object value) {
    return _secureStorage.write(key: key, value: jsonEncode(value));
  }

  static Future<T?> getSecureJson<T>(
    String key, {
    T Function(Object? json)? decoder,
    T? defaultValue,
  }) async {
    final value = await _secureStorage.read(key: key);
    if (value == null || value.isEmpty) {
      return defaultValue;
    }

    final decoded = jsonDecode(value);
    if (decoder != null) {
      return decoder(decoded);
    }
    if (decoded is T) {
      return decoded;
    }
    return defaultValue;
  }

  static Future<bool> containsSecureKey(String key) {
    return _secureStorage.containsKey(key: key);
  }

  static Future<void> removeSecure(String key) {
    return _secureStorage.delete(key: key);
  }

  static Future<void> clearSecure() {
    return _secureStorage.deleteAll();
  }
}
