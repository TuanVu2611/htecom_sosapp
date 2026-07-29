// ignore_for_file: file_names

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Theme/AppTypography.dart';
import 'package:hcmu_sos/ViewModel/Student/StudentInfoViewModel.dart';

class StudentInfoView extends GetWidget<StudentInfoViewModel> {
  const StudentInfoView({super.key});

  static const Color _primaryColor = Color(0xFF29306F);
  static const Color _textColor = Color(0xFF252733);
  static const Color _mutedColor = Color(0xFF858893);
  static const Color _fieldColor = Color(0xFFF7F8FC);
  static const Color _borderColor = Color(0xFFE7E9F2);
  static const Color _pageColor = Colors.white;

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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                child: Column(
                  children: [
                    _ProfileCard(controller: controller),
                    const SizedBox(height: 18),
                    _InfoCard(controller: controller),
                    const SizedBox(height: 18),
                    const _HousingInfoCard(),
                    const SizedBox(height: 18),
                    _DocumentCard(controller: controller),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final StudentInfoViewModel controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: StudentInfoView._borderColor, width: 0.7),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back<void>,
            icon: const Icon(Icons.chevron_left_rounded, size: 30),
            color: StudentInfoView._textColor,
          ),
          Expanded(
            child: Obx(
              () => Text(
                controller.isEditing.value
                    ? 'student.info.editTitle'.tr
                    : 'student.info.title'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.subtitle.copyWith(
                  color: StudentInfoView._textColor,
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
              color: StudentInfoView._primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.controller});

  final StudentInfoViewModel controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.user.value;
      final name = user?.displayName ?? '';
      final code = user?.studentCode ?? '';
      final isEditing = controller.isEditing.value;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
        decoration: BoxDecoration(
          color: isEditing ? const Color(0xFFF5F7FF) : const Color(0xFFF8F9FD),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isEditing
                ? const Color(0xFFDCE2F7)
                : StudentInfoView._borderColor,
          ),
        ),
        child: Column(
          children: [
            _AvatarEditor(controller: controller),
            const SizedBox(height: 14),
            Text(
              name.isEmpty ? 'student.info.fullName'.tr : name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.subtitle.copyWith(
                color: StudentInfoView._textColor,
                fontSize: AppFontSizes.lg,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (code.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                code,
                style: AppTextStyles.caption.copyWith(
                  color: StudentInfoView._mutedColor,
                  fontSize: AppFontSizes.base,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.controller});

  final StudentInfoViewModel controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final editing = controller.isEditing.value;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(16, 16, 16, editing ? 18 : 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: editing
                ? const Color(0xFFDCE2F7)
                : StudentInfoView._borderColor,
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
              title: editing
                  ? 'student.info.editTitle'.tr
                  : 'student.info.personalInfo'.tr,
            ),
            SizedBox(height: editing ? 16 : 8),

            _InfoField(
              controller: controller.studentCodeController,
              icon: Icons.badge_outlined,
              label: 'student.info.studentCode'.tr,
              editing: editing,
              editable: false,
            ),
            if (!editing) const _ViewDivider(),

            _InfoField(
              controller: controller.cccdController,
              icon: Icons.credit_card_rounded,
              label: 'student.info.cccd'.tr,
              editing: editing,
              editable: false,
            ),
            if (!editing) const _ViewDivider(),

            _InfoField(
              controller: controller.nameController,
              icon: Icons.person_outline_rounded,
              label: 'student.info.fullName'.tr,
              editing: editing,
              editable: true,
              textInputAction: TextInputAction.next,
            ),
            if (!editing) const _ViewDivider(),

            _InfoField(
              controller: controller.emailController,
              icon: Icons.mail_outline_rounded,
              label: 'student.info.email'.tr,
              editing: editing,
              editable: true,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            if (!editing) const _ViewDivider(),

            _InfoField(
              controller: controller.phoneController,
              icon: Icons.phone_in_talk_outlined,
              label: 'student.info.phone'.tr,
              editing: editing,
              editable: true,
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
                          foregroundColor: StudentInfoView._primaryColor,
                          side: const BorderSide(
                            color: StudentInfoView._borderColor,
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
                          backgroundColor: StudentInfoView._primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: StudentInfoView._primaryColor
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
                            : Text('student.info.save'.tr),
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
            color: StudentInfoView._primaryColor,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: AppTextStyles.subtitle.copyWith(
            color: StudentInfoView._textColor,
            fontSize: AppFontSizes.lg,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ViewDivider extends StatelessWidget {
  const _ViewDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      color: StudentInfoView._borderColor,
      indent: 51,
    );
  }
}

class _AvatarEditor extends StatelessWidget {
  const _AvatarEditor({required this.controller});

  final StudentInfoViewModel controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.user.value;
      final bytes = controller.avatarBytes.value;
      final name = user?.displayName ?? '';
      final isEditing = controller.isEditing.value;

      return InkWell(
        onTap: isEditing ? controller.pickAvatar : null,
        borderRadius: BorderRadius.circular(58),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _AvatarImage(name: name, imageUrl: user?.avatarUrl, bytes: bytes),
            if (isEditing)
              Positioned(
                right: 0,
                bottom: 2,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: StudentInfoView._primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.photo_camera_outlined,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({required this.name, this.imageUrl, this.bytes});

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
          initials.isEmpty ? 'U' : initials,
          style: AppTextStyles.h3.copyWith(
            color: StudentInfoView._primaryColor,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.controller});

  final StudentInfoViewModel controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.user.value;
      final studentCard = user?.studentCard;
      final nationalCard = user?.nationalCard;
      final hasAnyImage =
          _hasImage(studentCard?.frontUrl) ||
          _hasImage(studentCard?.backUrl) ||
          _hasImage(nationalCard?.frontUrl) ||
          _hasImage(nationalCard?.backUrl);

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: StudentInfoView._borderColor),
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
            _SectionHeader(title: 'student.info.documents'.tr),
            const SizedBox(height: 14),
            if (!hasAnyImage)
              _EmptyDocumentState(message: 'student.info.noDocuments'.tr)
            else ...[
              _DocumentGroup(
                title: 'student.info.studentCard'.tr,
                frontUrl: studentCard?.frontUrl,
                backUrl: studentCard?.backUrl,
              ),
              const SizedBox(height: 14),
              _DocumentGroup(
                title: 'student.info.nationalCard'.tr,
                frontUrl: nationalCard?.frontUrl,
                backUrl: nationalCard?.backUrl,
              ),
            ],
          ],
        ),
      );
    });
  }

  bool _hasImage(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}

class _HousingInfoCard extends GetWidget<StudentInfoViewModel> {
  const _HousingInfoCard();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.user.value;
      final roomBuilding = user?.roomBuilding?.trim();
      final ktxArea = user?.ktxArea?.trim();
      final hasRoomBuilding = roomBuilding != null && roomBuilding.isNotEmpty;
      final hasKtxArea = ktxArea != null && ktxArea.isNotEmpty;

      if (!hasRoomBuilding && !hasKtxArea) {
        return const SizedBox.shrink();
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: StudentInfoView._borderColor),
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
            _SectionHeader(title: 'student.info.housingInfo'.tr),
            const SizedBox(height: 14),
            if (hasRoomBuilding)
              _HousingInfoTile(
                icon: Icons.meeting_room_outlined,
                label: 'student.info.roomBuilding'.tr,
                value: roomBuilding,
              ),
            if (hasRoomBuilding && hasKtxArea) const SizedBox(height: 10),
            if (hasKtxArea)
              _HousingInfoTile(
                icon: Icons.location_city_outlined,
                label: 'student.info.ktxArea'.tr,
                value: ktxArea,
              ),
          ],
        ),
      );
    });
  }
}

