// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Component/ImagePreviewViewer.dart';
import 'package:hcmu_sos/Component/InteractiveTileMap.dart';
import 'package:hcmu_sos/Entity/SupportRequestEntity.dart';
import 'package:hcmu_sos/Navigator/AppRoute.dart';
import 'package:hcmu_sos/Theme/AppTypography.dart';
import 'package:hcmu_sos/Utils/ApiAssetUrl.dart';
import 'package:hcmu_sos/ViewModel/Student/TicketDetailViewModel.dart';
import 'package:url_launcher/url_launcher.dart';

class TicketDetailView extends GetWidget<TicketDetailViewModel> {
  const TicketDetailView({super.key});

  static const Color _primaryColor = Color(0xFF29306F);
  static const Color _dangerColor = Color(0xFFF82D37);
  static const Color _pageColor = Colors.white;
  static const Color _surfaceColor = Color(0xFFF7F8FC);
  static const Color _borderColor = Color(0xFFE2E4F0);
  static const Color _textColor = Color(0xFF242733);
  static const Color _mutedColor = Color(0xFF7A7D89);
  static const double _cardRadius = 16;
  static const double _controlRadius = 14;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value &&
                    controller.detail.value == null) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  );
                }

                final error = controller.errorMessage.value;
                final detail = controller.detail.value;
                if (error != null && detail == null) {
                  return _StateMessage(
                    message: error,
                    onRetry: controller.loadDetail,
                  );
                }
                if (detail == null) {
                  return _StateMessage(
                    message: 'ticket.detail.noData'.tr,
                    onRetry: controller.loadDetail,
                  );
                }

                final hasMeta = _hasMeta(detail);
                final hasStaff =
                    detail.assignedStaff != null &&
                    _hasText(detail.assignedStaff!.name);
                final timeline = _displayTimeline(detail);
                final hasTimeline = timeline.isNotEmpty;
                final hasAcceptance = _hasAcceptance(detail.acceptance);
                final hasRating = _hasRating(detail.rating);
                if (!hasRating &&
                    detail.status == SupportRequestStatus.done &&
                    controller.takeOpenRatingRequest()) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      _openRatingDialog(context, detail);
                    }
                  });
                }

                return RefreshIndicator(
                  color: _primaryColor,
                  onRefresh: controller.loadDetail,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SummarySection(detail: detail),
                        if (hasMeta) ...[
                          const SizedBox(height: 18),
                          _MetaGrid(detail: detail),
                        ],
                        if (_hasLocation(detail.location)) ...[
                          const SizedBox(height: 14),
                          _LocationSection(location: detail.location!),
                        ],
                        if (hasStaff) ...[
                          const SizedBox(height: 14),
                          _StaffCard(
                            staff: detail.assignedStaff!,
                            showZaloAction: detail.isSos,
                          ),
                        ],
                        if (hasTimeline) ...[
                          const SizedBox(height: 14),
                          _TimelineCard(
                            items: timeline,
                            currentStatus: detail.status,
                          ),
                        ],
                        if (hasAcceptance) ...[
                          const SizedBox(height: 14),
                          _AcceptanceSection(
                            acceptance: detail.acceptance!,
                            ticketId: detail.id,
                          ),
                        ],
                        if (hasRating) ...[
                          const SizedBox(height: 14),
                          _RatingSection(rating: detail.rating!),
                        ],
                        const SizedBox(height: 84),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
          child: Obx(() {
            final detail = controller.detail.value;
            final canRate = detail?.status == SupportRequestStatus.done;
            return Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: canRate && !controller.isSubmittingRating.value
                        ? () => _openRatingDialog(context, detail!)
                        : null,
                    icon: const Icon(Icons.star_border_rounded, size: 20),
                    label: Text('ticket.detail.rating'.tr),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryColor,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_controlRadius),
                      ),
                      textStyle: AppTextStyles.bodyStrong.copyWith(
                        fontSize: AppFontSizes.md,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: detail == null
                        ? null
                        : () => Get.toNamed(
                            AppRoute.commentTicket,
                            arguments: <String, dynamic>{
                              'thread_id': detail.id,
                              'incident_code': detail.code,
                              'incident_title': detail.title,
                              'status': _statusCode(detail.status),
                            },
                          ),
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 19,
                    ),
                    label: Text('ticket.detail.chat'.tr),
                    style: FilledButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_controlRadius),
                      ),
                      textStyle: AppTextStyles.bodyStrong.copyWith(
                        fontSize: AppFontSizes.md,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Future<void> _openRatingDialog(
    BuildContext context,
    SupportRequestDetailEntity detail,
  ) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (_) => _RatingDialog(controller: controller, detail: detail),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 8, 18, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back<void>(),
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            color: TicketDetailView._textColor,
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Text(
              'ticket.detail.title'.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.subtitle.copyWith(
                color: TicketDetailView._textColor,
                fontSize: AppFontSizes.xl,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.detail});

  final SupportRequestDetailEntity detail;

  @override
  Widget build(BuildContext context) {
    final status = _StatusStyle.fromStatus(detail.status);
    final priority = _PriorityStyle.fromPriority(detail.priority);
    final images = _displayImages(detail.images);
    final imageUrls = _imageUrls(images);
    final heroPrefix = 'ticket-${detail.id}-images';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: priority.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            _CodePill(code: detail.code),
            if (detail.isSos) ...[
              const SizedBox(width: 8),
              const _RequestTypePill(),
            ],
            const SizedBox(width: 8),
            Flexible(child: _StatusPill(style: status)),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          detail.title,
          style: AppTextStyles.subtitle.copyWith(
            color: TicketDetailView._textColor,
            fontSize: AppFontSizes.lg,
            fontWeight: FontWeight.w900,
            height: 1.25,
          ),
        ),
        if (_hasText(detail.description)) ...[
          const SizedBox(height: 8),
          Text(
            detail.description!,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(
              color: const Color(0xFF555B69),
              fontSize: AppFontSizes.base,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (images.isNotEmpty) ...[
          const SizedBox(height: 14),
          _SectionTitle('ticket.detail.conditionImages'.tr),
          const SizedBox(height: 8),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, index) => _ImageTile(
                imageUrl: imageUrls[index],
                imageUrls: imageUrls,
                initialIndex: index,
                heroTagPrefix: heroPrefix,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MetaGrid extends StatelessWidget {
  const _MetaGrid({required this.detail});

  final SupportRequestDetailEntity detail;

  @override
  Widget build(BuildContext context) {
    final items = [
      if (_hasText(detail.incidentType?.name))
        _MetaItem(
          icon: _iconForIncident(detail.incidentType?.code),
          label: 'ticket.detail.incidentType'.tr,
          value: detail.incidentType!.name,
        ),
      _MetaItem(
        icon: Icons.fact_check_outlined,
        label: 'ticket.detail.priority'.tr,
        value: _priorityLabel(detail.priority),
      ),
      if (_hasText(detail.location?.text))
        _MetaItem(
          icon: Icons.location_on_outlined,
          label: 'ticket.detail.location'.tr,
          value: detail.location!.text!,
        ),
      if (detail.createdAt != null)
        _MetaItem(
          icon: Icons.calendar_month_outlined,
          label: 'ticket.detail.createdAt'.tr,
          value: _formatDateTime(detail.createdAt!),
        ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TicketDetailView._borderColor),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _MetaRow(item: items[i]),
            if (i != items.length - 1)
              const Divider(
                height: 1,
                indent: 58,
                endIndent: 14,
                color: Color(0xFFE8EAF2),
              ),
          ],
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.item});

  final _MetaItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.icon,
              color: TicketDetailView._primaryColor,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: AppTextStyles.caption.copyWith(
                    color: TicketDetailView._mutedColor,
                    fontSize: AppFontSizes.sm,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: TicketDetailView._primaryColor,
                    fontSize: AppFontSizes.md,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaItem {
  const _MetaItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _LocationSection extends StatelessWidget {
  const _LocationSection({required this.location});

  final RequestLocationEntity location;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'ticket.detail.location'.tr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_hasText(location.text))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: TicketDetailView._surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TicketDetailView._borderColor),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.place_outlined,
                    color: TicketDetailView._primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      location.text!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: TicketDetailView._textColor,
                        fontSize: AppFontSizes.md,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (location.latitude != null && location.longitude != null) ...[
            const SizedBox(height: 10),
            InteractiveTileMap(
              latitude: location.latitude!,
              longitude: location.longitude!,
              primaryColor: TicketDetailView._primaryColor,
              dangerColor: TicketDetailView._dangerColor,
              borderColor: TicketDetailView._borderColor,
              onDirections: () =>
                  _openDirections(location.latitude!, location.longitude!),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({required this.item, this.fullWidth = false});

  final _MetaItem item;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: fullWidth ? 74 : 82),
      padding: EdgeInsets.symmetric(
        horizontal: fullWidth ? 14 : 12,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(TicketDetailView._cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              item.icon,
              color: TicketDetailView._primaryColor,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: TicketDetailView._mutedColor,
                    fontSize: AppFontSizes.md,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  maxLines: fullWidth ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: TicketDetailView._primaryColor,
                    fontSize: AppFontSizes.md,
                    fontWeight: FontWeight.w900,
                    height: 1.22,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard({required this.staff, required this.showZaloAction});

  final AssignedStaffEntity staff;
  final bool showZaloAction;

  @override
  Widget build(BuildContext context) {
    final name = staff.name;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(TicketDetailView._cardRadius),
        border: Border.all(color: TicketDetailView._borderColor),
      ),
      child: Row(
        children: [
          _Avatar(name: name, imageUrl: staff.avatarUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ticket.detail.staff'.tr,
                  style: AppTextStyles.caption.copyWith(
                    color: TicketDetailView._mutedColor,
                    fontSize: AppFontSizes.xs,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: TicketDetailView._textColor,
                    fontSize: AppFontSizes.md,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          _ContactButtons(phone: staff.phone, showZaloAction: showZaloAction),
        ],
      ),
    );
  }
}

class _ContactButtons extends StatelessWidget {
  const _ContactButtons({this.phone, required this.showZaloAction});

  final String? phone;
  final bool showZaloAction;

  @override
  Widget build(BuildContext context) {
    final enabled = _hasText(phone);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showZaloAction) ...[
          _ActionCircleButton(
            enabled: enabled,
            outerColor: Colors.transparent,
            outerBorderColor: Colors.transparent,
            innerColor: Colors.transparent,
            outerSize: 38,
            innerSize: 38,
            onTap: enabled ? () => _openZalo(phone!) : null,
            child: ClipOval(
              child: Image.asset(
                'assets/icon/icon_zalo.png',
                width: 38,
                height: 38,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        _ActionCircleButton(
          enabled: enabled,
          outerColor: enabled
              ? const Color(0xFFE8F8EF)
              : const Color(0xFFF1F2F5),
          outerBorderColor: enabled
              ? const Color(0xFFC8EFD8)
              : const Color(0xFFE2E4F0),
          innerColor: enabled
              ? const Color(0xFF21AD57)
              : const Color(0xFFB7BBC8),
          outerSize: 50,
          innerSize: 36,
          onTap: enabled ? () => _callPhone(phone!) : null,
          child: const Icon(
            Icons.phone_in_talk_rounded,
            color: Colors.white,
            size: 21,
          ),
        ),
      ],
    );
  }
}

class _ActionCircleButton extends StatelessWidget {
  const _ActionCircleButton({
    required this.enabled,
    required this.outerColor,
    required this.outerBorderColor,
    required this.innerColor,
    required this.child,
    this.outerSize = 58,
    this.innerSize = 38,
    this.onTap,
  });

  final bool enabled;
  final Color outerColor;
  final Color outerBorderColor;
  final Color innerColor;
  final Widget child;
  final double outerSize;
  final double innerSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        width: outerSize,
        height: outerSize,
        decoration: BoxDecoration(
          color: outerColor,
          shape: BoxShape.circle,
          border: Border.all(color: outerBorderColor),
          boxShadow: enabled
              ? const [
                  BoxShadow(
                    color: Color(0x1429306F),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Container(
            width: innerSize,
            height: innerSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: innerColor,
              shape: BoxShape.circle,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

Future<void> _callPhone(String phone) async {
  final normalizedPhone = _normalizePhoneForCall(phone);
  final uri = Uri(scheme: 'tel', path: normalizedPhone);
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched) {
    Get.snackbar(
      'ticket.detail.contact'.tr,
      phone,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

Future<void> _openZalo(String phone) async {
  final normalizedPhone = _normalizePhoneForZalo(phone);
  final uri = Uri.parse('https://zalo.me/$normalizedPhone');
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched) {
    Get.snackbar(
      'ticket.detail.contact'.tr,
      phone,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

String _normalizePhoneForCall(String phone) {
  return phone.replaceAll(RegExp(r'\s+'), '');
}

String _normalizePhoneForZalo(String phone) {
  return phone.replaceAll(RegExp(r'[^0-9]'), '');
}

class _TimelineVisual {
  const _TimelineVisual({
    required this.color,
    required this.background,
    required this.icon,
    required this.badgeText,
    required this.description,
  });

  final Color color;
  final Color background;
  final IconData icon;
  final String badgeText;
  final String description;

  factory _TimelineVisual.fromItem(
    RequestTimelineEntity item,
    SupportRequestStatus currentStatus,
  ) {
    final status = item.status.toLowerCase();
    if (status == 'rejected') {
      return _TimelineVisual(
        color: TicketDetailView._dangerColor,
        background: const Color(0xFFFFEEF0),
        icon: Icons.close_rounded,
        badgeText: 'status.rejected'.tr,
        description: 'ticket.detail.timeline.rejected'.tr,
      );
    }

    if (!item.reached) {
      return _TimelineVisual(
        color: const Color(0xFFB7BBC8),
        background: const Color(0xFFF4F4F5),
        icon: Icons.radio_button_unchecked_rounded,
        badgeText: 'ticket.detail.pending'.tr,
        description: _pendingTimelineDescription(status),
      );
    }

    if (status == _statusCode(currentStatus) &&
        currentStatus != SupportRequestStatus.done &&
        currentStatus != SupportRequestStatus.rejected) {
      return _TimelineVisual(
        color: const Color(0xFF3E8BFF),
        background: const Color(0xFFEAF3FF),
        icon: Icons.schedule_rounded,
        badgeText: _currentTimelineBadge(status),
        description: _currentTimelineDescription(status),
      );
    }

    return _TimelineVisual(
      color: const Color(0xFF21AD57),
      background: const Color(0xFFEAF8EF),
      icon: Icons.check_circle_outline_rounded,
      badgeText: 'ticket.detail.done'.tr,
      description: _doneTimelineDescription(status),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.items, required this.currentStatus});

  final List<RequestTimelineEntity> items;
  final SupportRequestStatus currentStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(TicketDetailView._cardRadius),
        border: Border.all(color: TicketDetailView._borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Text(
              'ticket.detail.timeline'.tr,
              style: AppTextStyles.bodyStrong.copyWith(
                color: TicketDetailView._textColor,
                fontSize: AppFontSizes.md,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Divider(height: 1, color: TicketDetailView._borderColor),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++)
                  _TimelineItem(
                    item: items[i],
                    isLast: i == items.length - 1,
                    currentStatus: currentStatus,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.item,
    required this.isLast,
    required this.currentStatus,
  });

  final RequestTimelineEntity item;
  final bool isLast;
  final SupportRequestStatus currentStatus;

  @override
  Widget build(BuildContext context) {
    final visual = _TimelineVisual.fromItem(item, currentStatus);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: visual.color, width: 1.6),
                  ),
                  child: Icon(visual.icon, color: visual.color, size: 15),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: visual.color.withValues(alpha: 0.24),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
              padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
              decoration: BoxDecoration(
                color: visual.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: visual.color.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyStrong.copyWith(
                            color: TicketDetailView._textColor,
                            fontSize: AppFontSizes.md,
                            fontWeight: FontWeight.w900,
                            height: 1.22,
                          ),
                        ),
                      ),
                      if (item.date != null) ...[
                        const SizedBox(width: 8),
                        _TimelineTime(value: item.date!),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    visual.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFF697181),
                      fontSize: AppFontSizes.base,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _TimelineBadge(
                        text: visual.badgeText,
                        color: visual.color,
                      ),
                      if (item.date != null) ...[
                        const SizedBox(width: 8),
                        _TimelineDateChip(
                          value: item.date!,
                          color: visual.color,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineTime extends StatelessWidget {
  const _TimelineTime({required this.value});

  final DateTime value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _formatTime(value),
        style: AppTextStyles.caption.copyWith(
          color: TicketDetailView._primaryColor,
          fontSize: AppFontSizes.base,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _TimelineDateChip extends StatelessWidget {
  const _TimelineDateChip({required this.value, required this.color});

  final DateTime value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Text(
        _formatShortDate(value),
        style: AppTextStyles.caption.copyWith(
          color: const Color(0xFF697181),
          fontSize: AppFontSizes.xs,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class _TimelineBadge extends StatelessWidget {
  const _TimelineBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontSize: AppFontSizes.xs,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class _AcceptanceSection extends StatelessWidget {
  const _AcceptanceSection({required this.acceptance, required this.ticketId});

  final RequestAcceptanceEntity acceptance;
  final int ticketId;

  @override
  Widget build(BuildContext context) {
    final images = _displayImages(acceptance.images);
    final imageUrls = _imageUrls(images);
    final heroPrefix = 'ticket-$ticketId-acceptance-images';
    final hasNote = _hasText(acceptance.note);
    final hasMeta = hasNote || acceptance.date != null;
    final hasImages = images.isNotEmpty;
    return _SectionCard(
      title: 'ticket.detail.acceptance'.tr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasMeta)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6FBF8),
                borderRadius: BorderRadius.circular(
                  TicketDetailView._controlRadius,
                ),
                border: Border.all(color: const Color(0xFFDCEFE4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1F7EA),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.task_alt_rounded,
                      color: Color(0xFF20A85A),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ticket.detail.acceptanceNote'.tr,
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFF667085),
                            fontSize: AppFontSizes.xs,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (hasNote) const SizedBox(height: 3),
                        if (hasNote)
                          Text(
                            acceptance.note!,
                            style: AppTextStyles.body.copyWith(
                              color: const Color(0xFF344054),
                              fontSize: AppFontSizes.md,
                              fontWeight: FontWeight.w700,
                              height: 1.32,
                            ),
                          ),
                        if (acceptance.date != null) ...[
                          if (hasNote) const SizedBox(height: 5),
                          Text(
                            _formatDateTime(acceptance.date!),
                            style: AppTextStyles.caption.copyWith(
                              color: TicketDetailView._mutedColor,
                              fontSize: AppFontSizes.sm,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (hasImages) ...[
            if (hasMeta) const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  color: TicketDetailView._primaryColor,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'ticket.detail.acceptanceImages'.tr,
                    style: AppTextStyles.caption.copyWith(
                      color: TicketDetailView._textColor,
                      fontSize: AppFontSizes.sm,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: TicketDetailView._surfaceColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${images.length}',
                    style: AppTextStyles.caption.copyWith(
                      color: TicketDetailView._primaryColor,
                      fontSize: AppFontSizes.xs,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 130,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, index) => _ImageTile(
                  imageUrl: imageUrls[index],
                  imageUrls: imageUrls,
                  initialIndex: index,
                  heroTagPrefix: heroPrefix,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.bodyStrong.copyWith(
        color: TicketDetailView._textColor,
        fontSize: AppFontSizes.md,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _RatingSection extends StatelessWidget {
  const _RatingSection({required this.rating});

  final RequestRatingEntity rating;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'ticket.detail.rating'.tr,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFAEC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFFE7AA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF2CA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFFFB820),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(
                          5,
                          (index) => Icon(
                            index < rating.rating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: const Color(0xFFFFB820),
                            size: 21,
                          ),
                        ),
                      ),
                      if (rating.createdAt != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          _formatDateTime(rating.createdAt!),
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFF8A7280),
                            fontSize: AppFontSizes.base,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (_hasText(rating.comment)) ...[
              const SizedBox(height: 10),
              Text(
                rating.comment!,
                style: AppTextStyles.body.copyWith(
                  color: const Color(0xFF4E5562),
                  fontSize: AppFontSizes.md,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RatingDialog extends StatefulWidget {
  const _RatingDialog({required this.controller, required this.detail});

  final TicketDetailViewModel controller;
  final SupportRequestDetailEntity detail;

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  late final TextEditingController _commentController;
  late int _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.detail.rating?.rating ?? 5;
    _commentController = TextEditingController(
      text: widget.detail.rating?.comment ?? '',
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final incidentName = widget.detail.incidentType?.name;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18),
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 28,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              Text(
                'ticket.rating.title'.tr,
                textAlign: TextAlign.center,
                style: AppTextStyles.subtitle.copyWith(
                  color: TicketDetailView._primaryColor,
                  fontSize: AppFontSizes.xl,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                [
                  widget.detail.code,
                  if (_hasText(incidentName)) incidentName!,
                ].join(' • '),
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: TicketDetailView._mutedColor,
                  fontSize: AppFontSizes.base,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 22),
              const _RatingSuccessMark(),
              const SizedBox(height: 22),
              Text(
                'ticket.rating.satisfaction'.tr,
                style: AppTextStyles.caption.copyWith(
                  color: TicketDetailView._mutedColor,
                  fontSize: AppFontSizes.base,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _RatingStars(
                rating: _rating,
                onChanged: (value) => setState(() => _rating = value),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _commentController,
                minLines: 3,
                maxLines: 4,
                maxLength: 300,
                style: AppTextStyles.body.copyWith(
                  color: TicketDetailView._textColor,
                  fontSize: AppFontSizes.md,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'ticket.rating.commentHint'.tr,
                  hintStyle: AppTextStyles.body.copyWith(
                    color: const Color(0xFF9AA1AE),
                    fontSize: AppFontSizes.md,
                    fontWeight: FontWeight.w600,
                  ),
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: TicketDetailView._borderColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: TicketDetailView._primaryColor,
                      width: 1.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Obx(
                () => SizedBox(
                  width: 150,
                  height: 48,
                  child: FilledButton(
                    onPressed: widget.controller.isSubmittingRating.value
                        ? null
                        : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: TicketDetailView._primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: AppTextStyles.bodyStrong.copyWith(
                        fontSize: AppFontSizes.md,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    child: widget.controller.isSubmittingRating.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Text('ticket.rating.submit'.tr),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final success = await widget.controller.submitRating(
      rating: _rating,
      comment: _commentController.text,
    );
    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _RatingSuccessMark extends StatelessWidget {
  const _RatingSuccessMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      height: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < 4; i++)
            Container(
              width: 72 + i * 18,
              height: 72 + i * 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFECEFF6)),
              ),
            ),
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFF55D6A4),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingStars extends StatelessWidget {
  const _RatingStars({required this.rating, required this.onChanged});

  final int rating;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final value = index + 1;
        final selected = value <= rating;
        return IconButton(
          onPressed: () => onChanged(value),
          icon: Icon(
            selected ? Icons.star_rounded : Icons.star_border_rounded,
            color: const Color(0xFFFFB820),
            size: 34,
          ),
          visualDensity: VisualDensity.compact,
        );
      }),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(TicketDetailView._cardRadius),
        border: Border.all(color: TicketDetailView._borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyStrong.copyWith(
              color: TicketDetailView._textColor,
              fontSize: AppFontSizes.md,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({
    required this.imageUrl,
    required this.imageUrls,
    required this.initialIndex,
    required this.heroTagPrefix,
    this.width = 214,
    this.height = 130,
  });

  final String imageUrl;
  final List<String> imageUrls;
  final int initialIndex;
  final String heroTagPrefix;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final heroTag = ImagePreviewViewer.heroTag(heroTagPrefix, initialIndex);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => ImagePreviewViewer.show(
          context,
          imageUrls: imageUrls,
          initialIndex: initialIndex,
          heroTagPrefix: heroTagPrefix,
        ),
        borderRadius: BorderRadius.circular(TicketDetailView._cardRadius),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(TicketDetailView._cardRadius),
          child: Hero(
            tag: heroTag,
            child: Image.network(
              imageUrl,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _imageFallback(width, height),
            ),
          ),
        ),
      ),
    );
  }

  Widget _imageFallback(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: TicketDetailView._surfaceColor,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: TicketDetailView._mutedColor,
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.imageUrl});

  final String name;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Container(
      width: 46,
      height: 46,
      decoration: const BoxDecoration(
        color: Color(0xFFE7E6F4),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: ClipOval(
        child: imageUrl == null
            ? Text(
                initials.isEmpty ? 'SV' : initials,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: TicketDetailView._primaryColor,
                  fontSize: AppFontSizes.md,
                  fontWeight: FontWeight.w900,
                ),
              )
            : Image.network(
                imageUrl!,
                width: 46,
                height: 46,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: Text(
                    initials.isEmpty ? 'SV' : initials,
                    style: AppTextStyles.bodyStrong.copyWith(
                      color: TicketDetailView._primaryColor,
                      fontSize: AppFontSizes.md,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _CodePill extends StatelessWidget {
  const _CodePill({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: TicketDetailView._surfaceColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        code,
        style: AppTextStyles.caption.copyWith(
          color: const Color(0xFF687080),
          fontSize: AppFontSizes.base,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.style});

  final _StatusStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 14, color: style.foreground),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              style.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: style.foreground,
                fontSize: AppFontSizes.base,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestTypePill extends StatelessWidget {
  const _RequestTypePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEF0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        Get.locale?.languageCode == 'en' ? 'SOS' : 'SOS',
        style: AppTextStyles.caption.copyWith(
          color: TicketDetailView._dangerColor,
          fontSize: AppFontSizes.base,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.assignment_late_outlined,
              color: TicketDetailView._primaryColor,
              size: 42,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: TicketDetailView._mutedColor,
                fontSize: AppFontSizes.md,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onRetry, child: Text('common.retry'.tr)),
          ],
        ),
      ),
    );
  }
}

class _StatusStyle {
  const _StatusStyle({
    required this.label,
    required this.foreground,
    required this.background,
    required this.icon,
  });

  final String label;
  final Color foreground;
  final Color background;
  final IconData icon;

  factory _StatusStyle.fromStatus(SupportRequestStatus status) {
    return switch (status) {
      SupportRequestStatus.pending => _StatusStyle(
        label: 'status.pending'.tr,
        foreground: Colors.white,
        background: const Color(0xFF18A8BA),
        icon: Icons.hourglass_empty_rounded,
      ),
      SupportRequestStatus.inProgress => _StatusStyle(
        label: 'status.in_progress'.tr,
        foreground: const Color(0xFF5D31D6),
        background: const Color(0xFFECE5FF),
        icon: Icons.schedule_rounded,
      ),
      SupportRequestStatus.reopened => _StatusStyle(
        label: 'status.reopened'.tr,
        foreground: const Color(0xFF2D6CDF),
        background: const Color(0xFFE8F1FF),
        icon: Icons.refresh_rounded,
      ),
      SupportRequestStatus.rejected => _StatusStyle(
        label: 'status.rejected'.tr,
        foreground: Colors.white,
        background: TicketDetailView._dangerColor,
        icon: Icons.close_rounded,
      ),
      SupportRequestStatus.done => _StatusStyle(
        label: 'status.done'.tr,
        foreground: const Color(0xFF21AD57),
        background: const Color(0xFFE5F8EE),
        icon: Icons.check_circle_outline_rounded,
      ),
    };
  }
}

class _PriorityStyle {
  const _PriorityStyle({required this.color});

  final Color color;

  factory _PriorityStyle.fromPriority(SupportRequestPriority priority) {
    return switch (priority) {
      SupportRequestPriority.normal => const _PriorityStyle(
        color: Color(0xFFFFC247),
      ),
      SupportRequestPriority.high => const _PriorityStyle(
        color: Color(0xFFFF7E6E),
      ),
      SupportRequestPriority.urgent => const _PriorityStyle(
        color: TicketDetailView._dangerColor,
      ),
    };
  }
}

String _priorityLabel(SupportRequestPriority priority) {
  return switch (priority) {
    SupportRequestPriority.normal => 'priority.normal'.tr,
    SupportRequestPriority.high => 'priority.high'.tr,
    SupportRequestPriority.urgent => 'priority.urgent'.tr,
  };
}

IconData _iconForIncident(String? code) {
  return switch (code?.toLowerCase()) {
    'medical' || 'health' || 'y_te' => Icons.monitor_heart_outlined,
    'security' || 'antt' => Icons.shield_outlined,
    'environment' || 'moi_truong' => Icons.recycling_rounded,
    'infrastructure' || 'ha_tang' => Icons.foundation_outlined,
    'disaster' || 'thien_tai' => Icons.thunderstorm_outlined,
    'fire' || 'chay_no' => Icons.local_fire_department_outlined,
    _ => Icons.warning_amber_rounded,
  };
}

String _formatDateTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$hour:$minute - $day/$month/${value.year}';
}

String _formatTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatShortDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

bool _hasText(String? value) {
  return value != null && value.trim().isNotEmpty;
}

bool _hasLocation(RequestLocationEntity? location) {
  if (location == null) {
    return false;
  }
  return _hasText(location.text) ||
      (location.latitude != null && location.longitude != null);
}

bool _hasMeta(SupportRequestDetailEntity detail) {
  return true;
}

bool _hasAcceptance(RequestAcceptanceEntity? acceptance) {
  if (acceptance == null) {
    return false;
  }
  return _hasText(acceptance.note) ||
      _displayImages(acceptance.images).isNotEmpty;
}

bool _hasRating(RequestRatingEntity? rating) {
  if (rating == null) {
    return false;
  }
  return rating.rating > 0 || _hasText(rating.comment);
}

List<RequestImageEntity> _displayImages(List<RequestImageEntity> images) {
  return images
      .where((image) => ApiAssetUrl.resolve(image.url) != null)
      .toList();
}

List<String> _imageUrls(List<RequestImageEntity> images) {
  return images
      .map((image) => ApiAssetUrl.resolve(image.url))
      .whereType<String>()
      .toList();
}

List<RequestTimelineEntity> _displayTimeline(
  SupportRequestDetailEntity detail,
) {
  return detail.timeline.where((item) {
    if (!_hasText(item.label)) {
      return false;
    }
    if (item.status.toLowerCase() != 'rejected') {
      return true;
    }
    return detail.status == SupportRequestStatus.rejected &&
        (item.reached || item.date != null);
  }).toList();
}

String _statusCode(SupportRequestStatus status) {
  return switch (status) {
    SupportRequestStatus.pending => 'pending',
    SupportRequestStatus.inProgress => 'in_progress',
    SupportRequestStatus.reopened => 'reopened',
    SupportRequestStatus.done => 'done',
    SupportRequestStatus.rejected => 'rejected',
  };
}

Future<void> _openDirections(double latitude, double longitude) async {
  final uri = Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': '$latitude,$longitude',
    'travelmode': 'driving',
  });
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

String _currentTimelineBadge(String status) {
  return switch (status) {
    'reopened' => 'status.reopened'.tr,
    'in_progress' => 'status.in_progress'.tr,
    _ => 'status.pending'.tr,
  };
}

String _doneTimelineDescription(String status) {
  return switch (status) {
    'pending' => 'ticket.detail.timeline.createdDone'.tr,
    'in_progress' => 'ticket.detail.timeline.inProgressDone'.tr,
    'reopened' => 'ticket.detail.timeline.reopenedDone'.tr,
    'done' => 'ticket.detail.timeline.doneDone'.tr,
    _ => 'ticket.detail.timeline.stepDone'.tr,
  };
}

String _currentTimelineDescription(String status) {
  return switch (status) {
    'reopened' => 'ticket.detail.timeline.reopenedCurrent'.tr,
    'in_progress' => 'ticket.detail.timeline.inProgressCurrent'.tr,
    _ => 'ticket.detail.timeline.pendingCurrent'.tr,
  };
}

String _pendingTimelineDescription(String status) {
  return switch (status) {
    'in_progress' => 'ticket.detail.timeline.inProgressPending'.tr,
    'reopened' => 'ticket.detail.timeline.reopenedPending'.tr,
    'done' => 'ticket.detail.timeline.donePending'.tr,
    _ => 'ticket.detail.timeline.stepPending'.tr,
  };
}
