// ignore_for_file: file_names

import 'package:flutter/material.dart';

class AppFontSizes {
  const AppFontSizes._();

  static const double xs = 11;
  static const double sm = 12;
  static const double base = 13;
  static const double md = 14;
  static const double lg = 16;
  static const double xl = 18;
  static const double xxl = 20;
  static const double h3 = 24;
  static const double h2 = 28;
  static const double h1 = 32;
}

class AppTextStyles {
  const AppTextStyles._();

  static const String? fontFamily = null;

  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppFontSizes.h1,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppFontSizes.h2,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppFontSizes.h3,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  static const TextStyle title = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppFontSizes.xl,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppFontSizes.lg,
    fontWeight: FontWeight.w500,
    height: 1.35,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppFontSizes.md,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppFontSizes.md,
    fontWeight: FontWeight.w600,
    height: 1.45,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppFontSizes.sm,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppFontSizes.md,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const TextStyle snackbarTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppFontSizes.md,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const TextStyle snackbarContent = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppFontSizes.base,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );

  static TextTheme textTheme(Color textColor) {
    return TextTheme(
      displayLarge: h1.copyWith(color: textColor),
      displayMedium: h2.copyWith(color: textColor),
      displaySmall: h3.copyWith(color: textColor),
      titleLarge: title.copyWith(color: textColor),
      titleMedium: subtitle.copyWith(color: textColor),
      bodyLarge: body.copyWith(color: textColor),
      bodyMedium: body.copyWith(color: textColor),
      bodySmall: caption.copyWith(color: textColor),
      labelLarge: button.copyWith(color: textColor),
    );
  }
}
