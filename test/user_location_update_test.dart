import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hcmu_sos/Entity/AuthUserEntity.dart';
import 'package:hcmu_sos/Repository/UserLocationRepository.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';
import 'package:hcmu_sos/Service/AppLocationRequirementService.dart';
import 'package:hcmu_sos/Service/UserLocationUpdateService.dart';
import 'package:hcmu_sos/Utils/StorageManager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecordingLocationRepository extends UserLocationRepository {
  int requests = 0;

  @override
  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    requests++;
  }
}

class GrantedLocationPlatform extends GeolocatorPlatform {
  Completer<Position>? pendingPosition;

  final position = Position(
    latitude: 10,
    longitude: 106,
    timestamp: DateTime(2026),
    accuracy: 5,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async =>
      pendingPosition == null ? position : await pendingPosition!.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final originalPlatform = GeolocatorPlatform.instance;
  final access = AppLocationRequirementService.instance;
  late RecordingLocationRepository repository;
  late GrantedLocationPlatform platform;
  late UserLocationUpdateService updater;
  late DateTime now;
  const student = AuthUserEntity(
    id: 'student',
    displayName: 'Student',
    role: AuthUserRole.student,
  );
  const staff = AuthUserEntity(
    id: 'staff',
    displayName: 'Staff',
    role: AuthUserRole.staff,
  );

  setUpAll(() async {
    ApiCaller.configure(baseUrl: 'https://example.invalid');
    SharedPreferences.setMockInitialValues({});
    await StorageManager.init();
  });

  setUp(() async {
    await StorageManager.clear();
    await StorageManager.setBool('location_update_consent_v1_student', true);
    await StorageManager.setBool('location_update_consent_v1_staff', true);
    platform = GrantedLocationPlatform();
    GeolocatorPlatform.instance = platform;
    repository = RecordingLocationRepository();
    now = DateTime(2026);
    updater = UserLocationUpdateService.forTesting(
      locationRepository: repository,
      now: () => now,
    );
  });

  tearDown(() {
    updater.stop();
    access.stop();
    GeolocatorPlatform.instance = originalPlatform;
  });

  Future<void> start(WidgetTester tester, AuthUserEntity user) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    access.startForUser(user);
    updater.startForUser(user);
    await tester.pump();
  }

  testWidgets(
    'Student sends once, has no periodic timer, and throttles resumes',
    (tester) async {
      await start(tester, student);
      expect(repository.requests, 1);
      expect(updater.isRunning, true);
      updater.didChangeAppLifecycleState(AppLifecycleState.paused);
      now = now.add(const Duration(minutes: 1));
      updater.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();
      expect(repository.requests, 1);

      now = now.add(const Duration(minutes: 10));
      await tester.pump(const Duration(minutes: 10));
      expect(repository.requests, 1);
      updater.didChangeAppLifecycleState(AppLifecycleState.paused);
      updater.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();
      expect(repository.requests, 2);
      updater.stop();
      updater.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();
      expect(repository.requests, 2);
    },
  );

  testWidgets(
    'Student discards GPS returned in background and retries on resume',
    (tester) async {
      platform.pendingPosition = Completer<Position>();
      await start(tester, student);
      updater.didChangeAppLifecycleState(AppLifecycleState.paused);
      platform.pendingPosition!.complete(platform.position);
      await tester.pump();
      expect(repository.requests, 0);
      platform.pendingPosition = null;
      updater.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();
      expect(repository.requests, 1);
      updater.stop();
    },
  );

  testWidgets('Staff keeps five minute periodic updates', (tester) async {
    await start(tester, staff);
    expect(repository.requests, 1);
    updater.didChangeAppLifecycleState(AppLifecycleState.paused);
    await tester.pump(const Duration(minutes: 5));
    expect(repository.requests, 2);
    updater.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump();
    expect(repository.requests, 2);
    updater.stop();
  });

  testWidgets('Stopping during GPS collection prevents upload', (tester) async {
    platform.pendingPosition = Completer<Position>();
    await start(tester, student);
    updater.stop();
    platform.pendingPosition!.complete(platform.position);
    await tester.pump();
    expect(repository.requests, 0);
    expect(updater.isRunning, false);
  });
}
