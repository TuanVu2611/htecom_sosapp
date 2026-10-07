import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hcmu_sos/Service/NotificationUnreadService.dart';

void main() {
  test('late API response cannot clear a newly received push', () async {
    final response = Completer<int>();
    final service = NotificationUnreadService(
      fetchCount: () => response.future,
    );
    service.setAccount('student');
    final pending = service.refresh();
    service.receivedPush();
    response.complete(0);
    await pending;
    expect(service.count.value, 1);
  });

  test(
    'refresh updates unread count without any dashboard controller',
    () async {
      final service = NotificationUnreadService(fetchCount: () async => 4);
      service.setAccount('student');
      await service.refresh();
      expect(service.count.value, 4);
      service.receivedPush();
      expect(service.count.value, 5);
    },
  );

  test('mark all read cannot clear a push received during the request', () {
    final service = NotificationUnreadService();
    service.setAccount('student');
    service.applyCount(3, service.beginRead());
    final beforeRead = service.revision;
    service.receivedPush();
    service.readCompleted(beforeRead, all: true);
    expect(service.count.value, greaterThan(0));
  });

  test('mark read clears badge and invalidates pending count responses', () {
    final service = NotificationUnreadService();
    service.setAccount('student');
    service.receivedPush();
    final ticket = service.beginRead();
    service.readCompleted(service.revision);
    expect(service.count.value, 0);
    expect(service.applyCount(1, ticket), isFalse);
    expect(service.count.value, 0);
  });

  test(
    'latest notification request wins when responses arrive out of order',
    () {
      final service = NotificationUnreadService();
      service.setAccount('staff');
      final old = service.beginRead();
      final latest = service.beginRead();
      expect(service.applyCount(2, latest), isTrue);
      expect(service.applyCount(0, old), isFalse);
      expect(service.count.value, 2);
    },
  );

  test('logout clears state and rejects previous account response', () async {
    final response = Completer<int>();
    final service = NotificationUnreadService(
      fetchCount: () => response.future,
    );
    service.setAccount('student');
    service.receivedPush();
    final pending = service.refresh();
    service.setAccount(null);
    service.setAccount('staff');
    response.complete(10);
    await pending;
    expect(service.count.value, 0);
  });

  test(
    'overlapping refreshes share a request and errors preserve badge',
    () async {
      final response = Completer<int>();
      var calls = 0;
      final service = NotificationUnreadService(
        fetchCount: () {
          calls++;
          return response.future;
        },
      );
      service.setAccount('student');
      service.receivedPush();
      final first = service.refresh();
      final second = service.refresh();
      expect(calls, 1);
      response.completeError(Exception('offline'));
      await Future.wait([first, second]);
      expect(service.count.value, 1);
    },
  );
}
