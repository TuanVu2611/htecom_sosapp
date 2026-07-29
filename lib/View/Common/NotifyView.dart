// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/NotificationEntity.dart';
import 'package:hcmu_sos/Theme/AppTypography.dart';
import 'package:hcmu_sos/ViewModel/Common/NotifyViewModel.dart';

class NotifyView extends GetWidget<NotifyViewModel> {
  const NotifyView({super.key});

  static const Color _primaryColor = Color(0xFF29306F);
  static const Color _textColor = Color(0xFF262936);
  static const Color _mutedColor = Color(0xFF858996);
  static const Color _pageColor = Color(0xFFFAFAFD);
  static const Color _unreadBorderColor = Color(0xFFBFC4FF);
  static const Color _unreadFillColor = Color(0xFFF5F7FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(controller: controller),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value &&
                    controller.notifications.isEmpty) {
                  return const _LoadingState();
                }

                if (controller.errorMessage.value != null &&
                    controller.notifications.isEmpty) {
                  return _ErrorState(
                    message: controller.errorMessage.value!,
                    onRetry: controller.loadFirstPage,
                  );
                }

                if (controller.notifications.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: controller.loadFirstPage,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [_EmptyState()],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: controller.loadFirstPage,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.pixels >=
                          notification.metrics.maxScrollExtent - 220) {
                        controller.loadMore();
                      }
                      return false;
                    },
                    child: _NotificationList(controller: controller),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final NotifyViewModel controller;

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
            color: NotifyView._textColor,
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Text(
              'Thông báo',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.subtitle.copyWith(
                color: NotifyView._textColor,
                fontSize: AppFontSizes.xl,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Obx(() {
            final enabled =
                controller.unreadCount.value > 0 &&
                !controller.isMarkingRead.value;
            return IconButton(
              onPressed: enabled ? controller.markAllRead : null,
              icon: const Icon(Icons.done_all_rounded),
              tooltip: 'Đánh dấu tất cả đã đọc',
              color: enabled
                  ? NotifyView._primaryColor
                  : NotifyView._mutedColor.withValues(alpha: 0.5),
            );
          }),
        ],
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({required this.controller});

  final NotifyViewModel controller;

  @override
  Widget build(BuildContext context) {
    final groups = _groupNotifications(controller.notifications);
    final children = <Widget>[];

    for (final group in groups) {
      children.add(_DateHeader(date: group.date));
      for (final item in group.items) {
        children.add(
          _NotificationCard(
            item: item,
            onTap: () => controller.openNotification(item),
          ),
        );
      }
      children.add(const SizedBox(height: 16));
    }

    children.add(
      Obx(
        () => controller.isLoadingMore.value
            ? const Padding(
                padding: EdgeInsets.only(bottom: 22),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                ),
              )
            : const SizedBox(height: 12),
      ),
    );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      children: children,
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 12),
      child: Text(
        _formatGroupDate(date),
        style: AppTextStyles.bodyStrong.copyWith(
          color: NotifyView._mutedColor,
          fontSize: AppFontSizes.base,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap});

  final NotificationEntity item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !item.isRead;
    final visual = _visualForItem(item);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
            decoration: BoxDecoration(
              color: unread ? NotifyView._unreadFillColor : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: unread
                    ? NotifyView._unreadBorderColor
                    : const Color(0xFFF0F1F6),
                width: unread ? 1.25 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: unread
                      ? const Color(0x1A29306F)
                      : const Color(0x0A000000),
                  blurRadius: unread ? 16 : 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NotificationIcon(visual: visual, unread: unread),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.title.isEmpty ? 'Thông báo' : item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyStrong.copyWith(
                                color: NotifyView._textColor,
                                fontSize: AppFontSizes.md,
                                fontWeight: FontWeight.w900,
                                height: 1.22,
                              ),
                            ),
                          ),
                          if (unread) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 7,
                              height: 7,
                              margin: const EdgeInsets.only(top: 5),
                              decoration: BoxDecoration(
                                color: visual.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          color: const Color(0xFF535765),
                          fontSize: AppFontSizes.base,
                          fontWeight: FontWeight.w500,
                          height: 1.34,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            color: NotifyView._mutedColor,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _formatNotificationTime(item.createdAt),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                color: NotifyView._mutedColor,
                                fontSize: AppFontSizes.sm,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({required this.visual, required this.unread});

  final _NotificationVisual visual;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: visual.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(visual.icon, color: visual.color, size: 23),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(strokeWidth: 2.6),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.62,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: NotifyView._primaryColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: NotifyView._primaryColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Chưa có thông báo nào',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: NotifyView._textColor,
                  fontSize: AppFontSizes.lg,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

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
              Icons.error_outline_rounded,
              color: Color(0xFFF82D37),
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyStrong.copyWith(
                color: NotifyView._textColor,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}

class _NotificationDayGroup {
  const _NotificationDayGroup({required this.date, required this.items});

  final DateTime date;
  final List<NotificationEntity> items;
}

class _NotificationVisual {
  const _NotificationVisual({
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  final IconData icon;
  final Color color;
  final Color backgroundColor;
}

List<_NotificationDayGroup> _groupNotifications(
  List<NotificationEntity> items,
) {
  final sorted = [...items]
    ..sort((a, b) {
      final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return right.compareTo(left);
    });

  final groups = <_NotificationDayGroup>[];
  for (final item in sorted) {
    final createdAt = item.createdAt ?? DateTime.now();
    final day = DateTime(createdAt.year, createdAt.month, createdAt.day);
    if (groups.isEmpty || !_isSameDate(groups.last.date, day)) {
      groups.add(_NotificationDayGroup(date: day, items: [item]));
    } else {
      groups.last.items.add(item);
    }
  }
  return groups;
}

_NotificationVisual _visualForItem(NotificationEntity item) {
  final category = item.category.trim().toLowerCase();
  if (category == 'incident') {
    return _visualForIncidentType(item.type);
  }

  return switch (category) {
    'sos' => const _NotificationVisual(
      icon: Icons.sos_outlined,
      color: Color(0xFFFF3B42),
      backgroundColor: Color(0xFFFFEAED),
    ),
    'chat' => const _NotificationVisual(
      icon: Icons.chat_bubble_outline_rounded,
      color: Color(0xFF128C7E),
      backgroundColor: Color(0xFFE6F7F4),
    ),
    'account' => const _NotificationVisual(
      icon: Icons.manage_accounts_outlined,
      color: Color(0xFF8A5A00),
      backgroundColor: Color(0xFFFFF4D8),
    ),
    _ => const _NotificationVisual(
      icon: Icons.notifications_none_rounded,
      color: NotifyView._primaryColor,
      backgroundColor: Color(0xFFF1F2F6),
    ),
  };
}

_NotificationVisual _visualForIncidentType(String type) {
  return switch (type.trim().toLowerCase()) {
    'incident_assigned' => const _NotificationVisual(
      icon: Icons.assignment_ind_outlined,
      color: Color(0xFF4056C8),
      backgroundColor: Color(0xFFEFF2FF),
    ),
    'incident_processing' => const _NotificationVisual(
      icon: Icons.engineering_outlined,
      color: Color(0xFF7A4DCC),
      backgroundColor: Color(0xFFF3ECFF),
    ),
    'incident_completed' => const _NotificationVisual(
      icon: Icons.task_alt_rounded,
      color: Color(0xFF22A45D),
      backgroundColor: Color(0xFFEAF8EE),
    ),
    'incident_cancelled' => const _NotificationVisual(
      icon: Icons.cancel_outlined,
      color: Color(0xFFE14957),
      backgroundColor: Color(0xFFFFECEF),
    ),
    'incident_rejected' => const _NotificationVisual(
      icon: Icons.cancel_outlined,
      color: Color(0xFFE14957),
      backgroundColor: Color(0xFFFFECEF),
    ),
    'incident_reopened' => const _NotificationVisual(
      icon: Icons.restart_alt_rounded,
      color: Color(0xFFF08A00),
      backgroundColor: Color(0xFFFFF3E1),
    ),
    'incident_transferred' => const _NotificationVisual(
      icon: Icons.swap_horiz_rounded,
      color: Color(0xFF7A4DCC),
      backgroundColor: Color(0xFFF3ECFF),
    ),
    'incident_needs_manual_assign' => const _NotificationVisual(
      icon: Icons.assignment_late_outlined,
      color: Color(0xFFD97706),
      backgroundColor: Color(0xFFFFF4DE),
    ),
    _ => const _NotificationVisual(
      icon: Icons.assignment_outlined,
      color: NotifyView._primaryColor,
      backgroundColor: Color(0xFFECEEFF),
    ),
  };
}

String _formatGroupDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final text = _formatDate(date);
  if (_isSameDate(date, today)) {
    return 'Hôm nay, $text';
  }
  return text;
}

String _formatNotificationTime(DateTime? value) {
  if (value == null) {
    return 'Chưa rõ';
  }

  final now = DateTime.now();
  final diff = now.difference(value);
  if (diff.inMinutes < 1) {
    return 'Vừa xong';
  }
  if (diff.inHours < 1) {
    return '${diff.inMinutes} phút trước';
  }
  if (diff.inDays < 1) {
    return '${diff.inHours} giờ trước';
  }
  return _formatDate(value);
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

bool _isSameDate(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}
