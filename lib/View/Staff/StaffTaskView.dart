// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/IncidentTypeEntity.dart';
import 'package:hcmu_sos/Entity/SupportRequestEntity.dart';
import 'package:hcmu_sos/Navigator/AppRoute.dart';
import 'package:hcmu_sos/Theme/AppTypography.dart';
import 'package:hcmu_sos/ViewModel/Staff/StaffTaskViewModel.dart';

String _taskText({required String vi, required String en}) {
  return Get.locale?.languageCode == 'en' ? en : vi;
}

const Color _primaryColor = Color(0xFF29306F);
const Color _dangerColor = Color(0xFFF82D37);
const Color _surfaceColor = Color(0xFFF7F8FC);
const Color _mutedColor = Color(0xFF7A7D89);

class StaffTaskView extends GetWidget<TaskViewModel> {
  const StaffTaskView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: _primaryColor,
          onRefresh: controller.loadTasks,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 240) {
                controller.loadMoreTasks();
              }
              return false;
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: _Header()),
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
                        title: _taskText(
                          vi: 'Không thể tải dữ liệu',
                          en: 'Could not load data',
                        ),
                        message: error,
                        actionLabel: _taskText(vi: 'Thử lại', en: 'Retry'),
                        onAction: controller.loadTasks,
                      ),
                    );
                  }

                  final items = controller.filteredTasks;
                  if (items.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: _StateMessage(
                        icon: Icons.assignment_outlined,
                        title: _taskText(
                          vi: 'Không có công việc',
                          en: 'No tasks',
                        ),
                        message: _taskText(
                          vi: 'Không có công việc phù hợp với bộ lọc hiện tại.',
                          en: 'No tasks match the current filter.',
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
                        final task = items[index];
                        return _TaskCard(
                          request: task,
                          incidentTypeName: controller.incidentTypeNameFor(
                            task,
                          ),
                          onReloadRequested: controller.loadTasks,
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
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _taskText(vi: 'Công việc của tôi', en: 'My tasks'),
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

  final TaskViewModel controller;

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
                hintText: _taskText(
                  vi: 'Tìm kiếm công việc',
                  en: 'Search tasks',
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
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
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
              active: controller.hasActiveFilters,
              onTap: () => _openFilterSheet(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFilterSheet(BuildContext context) async {
    var status = controller.statusFilter.value;
    var priority = controller.priorityFilter.value;
    var incidentType = controller.selectedIncidentType.value;
    var rating = controller.selectedRating.value;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(18, 0, 18, 18 + bottomInset),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FilterSheetHeader(
                        onClear: () async {
                          Navigator.of(context).pop();
                          await controller.clearFilters();
                        },
                      ),
                      const SizedBox(height: 16),
                      _FilterDropdown<StaffTaskStatusFilter>(
                        label: _taskText(vi: 'Trạng thái', en: 'Status'),
                        value: status,
                        items: StaffTaskStatusFilter.values,
                        itemLabel: _statusFilterLabel,
                        onChanged: (value) => setState(() => status = value),
                      ),
                      const SizedBox(height: 12),
                      _FilterDropdown<StaffTaskPriorityFilter>(
                        label: _taskText(vi: 'Độ ưu tiên', en: 'Priority'),
                        value: priority,
                        items: StaffTaskPriorityFilter.values,
                        itemLabel: _priorityFilterLabel,
                        onChanged: (value) => setState(() => priority = value),
                      ),
                      const SizedBox(height: 12),
                      Obx(
                        () => _FilterDropdown<IncidentTypeEntity?>(
                          label: _taskText(
                            vi: 'Loại sự cố',
                            en: 'Incident type',
                          ),
                          value: incidentType,
                          items: <IncidentTypeEntity?>[
                            null,
                            ...controller.incidentTypes,
                          ],
                          itemLabel: (value) =>
                              value?.name ?? _taskText(vi: 'Tất cả', en: 'All'),
                          onChanged: (value) =>
                              setState(() => incidentType = value),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _FilterDropdown<int?>(
                        label: _taskText(vi: 'Đánh giá', en: 'Rating'),
                        value: rating,
                        items: const <int?>[null, 5, 4, 3, 2, 1],
                        itemLabel: (value) => value == null
                            ? _taskText(vi: 'Tất cả', en: 'All')
                            : '$value sao',
                        onChanged: (value) => setState(() => rating = value),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await controller.applyFilters(
                              status: status,
                              priority: priority,
                              incidentType: incidentType,
                              rating: rating,
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            _taskText(vi: 'Áp dụng', en: 'Apply'),
                            style: AppTextStyles.button.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FilterSheetHeader extends StatelessWidget {
  const _FilterSheetHeader({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Color(0xFFF1F3FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.tune_rounded, color: _primaryColor, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _taskText(vi: 'Bộ lọc công việc', en: 'Task filters'),
            style: AppTextStyles.title.copyWith(
              color: _primaryColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton(
          onPressed: onClear,
          child: Text(_taskText(vi: 'Xóa lọc', en: 'Clear')),
        ),
      ],
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T value) itemLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 7),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: const Color(0xFF5E6684),
              fontSize: AppFontSizes.base,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Builder(
          builder: (fieldContext) {
            return InkWell(
              onTap: () => _openOptions(fieldContext),
              borderRadius: BorderRadius.circular(8),
              child: Ink(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E4F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        itemLabel(value),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyStrong.copyWith(
                          color: const Color(0xFF242733),
                          fontSize: AppFontSizes.md,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF606575),
                      size: 24,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _openOptions(BuildContext context) async {
    final renderBox = context.findRenderObject() as RenderBox;
    final overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero, ancestor: overlay);
    final size = renderBox.size;
    final selectedIndex = await showMenu<int>(
      context: context,
      color: Colors.white,
      elevation: 10,
      constraints: BoxConstraints(
        minWidth: size.width,
        maxWidth: size.width,
        maxHeight: MediaQuery.of(context).size.height * 0.42,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE2E4F0)),
      ),
      position: RelativeRect.fromRect(
        Rect.fromLTWH(offset.dx, offset.dy + size.height + 6, size.width, 0),
        Offset.zero & overlay.size,
      ),
      items: List.generate(items.length, (index) {
        final item = items[index];
        final selected = item == value;
        return PopupMenuItem<int>(
          value: index,
          height: 44,
          padding: EdgeInsets.zero,
          child: Container(
            color: selected ? const Color(0xFFF4F6FF) : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    itemLabel(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyStrong.copyWith(
                      color: const Color(0xFF242733),
                      fontSize: AppFontSizes.base,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                    ),
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.check_rounded,
                    color: _primaryColor,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    );
    if (selectedIndex != null) {
      onChanged(items[selectedIndex]);
    }
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 52,
      child: IconButton(
        onPressed: onTap,
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.tune_rounded,
              color: active ? _primaryColor : const Color(0xFF4D5570),
              size: 22,
            ),
            if (active)
              Positioned(
                top: -2,
                right: -4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _dangerColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({required this.controller});

  final TaskViewModel controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Obx(
            () => Text(
              _titleForStatus(controller.statusFilter.value),
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
          final total = controller.totalTasks.value == 0
              ? controller.tasks.length
              : controller.totalTasks.value;
          return Text(
            _taskText(vi: '$total công việc', en: '$total tasks'),
            style: AppTextStyles.caption.copyWith(
              color: _mutedColor,
              fontSize: AppFontSizes.base,
              fontWeight: FontWeight.w700,
            ),
          );
        }),
      ],
    );
  }

  String _titleForStatus(StaffTaskStatusFilter filter) {
    return switch (filter) {
      StaffTaskStatusFilter.all => _taskText(
        vi: 'Tất cả công việc',
        en: 'All tasks',
      ),
      StaffTaskStatusFilter.pending => _taskText(
        vi: 'Chờ tiếp nhận',
        en: 'Waiting',
      ),
      StaffTaskStatusFilter.inProgress => _taskText(
        vi: 'Đang xử lý',
        en: 'Processing',
      ),
      StaffTaskStatusFilter.reopened => _taskText(
        vi: 'Đã mở lại',
        en: 'Reopened',
      ),
      StaffTaskStatusFilter.done => _taskText(
        vi: 'Hoàn thành',
        en: 'Completed',
      ),
      StaffTaskStatusFilter.rejected => _taskText(
        vi: 'Từ chối',
        en: 'Rejected',
      ),
    };
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.request,
    required this.onReloadRequested,
    this.incidentTypeName,
  });

  final SupportRequestEntity request;
  final Future<void> Function() onReloadRequested;
  final String? incidentTypeName;

  @override
  Widget build(BuildContext context) {
    final status = _StatusStyle.fromStatus(request.status);
    final priority = _PriorityStyle.fromPriority(request.priority);
    final date = _formatDate(request.createdAt);

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
                    if (request.rating != null) ...[
                      const SizedBox(width: 8),
                      _RatingBadge(rating: request.rating!),
                    ],
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
                      incidentTypeName ??
                          request.incidentType ??
                          _taskText(vi: 'Sự cố', en: 'Incident'),
                      style: AppTextStyles.caption.copyWith(
                        color: _mutedColor,
                        fontSize: AppFontSizes.base,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (date != null) _MetaText('• $date'),
                    if (request.locationText != null)
                      _MetaText('• ${request.locationText}'),
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
        return _taskText(vi: 'Vừa xong', en: 'Just now');
      }
      if (difference.inHours < 1) {
        final minutes = difference.inMinutes;
        return _taskText(
          vi: '$minutes phút trước',
          en: '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago',
        );
      }
      final hours = difference.inHours;
      return _taskText(
        vi: '$hours giờ trước',
        en: '$hours ${hours == 1 ? 'hour' : 'hours'} ago',
      );
    }

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
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
        label: _taskText(vi: 'Chờ tiếp nhận', en: 'Waiting'),
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
        color: _dangerColor,
      ),
    };
  }
}

String _statusFilterLabel(StaffTaskStatusFilter filter) {
  return switch (filter) {
    StaffTaskStatusFilter.all => _taskText(vi: 'Tất cả', en: 'All'),
    StaffTaskStatusFilter.pending => _taskText(
      vi: 'Chờ tiếp nhận',
      en: 'Waiting',
    ),
    StaffTaskStatusFilter.inProgress => _taskText(
      vi: 'Đang xử lý',
      en: 'Processing',
    ),
    StaffTaskStatusFilter.reopened => _taskText(
      vi: 'Đã mở lại',
      en: 'Reopened',
    ),
    StaffTaskStatusFilter.done => _taskText(vi: 'Hoàn thành', en: 'Completed'),
    StaffTaskStatusFilter.rejected => _taskText(vi: 'Từ chối', en: 'Rejected'),
  };
}

String _priorityFilterLabel(StaffTaskPriorityFilter filter) {
  return switch (filter) {
    StaffTaskPriorityFilter.all => _taskText(vi: 'Tất cả', en: 'All'),
    StaffTaskPriorityFilter.normal => _taskText(vi: 'Trung bình', en: 'Medium'),
    StaffTaskPriorityFilter.high => _taskText(vi: 'Cao', en: 'High'),
    StaffTaskPriorityFilter.urgent => _taskText(vi: 'Khẩn cấp', en: 'Urgent'),
  };
}