class _HousingInfoTile extends StatelessWidget {
  const _HousingInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: StudentInfoView._borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF2FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: StudentInfoView._primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: StudentInfoView._mutedColor,
                    fontSize: AppFontSizes.base,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: StudentInfoView._textColor,
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

class _DocumentGroup extends StatelessWidget {
  const _DocumentGroup({
    required this.title,
    required this.frontUrl,
    required this.backUrl,
  });

  final String title;
  final String? frontUrl;
  final String? backUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.bodyStrong.copyWith(
            color: StudentInfoView._textColor,
            fontSize: AppFontSizes.md,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: _DocumentImageTile(
                label: 'student.info.front'.tr,
                imageUrl: frontUrl,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DocumentImageTile(
                label: 'student.info.back'.tr,
                imageUrl: backUrl,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DocumentImageTile extends StatelessWidget {
  const _DocumentImageTile({required this.label, required this.imageUrl});

  final String label;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1.58,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5FA),
                border: Border.all(color: StudentInfoView._borderColor),
              ),
              child: hasImage
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _DocumentPlaceholder(),
                    )
                  : const _DocumentPlaceholder(),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(
            color: StudentInfoView._mutedColor,
            fontSize: AppFontSizes.sm,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DocumentPlaceholder extends StatelessWidget {
  const _DocumentPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        color: StudentInfoView._mutedColor,
        size: 24,
      ),
    );
  }
}

class _EmptyDocumentState extends StatelessWidget {
  const _EmptyDocumentState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StudentInfoView._borderColor),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.perm_media_outlined,
            color: StudentInfoView._primaryColor,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.body.copyWith(
                color: StudentInfoView._mutedColor,
                fontSize: AppFontSizes.md,
                fontWeight: FontWeight.w600,
              ),
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
    required this.editable,
    this.keyboardType,
    this.textInputAction,
  });

  final TextEditingController controller;
  final IconData icon;
  final String label;
  final bool editing;
  final bool editable;
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
      child: editing && editable
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
    final value = controller.text.trim().isEmpty
        ? '--'
        : controller.text.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F5FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: StudentInfoView._primaryColor, size: 20),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: StudentInfoView._mutedColor,
                    fontSize: AppFontSizes.sm,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: StudentInfoView._textColor,
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
              Icon(icon, color: StudentInfoView._primaryColor, size: 17),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: StudentInfoView._primaryColor,
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
                color: StudentInfoView._textColor,
                fontSize: AppFontSizes.md,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: StudentInfoView._fieldColor,
                hintText: label,
                hintStyle: AppTextStyles.body.copyWith(
                  color: StudentInfoView._mutedColor,
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
                    color: StudentInfoView._primaryColor,
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
