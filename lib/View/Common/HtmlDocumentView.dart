// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Theme/AppTypography.dart';
import 'package:hcmu_sos/ViewModel/Common/HtmlDocumentViewModel.dart';
import 'package:url_launcher/url_launcher.dart';

class HtmlDocumentView extends GetWidget<HtmlDocumentViewModel> {
  const HtmlDocumentView({super.key});

  static const Color _primaryColor = Color(0xFF29306F);
  static const Color _textColor = Color(0xFF242733);
  static const Color _mutedColor = Color(0xFF7A7D89);
  static const Color _borderColor = Color(0xFFE4E6F0);
  static const Color _surfaceColor = Color(0xFFF7F8FC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Obx(() => _Header(title: controller.title)),
            Expanded(
              child: Obx(() {
                final document = controller.document.value;

                if (controller.isLoading.value && document == null) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  );
                }

                final error = controller.errorMessage.value;
                if (error != null && document == null) {
                  return _StateMessage(
                    message: error,
                    onRetry: controller.loadDocument,
                  );
                }

                if (document == null || document.content.trim().isEmpty) {
                  return _StateMessage(
                    message: 'No content available.',
                    onRetry: controller.loadDocument,
                  );
                }

                return RefreshIndicator(
                  color: _primaryColor,
                  onRefresh: controller.loadDocument,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DocumentMetaCompact(
                          version: document.version,
                          updatedAt: document.updatedAt,
                        ),
                        const SizedBox(height: 10),
                        _HtmlContentCard(content: document.content),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> openUrl(String? value) async {
    if (value == null || value.trim().isEmpty) return;

    final uri = Uri.tryParse(value);
    if (uri == null) return;

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: HtmlDocumentView._borderColor, width: 0.7),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back<void>,
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            color: const Color(0xFF242733),
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.subtitle.copyWith(
                color: const Color(0xFF242733),
                fontSize: AppFontSizes.xl,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _DocumentMetaCompact extends StatelessWidget {
  const _DocumentMetaCompact({this.version, this.updatedAt});

  final String? version;
  final DateTime? updatedAt;

  @override
  Widget build(BuildContext context) {
    final updatedText = updatedAt == null
        ? null
        : '${updatedAt!.day.toString().padLeft(2, '0')}/'
              '${updatedAt!.month.toString().padLeft(2, '0')}/'
              '${updatedAt!.year}';

    final hasVersion = version != null && version!.trim().isNotEmpty;

    if (!hasVersion && updatedText == null) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (hasVersion)
          _MetaChip(icon: Icons.verified_outlined, text: 'v$version'),
        if (updatedText != null)
          _MetaChip(icon: Icons.update_rounded, text: updatedText),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: HtmlDocumentView._surfaceColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: HtmlDocumentView._borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: HtmlDocumentView._mutedColor, size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: HtmlDocumentView._mutedColor,
              fontSize: AppFontSizes.xs,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HtmlContentCard extends StatelessWidget {
  const _HtmlContentCard({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HtmlDocumentView._borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Html(
        data: content,
        onLinkTap: (url, _, _) => HtmlDocumentView.openUrl(url),
        style: {
          'body': Style(
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
            color: HtmlDocumentView._textColor,
            fontSize: FontSize(AppFontSizes.base),
            lineHeight: const LineHeight(1.55),
            fontWeight: FontWeight.w500,
          ),
          'p': Style(
            margin: Margins.only(bottom: 10),
            color: HtmlDocumentView._textColor,
            lineHeight: const LineHeight(1.55),
          ),
          'h1': Style(
            margin: Margins.only(bottom: 12),
            fontSize: FontSize(AppFontSizes.xl),
            fontWeight: FontWeight.w900,
            color: HtmlDocumentView._primaryColor,
            lineHeight: const LineHeight(1.25),
          ),
          'h2': Style(
            margin: Margins.only(top: 10, bottom: 10),
            fontSize: FontSize(AppFontSizes.lg),
            fontWeight: FontWeight.w900,
            color: HtmlDocumentView._primaryColor,
            lineHeight: const LineHeight(1.28),
          ),
          'h3': Style(
            margin: Margins.only(top: 8, bottom: 8),
            fontSize: FontSize(AppFontSizes.md),
            fontWeight: FontWeight.w900,
            color: HtmlDocumentView._textColor,
          ),
          'ul': Style(
            margin: Margins.only(left: 12, bottom: 12),
            padding: HtmlPaddings.only(left: 10),
          ),
          'ol': Style(
            margin: Margins.only(left: 12, bottom: 12),
            padding: HtmlPaddings.only(left: 10),
          ),
          'li': Style(
            margin: Margins.only(bottom: 7),
            lineHeight: const LineHeight(1.5),
          ),
          'strong': Style(
            fontWeight: FontWeight.w900,
            color: HtmlDocumentView._textColor,
          ),
          'b': Style(
            fontWeight: FontWeight.w900,
            color: HtmlDocumentView._textColor,
          ),
          'a': Style(
            color: HtmlDocumentView._primaryColor,
            textDecoration: TextDecoration.underline,
            fontWeight: FontWeight.w800,
          ),
          'blockquote': Style(
            margin: Margins.only(top: 8, bottom: 12),
            padding: HtmlPaddings.only(left: 12, top: 8, bottom: 8),
            backgroundColor: HtmlDocumentView._surfaceColor,
            border: const Border(
              left: BorderSide(color: HtmlDocumentView._primaryColor, width: 4),
            ),
          ),
        },
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
          decoration: BoxDecoration(
            color: HtmlDocumentView._surfaceColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: HtmlDocumentView._borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: HtmlDocumentView._primaryColor,
                size: 34,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: HtmlDocumentView._mutedColor,
                  fontSize: AppFontSizes.base,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: HtmlDocumentView._primaryColor,
                  side: const BorderSide(color: HtmlDocumentView._primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('common.retry'.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
