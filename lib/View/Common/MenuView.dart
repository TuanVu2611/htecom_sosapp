// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/StaffPerformanceEntity.dart';
import 'package:hcmu_sos/Navigator/AppRoute.dart';
import 'package:hcmu_sos/Theme/AppTypography.dart';
import 'package:hcmu_sos/ViewModel/Common/MenuViewModel.dart';

String _menuText({required String vi, required String en}) {
  return Get.locale?.languageCode == 'en' ? en : vi;
}

const Color _primaryColor = Color(0xFF29306F);
const Color _mutedColor = Color(0xFF8A8D99);
const Color _lineColor = Color(0xFFEEF0F6);
const Color _iconSoftColor = Color(0xFF4B5278);
const Color _titleColor = Color(0xFF2C2F3A);
const Color _bodyColor = Color(0xFF343843);

class MenuView extends GetWidget<MenuViewModel> {
  const MenuView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _ProfileHeader(controller: controller)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 28, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(
                    title: _menuText(vi: 'Thông tin chung', en: 'General'),
                  ),
                  const SizedBox(height: 10),
                  _MenuCard(
                    children: [
                      _MenuActionTile(
                        icon: Icons.person_search_outlined,
                        title: _menuText(
                          vi: 'Thông tin tài khoản',
                          en: 'Account information',
                        ),
                        onTap: controller.openAccountInfo,
                      ),
                      if (controller.isStaff)
                        _MenuActionTile(
                          icon: Icons.bar_chart_rounded,
                          title: _menuText(
                            vi: 'Thống kê hiệu suất',
                            en: 'Performance statistics',
                          ),
                          onTap: controller.openStaffPerformance,
                        ),
                      _MenuActionTile(
                        icon: Icons.menu_book_outlined,
                        title: _menuText(
                          vi: 'Hướng dẫn sử dụng',
                          en: 'User guide',
                        ),
                        onTap: () => controller.openGuidelinesOfUse(
                          _menuText(vi: 'Hướng dẫn sử dụng', en: 'User guide'),
                        ),
                      ),
                      _MenuActionTile(
                        icon: Icons.description_outlined,
                        title: _menuText(
                          vi: 'Điều khoản sử dụng',
                          en: 'Terms of use',
                        ),
                        onTap: () => controller.openTermsOfUse(
                          _menuText(
                            vi: 'Điều khoản sử dụng',
                            en: 'Terms of use',
                          ),
                        ),
                      ),
                      _MenuActionTile(
                        icon: Icons.support_agent_rounded,
                        title: _menuText(
                          vi: 'Hotline hỗ trợ KTX',
                          en: 'Dormitory support hotline',
                        ),
                        trailing: Text(
                          '1900-56789',
                          style: AppTextStyles.bodyStrong.copyWith(
                            color: _primaryColor,
                            fontSize: AppFontSizes.base,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        showChevron: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle(
                    title: _menuText(vi: 'Cài đặt', en: 'Settings'),
                  ),
                  const SizedBox(height: 10),
                  _MenuCard(
                    children: [
                      Obx(
                        () => _MenuSwitchTile(
                          icon: Icons.notifications_none_rounded,
                          title: _menuText(
                            vi: 'Thông báo đẩy',
                            en: 'Push notifications',
                          ),
                          value: controller.pushNotificationsEnabled.value,
                          onChanged: controller.togglePushNotifications,
                        ),
                      ),
                      Obx(
                        () => _MenuSwitchTile(
                          icon: Icons.sos_outlined,
                          title: _menuText(
                            vi: 'Nhận cảnh báo SOS gần bạn',
                            en: 'Nearby SOS alerts',
                          ),
                          value: controller.nearbySosAlertsEnabled.value,
                          onChanged: controller.toggleNearbySosAlerts,
                        ),
                      ),
                      GetBuilder<MenuViewModel>(
                        builder: (controller) => _MenuActionTile(
                          icon: Icons.g_translate_rounded,
                          title: _menuText(vi: 'Ngôn ngữ', en: 'Language'),
                          trailing: Text(
                            controller.languageLabel,
                            style: AppTextStyles.bodyStrong.copyWith(
                              color: _primaryColor,
                              fontSize: AppFontSizes.base,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onTap: () => _showLanguageSheet(context, controller),
                        ),
                      ),
                      if (!controller.isStaff)
                        _MenuActionTile(
                          icon: Icons.lock_outline_rounded,
                          title: _menuText(
                            vi: 'Đổi mật khẩu',
                            en: 'Change password',
                          ),
                          onTap: () {
                            Get.toNamed(AppRoute.changePassword);
                          },
                        ),
                      if (controller.canDeactivateAccount)
                        _MenuActionTile(
                          icon: Icons.person_remove_alt_1_outlined,
                          iconColor: const Color(0xFFD92D20),
                          titleColor: const Color(0xFFD92D20),
                          title: 'auth.deactivateAccount'.tr,
                          onTap: () =>
                              _showDeactivateAccountConfirm(context, controller),
                        ),
                      _MenuActionTile(
                        icon: Icons.logout_rounded,
                        title: _menuText(vi: 'Đăng xuất', en: 'Sign out'),
                        showChevron: false,
                        onTap: () => _showLogoutConfirm(context, controller),
                      ),
                      const _VersionTile(),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.controller});

  final MenuViewModel controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final topPadding = MediaQuery.of(context).padding.top;
      final user = controller.currentUser;
      final isStaff = controller.isStaff;

      final name = user?.displayName.isNotEmpty == true
          ? user!.displayName
          : _menuText(vi: 'Người dùng', en: 'User');

      final code = user?.staffCode ?? user?.studentCode ?? user?.id ?? '';

      return SizedBox(
        height: topPadding + (isStaff ? 382 : 244),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topPadding + 166,
              child: CustomPaint(
                painter: const _HeaderBackgroundPainter(),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(15, topPadding + 15, 15, 0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      _menuText(vi: 'Tài khoản', en: 'Account'),
                      style: AppTextStyles.subtitle.copyWith(
                        color: Colors.white,
                        fontSize: AppFontSizes.xl,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: topPadding + 104,
              child: Column(
                children: [
                  _Avatar(name: name, imageUrl: user?.avatarUrl),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.subtitle.copyWith(
                        color: const Color(0xFF2B2F38),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (code.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: _mutedColor,
                        fontSize: AppFontSizes.base,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (isStaff) ...[
                    const SizedBox(height: 5),
                    _StaffRatingLine(controller: controller),
                  ],
                  if (isStaff) ...[
                    const SizedBox(height: 18),
                    _StaffMetricStrip(controller: controller),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _StaffRatingLine extends StatelessWidget {
  const _StaffRatingLine({required this.controller});

  final MenuViewModel controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final rating = controller.staffPerformance.value.ratingAvg;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFFFA31A), size: 15),
          const SizedBox(width: 3),
          Text(
            '${_formatRating(rating)}/5.0',
            style: AppTextStyles.caption.copyWith(
              color: _mutedColor,
              fontSize: AppFontSizes.sm,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    });
  }
}

class _StaffMetricStrip extends StatelessWidget {
  const _StaffMetricStrip({required this.controller});

  final MenuViewModel controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final performance = controller.staffPerformance.value;
      final processing = _processingCount(performance);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            Expanded(
              child: _StaffMetricCard(
                label: _menuText(vi: 'Hoàn thành', en: 'Completed'),
                value: performance.completed.toString(),
                color: const Color(0xFF21B85C),
                icon: Icons.check_circle_outline_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StaffMetricCard(
                label: _menuText(vi: 'TB xử lý', en: 'Avg time'),
                value: _formatPerformanceHours(
                  performance.avgProcessingTimeHours,
                ),
                color: const Color(0xFF4084FF),
                icon: Icons.schedule_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StaffMetricCard(
                label: _menuText(vi: 'Hiệu suất', en: 'Efficiency'),
                value: '${performance.completionRate.round()}%',
                color: const Color(0xFFFF9800),
                icon: processing > 0
                    ? Icons.bolt_rounded
                    : Icons.check_circle_outline_rounded,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _StaffMetricCard extends StatelessWidget {
  const _StaffMetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF0F1F6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 5),
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
              size: const Size.fromHeight(28),
              painter: _MetricIconBackgroundPainter(color.withOpacity(0.10)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 10, 6, 7),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF747887),
                    fontSize: AppFontSizes.sm,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                SizedBox(
                  height: 24,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: AppTextStyles.subtitle.copyWith(
                        color: color,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
                Icon(icon, color: color, size: 19),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricIconBackgroundPainter extends CustomPainter {
  const _MetricIconBackgroundPainter(this.color);

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
  bool shouldRepaint(covariant _MetricIconBackgroundPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _HeaderBackgroundPainter extends CustomPainter {
  const _HeaderBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _primaryColor;

    final path = Path()
      ..lineTo(0, size.height - 42)
      ..quadraticBezierTo(
        size.width * 0.02,
        size.height,
        size.width * 0.18,
        size.height,
      )
      ..lineTo(size.width * 0.82, size.height)
      ..quadraticBezierTo(
        size.width * 0.98,
        size.height,
        size.width,
        size.height - 42,
      )
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withOpacity(0.045);

    final center = Offset(size.width * 0.5, size.height - 18);

    for (final radius in <double>[54, 88, 122]) {
      canvas.drawCircle(center, radius, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HeaderBackgroundPainter oldDelegate) => false;
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
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl == null
            ? CircleAvatar(
                backgroundColor: const Color(0xFFEFF1F8),
                child: Text(
                  initials.isEmpty ? 'U' : initials,
                  style: AppTextStyles.h3.copyWith(
                    color: _primaryColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            : Image.network(
                imageUrl!,
                width: 88,
                height: 88,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => CircleAvatar(
                  backgroundColor: const Color(0xFFEFF1F8),
                  child: Text(
                    initials.isEmpty ? 'U' : initials,
                    style: AppTextStyles.h3.copyWith(
                      color: _primaryColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.subtitle.copyWith(
        color: _titleColor,
        fontSize: AppFontSizes.base,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0F1F6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              const Divider(height: 1, color: _lineColor, indent: 36),
          ],
        ],
      ),
    );
  }
}

class _MenuActionTile extends StatelessWidget {
  const _MenuActionTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.showChevron = true,
    this.titleColor,
    this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final bool showChevron;
  final Color? titleColor;
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              Icon(icon, color: iconColor ?? _iconSoftColor, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: titleColor ?? _bodyColor,
                    fontSize: AppFontSizes.base,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 10), trailing!],
              if (showChevron) ...[
                const SizedBox(width: 8),
                const _ChevronButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuSwitchTile extends StatelessWidget {
  const _MenuSwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Icon(icon, color: _iconSoftColor, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyStrong.copyWith(
                color: _bodyColor,
                fontSize: AppFontSizes.base,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: _primaryColor,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFD9DCE8),
          ),
        ],
      ),
    );
  }
}

class _VersionTile extends StatelessWidget {
  const _VersionTile();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: _iconSoftColor,
            size: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _menuText(vi: 'Phiên bản ứng dụng', en: 'App version'),
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: _bodyColor,
                    fontSize: AppFontSizes.base,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'v1.0.0',
                  style: AppTextStyles.caption.copyWith(
                    color: _mutedColor,
                    fontSize: AppFontSizes.sm,
                    fontWeight: FontWeight.w500,
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

class _ChevronButton extends StatelessWidget {
  const _ChevronButton();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.chevron_right_rounded,
      color: Color(0xFFB8BDCA),
      size: 22,
    );
  }
}

int _processingCount(StaffPerformanceEntity performance) {
  final processing = performance.totalAssigned - performance.completed;
  return processing < 0 ? 0 : processing;
}

String _formatPerformanceHours(double hours) {
  if (hours <= 0) {
    return '0 phút';
  }
  if (hours < 1) {
    return '${(hours * 60).round()} phút';
  }
  return '${hours.round()} giờ';
}

String _formatRating(double rating) {
  if (rating == rating.roundToDouble()) {
    return rating.toStringAsFixed(0);
  }
  return rating.toStringAsFixed(1);
}

void _showLanguageSheet(BuildContext context, MenuViewModel controller) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _menuText(vi: 'Chọn ngôn ngữ', en: 'Choose language'),
                style: AppTextStyles.subtitle.copyWith(
                  color: const Color(0xFF2B2F38),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              for (final locale in controller.supportedLocales)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    controller.languageLabelFor(locale),
                    style: AppTextStyles.bodyStrong.copyWith(
                      color: _bodyColor,
                      fontSize: AppFontSizes.base,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  trailing: controller.isCurrentLocale(locale)
                      ? const Icon(Icons.check_rounded, color: _primaryColor)
                      : null,
                  onTap: () async {
                    await controller.changeLanguage(locale);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}

void _showLogoutConfirm(BuildContext context, MenuViewModel controller) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEEF0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFF82D37),
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _menuText(vi: 'Đăng xuất', en: 'Sign out'),
                textAlign: TextAlign.center,
                style: AppTextStyles.subtitle.copyWith(
                  color: const Color(0xFF2B2F38),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _menuText(
                  vi: 'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản này?',
                  en: 'Are you sure you want to sign out of this account?',
                ),
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: _mutedColor,
                  fontSize: AppFontSizes.base,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryColor,
                        side: const BorderSide(color: _lineColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size.fromHeight(44),
                        textStyle: AppTextStyles.button.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text(_menuText(vi: 'Huỷ', en: 'Cancel')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await controller.logout();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF82D37),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size.fromHeight(44),
                        textStyle: AppTextStyles.button.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text(_menuText(vi: 'Đăng xuất', en: 'Sign out')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _showDeactivateAccountConfirm(
  BuildContext context,
  MenuViewModel controller,
) {
  final passwordController = TextEditingController();
  final obscurePassword = ValueNotifier<bool>(true);

  showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEEF0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_remove_alt_1_rounded,
                  color: Color(0xFFD92D20),
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'auth.deactivateAccount'.tr,
                textAlign: TextAlign.center,
                style: AppTextStyles.subtitle.copyWith(
                  color: const Color(0xFF2B2F38),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'auth.deactivateAccountHint'.tr,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: _mutedColor,
                  fontSize: AppFontSizes.base,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<bool>(
                valueListenable: obscurePassword,
                builder: (context, isObscured, _) {
                  return TextField(
                    controller: passwordController,
                    obscureText: isObscured,
                    onTapOutside: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    decoration: InputDecoration(
                      hintText: 'auth.deactivateAccountPasswordHint'.tr,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () =>
                            obscurePassword.value = !obscurePassword.value,
                        icon: Icon(
                          isObscured
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _lineColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _lineColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _primaryColor),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: controller.isDeactivatingAccount.value
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryColor,
                          side: const BorderSide(color: _lineColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: const Size.fromHeight(44),
                          textStyle: AppTextStyles.button.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: Text(_menuText(vi: 'Huỷ', en: 'Cancel')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: controller.isDeactivatingAccount.value
                            ? null
                            : () async {
                                final navigator = Navigator.of(context);
                                final success =
                                    await controller.deactivateAccount(
                                  password: passwordController.text,
                                );
                                if (success && navigator.mounted) {
                                  navigator.pop();
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFD92D20),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: const Size.fromHeight(44),
                          textStyle: AppTextStyles.button.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: controller.isDeactivatingAccount.value
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text('auth.deactivateAccount'.tr),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  ).whenComplete(() {
    passwordController.dispose();
    obscurePassword.dispose();
  });
}
