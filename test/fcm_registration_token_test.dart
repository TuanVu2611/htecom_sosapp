import 'package:flutter_test/flutter_test.dart';
import 'package:hcmu_sos/Service/fcm_registration_token.dart';

void main() {
  test(
    'iOS waits for delayed APNs registration before requesting FCM',
    () async {
      var apnsCalls = 0;
      var waits = 0;
      final token = await getFcmRegistrationToken(
        requiresApnsToken: true,
        getApnsToken: () async => ++apnsCalls < 3 ? null : 'apns',
        getFcmToken: () async {
          expect(apnsCalls, 3);
          return 'fcm';
        },
        wait: (_) async {
          waits++;
        },
      );
      expect(token, 'fcm');
      expect(waits, 2);
    },
  );

  test(
    'missing APNs token has bounded waiting and never requests FCM',
    () async {
      var fcmCalls = 0;
      var waits = 0;
      final token = await getFcmRegistrationToken(
        requiresApnsToken: true,
        getApnsToken: () async => null,
        getFcmToken: () async {
          fcmCalls++;
          return 'fcm';
        },
        wait: (_) async {
          waits++;
        },
      );
      expect(token, isNull);
      expect(fcmCalls, 0);
      expect(waits, 19);
    },
  );

  test('Android requests FCM without checking or waiting for APNs', () async {
    final token = await getFcmRegistrationToken(
      requiresApnsToken: false,
      getApnsToken: () async => throw StateError('Unexpected APNs call'),
      getFcmToken: () async => 'android-fcm',
      wait: (_) async => throw StateError('Unexpected wait'),
    );
    expect(token, 'android-fcm');
  });
}
