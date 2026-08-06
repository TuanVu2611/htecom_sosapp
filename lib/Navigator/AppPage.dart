// ignore_for_file: file_names

import 'package:get/get.dart';
import 'package:hcmu_sos/Navigator/AppRoute.dart';
import 'package:hcmu_sos/Repository/AuthRepository.dart';
import 'package:hcmu_sos/View/Common/Auth/ChangePassView.dart';
import 'package:hcmu_sos/View/Common/Auth/ForgotPasswordView.dart';
import 'package:hcmu_sos/View/Common/Auth/LoginView.dart';
import 'package:hcmu_sos/View/Common/Auth/RegisterView.dart';
import 'package:hcmu_sos/View/Common/HtmlDocumentView.dart';
import 'package:hcmu_sos/View/Common/NotifyView.dart';
import 'package:hcmu_sos/View/Common/SplashView.dart';
import 'package:hcmu_sos/View/Staff/SOSDetailView.dart';
import 'package:hcmu_sos/View/Staff/SOSRealtimeMapView.dart';
import 'package:hcmu_sos/View/Staff/StaffPerformanceView.dart';
import 'package:hcmu_sos/View/Staff/StaffDashboardView.dart';
import 'package:hcmu_sos/View/Staff/StaffInfoView.dart';
import 'package:hcmu_sos/View/Staff/SOSListView.dart';
import 'package:hcmu_sos/View/Staff/StaffTicketDetailView.dart';
import 'package:hcmu_sos/View/Student/CommentTicketView.dart';
import 'package:hcmu_sos/View/Student/StudentDashboardView.dart';
import 'package:hcmu_sos/View/Student/StudentInfoView.dart';
import 'package:hcmu_sos/View/Student/TicketDetailView.dart';
import 'package:hcmu_sos/ViewModel/Common/Auth/ChangePassViewModel.dart';
import 'package:hcmu_sos/ViewModel/Common/Auth/LoginViewModel.dart';
import 'package:hcmu_sos/ViewModel/Common/Auth/ForgotPasswordViewModel.dart';
import 'package:hcmu_sos/ViewModel/Common/Auth/RegisterViewModel.dart';
import 'package:hcmu_sos/ViewModel/Common/HtmlDocumentViewModel.dart';
import 'package:hcmu_sos/ViewModel/Common/MenuViewModel.dart';
import 'package:hcmu_sos/ViewModel/Common/NotifyViewModel.dart';
import 'package:hcmu_sos/ViewModel/Common/SplashViewModel.dart';
import 'package:hcmu_sos/ViewModel/Staff/StaffHomeViewModel.dart';
import 'package:hcmu_sos/ViewModel/Staff/StaffInfoViewModel.dart';
import 'package:hcmu_sos/ViewModel/Staff/SOSDetailViewModel.dart';
import 'package:hcmu_sos/ViewModel/Staff/SOSListViewModel.dart';
import 'package:hcmu_sos/ViewModel/Staff/SOSRealtimeMapViewModel.dart';
import 'package:hcmu_sos/ViewModel/Staff/StaffTicketDetailViewModel.dart';
import 'package:hcmu_sos/ViewModel/Staff/StaffTaskViewModel.dart';
import 'package:hcmu_sos/ViewModel/Student/CommentTicketViewModel.dart';
import 'package:hcmu_sos/ViewModel/Student/CreateSOSViewModel.dart';
import 'package:hcmu_sos/ViewModel/Student/CreateTicketViewModel.dart';
import 'package:hcmu_sos/ViewModel/Student/HistoryViewModel.dart';
import 'package:hcmu_sos/ViewModel/Student/StudentHomeViewModel.dart';
import 'package:hcmu_sos/ViewModel/Student/StudentInfoViewModel.dart';
import 'package:hcmu_sos/ViewModel/Student/TicketDetailViewModel.dart';

class AppPage {
  const AppPage._();

  static const String initial = AppRoute.splash;

