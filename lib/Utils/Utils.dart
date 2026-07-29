// ignore_for_file: file_names

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';
import 'package:hcmu_sos/Theme/AppTypography.dart';

class Utils {
  const Utils._();

  static void showSnackbar({
    required String title,
    required String content,
    SnackPosition position = SnackPosition.TOP,
    Duration duration = const Duration(seconds: 3),
    Color backgroundColor = Colors.white,
    Color textColor = const Color(0xFF111827),
    Color accentColor = const Color(0xFF2563EB),
    IconData icon = Icons.info_outline_rounded,
  }) {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.rawSnackbar(
      snackPosition: position,
      duration: duration,
      backgroundColor: Colors.transparent,
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: EdgeInsets.zero,
      borderRadius: 18,
      maxWidth: 560,
      messageText: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(width: 5, color: accentColor),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: accentColor, size: 22),
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.snackbarTitle.copyWith(
                                  color: textColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                content,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.snackbarContent.copyWith(
                                  color: const Color(0xFF4B5563),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
      animationDuration: const Duration(milliseconds: 260),
    );
  }

  static Future<int> uploadFile({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String purpose,
    bool skipAuth = false,
  }) async {
    final response = await ApiCaller.getInstance().postBase<Object?>(
      'file/upload',
      <String, dynamic>{
        'file': base64Encode(bytes),
        'file_name': fileName,
        'mime_type': mimeType,
        'purpose': purpose,
      },
      options: skipAuth
          ? Options(extra: <String, dynamic>{'skipAuth': true})
          : null,
    );

    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Upload failed.',
        code: response.code,
        data: response.raw,
      );
    }

    final fileId = _extractFileId(response.data);
    if (fileId == null) {
      throw ApiException(
        message: 'Upload response does not contain file id.',
        code: 'decode_error',
        data: response.raw,
      );
    }

    return fileId;
  }

  static int? _extractFileId(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    if (value is Map) {
      for (final key in const ['id', 'file_id', 'fileId', 'attachment_id']) {
        final id = _extractFileId(value[key]);
        if (id != null) {
          return id;
        }
      }
    }
    return null;
  }
}
