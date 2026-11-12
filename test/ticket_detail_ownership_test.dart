import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/SupportRequestEntity.dart';
import 'package:hcmu_sos/Repository/SupportRequestRepository.dart';
import 'package:hcmu_sos/View/Student/TicketDetailView.dart';
import 'package:hcmu_sos/ViewModel/Student/TicketDetailViewModel.dart';

class RecordingRequestRepository implements SupportRequestRepository {
  int ratingsSent = 0;
  SupportRequestDetailEntity? result;

  @override
  Future<SupportRequestDetailEntity> getRequestDetail(int requestId) async =>
      result!;

  @override
  Future<void> rateRequest({
    required int requestId,
    required int rating,
    String? comment,
  }) async {
    ratingsSent++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

SupportRequestDetailEntity request({
  bool isSos = true,
  Object? studentId = 101,
}) => SupportRequestDetailEntity.fromJson({
  'id': 10,
  'code': 'SOS-10',
  'title': 'Incident title',
  'status': 'done',
  'is_sos': isSos,
  if (studentId != null) 'student': {'id': studentId, 'name': 'Student'},
  'assigned_staff': {'id': 20, 'name': 'Assigned staff', 'phone': '0900000000'},
  'acceptance': {'note': 'Private acceptance note'},
});

void main() {
  late RecordingRequestRepository repository;
  late TicketDetailViewModel controller;
  setUp(() {
    repository = RecordingRequestRepository();
    controller = TicketDetailViewModel(
      requestRepository: repository,
      currentUserId: () => '101',
    );
    controller.requestId = 10;
  });
  tearDown(Get.reset);

  test('Own SOS is recognized from student.id after ID normalization', () {
    controller.detail.value = request(studentId: '101');
    expect(controller.isOwnSos, true);
    expect(controller.canAccessOwnerFeatures, true);
    expect(controller.canRate, true);
  });

  test(
    'Other student and missing or invalid ownership cannot submit rating',
    () async {
      for (final id in [102, null, 0, 'invalid']) {
        controller.detail.value = request(studentId: id);
        expect(controller.isOwnSos, false);
        expect(controller.canAccessOwnerFeatures, false);
        expect(await controller.submitRating(rating: 5), false);
      }
      expect(repository.ratingsSent, 0);
    },
  );

  test('Missing logged-in user does not grant ownership', () async {
    final anonymous = TicketDetailViewModel(
      requestRepository: repository,
      currentUserId: () => null,
    );
    anonymous.requestId = 10;
    anonymous.detail.value = request();
    expect(anonymous.canAccessOwnerFeatures, false);
    expect(await anonymous.submitRating(rating: 5), false);
    expect(repository.ratingsSent, 0);
  });

  test('Normal tickets retain owner features without a student ID', () {
    controller.detail.value = request(isSos: false, studentId: null);
    expect(controller.canAccessOwnerFeatures, true);
    expect(controller.canRate, true);
  });

  testWidgets('Own SOS retains acceptance, contact and rating/chat actions', (
    tester,
  ) async {
    controller.detail.value = request();
    repository.result = controller.detail.value;
    Get.put(controller);
    controller.requestId = 10;
    await tester.pumpWidget(const GetMaterialApp(home: TicketDetailView()));
    await tester.pumpAndSettle();
    expect(find.text('Private acceptance note'), findsOneWidget);
    expect(find.text('ticket.detail.chat'), findsOneWidget);
    expect(find.text('ticket.detail.rating'), findsOneWidget);
    expect(find.byIcon(Icons.phone_in_talk_rounded), findsOneWidget);
  });

  testWidgets(
    'Other SOS shows incident and staff but hides private sections and actions',
    (tester) async {
      controller.detail.value = request(studentId: 102);
      repository.result = controller.detail.value;
      Get.put(controller);
      controller.requestId = 10;
      await tester.pumpWidget(const GetMaterialApp(home: TicketDetailView()));
      await tester.pumpAndSettle();
      expect(find.text('Incident title'), findsOneWidget);
      expect(find.text('Assigned staff'), findsOneWidget);
      expect(find.text('Private acceptance note'), findsNothing);
      expect(find.text('ticket.detail.chat'), findsNothing);
      expect(find.text('ticket.detail.rating'), findsNothing);
      expect(find.byIcon(Icons.phone_in_talk_rounded), findsNothing);
    },
  );
}
