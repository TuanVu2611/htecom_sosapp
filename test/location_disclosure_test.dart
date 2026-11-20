import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart' hide Response;
import 'package:hcmu_sos/Entity/AuthUserEntity.dart';
import 'package:hcmu_sos/Localization/AppTranslations.dart';
import 'package:hcmu_sos/Service/AppLocationRequirementService.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';
import 'package:hcmu_sos/Service/UserLocationUpdateService.dart';
import 'package:hcmu_sos/Service/StudentSosTrackingService.dart';
import 'package:hcmu_sos/ViewModel/Student/CreateSOSViewModel.dart';
import 'package:hcmu_sos/ViewModel/Student/CreateTicketViewModel.dart';
import 'package:hcmu_sos/Utils/StorageManager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationPlatformFake extends GeolocatorPlatform {
  int checks = 0;
  int requests = 0;
  int positions = 0;
  Position? positionResult;
  int streams = 0;
  bool grantRequest = true;
  LocationPermission permission = LocationPermission.denied;

  @override
  Future<bool> isLocationServiceEnabled() async {
    checks++;
    return true;
  }

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async {
    requests++;
    if (grantRequest) permission = LocationPermission.whileInUse;
    return permission;
  }

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    streams++;
    return const Stream<Position>.empty();
  }

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) {
    positions++;
    if (positionResult != null) return Future.value(positionResult);
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
    StudentSosTrackingService.instance.stop();
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
        StorageManager.getBool('location_consent_v2_test-user_student_general'),
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
        StorageManager.getBool('location_consent_v2_test-user_student_general'),
        true,
      );
      expect(tester.takeException(), isNull);
      service.stop();
      service.startForUser(user);
      await tester.pumpAndSettle();
      expect(find.text('Đồng ý'), findsNothing);
    },
  );
  Future<void> choose(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Old consent and already granted OS permission do not bypass new disclosure',
    (tester) async {
      await StorageManager.setBool(
        'location_update_consent_v1_test-user',
        true,
      );
      platform.permission = LocationPermission.whileInUse;
      await openApp(tester);
      expect(find.text('Đồng ý'), findsOneWidget);
      expect(service.hasConsent(), false);
      expect(platform.positions, 0);
      await choose(tester, 'Đồng ý');
      expect(service.hasConsent(), true);
      expect(platform.requests, 0);
    },
  );

  testWidgets(
    'SOS restoration queues behind general consent and cannot start tracking early',
    (tester) async {
      await openApp(tester);
      final started = StudentSosTrackingService.instance.startTracking(123);
      await tester.pumpAndSettle();
      expect(platform.requests, 0);
      expect(platform.streams, 0);
      await choose(tester, 'Đồng ý');
      expect(platform.requests, 1);
      expect(platform.streams, 0);
      expect(find.text('location.sosDisclosureMessage'.tr), findsOneWidget);
      await choose(tester, 'Đồng ý');
      await started;
      expect(platform.streams, 1);
      expect(platform.requests, 1);
      expect(service.hasConsent(use: LocationUse.sosTracking), true);
      StudentSosTrackingService.instance.stop();
    },
  );

  testWidgets(
    'Later blocks automatic restoration; explicit SOS can ask again but cannot collect on decline',
    (tester) async {
      await openApp(tester);
      final restored = StudentSosTrackingService.instance.startTracking(123);
      await choose(tester, 'Để sau');
      await restored;
      expect(platform.requests, 0);
      expect(platform.streams, 0);
      final create = CreateSOSViewModel();
      final submitted = create.createSOS();
      await tester.pumpAndSettle();
      expect(find.text('location.disclosureMessage'.tr), findsOneWidget);
      await choose(tester, 'Để sau');
      await submitted;
      expect(platform.positions, 0);
      expect(platform.streams, 0);
      expect(platform.requests, 0);
      expect(create.sentSosId.value, isNull);
      create.onClose();
      StudentSosTrackingService.instance.stop();
    },
  );

  testWidgets(
    'Logout while consent is open prevents permission request and consent persistence',
    (tester) async {
      await openApp(tester);
      service.stop();
      await choose(tester, 'Đồng ý');
      expect(platform.requests, 0);
      expect(
        StorageManager.getBool('location_consent_v2_test-user_student_general'),
        isNull,
      );
    },
  );

  testWidgets(
    'Revoked permission requires a fresh explanation before another native request',
    (tester) async {
      await openApp(tester);
      await choose(tester, 'Đồng ý');
      platform.permission = LocationPermission.denied;
      final access = service.checkLocationStatus(userInitiated: true);
      await tester.pumpAndSettle();
      expect(platform.requests, 1);
      expect(find.text('location.disclosureMessage'.tr), findsOneWidget);
      await choose(tester, 'Đồng ý');
      expect(await access, true);
      expect(platform.requests, 2);
    },
  );

  testWidgets(
    'OS refusal does not trigger repeat prompts or allow collection',
    (tester) async {
      platform.grantRequest = false;
      await openApp(tester);
      await choose(tester, 'Đồng ý');
      expect(platform.requests, 1);
      expect(await service.checkLocationStatus(), false);
      expect(platform.requests, 1);
      expect(platform.checks, 0);
      expect(find.text('Đồng ý'), findsNothing);
    },
  );

  testWidgets(
    'Background callers cannot display disclosure or ask native permission',
    (tester) async {
      await openApp(tester);
      await choose(tester, 'Đồng ý');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      final allowed = await service.checkLocationStatus(
        use: LocationUse.sosTracking,
      );
      expect(allowed, false);
      expect(service.hasConsent(use: LocationUse.sosTracking), false);
      expect(platform.requests, 1);
      service.stop();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    },
  );

  testWidgets('Staff disclosure explains background periodic updates', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('vi', 'VN'),
        home: const Scaffold(body: Text('Home')),
      ),
    );
    service.startForUser(
      const AuthUserEntity(
        id: 'staff',
        displayName: 'Staff',
        role: AuthUserRole.staff,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('location.staffDisclosureMessage'.tr), findsOneWidget);
    expect(platform.requests, 0);
    await choose(tester, 'Đồng ý');
    expect(platform.requests, 1);
    expect(
      StorageManager.getBool('location_consent_v2_staff_staff_general'),
      true,
    );
  });
  testWidgets(
    'Creating a ticket cannot request permission or GPS after disclosure is declined',
    (tester) async {
      await openApp(tester);
      await choose(tester, 'Để sau');
      final ticket = CreateTicketViewModel();
      final locating = ticket.loadCurrentLocation(userInitiated: true);
      await tester.pumpAndSettle();
      expect(platform.requests, 0);
      expect(find.text('location.disclosureMessage'.tr), findsOneWidget);
      await choose(tester, 'Để sau');
      await locating;
      expect(platform.requests, 0);
      expect(platform.positions, 0);
      ticket.onClose();
    },
  );

  testWidgets('Dismissing a disclosure is not consent', (tester) async {
    await openApp(tester);
    Get.back<void>();
    await tester.pumpAndSettle();
    expect(service.hasConsent(), false);
    expect(platform.requests, 0);
    expect(await service.checkLocationStatus(showDialog: false), false);
  });
  testWidgets(
    'Student can create a one-time SOS while declining background tracking',
    (tester) async {
      await openApp(tester);
      await choose(tester, 'Đồng ý');
      platform.positionResult = Position(
        latitude: 10,
        longitude: 106,
        timestamp: DateTime.now(),
        accuracy: 5,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      var creations = 0;
      RequestOptions? capturedRequest;
      final interceptor = InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedRequest = options;
          creations++;
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'data': {'id': 123},
              },
            ),
          );
        },
      );
      final client = ApiCaller.getInstance().client;
      client.interceptors.add(interceptor);
      addTearDown(() => client.interceptors.remove(interceptor));
      final create = CreateSOSViewModel();
      final submitted = create.createSOS();
      // Flush the asynchronous Dio interceptor before checking the tracking prompt.
      for (
        var i = 0;
        i < 20 && !service.hasConsent(use: LocationUse.sosTracking);
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump(const Duration(milliseconds: 100));
        if (find
            .text('location.sosDisclosureMessage'.tr)
            .evaluate()
            .isNotEmpty) {
          break;
        }
      }
      await tester.pumpAndSettle();
      expect(creations, 1);
      expect(create.state.value, CreateSOSState.sent);
      expect(platform.streams, 0);
      expect(find.text('location.sosDisclosureMessage'.tr), findsOneWidget);
      await choose(tester, 'Để sau');
      await submitted;
      expect(create.sentSosId.value, 123);
      expect(create.state.value, CreateSOSState.sent);
      expect(platform.positions, 1);
      expect(capturedRequest?.path, 'sos');
      expect(capturedRequest?.data, {
        'latitude': 10.0,
        'longitude': 106.0,
        'note': null,
      });
      expect(platform.streams, 0);
      expect(service.hasConsent(use: LocationUse.sosTracking), false);
      StudentSosTrackingService.instance.stop();
      create.onClose();
    },
  );
}
