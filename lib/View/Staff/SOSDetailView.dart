// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Component/InteractiveTileMap.dart';
import 'package:hcmu_sos/Entity/StaffHomeEntity.dart';
import 'package:hcmu_sos/Entity/SupportRequestEntity.dart';
import 'package:hcmu_sos/Theme/AppTypography.dart';
import 'package:hcmu_sos/Utils/Utils.dart';
import 'package:hcmu_sos/ViewModel/Staff/SOSDetailViewModel.dart';
import 'package:url_launcher/url_launcher.dart';

class SOSViewDetail extends GetWidget<SOSDetailViewModel> {
  const SOSViewDetail({super.key});

  static const Color _primaryColor = Color(0xFF29306F);
  static const Color _dangerColor = Color(0xFFF82D37);
  static const Color _successColor = Color(0xFF22B45A);
  static const Color _textColor = Color(0xFF222532);
  static const Color _mutedColor = Color(0xFF858996);
  static const Color _pageColor = Color(0xFFF7F8FC);
  static const Color _borderColor = Color(0xFFE2E4F0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageColor,
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          final item = controller.sos.value;
          if (item == null) {
            return const _MissingState();
          }

          return Column(
            children: [
              const _Header(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    _MapSection(item: item),
                    const SizedBox(height: 12),
                    _InfoCard(item: item),
                    const SizedBox(height: 12),
                    _TimelineCard(controller: controller, item: item),
                    if (item.checklist.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _ChecklistSection(item: item, controller: controller),
                    ],
                    const SizedBox(height: 12),
                    _ReportCard(controller: controller),
                  ],
                ),
              ),
              _BottomActions(controller: controller, item: item),
            ],
          );
        }),
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
            color: SOSViewDetail._textColor,
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Text(
              'Chi tiết SOS',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.subtitle.copyWith(
                color: SOSViewDetail._textColor,
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

class _MapSection extends StatelessWidget {
  const _MapSection({required this.item});

  final StaffActiveSosEntity item;

  @override
  Widget build(BuildContext context) {
    final latitude = item.latitude;
    final longitude = item.longitude;
    final hasCoordinates = latitude != null && longitude != null;

    return Container(
      height: 236,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SOSViewDetail._borderColor),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasCoordinates)
            InteractiveTileMap(
              latitude: latitude,
              longitude: longitude,
              height: 236,
              primaryColor: SOSViewDetail._primaryColor,
              dangerColor: SOSViewDetail._dangerColor,
              borderColor: SOSViewDetail._borderColor,
              onDirections: () => _openDirections(latitude, longitude),
            )
          else
            Container(
              color: const Color(0xFFEFF2F6),
              alignment: Alignment.center,
              child: Text(
                'Chưa có tọa độ SOS',
                style: AppTextStyles.bodyStrong.copyWith(
                  color: SOSViewDetail._mutedColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.item});

  final StaffActiveSosEntity item;

  @override
  Widget build(BuildContext context) {
    final assignee = item.assignedStaff;
    final student = item.student;
    final studentName = _firstText(student?.name, null) ?? 'Sinh viên';
    final studentCode = _firstText(student?.studentCode, null);
    final studentPhone = _firstText(student?.phone, null);
    final studentEmail = _firstText(student?.email, null);
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StudentAvatar(name: studentName, imageUrl: student?.avatarUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: SOSViewDetail._textColor,
                        fontSize: AppFontSizes.lg,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (studentCode != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        studentCode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: SOSViewDetail._mutedColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _StatusChip(status: item.status),
                        _TimeChip(createdAt: item.createdAt),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _CircleContactButtons(phone: studentPhone),
            ],
          ),
          const SizedBox(height: 14),
          _DetailRow(
            icon: Icons.badge_outlined,
            label: 'Mã SOS',
            value: '#${item.id}',
          ),
          if (_hasText(studentPhone)) ...[
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.phone_outlined,
              label: 'SĐT sinh viên',
              value: studentPhone!,
              onTap: () => _callPhone(studentPhone),
            ),
          ],
          if (studentEmail != null) ...[
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.mail_outline_rounded,
              label: 'Email sinh viên',
              value: studentEmail,
            ),
          ],
          const SizedBox(height: 8),
          _DetailRow(
            icon: Icons.person_pin_circle_outlined,
            label: 'Cán bộ phụ trách',
            value: _staffName(assignee?.name),
          ),
          if (_hasText(assignee?.phone)) ...[
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.phone_outlined,
              label: 'Số điện thoại',
              value: assignee!.phone!,
              onTap: () => _callPhone(assignee.phone!),
            ),
          ],
        ],
      ),
    );
  }
}

