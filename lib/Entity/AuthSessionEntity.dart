// ignore_for_file: file_names

import 'package:hcmu_sos/Entity/AuthUserEntity.dart';

class AuthSessionEntity {
  const AuthSessionEntity({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    this.expiresIn,
    this.tokenType,
  });

  final AuthUserEntity user;
  final String accessToken;
  final String refreshToken;
  final int? expiresIn;
  final String? tokenType;
}
