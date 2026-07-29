// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/SupportRequestEntity.dart';
import 'package:hcmu_sos/Navigator/AppRoute.dart';
import 'package:hcmu_sos/Theme/AppTypography.dart';
import 'package:hcmu_sos/ViewModel/Student/StudentHomeViewModel.dart';

String _localized({required String vi, required String en}) {
  return Get.locale?.languageCode == 'en' ? en : vi;
}

class StudentHomeView extends GetWidget<StudentHomeViewModel> {
  const StudentHomeView({
    super.key,
    this.onSeeMoreRequests,
    this.onSosTap,
    this.onCreateRequestTap,
  });

  final VoidCallback? onSeeMoreRequests;
  final VoidCallback? onSosTap;
  final VoidCallback? onCreateRequestTap;

  static const Color _primaryColor = Color(0xFF29306F);
  static const Color _dangerColor = Color(0xFFF82D37);
  static const Color _surfaceColor = Color(0xFFF7F8FC);
  static const Color _mutedColor = Color(0xFF7A7D89);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: SizedBox(
          width: 48,
          height: 48,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.48, 1.0],
                colors: [
                  Color(0xFF4F5ABB),
                  Color(0xFF313A88),
                  Color(0xFF171D52),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withValues(alpha: 0.24),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: onCreateRequestTap,
              heroTag: 'student_home_create_request',
              elevation: 0,
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.add_rounded, size: 30),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: _primaryColor,
        onRefresh: controller.loadHome,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 240) {
              controller.loadMoreRequests();
            }
            return false;
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _TopSection(controller: controller)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
                  child: Column(
                    children: [
                      _SosCallButton(onTap: onSosTap),
                      const SizedBox(height: 20),
                      _SectionHeader(onSeeMore: onSeeMoreRequests),
                      const SizedBox(height: 6),
                      const _PriorityLegend(),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              Obx(() {
                if (controller.isLoading.value && controller.requests.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final error = controller.errorMessage.value;
                if (error != null && controller.requests.isEmpty) {
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

                final items = controller.recentRequests;
                if (items.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _StateMessage(
                      icon: Icons.assignment_outlined,
                      title: _localized(
                        vi: 'Chưa có yêu cầu',
                        en: 'No requests yet',
                      ),
                      message: _localized(
                        vi: 'Các yêu cầu SOS của bạn sẽ hiển thị tại đây.',
                        en: 'Your SOS requests will appear here.',
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                  sliver: SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final request = items[index];
                      return _RequestCard(
                        request: request,
                        onReloadRequested: controller.loadHome,
                        incidentTypeName: controller.incidentTypeNameFor(
                          request,
                        ),
                        onRate: () async {
                          await Get.toNamed(
                            AppRoute.ticketDetail,
                            arguments: <String, dynamic>{
                              'id': request.id,
                              'open_rating': true,
                            },
                          );
                          await controller.loadHome();
                        },
                      );
                    },
                  ),
                );
              }),
              Obx(
                () => SliverToBoxAdapter(
                  child: controller.isLoadingMore.value
                      ? const Padding(
                          padding: EdgeInsets.fromLTRB(18, 0, 18, 24),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: _primaryColor,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(height: 8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopSection extends StatelessWidget {
  const _TopSection({required this.controller});

  final StudentHomeViewModel controller;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final headerHeight = topPadding + 154;
    final sectionHeight = topPadding + 210;

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
            top: topPadding + 106,
            child: Obx(
              () => _SummaryRow(
                waiting: controller.waitingCount,
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

  final StudentHomeViewModel controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final topPadding = MediaQuery.of(context).padding.top;
      final user = controller.currentUser;
      final displayName = user?.displayName.isNotEmpty == true
          ? user!.displayName
          : _localized(vi: 'Sinh viên', en: 'Student');
      final studentCode = user?.studentCode ?? user?.id ?? '';

      return Container(
        padding: EdgeInsets.fromLTRB(18, topPadding + 18, 18, 0),
        decoration: const BoxDecoration(
          color: StudentHomeView._primaryColor,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Get.toNamed(AppRoute.studentInfo),
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      children: [
                        _Avatar(name: displayName, imageUrl: user?.avatarUrl),
                        const SizedBox(width: 12),
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
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (studentCode.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  studentCode,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption.copyWith(
                                    color: Colors.white.withValues(alpha: 0.75),
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
              _NotificationButton(
                unreadCount: controller.unreadNotificationCount.value,
              ),
            ],
          ),
        ),
      );
    });
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
      width: 54,
      height: 54,
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
                  initials.isEmpty ? 'SV' : initials,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: Colors.white,
                    fontSize: AppFontSizes.lg,
                  ),
                ),
              )
            : Image.network(
                imageUrl!,
                width: 54,
                height: 54,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: Text(
                    initials.isEmpty ? 'SV' : initials,
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: 25,
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
                  color: StudentHomeView._dangerColor,
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.waiting,
    required this.processing,
    required this.completed,
  });

  final int waiting;
  final int processing;
  final int completed;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset.zero,
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              count: waiting,
              label: _localized(vi: 'Đang chờ', en: 'Waiting'),
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
      ),
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

class _SosCallButton extends StatelessWidget {
  const _SosCallButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: StudentHomeView._dangerColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _localized(vi: 'SOS KHẨN CẤP!', en: 'SOS EMERGENCY!'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.button.copyWith(
                  color: Colors.white,
                  fontSize: AppFontSizes.lg,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Positioned(
            left: 2,
            child: IgnorePointer(
              child: Image.asset(
                'assets/icon/icon_callsos.png',
                width: 48,
                height: 48,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _SosButton extends StatelessWidget {
  const _SosButton();

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset.zero,
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton.icon(
          onPressed: () {},
          icon: Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFFFFD84A),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              'SOS',
              style: AppTextStyles.caption.copyWith(
                color: StudentHomeView._dangerColor,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          label: Text(
            _localized(vi: 'SOS KHẨN CẤP!', en: 'SOS EMERGENCY!'),
            style: AppTextStyles.button.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: StudentHomeView._dangerColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
    return Transform.translate(
      offset: Offset.zero,
      child: Row(
        children: [
          Expanded(
            child: Text(
              _localized(vi: 'Yêu cầu gần đây', en: 'Recent requests'),
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
            label: Text(_localized(vi: 'Xem thêm', en: 'See more')),
            style: TextButton.styleFrom(
              foregroundColor: StudentHomeView._primaryColor,
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: AppTextStyles.caption.copyWith(
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

class _PriorityLegend extends StatelessWidget {
  const _PriorityLegend();

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset.zero,
      child: Row(
        children: [
          // _LegendItem(
          //   label: _localized(vi: 'Thấp', en: 'Low'),
          //   color: Color(0xFF7C78AE),
          // ),
          // SizedBox(width: 12),
          _LegendItem(
            label: _localized(vi: 'Trung bình', en: 'Medium'),
            color: Color(0xFFFFC247),
          ),
          SizedBox(width: 12),
          _LegendItem(
            label: _localized(vi: 'Cao', en: 'High'),
            color: Color(0xFFFF7E6E),
          ),
          SizedBox(width: 12),
          _LegendItem(
            label: _localized(vi: 'Khẩn cấp', en: 'Urgent'),
            color: StudentHomeView._dangerColor,
          ),
        ],
      ),
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
                color: StudentHomeView._mutedColor,
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

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.onRate,
    required this.onReloadRequested,
    this.incidentTypeName,
  });

  final SupportRequestEntity request;
  final String? incidentTypeName;
  final VoidCallback onRate;
  final Future<void> Function() onReloadRequested;

  @override
  Widget build(BuildContext context) {
    final status = _StatusStyle.fromStatus(request.status);
    final priority = _PriorityStyle.fromPriority(request.priority);
    final location = request.locationText;
    final date = _formatDate(request.createdAt);
    final staff = request.assignedStaff?.name;
    final canRate =
        request.status == SupportRequestStatus.done && request.rating == null;

    return InkWell(
      onTap: () async {
        await Get.toNamed(AppRoute.ticketDetail, arguments: request.id);
        await onReloadRequested();
      },
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
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
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 32),
                        child: Row(
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
                            if (request.isSos) ...[
                              const SizedBox(width: 8),
                              const _RequestTypePill(),
                            ],
                            const SizedBox(width: 8),
                            Flexible(child: _StatusPill(style: status)),
                            if (request.rating != null) ...[
                              const SizedBox(width: 8),
                              _RatingBadge(rating: request.rating!),
                            ],
                          ],
                        ),
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
                            incidentTypeName ??
                                request.incidentType ??
                                _localized(vi: 'Sự cố', en: 'Incident'),
                            style: AppTextStyles.caption.copyWith(
                              color: StudentHomeView._mutedColor,
                              fontSize: AppFontSizes.base,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (location != null) _MetaText('• $location'),
                          if (date != null) _MetaText('• $date'),
                          if (staff != null) _MetaText('• $staff'),
                        ],
                      ),
                      if (canRate) ...[
                        const SizedBox(height: 6),
                        _RateNowButton(onPressed: onRate),
                      ],
                    ],
                  ),
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
                color: StudentHomeView._surfaceColor,
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

class _RateNowButton extends StatelessWidget {
  const _RateNowButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF0FF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFC9CEF5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star_outline_rounded,
                size: 16,
                color: StudentHomeView._primaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                'ticket.rating.rateNow'.tr,
                style: AppTextStyles.caption.copyWith(
                  color: StudentHomeView._primaryColor,
                  fontSize: AppFontSizes.base,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: Color(0xFFFFB020), size: 15),
        const SizedBox(width: 2),
        Text(
          rating.toString(),
          style: AppTextStyles.caption.copyWith(
            color: const Color(0xFF8A6300),
            fontSize: AppFontSizes.base,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
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
        color: StudentHomeView._mutedColor,
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
        color: StudentHomeView._surfaceColor,
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
        _localized(vi: 'SOS', en: 'SOS'),
        style: AppTextStyles.caption.copyWith(
          color: StudentHomeView._dangerColor,
          fontSize: AppFontSizes.base,
          fontWeight: FontWeight.w800,
        ),
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
          Icon(icon, size: 42, color: StudentHomeView._primaryColor),
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
              color: StudentHomeView._mutedColor,
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
        background: Color.fromARGB(255, 245, 242, 226),
        icon: Icons.hourglass_empty_rounded,
      ),
      SupportRequestStatus.inProgress => _StatusStyle(
        label: 'status.in_progress'.tr,
        foreground: Color(0xFF5D31D6),
        background: Color(0xFFECE5FF),
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
        foreground: Color(0xFFE83248),
        background: Color.fromARGB(255, 244, 237, 238),
        icon: Icons.close_rounded,
      ),
      SupportRequestStatus.done => _StatusStyle(
        label: 'status.done'.tr,
        foreground: Color(0xFF21AD57),
        background: Color(0xFFE5F8EE),
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
        color: StudentHomeView._dangerColor,
      ),
    };
  }
}
