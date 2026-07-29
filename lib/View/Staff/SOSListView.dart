// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/StaffHomeEntity.dart';
import 'package:hcmu_sos/Navigator/AppRoute.dart';
import 'package:hcmu_sos/Theme/AppTypography.dart';
import 'package:hcmu_sos/ViewModel/Staff/SOSListViewModel.dart';
import 'package:url_launcher/url_launcher.dart';

class SOSListView extends GetWidget<SOSListViewModel> {
  const SOSListView({super.key});

  static const Color _primaryColor = Color(0xFF29306F);
  static const Color _dangerColor = Color(0xFFF82D37);
  static const Color _successColor = Color(0xFF22B45A);
  static const Color _textColor = Color(0xFF232633);
  static const Color _mutedColor = Color(0xFF858996);
  static const Color _pageColor = Color(0xFFF7F8FC);
  static const Color _borderColor = Color(0xFFE1E4EF);

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
                if (controller.isLoading.value && controller.sosItems.isEmpty) {
                  return const _LoadingState();
                }

                if (controller.errorMessage.value != null &&
                    controller.sosItems.isEmpty) {
                  return _ErrorState(
                    message: controller.errorMessage.value!,
                    onRetry: () {
                      controller.loadFirstPage();
                    },
                  );
                }

                if (controller.sosItems.isEmpty) {
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
                          notification.metrics.maxScrollExtent - 160) {
                        controller.loadMore();
                      }
                      return false;
                    },
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: controller.sosItems.length + 2,
                      separatorBuilder: (_, index) =>
                          SizedBox(height: index == 0 ? 12 : 14),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _SummaryBanner(
                            count: controller.total.value == 0
                                ? controller.sosItems.length
                                : controller.total.value,
                          );
                        }
                        if (index == controller.sosItems.length + 1) {
                          return Obx(
                            () => controller.isLoadingMore.value
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Center(
                                      child: SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          );
                        }
                        final item = controller.sosItems[index - 1];
                        return _SosCard(
                          item: item,
                          onTap: () async {
                            await Get.toNamed(
                              AppRoute.staffSosDetail,
                              arguments: item,
                            );
                            await controller.loadFirstPage();
                          },
                        );
                      },
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
            color: SOSListView._textColor,
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Text(
              'SOS khẩn cấp',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.subtitle.copyWith(
                color: SOSListView._textColor,
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

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDEE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFCED2)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: SOSListView._dangerColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count SOS đang hoạt động',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: SOSListView._dangerColor,
                    fontSize: AppFontSizes.md,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Ưu tiên kiểm tra liên hệ sinh viên và xử lý theo tiến trình.',
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF794250),
                    fontSize: AppFontSizes.base,
                    fontWeight: FontWeight.w700,
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

class _SosCard extends StatelessWidget {
  const _SosCard({required this.item, required this.onTap});

  final StaffActiveSosEntity item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final student = item.student;
    final studentName = _firstText(student?.name, null) ?? 'Sinh viên';
    final studentCode = _firstText(student?.studentCode, null);
    final studentPhone = _firstText(student?.phone, null);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF0D2D5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const _SosIcon(),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studentName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyStrong.copyWith(
                              color: SOSListView._textColor,
                              fontSize: AppFontSizes.lg,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            studentCode == null
                                ? 'SOS #${item.id}'
                                : '$studentCode · SOS #${item.id}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: SOSListView._mutedColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (studentPhone != null)
                      _PhoneButton(phone: studentPhone)
                    else
                      const _UnavailablePhoneButton(),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: SOSListView._mutedColor,
                      size: 22,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFBFE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: SOSListView._borderColor),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _StatusChip(status: item.status),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: _TimeChip(createdAt: item.createdAt),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      _AssigneeLine(name: _staffName(item.assignedStaff?.name)),
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

class _PhoneButton extends StatelessWidget {
  const _PhoneButton({required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _callPhone(phone),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: SOSListView._successColor,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.phone_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}

class _UnavailablePhoneButton extends StatelessWidget {
  const _UnavailablePhoneButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(
        color: Color(0xFFE8EAF2),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.phone_disabled_rounded,
        color: SOSListView._mutedColor,
        size: 19,
      ),
    );
  }
}

class _SosIcon extends StatelessWidget {
  const _SosIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFFFFE5E8),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.warning_amber_rounded,
        color: SOSListView._dangerColor,
        size: 24,
      ),
    );
  }
}

class _AssigneeLine extends StatelessWidget {
  const _AssigneeLine({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.support_agent_rounded,
          color: SOSListView._primaryColor,
          size: 18,
        ),
        const SizedBox(width: 7),
        Text(
          'Cán bộ phụ trách',
          style: AppTextStyles.caption.copyWith(
            color: SOSListView._mutedColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: AppTextStyles.caption.copyWith(
              color: SOSListView._textColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(status),
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontSize: AppFontSizes.base,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.createdAt});

  final DateTime? createdAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: SOSListView._borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.schedule_rounded,
            color: SOSListView._mutedColor,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            _formatDateTime(createdAt),
            style: AppTextStyles.caption.copyWith(
              color: SOSListView._mutedColor,
              fontSize: AppFontSizes.base,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
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
              Icons.cloud_off_rounded,
              color: SOSListView._dangerColor,
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyStrong.copyWith(
                color: SOSListView._textColor,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onRetry,
              style: _outlinedButtonStyle(),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.72,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEDEE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: SOSListView._dangerColor,
                  size: 34,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Không có SOS khẩn cấp',
                textAlign: TextAlign.center,
                style: AppTextStyles.subtitle.copyWith(
                  color: SOSListView._textColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Danh sách SOS đang hoạt động sẽ hiển thị tại đây.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: SOSListView._mutedColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

ButtonStyle _outlinedButtonStyle() {
  return OutlinedButton.styleFrom(
    foregroundColor: SOSListView._primaryColor,
    side: const BorderSide(color: SOSListView._borderColor),
    minimumSize: const Size.fromHeight(42),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: AppTextStyles.bodyStrong.copyWith(
      fontSize: AppFontSizes.base,
      fontWeight: FontWeight.w900,
    ),
  );
}

String _staffName(String? value) {
  if (value != null && value.trim().isNotEmpty) {
    return value.trim();
  }
  return 'Chưa phân công';
}

String? _firstText(String? value, String? fallback) {
  if (value != null && value.trim().isNotEmpty) {
    return value.trim();
  }
  return fallback;
}

Color _statusColor(String status) {
  return switch (status.toLowerCase()) {
    'pending' => SOSListView._dangerColor,
    'in_progress' => SOSListView._primaryColor,
    'reopened' => const Color(0xFF2D6CDF),
    'done' => SOSListView._successColor,
    'rejected' => SOSListView._mutedColor,
    _ => SOSListView._dangerColor,
  };
}

String _statusLabel(String status) {
  return switch (status.toLowerCase()) {
    'pending' => 'Chờ tiếp nhận',
    'in_progress' => 'Đang xử lý',
    'reopened' => 'Đã mở lại',
    'done' => 'Hoàn thành',
    'rejected' => 'Từ chối',
    _ => 'SOS khẩn cấp',
  };
}

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return 'Chưa rõ';
  }
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$hour:$minute - $day/$month/${value.year}';
}

Future<void> _callPhone(String phone) async {
  final normalizedPhone = phone.replaceAll(RegExp(r'\s+'), '');
  final uri = Uri(scheme: 'tel', path: normalizedPhone);
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched) {
    Get.snackbar('Liên hệ', phone, snackPosition: SnackPosition.BOTTOM);
  }
}
