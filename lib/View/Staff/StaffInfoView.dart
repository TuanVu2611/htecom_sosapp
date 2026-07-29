// ignore_for_file: file_names

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/AuthUserEntity.dart';
import 'package:hcmu_sos/Theme/AppTypography.dart';
import 'package:hcmu_sos/ViewModel/Staff/StaffInfoViewModel.dart';

class StaffInfoView extends GetWidget<StaffInfoViewModel> {
  const StaffInfoView({super.key});

  static const Color _primaryColor = Color(0xFF29306F);
  static const Color _accentColor = Color(0xFF1FA971);
  static const Color _textColor = Color(0xFF252733);
  static const Color _mutedColor = Color(0xFF858893);
  static const Color _borderColor = Color(0xFFE7E9F2);
  static const Color _softColor = Color(0xFFF7F8FC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(controller: controller),
            Expanded(
              child: Obx(() {
                final user = controller.user.value;
                if (user == null && controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                return RefreshIndicator(
                  onRefresh: controller.refreshProfile,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                    children: [
                      _ProfileCard(controller: controller, user: user),
                      const SizedBox(height: 16),
                      _PersonalInfoCard(controller: controller),
                      const SizedBox(height: 16),
                      _WorkInfoCard(user: user),
                    ],
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

  final StaffInfoViewModel controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: StaffInfoView._borderColor, width: 0.7),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back<void>,
            icon: const Icon(Icons.chevron_left_rounded, size: 30),
            color: StaffInfoView._textColor,
          ),
          Expanded(
            child: Obx(
              () => Text(
                controller.isEditing.value
                    ? 'Chỉnh sửa thông tin'
                    : 'Thông tin cán bộ',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.subtitle.copyWith(
                  color: StaffInfoView._textColor,
                  fontSize: AppFontSizes.xl,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Obx(
            () => IconButton(
              onPressed: controller.isSaving.value || controller.isEditing.value
                  ? null
                  : controller.startEditing,
              icon: Icon(
                controller.isEditing.value
                    ? Icons.edit_off_outlined
                    : Icons.edit_outlined,
                size: 23,
              ),
              color: StaffInfoView._primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.controller, required this.user});

  final StaffInfoViewModel controller;
  final AuthUserEntity? user;

  @override
  Widget build(BuildContext context) {
    final name = user?.displayName ?? '';
    final code = _firstNotEmpty([
      user?.staffCode,
      user?.displayCode,
      user?.staffWork?.employeeCode,
      user?.id,
    ]);
    final active = user?.staffActive ?? user?.staffWork?.staffActive ?? true;

    return Obx(() {
      final bytes = controller.avatarBytes.value;
      final isEditing = controller.isEditing.value;

      return Container(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        decoration: BoxDecoration(
          color: isEditing ? const Color(0xFFF5F7FF) : const Color(0xFFF8F9FD),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isEditing
                ? const Color(0xFFDCE2F7)
                : StaffInfoView._borderColor,
          ),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: isEditing ? controller.pickAvatar : null,
              borderRadius: BorderRadius.circular(58),
              child: _Avatar(
                name: name,
                imageUrl: user?.avatarUrl,
                bytes: bytes,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              name.isEmpty ? 'Cán bộ' : name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle.copyWith(
                color: StaffInfoView._textColor,
                fontSize: AppFontSizes.lg,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (code != null) ...[
              const SizedBox(height: 5),
              Text(
                code,
                style: AppTextStyles.caption.copyWith(
                  color: StaffInfoView._mutedColor,
                  fontSize: AppFontSizes.base,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 14),
            _StatusPill(
              active: active,
              label: active ? 'Đang làm việc' : 'Tạm ngưng làm việc',
            ),
          ],
        ),
      );
    });
  }
}

class _PersonalInfoCard extends StatelessWidget {
  const _PersonalInfoCard({required this.controller});

  final StaffInfoViewModel controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final editing = controller.isEditing.value;
      return Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(16, 16, 16, editing ? 18 : 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: editing
                ? const Color(0xFFDCE2F7)
                : StaffInfoView._borderColor,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: editing ? 'Chỉnh sửa thông tin' : 'Thông tin cá nhân',
            ),
            SizedBox(height: editing ? 16 : 8),
            _InfoField(
              controller: controller.nameController,
              icon: Icons.person_outline_rounded,
              label: 'Họ và tên',
              editing: editing,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
            ),
            if (!editing) const _ViewDivider(),
            _InfoField(
              controller: controller.emailController,
              icon: Icons.mail_outline_rounded,
              label: 'Email',
              editing: editing,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            if (!editing) const _ViewDivider(),
            _InfoField(
              controller: controller.phoneController,
              icon: Icons.phone_in_talk_outlined,
              label: 'Số điện thoại',
              editing: editing,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
            ),
            if (editing)
              Padding(
                padding: const EdgeInsets.only(top: 22),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: controller.isSaving.value
                            ? null
                            : controller.cancelEditing,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: StaffInfoView._primaryColor,
                          side: const BorderSide(
                            color: StaffInfoView._borderColor,
                          ),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: AppTextStyles.bodyStrong.copyWith(
                            fontSize: AppFontSizes.md,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        child: Text('common.cancel'.tr),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: controller.isSaving.value
                            ? null
                            : controller.saveProfile,
                        style: FilledButton.styleFrom(
                          backgroundColor: StaffInfoView._primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: StaffInfoView._primaryColor
                              .withValues(alpha: 0.65),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: AppTextStyles.bodyStrong.copyWith(
                            fontSize: AppFontSizes.md,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        child: controller.isSaving.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.2,
                                ),
                              )
                            : const Text('Lưu thay đổi'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _WorkInfoCard extends StatelessWidget {
  const _WorkInfoCard({required this.user});

  final AuthUserEntity? user;

  @override
  Widget build(BuildContext context) {
    final work = user?.staffWork;
    return _InfoCard(
      title: 'Thông tin công việc',
      children: [
        _InfoRow(
          icon: Icons.verified_user_outlined,
          label: 'Vai trò',
          value: _firstNotEmpty([work?.roleLabel, work?.employeeTypeLabel]),
        ),
        const _ViewDivider(),
        _InfoRow(
          icon: Icons.business_outlined,
          label: 'Phòng ban',
          value: _firstNotEmpty([
            user?.departmentName,
            work?.departmentName,
            user?.department,
            work?.department,
          ]),
        ),
        const _ViewDivider(),
        _InfoRow(
          icon: Icons.apartment_rounded,
          label: 'Bộ phận KTX',
          value: _firstNotEmpty([
            user?.ktxDepartmentName,
            work?.ktxDepartmentName,
          ]),
        ),
        const _ViewDivider(),
        _InfoRow(
          icon: Icons.work_outline_rounded,
          label: 'Chức danh',
          value: work?.jobTitle,
        ),
        const _ViewDivider(),
        _InfoRow(
          icon: Icons.location_on_outlined,
          label: 'Khu vực phụ trách',
          value: work?.zone,
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: StaffInfoView._borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: StaffInfoView._primaryColor,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.subtitle.copyWith(
              color: StaffInfoView._textColor,
              fontSize: AppFontSizes.lg,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final displayValue = value == null || value!.trim().isEmpty
        ? '--'
        : value!.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: StaffInfoView._softColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: StaffInfoView._primaryColor, size: 20),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: StaffInfoView._mutedColor,
                    fontSize: AppFontSizes.sm,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  displayValue,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: StaffInfoView._textColor,
                    fontSize: AppFontSizes.md,
                    fontWeight: FontWeight.w800,
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

class _InfoField extends StatelessWidget {
  const _InfoField({
    required this.controller,
    required this.icon,
    required this.label,
    required this.editing,
    this.keyboardType,
    this.textInputAction,
  });

  final TextEditingController controller;
  final IconData icon;
  final String label;
  final bool editing;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1,
            child: child,
          ),
        );
      },
      child: editing
          ? _InfoEditField(
              key: ValueKey('edit_$label'),
              controller: controller,
              icon: icon,
              label: label,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
            )
          : _InfoViewField(
              key: ValueKey('view_$label'),
              controller: controller,
              icon: icon,
              label: label,
            ),
    );
  }
}

class _InfoViewField extends StatelessWidget {
  const _InfoViewField({
    super.key,
    required this.controller,
    required this.icon,
    required this.label,
  });

  final TextEditingController controller;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return _InfoRow(icon: icon, label: label, value: controller.text);
  }
}

class _InfoEditField extends StatelessWidget {
  const _InfoEditField({
    super.key,
    required this.controller,
    required this.icon,
    required this.label,
    this.keyboardType,
    this.textInputAction,
  });

  final TextEditingController controller;
  final IconData icon;
  final String label;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: StaffInfoView._primaryColor, size: 17),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: StaffInfoView._primaryColor,
                  fontSize: AppFontSizes.sm,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          SizedBox(
            height: 50,
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              style: AppTextStyles.bodyStrong.copyWith(
                color: StaffInfoView._textColor,
                fontSize: AppFontSizes.md,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: StaffInfoView._softColor,
                hintText: label,
                hintStyle: AppTextStyles.body.copyWith(
                  color: StaffInfoView._mutedColor,
                  fontSize: AppFontSizes.md,
                  fontWeight: FontWeight.w500,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFDCE2F2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: StaffInfoView._primaryColor,
                    width: 1.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewDivider extends StatelessWidget {
  const _ViewDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      color: StaffInfoView._borderColor,
      indent: 51,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.active, required this.label});

  final bool active;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = active ? StaffInfoView._accentColor : const Color(0xFFB35C24);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.radio_button_checked_rounded : Icons.pause_circle,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontSize: AppFontSizes.sm,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.imageUrl, this.bytes});

  final String name;
  final String? imageUrl;
  final Uint8List? bytes;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: bytes != null
            ? Image.memory(bytes!, fit: BoxFit.cover)
            : imageUrl == null || imageUrl!.isEmpty
            ? _InitialsAvatar(initials: initials)
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _InitialsAvatar(initials: initials),
              ),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFEFF1F8),
      child: Center(
        child: Text(
          initials.isEmpty ? 'S' : initials,
          style: AppTextStyles.h3.copyWith(
            color: StaffInfoView._primaryColor,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

String? _firstNotEmpty(List<String?> values) {
  for (final value in values) {
    if (value != null && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}
