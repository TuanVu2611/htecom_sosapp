import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/AuthUserEntity.dart';
import 'package:hcmu_sos/Entity/StaffHomeEntity.dart';
import 'package:hcmu_sos/Repository/StaffSosRepository.dart';
import 'package:hcmu_sos/Repository/SupportRequestRepository.dart';
import 'package:hcmu_sos/ViewModel/Staff/SOSDetailViewModel.dart';

StaffActiveSosEntity incident({int? assignee, String status = 'pending'}) =>
    StaffActiveSosEntity.fromJson({
      'id': 10,
      'status': status,
      if (assignee != null) 'assigned_staff': {'id': assignee, 'name': 'Staff'},
    });

class SosRepository implements StaffSosRepository {
  StaffActiveSosEntity latest = incident();
  int updates = 0;
  int reads = 0;

  @override
  Future<StaffActiveSosEntity> getSosDetail(int sosId) async {
    reads++;
    return latest;
  }

  @override
  Future<void> updateSos({
    required int sosId,
    required String status,
    String? note,
    List<int>? imageFileIds,
  }) async {
    updates++;
    latest = incident(assignee: 20, status: status);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ChecklistRepository implements SupportRequestRepository {
  int updates = 0;
  @override
  Future<void> updateStaffRequestChecklist({
    required int requestId,
    required List<Map<String, dynamic>> checklist,
  }) async {
    updates++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late SosRepository repository;
  late ChecklistRepository checklistRepository;
  late SOSDetailViewModel controller;
  AuthUserEntity? user;

  setUp(() {
    user = const AuthUserEntity(
      id: '20',
      displayName: 'Staff',
      role: AuthUserRole.staff,
    );
    repository = SosRepository();
    checklistRepository = ChecklistRepository();
    controller = SOSDetailViewModel(
      sosRepository: repository,
      requestRepository: checklistRepository,
      currentUser: () => user,
    );
  });
  tearDown(() {
    controller.onClose();
    Get.reset();
  });

  test(
    'Other staff SOS is read-only and direct mutations are blocked',
    () async {
      controller.sos.value = incident(assignee: 30);
      expect(controller.canEdit, false);
      for (final status in ['in_progress', 'done', 'rejected', 'reopened']) {
        expect(controller.canUpdateStatus(status), false);
        expect(await controller.updateStatus(status), false);
      }
      expect(await controller.updateChecklist(checklist: []), false);
      expect(repository.updates, 0);
      expect(checklistRepository.updates, 0);
    },
  );

  test('Unassigned SOS only allows confirming processing', () {
    controller.sos.value = incident();
    expect(controller.canEdit, false);
    expect(controller.canUpdateStatus('in_progress'), true);
    for (final status in ['done', 'rejected', 'reopened', 'pending']) {
      expect(controller.canUpdateStatus(status), false);
    }
  });

  test('Own active SOS can be edited, terminal SOS cannot', () {
    controller.sos.value = incident(assignee: 20, status: 'in_progress');
    expect(controller.canEdit, true);
    expect(controller.canUpdateStatus('done'), true);
    expect(controller.canUpdateStatus('rejected'), true);
    expect(controller.canUpdateStatus('in_progress'), false);
    for (final status in ['done', 'rejected']) {
      controller.sos.value = incident(assignee: 20, status: status);
      expect(controller.canEdit, false);
      expect(controller.canUpdateStatus('in_progress'), false);
    }
  });

  test('Missing or student session cannot claim or edit', () {
    controller.sos.value = incident();
    user = null;
    expect(controller.canUpdateStatus('in_progress'), false);
    user = const AuthUserEntity(
      id: '20',
      displayName: 'Student',
      role: AuthUserRole.student,
    );
    controller.sos.value = incident(assignee: 20);
    expect(controller.canEdit, false);
    expect(controller.canUpdateStatus('done'), false);
  });

  test('Reassignment before status update prevents mutation', () async {
    controller.sos.value = incident(assignee: 20);
    repository.latest = incident(assignee: 30);
    expect(await controller.updateStatus('in_progress'), false);
    expect(repository.reads, 1);
    expect(repository.updates, 0);
    expect(controller.canEdit, false);
  });

  test('Claim is blocked if another staff has already claimed SOS', () async {
    controller.sos.value = incident();
    repository.latest = incident(assignee: 30, status: 'in_progress');
    expect(await controller.updateStatus('in_progress'), false);
    expect(repository.updates, 0);
  });

  test('Reassignment before checklist save prevents mutation', () async {
    controller.sos.value = incident(assignee: 20);
    repository.latest = incident(assignee: 30);
    expect(await controller.updateChecklist(checklist: []), false);
    expect(checklistRepository.updates, 0);
  });

  testWidgets('Claim reloads actual assignee and enables owned actions', (
    tester,
  ) async {
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));
    controller.sos.value = incident();
    expect(await controller.updateStatus('in_progress'), true);
    expect(repository.updates, 1);
    expect(repository.reads, 2);
    expect(controller.sos.value?.assignedStaff?.id, 20);
    expect(controller.canEdit, true);
    expect(controller.canUpdateStatus('done'), true);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