class _StudentAvatar extends StatelessWidget {
  const _StudentAvatar({required this.name, this.imageUrl});

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
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFFEFF1FF),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: ClipOval(
        child: imageUrl == null
            ? Text(
                initials.isEmpty ? 'SV' : initials,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: SOSViewDetail._primaryColor,
                  fontWeight: FontWeight.w900,
                ),
              )
            : Image.network(
                imageUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: Text(
                    initials.isEmpty ? 'SV' : initials,
                    style: AppTextStyles.bodyStrong.copyWith(
                      color: SOSViewDetail._primaryColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _CircleContactButtons extends StatelessWidget {
  const _CircleContactButtons({this.phone});

  final String? phone;

  @override
  Widget build(BuildContext context) {
    final enabled = _hasText(phone);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CompactActionButton(
          backgroundColor: Colors.transparent,
          foregroundColor: enabled ? Colors.white : SOSViewDetail._mutedColor,
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
        _CompactActionButton(
          backgroundColor: enabled
              ? SOSViewDetail._successColor
              : const Color(0xFFE5E7EF),
          foregroundColor: enabled ? Colors.white : SOSViewDetail._mutedColor,
          onTap: enabled ? () => _callPhone(phone!) : null,
          child: const Icon(Icons.phone_rounded, size: 20),
        ),
      ],
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  const _CompactActionButton({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.child,
    this.onTap,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: IconTheme(
          data: IconThemeData(color: foregroundColor),
          child: DefaultTextStyle(
            style: TextStyle(
              color: foregroundColor,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.controller, required this.item});

  final SOSDetailViewModel controller;
  final StaffActiveSosEntity item;

  @override
  Widget build(BuildContext context) {
    final timeline = item.timeline.isEmpty
        ? _fallbackTimeline(item.status, item.createdAt)
        : item.timeline;
    final actions = _statusActions(item);
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tiến trình xử lý',
            style: AppTextStyles.bodyStrong.copyWith(
              color: SOSViewDetail._textColor,
              fontSize: AppFontSizes.lg,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < timeline.length; index++)
            _TimelineStep(
              step: timeline[index],
              isLast: index == timeline.length - 1,
              isCurrent: timeline[index].status == item.status,
            ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 14),
            _QuickUpdateBox(controller: controller, actions: actions),
          ],
        ],
      ),
    );
  }
}

class _QuickUpdateBox extends StatelessWidget {
  const _QuickUpdateBox({required this.controller, required this.actions});

  final SOSDetailViewModel controller;
  final List<StaffSosTimelineEntity> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE3FA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cập nhật nhanh',
            style: AppTextStyles.bodyStrong.copyWith(
              color: SOSViewDetail._primaryColor,
              fontSize: AppFontSizes.md,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Obx(() {
            final isUpdating = controller.isUpdating.value;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions
                  .map(
                    (step) => _StatusActionButton(
                      step: step,
                      isUpdating: isUpdating,
                      onPressed: () =>
                          step.status.trim().toLowerCase() == 'rejected'
                          ? _confirmCancelledStatusUpdate(
                              context: context,
                              controller: controller,
                              status: step.status,
                            )
                          : _confirmStatusUpdate(
                              context: context,
                              controller: controller,
                              status: step.status,
                              label: step.label.isEmpty
                                  ? _statusLabel(step.status)
                                  : step.label,
                            ),
                    ),
                  )
                  .toList(),
            );
          }),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.step,
    required this.isLast,
    required this.isCurrent,
  });

  final StaffSosTimelineEntity step;
  final bool isLast;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final color = step.reached
        ? SOSViewDetail._successColor
        : isCurrent
        ? SOSViewDetail._primaryColor
        : SOSViewDetail._borderColor;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: step.reached || isCurrent ? color : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(
                step.reached ? Icons.check_rounded : Icons.circle_outlined,
                size: step.reached ? 17 : 12,
                color: step.reached || isCurrent
                    ? Colors.white
                    : SOSViewDetail._mutedColor,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: color.withOpacity(step.reached ? 0.55 : 1),
              ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: step.reached
                  ? const Color(0xFFEFFAF3)
                  : isCurrent
                  ? const Color(0xFFF1F3FF)
                  : const Color(0xFFF7F8FC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCurrent
                    ? const Color(0xFFD9DDFC)
                    : SOSViewDetail._borderColor,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    step.label.isEmpty ? _statusLabel(step.status) : step.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyStrong.copyWith(
                      color: SOSViewDetail._textColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  step.date == null ? '--:--' : _formatTime(step.date),
                  style: AppTextStyles.caption.copyWith(
                    color: SOSViewDetail._mutedColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.controller});

  final SOSDetailViewModel controller;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Báo cáo xử lý',
            style: AppTextStyles.bodyStrong.copyWith(
              color: SOSViewDetail._textColor,
              fontSize: AppFontSizes.lg,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _EvidenceImages(controller: controller),
          const SizedBox(height: 12),
          TextField(
            controller: controller.noteController,
            minLines: 4,
            maxLines: 6,
            maxLength: 500,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            decoration: InputDecoration(
              hintText: 'Ghi chú xử lý',
              hintStyle: AppTextStyles.body.copyWith(
                color: SOSViewDetail._mutedColor,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: SOSViewDetail._borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: SOSViewDetail._borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: SOSViewDetail._primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceImages extends StatelessWidget {
  const _EvidenceImages({required this.controller});

  final SOSDetailViewModel controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final images = controller.images;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ảnh xử lý (${images.length}/$maxSosProgressImages)',
                  style: AppTextStyles.caption.copyWith(
                    color: SOSViewDetail._mutedColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (images.isNotEmpty)
                Text(
                  'Tối đa 5MB/ảnh',
                  style: AppTextStyles.caption.copyWith(
                    color: SOSViewDetail._mutedColor,
                    fontSize: AppFontSizes.xs,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount:
                  images.length +
                  (images.length < maxSosProgressImages ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                if (index == images.length) {
                  return _AddImageTile(
                    onTap: () {
                      controller.pickImages();
                    },
                  );
                }
                final image = images[index];
                return _ImageTile(
                  image: image,
                  onRemove: () => controller.removeImage(image),
                );
              },
            ),
          ),
        ],
      );
    });
  }
}

class _AddImageTile extends StatelessWidget {
  const _AddImageTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: SOSViewDetail._borderColor),
        ),
        child: const Icon(
          Icons.add_photo_alternate_outlined,
          color: SOSViewDetail._primaryColor,
          size: 27,
        ),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({required this.image, required this.onRemove});

  final SosProgressImageDraft image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            image.bytes,
            width: 76,
            height: 76,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          right: -6,
          top: -6,
          child: InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Color(0xCC222532),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.controller, required this.item});

  final SOSDetailViewModel controller;
  final StaffActiveSosEntity item;

  @override
  Widget build(BuildContext context) {
    final isResolved = item.status == 'done';
    final isProcessing = item.status == 'in_progress';
    return Obx(() {
      final isUpdating =
          controller.isUpdating.value || controller.isUpdatingChecklist.value;
      return Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12 + MediaQuery.of(context).padding.bottom,
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: (isUpdating || isResolved || isProcessing)
                    ? null
                    : () => _confirmStatusUpdate(
                        context: context,
                        controller: controller,
                        status: 'in_progress',
                        label: _statusLabel('in_progress'),
                      ),
                style: _mapButtonStyle(),
                child: const Text('Xác nhận xử lý'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: isUpdating || isResolved
                    ? null
                    : () => _confirmStatusUpdate(
                        context: context,
                        controller: controller,
                        status: 'done',
                        label: _statusLabel('done'),
                      ),
                style: _primaryButtonStyle(),
                child: isUpdating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Hoàn thành'),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _StatusActionButton extends StatelessWidget {
  const _StatusActionButton({
    required this.step,
    required this.isUpdating,
    required this.onPressed,
  });

  final StaffSosTimelineEntity step;
  final bool isUpdating;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = step.label.isEmpty ? _statusLabel(step.status) : step.label;
    return FilledButton.icon(
      onPressed: isUpdating ? null : onPressed,
      icon: Icon(_statusActionIcon(step.status), size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: _statusActionColor(step.status),
        foregroundColor: Colors.white,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: AppTextStyles.caption.copyWith(
          fontSize: AppFontSizes.base,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ChecklistSection extends StatefulWidget {
  const _ChecklistSection({required this.item, required this.controller});

  final StaffActiveSosEntity item;
  final SOSDetailViewModel controller;

  @override
  State<_ChecklistSection> createState() => _ChecklistSectionState();
}

class _ChecklistSectionState extends State<_ChecklistSection> {
  late Set<String> _selectedItems;

  @override
  void initState() {
    super.initState();
    _selectedItems = _initialSelectedItems();
  }

  @override
  void didUpdateWidget(covariant _ChecklistSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item) {
      _selectedItems = _initialSelectedItems();
    }
  }

  Set<String> _initialSelectedItems() {
    return widget.item.checklist
        .where((entry) => entry.isDone)
        .map((entry) => entry.name.trim())
        .where((entry) => entry.isNotEmpty)
        .toSet();
  }

  List<RequestChecklistEntity> _sortedChecklist() {
    final items = widget.item.checklist.toList();
    items.sort((a, b) {
      final sequenceCompare = a.sequence.compareTo(b.sequence);
      if (sequenceCompare != 0) {
        return sequenceCompare;
      }
      return a.id.compareTo(b.id);
    });
    return items;
  }

  bool get _canEdit =>
      widget.item.status != 'done' && widget.item.status != 'rejected';

  bool get _hasChanges {
    final initial = _initialSelectedItems();
    if (initial.length != _selectedItems.length) {
      return true;
    }
    return !_selectedItems.containsAll(initial);
  }

  Future<void> _submitChecklist() async {
    final payload = _sortedChecklist()
        .where((entry) => _selectedItems.contains(entry.name.trim()))
        .map(
          (entry) => <String, dynamic>{
            'id': entry.id,
            'name': entry.name,
            'is_done': true,
            'check_date': entry.checkDate?.toIso8601String() ?? false,
            'sequence': entry.sequence,
          },
        )
        .toList();
    await widget.controller.updateChecklist(checklist: payload);
  }

  @override
  Widget build(BuildContext context) {
    final items = _sortedChecklist();
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'staff.ticket.processingGuide'.tr,
            style: AppTextStyles.bodyStrong.copyWith(
              color: SOSViewDetail._textColor,
              fontSize: AppFontSizes.lg,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFBFCFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE7EAF3)),
            ),
            child: Column(
              children: items
                  .map(
                    (entry) => Padding(
                      padding: EdgeInsets.only(
                        bottom: entry == items.last ? 0 : 10,
                      ),
                      child: _ChecklistItemTile(
                        item: entry,
                        isChecked: _selectedItems.contains(entry.name.trim()),
                        enabled: _canEdit && !entry.isDone,
                        onChanged: (value) {
                          final itemName = entry.name.trim();
                          if (itemName.isEmpty) {
                            return;
                          }
                          setState(() {
                            if (value == true) {
                              _selectedItems.add(itemName);
                            } else {
                              _selectedItems.remove(itemName);
                            }
                          });
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          if (_canEdit) ...[
            const SizedBox(height: 12),
            Obx(
              () => SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed:
                      widget.controller.isUpdatingChecklist.value ||
                          !_hasChanges
                      ? null
                      : _submitChecklist,
                  style: FilledButton.styleFrom(
                    backgroundColor: SOSViewDetail._primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: widget.controller.isUpdatingChecklist.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('staff.ticket.updateChecklist'.tr),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChecklistItemTile extends StatelessWidget {
  const _ChecklistItemTile({
    required this.item,
    required this.isChecked,
    required this.enabled,
    required this.onChanged,
  });

  final RequestChecklistEntity item;
  final bool isChecked;
  final bool enabled;
  final ValueChanged<bool?> onChanged;

  void _toggle() {
    if (!enabled) {
      return;
    }
    onChanged(!isChecked);
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = item.checkDate != null
        ? 'staff.ticket.checklistCompletedAt'.trParams({
            'time': _formatDateTime(item.checkDate!),
          })
        : isChecked
        ? 'staff.ticket.checklistPendingSync'.tr
        : 'staff.ticket.checklistPendingPlaceholder'.tr;

    final subtitleColor = item.checkDate != null
        ? SOSViewDetail._mutedColor
        : isChecked
        ? const Color(0xFF5F6B94)
        : const Color(0xFF99A1B3);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? _toggle : null,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isChecked ? const Color(0xFFF2F5FF) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isChecked
                  ? const Color(0xFFC9D4FF)
                  : SOSViewDetail._borderColor,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Theme(
                data: Theme.of(context).copyWith(
                  checkboxTheme: CheckboxThemeData(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                child: Checkbox(
                  value: isChecked,
                  onChanged: enabled ? onChanged : null,
                  activeColor: SOSViewDetail._primaryColor,
                  side: const BorderSide(color: Color(0xFFBCC4D7), width: 1.4),
                  visualDensity: const VisualDensity(
                    horizontal: -4,
                    vertical: -4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: SOSViewDetail._textColor,
                        fontSize: AppFontSizes.md,
                        fontWeight: FontWeight.w800,
                        decoration: isChecked
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: const Color(0xFF7A86B6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: subtitleColor,
                        fontSize: AppFontSizes.base,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.icon,
    required this.title,
    required this.message,
    required this.confirmText,
    this.inputController,
    this.inputHint,
  });

  final IconData icon;
  final String title;
  final String message;
  final String confirmText;
  final TextEditingController? inputController;
  final String? inputHint;

  @override
  Widget build(BuildContext context) {
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
              decoration: const BoxDecoration(
                color: Color(0xFFE8ECFF),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: SOSViewDetail._primaryColor, size: 33),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle.copyWith(
                color: SOSViewDetail._textColor,
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
            if (inputController != null) ...[
              const SizedBox(height: 14),
              TextField(
                controller: inputController,
                minLines: 3,
                maxLines: 4,
                maxLength: 300,
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                decoration: InputDecoration(
                  hintText: inputHint,
                  filled: true,
                  fillColor: const Color(0xFFF7F8FC),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: SOSViewDetail._borderColor,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: SOSViewDetail._borderColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: SOSViewDetail._primaryColor,
                      width: 1.3,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SOSViewDetail._mutedColor,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: SOSViewDetail._primaryColor,
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SOSViewDetail._borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(11, 9, 8, 9),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFBFE),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: SOSViewDetail._borderColor),
          ),
          child: Row(
            children: [
              Icon(icon, color: SOSViewDetail._primaryColor, size: 19),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.caption.copyWith(
                        color: SOSViewDetail._mutedColor,
                        fontSize: AppFontSizes.xs,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: SOSViewDetail._textColor,
                        fontSize: AppFontSizes.base,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
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
        color: color.withOpacity(0.11),
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
        border: Border.all(color: SOSViewDetail._borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.schedule_rounded,
            color: SOSViewDetail._mutedColor,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            _formatDateTime(createdAt),
            style: AppTextStyles.caption.copyWith(
              color: SOSViewDetail._mutedColor,
              fontSize: AppFontSizes.base,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingState extends StatelessWidget {
  const _MissingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: SOSViewDetail._dangerColor,
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              'Không có dữ liệu SOS.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyStrong.copyWith(
                color: SOSViewDetail._textColor,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: () => Get.back<void>(),
              style: _mapButtonStyle(),
              child: const Text('Quay lại'),
            ),
          ],
        ),
      ),
    );
  }
}

ButtonStyle _mapButtonStyle() {
  return OutlinedButton.styleFrom(
    foregroundColor: SOSViewDetail._primaryColor,
    side: const BorderSide(color: SOSViewDetail._borderColor),
    minimumSize: const Size.fromHeight(42),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: AppTextStyles.bodyStrong.copyWith(
      fontSize: AppFontSizes.base,
      fontWeight: FontWeight.w900,
    ),
  );
}

ButtonStyle _primaryButtonStyle() {
  return FilledButton.styleFrom(
    backgroundColor: SOSViewDetail._primaryColor,
    foregroundColor: Colors.white,
    minimumSize: const Size.fromHeight(42),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: AppTextStyles.bodyStrong.copyWith(
      fontSize: AppFontSizes.base,
      fontWeight: FontWeight.w900,
    ),
  );
}

Future<void> _confirmStatusUpdate({
  required BuildContext context,
  required SOSDetailViewModel controller,
  required String status,
  required String label,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.42),
    builder: (_) => _ConfirmDialog(
      icon: _statusActionIcon(status),
      title: 'Cập nhật tiến trình',
      message: 'Bạn chắc chắn muốn chuyển SOS sang "$label"?',
      confirmText: 'Cập nhật',
    ),
  );
  if (confirmed == true) {
    await controller.updateStatus(status);
  }
}

Future<void> _confirmCancelledStatusUpdate({
  required BuildContext context,
  required SOSDetailViewModel controller,
  required String status,
}) async {
  final reasonController = TextEditingController(
    text: controller.noteController.text,
  );
  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.42),
    builder: (_) => _ConfirmDialog(
      icon: _statusActionIcon(status),
      title: 'sos.cancelDialogTitle'.tr,
      message: 'sos.cancelDialogMessage'.tr,
      confirmText: 'sos.cancelConfirm'.tr,
      inputController: reasonController,
      inputHint: 'sos.cancelReasonHint'.tr,
    ),
  );
  if (confirmed == true) {
    final reason = reasonController.text.trim();
    if (reason.isEmpty) {
      Utils.showSnackbar(
        title: 'sos.title'.tr,
        content: 'sos.cancelReasonRequired'.tr,
      );
      reasonController.dispose();
      return;
    }
    controller.noteController.text = reason;
    await controller.updateStatus(status);
  }
  reasonController.dispose();
}

List<StaffSosTimelineEntity> _statusActions(StaffActiveSosEntity item) {
  final timeline = item.timeline.isEmpty
      ? _fallbackTimeline(item.status, item.createdAt)
      : item.timeline;
  return timeline.where((step) {
    final status = step.status.trim();
    if (status.isEmpty || step.reached || status == item.status) {
      return false;
    }
    return true;
  }).toList();
}

List<StaffSosTimelineEntity> _fallbackTimeline(
  String status,
  DateTime? createdAt,
) {
  return <StaffSosTimelineEntity>[
    StaffSosTimelineEntity(
      status: 'pending',
      label: 'Chờ tiếp nhận',
      date: createdAt,
      reached: true,
    ),
    StaffSosTimelineEntity(
      status: 'in_progress',
      label: 'Đang xử lý',
      reached: _hasReached(status, 'in_progress'),
    ),
    StaffSosTimelineEntity(
      status: 'reopened',
      label: 'Đã mở lại',
      reached: _hasReached(status, 'reopened'),
    ),
    StaffSosTimelineEntity(
      status: 'done',
      label: 'Hoàn thành',
      reached: _hasReached(status, 'done'),
    ),
  ];
}

bool _hasReached(String current, String step) {
  const order = <String, int>{
    'pending': 0,
    'in_progress': 1,
    'reopened': 2,
    'done': 3,
  };
  return (order[current] ?? 0) >= (order[step] ?? 0);
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

bool _hasText(String? value) {
  return value != null && value.trim().isNotEmpty;
}

Color _statusColor(String status) {
  return switch (status.toLowerCase()) {
    'pending' => SOSViewDetail._dangerColor,
    'in_progress' => SOSViewDetail._primaryColor,
    'reopened' => const Color(0xFF2D6CDF),
    'done' => SOSViewDetail._successColor,
    'rejected' => SOSViewDetail._mutedColor,
    _ => SOSViewDetail._dangerColor,
  };
}

Color _statusActionColor(String status) {
  return switch (status.toLowerCase()) {
    'rejected' => SOSViewDetail._dangerColor,
    'done' => SOSViewDetail._successColor,
    'in_progress' => SOSViewDetail._successColor,
    'reopened' => const Color(0xFF2D6CDF),
    _ => SOSViewDetail._primaryColor,
  };
}

IconData _statusActionIcon(String status) {
  return switch (status.toLowerCase()) {
    'rejected' => Icons.close_rounded,
    'done' => Icons.check_circle_outline_rounded,
    'in_progress' => Icons.play_arrow_rounded,
    'reopened' => Icons.refresh_rounded,
    _ => Icons.update_rounded,
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

String _formatTime(DateTime? value) {
  if (value == null) {
    return '--:--';
  }
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

Future<void> _callPhone(String phone) async {
  final normalizedPhone = phone.replaceAll(RegExp(r'\s+'), '');
  final uri = Uri(scheme: 'tel', path: normalizedPhone);
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched) {
    Get.snackbar('Liên hệ', phone, snackPosition: SnackPosition.BOTTOM);
  }
}

Future<void> _openZalo(String phone) async {
  final normalizedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
  final uri = Uri.parse('https://zalo.me/$normalizedPhone');
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched) {
    Get.snackbar('LiÃªn há»‡', phone, snackPosition: SnackPosition.BOTTOM);
  }
}

Future<void> _openDirections(double latitude, double longitude) async {
  final uri = Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': '$latitude,$longitude',
    'travelmode': 'driving',
  });
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
