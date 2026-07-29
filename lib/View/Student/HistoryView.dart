// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/SupportRequestEntity.dart';
import 'package:hcmu_sos/Navigator/AppRoute.dart';
import 'package:hcmu_sos/Theme/AppTypography.dart';
import 'package:hcmu_sos/ViewModel/Student/HistoryViewModel.dart';

String _historyText({required String vi, required String en}) {
  return Get.locale?.languageCode == 'en' ? en : vi;
}

const Color _primaryColor = Color(0xFF29306F);
const Color _dangerColor = Color(0xFFF82D37);
const Color _surfaceColor = Color(0xFFF7F8FC);
const Color _mutedColor = Color(0xFF7A7D89);

class HistoryView extends GetWidget<HistoryViewModel> {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: _primaryColor,
          onRefresh: controller.loadRequests,
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
                SliverToBoxAdapter(child: _Header(controller: controller)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                    child: _SearchFilterBar(controller: controller),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
                    child: _ListHeader(controller: controller),
                  ),
                ),
                Obx(() {
                  if (controller.isLoading.value &&
                      controller.requests.isEmpty) {
                    return const SliverFillRemaining(
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
                        title: _historyText(
                          vi: 'Không thể tải dữ liệu',
                          en: 'Could not load data',
                        ),
                        message: error,
                        actionLabel: _historyText(vi: 'Thử lại', en: 'Retry'),
                        onAction: controller.loadRequests,
                      ),
                    );
                  }

                  final items = controller.filteredRequests;
                  if (items.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: _StateMessage(
                        icon: Icons.assignment_outlined,
                        title: _historyText(
                          vi: 'Không có yêu cầu',
                          en: 'No requests',
                        ),
                        message: _historyText(
                          vi: 'Không có yêu cầu phù hợp với bộ lọc hiện tại.',
                          en: 'No requests match the current filter.',
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 26),
                    sliver: SliverList.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final request = items[index];
                        return _HistoryRequestCard(
                          request: request,
                          onReloadRequested: controller.loadRequests,
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
                            await controller.loadRequests();
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
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final HistoryViewModel controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 25, 15, 5),
      child: Row(
        children: [
          // IconButton(
          //   onPressed: () {},
          //   icon: const Icon(Icons.chevron_left_rounded, size: 28),
          //   color: const Color(0xFF242733),
          //   visualDensity: VisualDensity.compact,
          // ),
          Expanded(
            child: Text(
              _historyText(vi: 'Lịch sử yêu cầu', en: 'Request history'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.subtitle.copyWith(
                color: const Color(0xFF242733),
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

class _SearchFilterBar extends StatelessWidget {
  const _SearchFilterBar({required this.controller});

  final HistoryViewModel controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9EBF4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.searchController,
              textInputAction: TextInputAction.search,
              onChanged: controller.onSearchChanged,
              onSubmitted: (_) => controller.submitSearch(),
              style: AppTextStyles.body.copyWith(
                color: const Color(0xFF242733),
                fontSize: AppFontSizes.md,
              ),
              decoration: InputDecoration(
                hintText: _historyText(
                  vi: 'Tìm kiếm yêu cầu',
                  en: 'Search requests',
                ),
                hintStyle: AppTextStyles.body.copyWith(
                  color: const Color(0xFF9AA0B3),
                  fontSize: AppFontSizes.md,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: _primaryColor,
                  size: 22,
                ),
                suffixIcon: Obx(
                  () => controller.keyword.value.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          onPressed: controller.clearSearch,
                          icon: const Icon(Icons.close_rounded, size: 18),
                          color: _mutedColor,
                          visualDensity: VisualDensity.compact,
                        ),
                ),
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(
            height: 28,
            child: VerticalDivider(
              width: 1,
              thickness: 1,
              color: Color(0xFFE3E6F0),
            ),
          ),
          Obx(
            () => _FilterButton(
              label: _filterLabel(controller.selectedFilter.value),
              active:
                  controller.selectedFilter.value != RequestHistoryFilter.all,
              onTap: () => _openStatusFilter(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openStatusFilter(BuildContext context) async {
    final filters = [
      for (final filter in RequestHistoryFilter.values)
        _FilterConfig(filter: filter, label: _filterLabel(filter)),
    ];

    final selected = await showModalBottomSheet<RequestHistoryFilter>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F3FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: _primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _historyText(vi: 'Lọc trạng thái', en: 'Filter status'),
                        style: AppTextStyles.title.copyWith(
                          color: _primaryColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Obx(() {
                  final selectedFilter = controller.selectedFilter.value;
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: filters.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final config = filters[index];
                      final isSelected = config.filter == selectedFilter;
                      return InkWell(
                        onTap: () => Navigator.of(context).pop(config.filter),
                        borderRadius: BorderRadius.circular(8),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFF1F3FF)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? _primaryColor
                                  : const Color(0xFFE2E4F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _iconForFilter(config.filter),
                                color: isSelected
                                    ? _primaryColor
                                    : const Color(0xFF8D94A8),
                                size: 19,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  config.label,
                                  style: AppTextStyles.bodyStrong.copyWith(
                                    color: const Color(0xFF242733),
                                    fontSize: AppFontSizes.md,
                                  ),
                                ),
                              ),
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 120),
                                opacity: isSelected ? 1 : 0,
                                child: const Icon(
                                  Icons.check_circle_rounded,
                                  color: _primaryColor,
                                  size: 21,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      await controller.selectFilter(selected);
    }
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 52,
      child: TextButton.icon(
        onPressed: onTap,
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.tune_rounded, size: 19),
            if (active)
              Positioned(
                top: -2,
                right: -4,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _dangerColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
              ),
          ],
        ),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: TextButton.styleFrom(
          foregroundColor: active ? _primaryColor : const Color(0xFF4D5570),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          textStyle: AppTextStyles.caption.copyWith(
            fontSize: AppFontSizes.base,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

String _filterLabel(RequestHistoryFilter filter) {
  return switch (filter) {
    RequestHistoryFilter.all => _historyText(vi: 'Tất cả', en: 'All'),
    RequestHistoryFilter.pending => _historyText(
      vi: 'Chờ tiếp nhận',
      en: 'Waiting',
    ),
    RequestHistoryFilter.inProgress => _historyText(
      vi: 'Đang xử lý',
      en: 'Processing',
    ),
    RequestHistoryFilter.reopened => _historyText(
      vi: 'Đã mở lại',
      en: 'Reopened',
    ),
    RequestHistoryFilter.done => _historyText(
      vi: 'Hoàn thành',
      en: 'Completed',
    ),
    RequestHistoryFilter.rejected => _historyText(
      vi: 'Từ chối',
      en: 'Rejected',
    ),
  };
}

IconData _iconForFilter(RequestHistoryFilter filter) {
  return switch (filter) {
    RequestHistoryFilter.all => Icons.list_alt_rounded,
    RequestHistoryFilter.pending => Icons.hourglass_empty_rounded,
    RequestHistoryFilter.inProgress => Icons.schedule_rounded,
    RequestHistoryFilter.reopened => Icons.refresh_rounded,
    RequestHistoryFilter.done => Icons.check_circle_outline_rounded,
    RequestHistoryFilter.rejected => Icons.close_rounded,
  };
}

class _FilterConfig {
  const _FilterConfig({required this.filter, required this.label});

  final RequestHistoryFilter filter;
  final String label;
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({required this.controller});

  final HistoryViewModel controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Obx(
            () => Text(
              _titleForFilter(controller.selectedFilter.value),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.subtitle.copyWith(
                color: const Color(0xFF2C2F3A),
                fontSize: AppFontSizes.lg,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        Obx(() {
          final total = controller.totalRequests.value == 0
              ? controller.requests.length
              : controller.totalRequests.value;
          return _TotalRequestsBadge(total: total);
        }),
      ],
    );
  }

  static String _titleForFilter(RequestHistoryFilter filter) {
    return switch (filter) {
      RequestHistoryFilter.all => _historyText(
        vi: 'Tất cả yêu cầu',
        en: 'All requests',
      ),
      RequestHistoryFilter.pending => _historyText(
        vi: 'Chờ tiếp nhận',
        en: 'Waiting',
      ),
      RequestHistoryFilter.inProgress => _historyText(
        vi: 'Đang xử lý',
        en: 'Processing',
      ),
      RequestHistoryFilter.reopened => _historyText(
        vi: 'Đã mở lại',
        en: 'Reopened',
      ),
      RequestHistoryFilter.done => _historyText(
        vi: 'Hoàn thành',
        en: 'Completed',
      ),
      RequestHistoryFilter.rejected => _historyText(
        vi: 'Từ chối',
        en: 'Rejected',
      ),
    };
  }
}

class _TotalRequestsBadge extends StatelessWidget {
  const _TotalRequestsBadge({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.only(left: 9, right: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE1E5FF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A29306F),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: _primaryColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.assignment_outlined,
              color: Colors.white,
              size: 12,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            total.toString(),
            style: AppTextStyles.caption.copyWith(
              color: _primaryColor,
              fontSize: AppFontSizes.base,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _historyText(vi: 'yêu cầu', en: 'requests'),
            style: AppTextStyles.caption.copyWith(
              color: const Color(0xFF5E6684),
              fontSize: AppFontSizes.base,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRequestCard extends StatelessWidget {
  const _HistoryRequestCard({
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
                                _historyText(vi: 'Sự cố', en: 'Incident'),
                            style: AppTextStyles.caption.copyWith(
                              color: _mutedColor,
                              fontSize: AppFontSizes.base,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          //if (location != null) _MetaText('• $location'),
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
                color: _surfaceColor,
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

    final difference = DateTime.now().difference(value);
    if (!difference.isNegative && difference <= const Duration(hours: 24)) {
      if (difference.inMinutes < 1) {
        return _historyText(vi: 'Vừa xong', en: 'Just now');
      }
      if (difference.inHours < 1) {
        final minutes = difference.inMinutes;
        return _historyText(
          vi: '$minutes phút trước',
          en: '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago',
        );
      }
      final hours = difference.inHours;
      return _historyText(
        vi: '$hours giờ trước',
        en: '$hours ${hours == 1 ? 'hour' : 'hours'} ago',
      );
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
                color: _primaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                'ticket.rating.rateNow'.tr,
                style: AppTextStyles.caption.copyWith(
                  color: _primaryColor,
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
        color: _mutedColor,
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
        color: _surfaceColor,
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
        _historyText(vi: 'SOS', en: 'SOS'),
        style: AppTextStyles.caption.copyWith(
          color: _dangerColor,
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
          Icon(icon, size: 42, color: _primaryColor),
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
            style: AppTextStyles.body.copyWith(color: _mutedColor),
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
        label: _historyText(vi: 'Chờ tiếp nhận', en: 'Waiting'),
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
        color: _dangerColor,
      ),
    };
  }
}
