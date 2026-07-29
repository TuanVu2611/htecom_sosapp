// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Theme/AppTypography.dart';

class ExitAppConfirmScope extends StatefulWidget {
  const ExitAppConfirmScope({super.key, required this.child});

  final Widget child;

  @override
  State<ExitAppConfirmScope> createState() => _ExitAppConfirmScopeState();
}

class _ExitAppConfirmScopeState extends State<ExitAppConfirmScope> {
  bool _showingDialog = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _confirmExit();
      },
      child: widget.child,
    );
  }

  Future<void> _confirmExit() async {
    if (_showingDialog) return;

    _showingDialog = true;
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            _text(vi: 'Đóng ứng dụng?', en: 'Close app?'),
            style: AppTextStyles.title.copyWith(
              color: const Color(0xFF29306F),
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            _text(
              vi: 'Bạn có muốn đóng ứng dụng không?',
              en: 'Do you want to close the app?',
            ),
            style: AppTextStyles.body.copyWith(
              color: const Color(0xFF4B5563),
              height: 1.35,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('common.cancel'.tr),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF29306F),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(_text(vi: 'Đóng', en: 'Close')),
            ),
          ],
        );
      },
    );

    _showingDialog = false;
    if (!mounted || shouldExit != true) return;

    SystemNavigator.pop();
  }

  String _text({required String vi, required String en}) {
    return Get.locale?.languageCode == 'en' ? en : vi;
  }
}
