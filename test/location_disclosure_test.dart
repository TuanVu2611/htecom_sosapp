import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/AuthUserEntity.dart';
import 'package:hcmu_sos/Localization/AppTranslations.dart';
import 'package:hcmu_sos/Service/AppLocationRequirementService.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';
import 'package:hcmu_sos/Service/UserLocationUpdateService.dart';
import 'package:hcmu_sos/Utils/StorageManager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationPlatformFake extends GeolocatorPlatform {
  int checks = 0;
  int requests = 0;
  int positions = 0;

  @override
  Future<bool> isLocationServiceEnabled() async {
    checks++;
    return true;
  }

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.denied;

  @override
  Future<LocationPermission> requestPermission() async {
    requests++;
    return LocationPermission.whileInUse;
  }

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) {
    positions++;
    throw StateError('Unexpected GPS collection');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final service = AppLocationRequirementService.instance;
  final originalPlatform = GeolocatorPlatform.instance;
  late LocationPlatformFake platform;
  const user = AuthUserEntity(
    id: 'test-user',
    displayName: 'Test',
    role: AuthUserRole.student,
  );

  setUpAll(() async {
    ApiCaller.configure(baseUrl: 'https://example.invalid');
    SharedPreferences.setMockInitialValues({});
    await StorageManager.init();
  });
  setUp(() async {
    await StorageManager.clear();
    platform = LocationPlatformFake();
    GeolocatorPlatform.instance = platform;
  });
  tearDown(() {
    UserLocationUpdateService.instance.stop();
    service.stop();
    GeolocatorPlatform.instance = originalPlatform;
    Get.reset();
  });

  Future<void> openApp(WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('vi', 'VN'),
        home: const Scaffold(body: Text('Home')),
      ),
    );
    service.startForUser(user);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Later prevents permission requests and periodic GPS collection',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await openApp(tester);
      UserLocationUpdateService.instance.startForUser(user);
      expect(platform.checks, 0);
      await tester.ensureVisible(find.text('Để sau'));
      await tester.tap(find.text('Để sau'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(minutes: 5));
      expect(platform.checks, 0);
      expect(platform.requests, 0);
      expect(platform.positions, 0);
      expect(await service.checkLocationStatus(showDialog: false), false);
      expect(
        StorageManager.getBool('location_update_consent_v1_test-user'),
        isNull,
      );
      expect(tester.takeException(), isNull);
      UserLocationUpdateService.instance.stop();
    },
  );

  testWidgets(
    'Consent precedes permission and concurrent checks share one request',
    (tester) async {
      await openApp(tester);
      final first = service.checkLocationStatus();
      final second = service.checkLocationStatus(showDialog: false);
      expect(platform.requests, 0);
      expect(platform.checks, 0);
      await tester.ensureVisible(find.text('Đồng ý'));
      await tester.tap(find.text('Đồng ý'));
      await tester.pumpAndSettle();
      expect(await first, true);
      expect(await second, true);
      expect(platform.requests, 1);
      expect(
        StorageManager.getBool('location_update_consent_v1_test-user'),
        true,
      );
      expect(tester.takeException(), isNull);
      service.stop();
      service.startForUser(user);
      await tester.pumpAndSettle();
      expect(find.text('Đồng ý'), findsNothing);
    },
  );
}
