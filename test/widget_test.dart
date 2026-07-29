import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Localization/AppTranslations.dart';
import 'package:hcmu_sos/View/Staff/StaffDashboardView.dart';
import 'package:hcmu_sos/View/Student/StudentDashboardView.dart';
import 'package:hcmu_sos/ViewModel/Common/MenuViewModel.dart';
import 'package:hcmu_sos/ViewModel/Staff/StaffHomeViewModel.dart';
import 'package:hcmu_sos/ViewModel/Staff/StaffTaskViewModel.dart';
import 'package:hcmu_sos/ViewModel/Student/CreateTicketViewModel.dart';
import 'package:hcmu_sos/ViewModel/Student/HistoryViewModel.dart';
import 'package:hcmu_sos/ViewModel/Student/StudentHomeViewModel.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('student dashboard renders bottom navigation', (tester) async {
    Get.put(StudentHomeViewModel());
    Get.put(HistoryViewModel());
    Get.put(CreateTicketViewModel());
    Get.put(MenuViewModel());

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('vi', 'VN'),
        home: const StudentDashboardView(),
      ),
    );

    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Lịch sử'), findsOneWidget);
    expect(find.text('Yêu cầu'), findsOneWidget);
    expect(find.text('Tài khoản'), findsOneWidget);

    await tester.tap(find.text('Lịch sử'));
    await tester.pump();

    expect(find.text('Lịch sử'), findsWidgets);
  });

  testWidgets('staff dashboard renders bottom navigation', (tester) async {
    Get.put(StaffHomeViewModel());
    Get.put(TaskViewModel());
    Get.put(MenuViewModel());

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('vi', 'VN'),
        home: const StaffDashboardView(),
      ),
    );

    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Công việc'), findsOneWidget);
    expect(find.text('Tài khoản'), findsOneWidget);

    await tester.tap(find.text('Công việc'));
    await tester.pump();

    expect(find.text('Công việc'), findsWidgets);
  });
}