  static final List<GetPage<dynamic>> pages = [
    GetPage(
      name: AppRoute.splash,
      page: () => const SplashView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SplashViewModel>(() => SplashViewModel());
      }),
    ),
    GetPage(
      name: AppRoute.login,
      page: () => const LoginView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AuthRepository>(() => ApiAuthRepository());
        Get.lazyPut<LoginViewModel>(
          () => LoginViewModel(authRepository: Get.find<AuthRepository>()),
        );
      }),
    ),
    GetPage(
      name: AppRoute.register,
      page: () => const RegisterView(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<AuthRepository>()) {
          Get.lazyPut<AuthRepository>(() => ApiAuthRepository());
        }
        Get.lazyPut<RegisterViewModel>(
          () => RegisterViewModel(authRepository: Get.find<AuthRepository>()),
        );
      }),
    ),
    GetPage(
      name: AppRoute.forgotPassword,
      page: () => const ForgotPasswordView(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<AuthRepository>()) {
          Get.lazyPut<AuthRepository>(() => ApiAuthRepository());
        }
        Get.lazyPut<ForgotPasswordViewModel>(
          () => ForgotPasswordViewModel(
            authRepository: Get.find<AuthRepository>(),
          ),
        );
      }),
    ),
    GetPage(
      name: AppRoute.studentDashboard,
      page: () => const StudentDashboardView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<StudentHomeViewModel>(() => StudentHomeViewModel());
        Get.lazyPut<HistoryViewModel>(() => HistoryViewModel());
        Get.lazyPut<CreateSOSViewModel>(() => CreateSOSViewModel());
        Get.lazyPut<CreateTicketViewModel>(() => CreateTicketViewModel());
        Get.lazyPut<MenuViewModel>(() => MenuViewModel());
      }),
    ),
    GetPage(
      name: AppRoute.ticketDetail,
      page: () => const TicketDetailView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<TicketDetailViewModel>(() => TicketDetailViewModel());
      }),
    ),
    GetPage(
      name: AppRoute.commentTicket,
      page: () => const CommentTicketView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<CommentTicketViewModel>(() => CommentTicketViewModel());
      }),
    ),
    GetPage(
      name: AppRoute.studentInfo,
      page: () => const StudentInfoView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<StudentInfoViewModel>(() => StudentInfoViewModel());
      }),
    ),
    GetPage(
      name: AppRoute.staffDashboard,
      page: () => const StaffDashboardView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<StaffHomeViewModel>(() => StaffHomeViewModel());
        Get.lazyPut<TaskViewModel>(() => TaskViewModel());
        Get.lazyPut<MenuViewModel>(() => MenuViewModel());
      }),
    ),
    GetPage(
      name: AppRoute.staffInfo,
      page: () => const StaffInfoView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<StaffInfoViewModel>(() => StaffInfoViewModel());
      }),
    ),
    GetPage(
      name: AppRoute.staffTicketDetail,
      page: () => const StaffTicketDetailView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<StaffTicketDetailViewModel>(
          () => StaffTicketDetailViewModel(),
        );
      }),
    ),
    GetPage(
      name: AppRoute.staffSosList,
      page: () => const SOSListView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SOSListViewModel>(() => SOSListViewModel());
      }),
    ),
    GetPage(
      name: AppRoute.staffSosDetail,
      page: () => const SOSViewDetail(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SOSDetailViewModel>(() => SOSDetailViewModel());
      }),
    ),
    GetPage(
      name: AppRoute.staffSosRealtimeMap,
      page: () => const SOSRealtimeMapView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SOSRealtimeMapViewModel>(() => SOSRealtimeMapViewModel());
      }),
    ),
    GetPage(
      name: AppRoute.staffPerformance,
      page: () => const StaffPerformanceView(),
    ),
    GetPage(
      name: AppRoute.changePassword,
      page: () => const ChangePassView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AuthRepository>(() => ApiAuthRepository());
        Get.lazyPut<ChangePassViewModel>(
          () => ChangePassViewModel(authRepository: Get.find<AuthRepository>()),
        );
      }),
    ),
    GetPage(
      name: AppRoute.htmlDocument,
      page: () => const HtmlDocumentView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<HtmlDocumentViewModel>(() => HtmlDocumentViewModel());
      }),
    ),
    GetPage(
      name: AppRoute.notifications,
      page: () => const NotifyView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<NotifyViewModel>(() => NotifyViewModel());
      }),
    ),
  ];
}
