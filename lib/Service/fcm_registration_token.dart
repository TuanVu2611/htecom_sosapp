/// Waits for Apple's asynchronous APNs registration before asking FCM for a
/// token. A missing APNs token must not prevent the app from starting.
Future<String?> getFcmRegistrationToken({
  required bool requiresApnsToken,
  required Future<String?> Function() getApnsToken,
  required Future<String?> Function() getFcmToken,
  Future<void> Function(Duration) wait = Future<void>.delayed,
}) async {
  if (requiresApnsToken) {
    for (var attempt = 0; attempt < 20; attempt++) {
      final token = await getApnsToken();
      if (token != null && token.isNotEmpty) {
        return getFcmToken();
      }
      if (attempt < 19) {
        await wait(const Duration(milliseconds: 500));
      }
    }
    return null;
  }
  return getFcmToken();
}
