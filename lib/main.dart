import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Localization/AppTranslations.dart';
import 'package:hcmu_sos/Localization/LocaleManager.dart';
import 'package:hcmu_sos/Navigator/AppPage.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';
import 'package:hcmu_sos/Service/AuthSessionService.dart';
import 'package:hcmu_sos/Service/AuthSessionStorage.dart';
import 'package:hcmu_sos/Service/FcmService.dart';
import 'package:hcmu_sos/Service/PendingTicketSyncService.dart';
import 'package:hcmu_sos/Theme/AppTypography.dart';
import 'package:hcmu_sos/Utils/StorageManager.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _configureImagePicker();
  await StorageManager.init();
  ApiCaller.configure(
    baseUrl: 'https://appsos.htecom.com/api/v1/',
    tokenProvider: AuthSessionStorage.getAccessToken,
    refreshToken: () => AuthSessionService().refreshToken(),
  );
  runApp(const MyApp());
  unawaited(_startAppServices());
}

Future<void> _startAppServices() async {
  try {
    await FcmService.instance.init();
  } catch (error, stackTrace) {
    developer.log(
      'FCM initialization failed',
      name: 'main',
      error: error,
      stackTrace: stackTrace,
    );
  }

  try {
    await PendingTicketSyncService.instance.start();
  } catch (error, stackTrace) {
    developer.log(
      'Pending ticket sync failed to start',
      name: 'main',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

void _configureImagePicker() {
  final imagePickerImplementation = ImagePickerPlatform.instance;
  if (imagePickerImplementation is ImagePickerAndroid) {
    imagePickerImplementation.useAndroidPhotoPicker = true;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VNUHCM Smart Campus',
      translations: AppTranslations(),
      locale: LocaleManager.initialLocale,
      fallbackLocale: LocaleManager.fallbackLocale,
      supportedLocales: LocaleManager.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: .fromSeed(
          seedColor: const Color.fromARGB(255, 58, 183, 85),
        ),
        textTheme: AppTextStyles.textTheme(const Color(0xFF111827)),
      ),
      initialRoute: AppPage.initial,
      getPages: AppPage.pages,
    );
  }
}
