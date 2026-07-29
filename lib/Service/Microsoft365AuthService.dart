// ignore_for_file: file_names

import 'package:flutter_appauth/flutter_appauth.dart';

class Microsoft365AuthService {
  Microsoft365AuthService({FlutterAppAuth? appAuth})
    : _appAuth = appAuth ?? const FlutterAppAuth();

  // static const String clientId = String.fromEnvironment('M365_CLIENT_ID');
  // static const String tenantId = String.fromEnvironment(
  //   'M365_TENANT_ID',
  //   defaultValue: 'common',
  // );
  static const String clientId = '73891f85-999c-469e-af74-d68c78e4f170';
  static const String tenantId = '713fb3bf-e05a-4533-9ed4-4f88791ce09c';
  static const String redirectScheme = String.fromEnvironment(
    'M365_REDIRECT_SCHEME',
    defaultValue: 'hcmusos',
  );
  static const String redirectHost = String.fromEnvironment(
    'M365_REDIRECT_HOST',
    defaultValue: 'auth',
  );

  static const List<String> _scopes = [
    'openid',
    'profile',
    'email',
    'offline_access',
    'User.Read',
  ];

  final FlutterAppAuth _appAuth;

  bool get isConfigured => clientId.isNotEmpty;

  Future<String> signInAndGetAccessToken() async {
    if (!isConfigured) {
      throw const Microsoft365AuthConfigurationException();
    }

    final response = await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        clientId,
        '$redirectScheme://$redirectHost',
        discoveryUrl:
            'https://login.microsoftonline.com/$tenantId/v2.0/.well-known/openid-configuration',
        scopes: _scopes,
        promptValues: const ['select_account'],
      ),
    );

    final accessToken = response.idToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw const Microsoft365AuthTokenException();
    }

    return accessToken;
  }
}

class Microsoft365AuthConfigurationException implements Exception {
  const Microsoft365AuthConfigurationException();
}

class Microsoft365AuthTokenException implements Exception {
  const Microsoft365AuthTokenException();
}
