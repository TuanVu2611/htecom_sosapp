// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/SupportRequestEntity.dart';
import 'package:hcmu_sos/Navigator/AppRoute.dart';
import 'package:hcmu_sos/Theme/AppTypography.dart';
import 'package:hcmu_sos/ViewModel/Staff/StaffHomeViewModel.dart';

String _localized({required String vi, required String en}) {
  return Get.locale?.languageCode == 'en' ? en : vi;
}

class StaffHomeView extends GetWidget<StaffHomeViewModel> {
  const StaffHomeView({super.key, this.onSeeMoreTasks});

  final VoidCallback? onSeeMoreTasks;

  static const Color _primaryColor = Color(0xFF29306F);
  static const Color _dangerColor = Color(0xFFF82D37);
  static const Color _surfaceColor = Color(0xFFF7F8FC);
  static const Color _textColor = Color(0xFF242733);
  static const Color _mutedColor = Color(0xFF7A7D89);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: _primaryColor,
        onRefresh: controller.loadHome,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _TopSection(controller: controller)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
                child: Column(
                  children: [
                    Obx(
                      () => _SosAlert(
                        count: controller.activeSosCount,
                        onTap: controller.activeSosCount <= 0
                            ? null
                            : () => Get.toNamed(
                                AppRoute.staffSosList,
                                arguments: controller.activeSos.toList(),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SectionHeader(onSeeMore: onSeeMoreTasks),
                    const SizedBox(height: 6),
                    const _PriorityLegend(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            Obx(() {
              if (controller.isLoading.value && controller.tasks.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final error = controller.errorMessage.value;
              if (error != null && controller.tasks.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _StateMessage(
                    icon: Icons.cloud_off_rounded,
                    title: _localized(
                      vi: 'Không thể tải dữ liệu',
                      en: 'Could not load data',
                    ),
                    message: error,
                    actionLabel: _localized(vi: 'Thử lại', en: 'Retry'),
                    onAction: controller.loadHome,
                  ),
                );
              }

              if (controller.tasks.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _StateMessage(
                    icon: Icons.task_alt_rounded,
                    title: _localized(
                      vi: 'Chưa có công việc cần xử lý',
                      en: 'No active tasks',
                    ),
                    message: _localized(
                      vi: 'Các công việc được phân công cho bạn sẽ hiển thị tại đây.',
                      en: 'Tasks assigned to you will appear here.',
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                sliver: SliverList.separated(
                  itemCount: controller.tasks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    return _TaskCard(
                      request: controller.tasks[index],
                      onReloadRequested: controller.loadHome,
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TopSection extends StatelessWidget {
  const _TopSection({required this.controller});

  final StaffHomeViewModel controller;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final headerHeight = topPadding + 218;
    final sectionHeight = topPadding + 286;

    return SizedBox(
      height: sectionHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: headerHeight,
            child: _Header(controller: controller),
          ),
          Positioned(
            left: 18,
            right: 18,
            top: topPadding + 168,
            child: Obx(
              () => _SummaryRow(
                pending: controller.pendingCount,
                processing: controller.processingCount,
                completed: controller.completedCount,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final StaffHomeViewModel controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final topPadding = MediaQuery.of(context).padding.top;
      final user = controller.currentUser;
      final displayName = user?.displayName.isNotEmpty == true
          ? user!.displayName
          : _localized(vi: 'Cán bộ', en: 'Staff');
      final code = user?.staffCode ?? user?.email ?? user?.id ?? '';

      return Container(
        padding: EdgeInsets.fromLTRB(20, topPadding + 20, 20, 0),
        decoration: const BoxDecoration(
          color: StaffHomeView._primaryColor,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _localized(
                      vi: 'Hệ thống Báo cáo và Xử lý sự cố',
                      en: 'Incident Reporting and Resolution System',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyStrong.copyWith(
                      color: Colors.white,
                      fontSize: AppFontSizes.md,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _NotificationButton(
                  unreadCount: controller.unreadMessageCount.value,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Get.toNamed(AppRoute.staffInfo),
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        children: [
                          _Avatar(name: displayName, imageUrl: user?.avatarUrl),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.subtitle.copyWith(
                                    color: Colors.white,
                                    fontSize: AppFontSizes.xl,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (code.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    code,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.caption.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.75,
                                      ),
                                      fontSize: AppFontSizes.base,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Obx(
                  () => Switch(
                    value: controller.isAvailable.value,
                    activeThumbColor: Colors.white,
                    activeTrackColor: const Color(0xFF22C765),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.28),
                    onChanged: controller.isUpdatingAvailability.value
                        ? null
                        : (value) => _confirmAvailabilityChange(context, value),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Future<void> _confirmAvailabilityChange(
    BuildContext context,
    bool nextValue,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (_) => _AvailabilityConfirmDialog(isActive: nextValue),
    );
    if (confirmed == true) {
      await controller.updateAvailability(nextValue);
    }
  }
}

class _AvailabilityConfirmDialog extends StatelessWidget {
  const _AvailabilityConfirmDialog({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final title = isActive
        ? _localized(vi: 'Bật trạng thái làm việc?', en: 'Go active?')
        : _localized(vi: 'Tắt trạng thái làm việc?', en: 'Go inactive?');
    final message = isActive
        ? _localized(
            vi: 'Bạn sẽ nhận các công việc mới khi đang ở trạng thái làm việc.',
            en: 'You will receive new tasks while active.',
          )
        : _localized(
            vi: 'Bạn sẽ tạm ngừng nhận công việc mới khi tắt trạng thái làm việc.',
            en: 'You will pause receiving new tasks while inactive.',
          );
    final confirmText = isActive
        ? _localized(vi: 'Bật', en: 'Turn on')
        : _localized(vi: 'Tắt', en: 'Turn off');

    return Dialog(
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 30),
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x24000000),
              blurRadius: 26,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFE5F8EE)
                    : const Color(0xFFFFEEF0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isActive ? Icons.work_outline_rounded : Icons.work_off_outlined,
                color: isActive
                    ? const Color(0xFF21AD57)
                    : StaffHomeView._dangerColor,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle.copyWith(
                color: StaffHomeView._textColor,
                fontSize: AppFontSizes.xl,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: const Color(0xFF626878),
                fontSize: AppFontSizes.base,
                height: 1.42,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: StaffHomeView._mutedColor,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(_localized(vi: 'Hủy', en: 'Cancel')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: StaffHomeView._primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(confirmText),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.toNamed(AppRoute.notifications),
      borderRadius: BorderRadius.circular(999),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: StaffHomeView._dangerColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.4),
                ),
              ),
            ),
        ],
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
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: ClipOval(
        child: imageUrl == null
            ? Center(
                child: Text(
                  initials.isEmpty ? 'CB' : initials,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: Colors.white,
                    fontSize: AppFontSizes.lg,
                  ),
                ),
              )
            : Image.network(
                imageUrl!,
                width: 62,
                height: 62,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: Text(
                    initials.isEmpty ? 'CB' : initials,
                    style: AppTextStyles.bodyStrong.copyWith(
                      color: Colors.white,
                      fontSize: AppFontSizes.lg,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.pending,
    required this.processing,
    required this.completed,
  });

  final int pending;
  final int processing;
  final int completed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            count: pending,
            label: _localized(vi: 'Chờ xử lý', en: 'Pending'),
            icon: Icons.hourglass_empty_rounded,
            color: const Color(0xFFFFA800),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            count: processing,
            label: _localized(vi: 'Đang xử lý', en: 'Processing'),
            icon: Icons.schedule_rounded,
            color: const Color(0xFF9B5CFF),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            count: completed,
            label: _localized(vi: 'Hoàn thành', en: 'Completed'),
            icon: Icons.check_circle_outline_rounded,
            color: const Color(0xFF32C873),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.count,
    required this.label,
    required this.icon,
    required this.color,
  });

  final int count;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomPaint(
              size: const Size.fromHeight(26),
              painter: _SummaryIconBackgroundPainter(
                color.withValues(alpha: 0.10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 7, 6, 7),
            child: Column(
              children: [
                Text(
                  count.toString(),
                  maxLines: 1,
                  style: AppTextStyles.h2.copyWith(
                    color: const Color(0xFF171923),
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF555966),
                    fontSize: AppFontSizes.base,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Icon(icon, color: color, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryIconBackgroundPainter extends CustomPainter {
  const _SummaryIconBackgroundPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.18)
      ..lineTo(size.width * 0.24, size.height)
      ..lineTo(size.width * 0.76, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SummaryIconBackgroundPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _SosAlert extends StatelessWidget {
  const _SosAlert({required this.count, this.onTap});

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 10, 18, 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFE9E9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFB9B9), width: 1.4),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _localized(vi: 'SOS KHẨN CẤP!', en: 'SOS EMERGENCY!'),
                      style: AppTextStyles.subtitle.copyWith(
                        color: StaffHomeView._dangerColor,
                        fontSize: AppFontSizes.lg,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _localized(
                        vi: 'Có $count SOS khẩn cấp',
                        en: '$count SOS alert(s)',
                      ),
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: const Color(0xFF30323A),
                        fontSize: AppFontSizes.base,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _localized(vi: 'Chi tiết', en: 'Details'),
                          style: AppTextStyles.caption.copyWith(
                            color: StaffHomeView._dangerColor,
                            fontSize: AppFontSizes.base,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: StaffHomeView._dangerColor,
                          size: 18,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Image.asset(
                'assets/image/icon_sos_done.png',
                width: 82,
                height: 82,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.onSeeMore});

  final VoidCallback? onSeeMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            _localized(vi: 'Công việc của tôi', en: 'My tasks'),
            style: AppTextStyles.subtitle.copyWith(
              color: const Color(0xFF2C2F3A),
              fontSize: AppFontSizes.lg,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onSeeMore,
          iconAlignment: IconAlignment.end,
          icon: const Icon(Icons.chevron_right_rounded, size: 20),
          label: Text(_localized(vi: 'Xem chi tiết', en: 'See details')),
          style: TextButton.styleFrom(
            foregroundColor: StaffHomeView._primaryColor,
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: AppTextStyles.caption.copyWith(
              fontSize: AppFontSizes.base,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _PriorityLegend extends StatelessWidget {
  const _PriorityLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // _LegendItem(
        //   label: _localized(vi: 'Thấp', en: 'Low'),
        //   color: const Color(0xFF9EA0B8),
        // ),
        // const SizedBox(width: 10),
        _LegendItem(
          label: _localized(vi: 'Trung bình', en: 'Medium'),
          color: const Color(0xFFFFC247),
        ),
        const SizedBox(width: 10),
        _LegendItem(
          label: _localized(vi: 'Cao', en: 'High'),
          color: const Color(0xFFFF7E6E),
        ),
        const SizedBox(width: 10),
        _LegendItem(
          label: _localized(vi: 'Khẩn cấp', en: 'Urgent'),
          color: StaffHomeView._dangerColor,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: StaffHomeView._mutedColor,
                fontSize: AppFontSizes.base,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.request, required this.onReloadRequested});

  final SupportRequestEntity request;
  final Future<void> Function() onReloadRequested;

  @override
  Widget build(BuildContext context) {
    final status = _StatusStyle.fromStatus(request.status);
    final priority = _PriorityStyle.fromPriority(request.priority);
    final date = _formatDate(request.updatedAt ?? request.createdAt);

    return InkWell(
      onTap: () async {
        await Get.toNamed(AppRoute.staffTicketDetail, arguments: request.id);
        await onReloadRequested();
      },
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 14, 46, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
              border: Border.all(color: const Color(0xFFF0F1F6)),
            ),
            child: Column(
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
                    _CodePill(code: request.code),
                    const SizedBox(width: 8),
                    Flexible(child: _StatusPill(style: status)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  request.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: const Color(0xFF2B2F38),
                    fontSize: AppFontSizes.base,
                    fontWeight: FontWeight.w800,
                    height: 1.32,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 5,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      request.incidentType ??
                          _localized(vi: 'Sự cố', en: 'Incident'),
                      style: AppTextStyles.caption.copyWith(
                        color: StaffHomeView._mutedColor,
                        fontSize: AppFontSizes.base,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (request.locationText != null)
                      _MetaText('• ${request.locationText}'),
                    if (date != null) _MetaText('• $date'),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 14,
            top: 14,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: StaffHomeView._surfaceColor,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E4F0)),
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFC2C5D2),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String? _formatDate(DateTime? value) {
    if (value == null) {
      return null;
    }
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.caption.copyWith(
        color: StaffHomeView._mutedColor,
        fontSize: AppFontSizes.base,
        fontWeight: FontWeight.w600,
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
        color: StaffHomeView._surfaceColor,
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
          Text(
            style.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: style.foreground,
              fontSize: AppFontSizes.base,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 42, color: StaffHomeView._primaryColor),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle.copyWith(
              color: const Color(0xFF2B2F38),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: StaffHomeView._mutedColor,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
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
        label: _localized(vi: 'Chờ tiếp nhận', en: 'Waiting'),
        foreground: const Color(0xFFD76400),
        background: const Color(0xFFF5F2E2),
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
        foreground: const Color(0xFFE83248),
        background: const Color(0xFFF4EDEE),
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
        color: StaffHomeView._dangerColor,
      ),
    };
  }
}
