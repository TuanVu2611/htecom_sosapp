// ignore_for_file: file_names

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/IncidentTypeEntity.dart';
import 'package:hcmu_sos/Service/PendingTicketSyncService.dart';
import 'package:hcmu_sos/Theme/AppTypography.dart';
import 'package:hcmu_sos/ViewModel/Student/CreateTicketViewModel.dart';

class CreateTicketView extends GetWidget<CreateTicketViewModel> {
  const CreateTicketView({super.key, this.onCreated});

  final VoidCallback? onCreated;

  static const Color _primaryColor = Color(0xFF29306F);
  static const Color _dangerColor = Color(0xFFF82D37);
  static const Color _pageColor = Colors.white;
  static const Color _surfaceColor = Color.fromARGB(255, 243, 243, 243);
  static const Color _mutedColor = Color(0xFF7A7D89);
  static const Color _borderColor = Color(0xFFE5E7EF);
  static const Color _textColor = Color(0xFF242733);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _pageColor,
        body: SafeArea(
          bottom: false,
          child: ClipRect(
            child: NotificationListener<OverscrollIndicatorNotification>(
              onNotification: (notification) {
                notification.disallowIndicator();
                return true;
              },
              child: CustomScrollView(
                physics: const ClampingScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: _Header()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _OfflineNote(),
                          const SizedBox(height: 16),
                          _FieldLabel('ticket.field.title'.tr, required: true),
                          const SizedBox(height: 8),
                          _TicketTextField(
                            controller: controller.titleController,
                            hintText: 'ticket.hint.title'.tr,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 18),
                          _FieldLabel(
                            'ticket.field.incidentType'.tr,
                            required: true,
                          ),
                          const SizedBox(height: 10),
                          _IncidentTypeGrid(controller: controller),
                          const SizedBox(height: 18),
                          _PrioritySection(controller: controller),
                          const SizedBox(height: 18),
                          _FieldLabel(
                            'ticket.field.description'.tr,
                            required: true,
                          ),
                          const SizedBox(height: 8),
                          _TicketTextField(
                            controller: controller.descriptionController,
                            hintText: 'ticket.hint.description'.tr,
                            maxLines: 5,
                            maxLength: 500,
                            textInputAction: TextInputAction.newline,
                          ),
                          const SizedBox(height: 18),
                          _PhotoSection(controller: controller),
                          const SizedBox(height: 18),
                          _FieldLabel(
                            'ticket.field.location'.tr,
                            required: true,
                          ),
                          const SizedBox(height: 8),
                          Obx(
                            () => _TicketTextField(
                              controller: controller.locationController,
                              hintText: 'ticket.hint.location'.tr,
                              prefixIcon: Icons.place_outlined,
                              suffixIcon:
                                  controller.isResolvingLocationText.value
                                  ? const Padding(
                                      padding: EdgeInsets.all(14),
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: CreateTicketView._primaryColor,
                                        ),
                                      ),
                                    )
                                  : null,
                              textInputAction: TextInputAction.done,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _LocationMap(controller: controller),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.only(top: 12),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x0A000000),
                                  blurRadius: 16,
                                  offset: Offset(0, -4),
                                ),
                              ],
                            ),
                            child: _ActionRow(
                              controller: controller,
                              onCreated: onCreated,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 25, 15, 15),
        child: Row(
          children: [
            // SizedBox(
            //   width: 38,
            //   height: 38,
            //   child: IconButton(
            //     onPressed: Get.back,
            //     icon: const Icon(Icons.chevron_left_rounded, size: 26),
            //     color: CreateTicketView._textColor,
            //     padding: EdgeInsets.zero,
            //     visualDensity: VisualDensity.compact,
            //     style: IconButton.styleFrom(
            //       backgroundColor: CreateTicketView._surfaceColor,
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(20),
            //       ),
            //     ),
            //   ),
            // ),
            // const SizedBox(width: 12),
            Expanded(
              child: Text(
                'ticket.create.title'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.subtitle.copyWith(
                  color: CreateTicketView._textColor,
                  fontSize: AppFontSizes.xl,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PendingTicketSyncState>(
      stream: PendingTicketSyncService.instance.stateStream,
      initialData: PendingTicketSyncService.instance.currentState,
      builder: (context, snapshot) {
        final state = snapshot.data ?? const PendingTicketSyncState();
        final hasPending = state.pendingCount > 0;
        final text = state.isSyncing && hasPending
            ? 'ticket.sync.syncing'.trParams({
                'count': state.pendingCount.toString(),
              })
            : hasPending
            ? 'ticket.sync.pending'.trParams({
                'count': state.pendingCount.toString(),
              })
            : 'ticket.offlineNote'.tr;

        return Row(
          children: [
            if (state.isSyncing && hasPending)
              const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: CreateTicketView._primaryColor,
                ),
              )
            else
              Icon(
                hasPending
                    ? Icons.cloud_upload_outlined
                    : Icons.info_outline_rounded,
                color: CreateTicketView._primaryColor,
                size: 17,
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.caption.copyWith(
                  color: const Color(0xFF525A70),
                  fontSize: AppFontSizes.base,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  height: 1.25,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label, {this.required = false});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: label,
        style: AppTextStyles.bodyStrong.copyWith(
          color: CreateTicketView._textColor,
          fontSize: AppFontSizes.lg,
          fontWeight: FontWeight.w900,
        ),
        children: [
          if (required)
            const TextSpan(
              text: '*',
              style: TextStyle(color: CreateTicketView._dangerColor),
            ),
        ],
      ),
    );
  }
}

class _TicketTextField extends StatelessWidget {
  const _TicketTextField({
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final int? maxLength;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      textInputAction: textInputAction,
      style: AppTextStyles.body.copyWith(
        color: CreateTicketView._textColor,
        fontSize: AppFontSizes.md,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.body.copyWith(
          color: const Color(0xFF9AA1AE),
          fontSize: AppFontSizes.md,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, color: CreateTicketView._primaryColor, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: CreateTicketView._surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: CreateTicketView._borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: CreateTicketView._primaryColor,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _IncidentTypeGrid extends StatelessWidget {
  const _IncidentTypeGrid({required this.controller});

  final CreateTicketViewModel controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingCatalog.value &&
          controller.incidentTypes.isEmpty) {
        return const SizedBox(
          height: 86,
          child: Center(
            child: CircularProgressIndicator(
              color: CreateTicketView._primaryColor,
            ),
          ),
        );
      }

      final items = controller.incidentTypes;
      if (items.isEmpty) {
        return _InlineRetry(
          onTap: () => controller.loadIncidentTypes(forceRefresh: true),
        );
      }

      final selectedType = controller.selectedIncidentType.value;

      return LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 9.0;
          const minItemWidth = 72.0;
          const minItemHeight = 94.0;

          final crossAxisCount = math.max(
            2,
            math.min(
              4,
              ((constraints.maxWidth + spacing) / (minItemWidth + spacing))
                  .floor(),
            ),
          );

          final itemWidth =
              (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
              crossAxisCount;
          final itemHeight = math.max(itemWidth, minItemHeight);

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            clipBehavior: Clip.hardEdge,
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              mainAxisExtent: itemHeight,
            ),
            itemBuilder: (context, index) {
              final type = items[index];
              final selected = _isSelectedIncidentType(type, selectedType);

              return _IncidentTypeTile(
                type: type,
                selected: selected,
                onTap: () => controller.selectIncidentType(type),
              );
            },
          );
        },
      );
    });
  }

  bool _isSelectedIncidentType(
    IncidentTypeEntity type,
    IncidentTypeEntity? selected,
  ) {
    if (selected == null) {
      return false;
    }
    if (type.id != 0 || selected.id != 0) {
      return type.id == selected.id;
    }
    return type.code == selected.code && type.name == selected.name;
  }
}

class _InlineRetry extends StatelessWidget {
  const _InlineRetry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.refresh_rounded, size: 18),
      label: Text('common.retry'.tr),
      style: OutlinedButton.styleFrom(
        foregroundColor: CreateTicketView._primaryColor,
        side: const BorderSide(color: CreateTicketView._primaryColor),
      ),
    );
  }
}

class _IncidentTypeTile extends StatelessWidget {
  const _IncidentTypeTile({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final IncidentTypeEntity type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(18);

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: borderRadius,
            border: Border.all(
              color: selected
                  ? CreateTicketView._primaryColor
                  : CreateTicketView._borderColor,
              width: selected ? 1.3 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x05000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFF3F6FF)
                                : CreateTicketView._surfaceColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: _IncidentIcon(type: type, selected: selected),
                      ),
                      if (selected)
                        Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: CreateTicketView._primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Tooltip(
                    message: type.name,
                    child: Text(
                      type.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: selected
                            ? CreateTicketView._primaryColor
                            : const Color(0xFF4A4F5F),
                        fontSize: AppFontSizes.xs,
                        fontWeight: FontWeight.w800,
                        height: 1.12,
                      ),
                    ),
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

class _IncidentIcon extends StatelessWidget {
  const _IncidentIcon({required this.type, required this.selected});

  final IncidentTypeEntity type;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final iconUrl = type.iconUrl;
    if (iconUrl != null && iconUrl.isNotEmpty) {
      return Image.network(
        iconUrl,
        width: 27,
        height: 27,
        errorBuilder: (_, _, _) => _fallbackIcon(),
      );
    }
    return _fallbackIcon();
  }

  Widget _fallbackIcon() {
    final icon = switch (type.code.toLowerCase()) {
      'medical' || 'health' || 'y_te' => Icons.monitor_heart_outlined,
      'security' || 'antt' => Icons.shield_outlined,
      'environment' || 'moi_truong' => Icons.recycling_rounded,
      'infrastructure' || 'ha_tang' => Icons.foundation_outlined,
      'disaster' || 'thien_tai' => Icons.thunderstorm_outlined,
      'fire' || 'chay_no' => Icons.local_fire_department_outlined,
      _ => Icons.warning_amber_rounded,
    };
    return Icon(
      icon,
      color: selected
          ? CreateTicketView._primaryColor
          : const Color(0xFF586079),
      size: 27,
    );
  }
}

class _PrioritySection extends StatelessWidget {
  const _PrioritySection({required this.controller});

  final CreateTicketViewModel controller;

  @override
  Widget build(BuildContext context) {
    final priorities = [
      _PriorityOption(
        priority: TicketPriority.normal,
        label: 'priority.normal'.tr,
        color: const Color(0xFFFFC247),
      ),
      _PriorityOption(
        priority: TicketPriority.high,
        label: 'priority.high'.tr,
        color: const Color(0xFFFF7E6E),
      ),
      _PriorityOption(
        priority: TicketPriority.urgent,
        label: 'priority.urgent'.tr,
        color: CreateTicketView._dangerColor,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('ticket.field.priority'.tr, required: true),
        const SizedBox(height: 10),
        Obx(() {
          final selectedIndex = priorities.indexWhere(
            (e) => e.priority == controller.selectedPriority.value,
          );

          final safeIndex = selectedIndex < 0 ? 0 : selectedIndex;

          return LayoutBuilder(
            builder: (context, constraints) {
              const padding = 5.0;
              const gap = 4.0;
              final itemWidth =
                  (constraints.maxWidth - padding * 2 - gap * 2) / 3;

              return Container(
                height: 50,
                padding: const EdgeInsets.all(padding),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FD),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: CreateTicketView._borderColor),
                ),
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      left: safeIndex * (itemWidth + gap),
                      top: 0,
                      bottom: 0,
                      width: itemWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFD8DEF8)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0C000000),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Row(
                      children: [
                        for (var i = 0; i < priorities.length; i++) ...[
                          Expanded(
                            child: _PriorityAnimatedItem(
                              option: priorities[i],
                              selected: safeIndex == i,
                              onTap: () => controller.selectPriority(
                                priorities[i].priority,
                              ),
                            ),
                          ),
                          if (i != priorities.length - 1)
                            const SizedBox(width: gap),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ],
    );
  }
}

class _PriorityAnimatedItem extends StatelessWidget {
  const _PriorityAnimatedItem({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _PriorityOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            style: AppTextStyles.caption.copyWith(
              color: selected
                  ? CreateTicketView._primaryColor
                  : const Color(0xFF5E6475),
              fontSize: AppFontSizes.base,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: selected ? 8 : 6,
                  height: selected ? 8 : 6,
                  decoration: BoxDecoration(
                    color: option.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    option.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class _PriorityOption {
  const _PriorityOption({
    required this.priority,
    required this.label,
    required this.color,
  });

  final TicketPriority priority;
  final String label;
  final Color color;
}

class _PrioritySegment extends StatelessWidget {
  const _PrioritySegment({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _PriorityOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: selected
                ? Border.all(color: const Color(0xFFD8DEF8))
                : null,
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x0C000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: option.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: selected
                        ? CreateTicketView._primaryColor
                        : const Color(0xFF5E6475),
                    fontSize: AppFontSizes.base,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({required this.controller});

  final CreateTicketViewModel controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: 'ticket.field.photos'.tr,
              style: AppTextStyles.bodyStrong.copyWith(
                color: CreateTicketView._textColor,
                fontSize: AppFontSizes.lg,
                fontWeight: FontWeight.w900,
              ),
              children: [
                TextSpan(
                  text:
                      ' (${controller.attachments.length}/$maxTicketAttachments)',
                  style: AppTextStyles.caption.copyWith(
                    color: CreateTicketView._mutedColor,
                    fontSize: AppFontSizes.base,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount:
                  controller.attachments.length +
                  (controller.attachments.length < maxTicketAttachments
                      ? 1
                      : 0),
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                if (index == controller.attachments.length) {
                  return _AddPhotoTile(onTap: controller.pickImages);
                }
                final attachment = controller.attachments[index];
                return _PhotoTile(
                  attachment: attachment,
                  onRemove: () => controller.removeImage(attachment),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.attachment, required this.onRemove});

  final TicketImageAttachment attachment;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            attachment.bytes,
            width: 84,
            height: 84,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xCC000000),
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

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: CreateTicketView._surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CreateTicketView._borderColor),
        ),
        child: const Icon(
          Icons.add_photo_alternate_outlined,
          color: CreateTicketView._primaryColor,
          size: 28,
        ),
      ),
    );
  }
}

class _LocationMap extends StatefulWidget {
  const _LocationMap({required this.controller});

  final CreateTicketViewModel controller;

  @override
  State<_LocationMap> createState() => _LocationMapState();
}

class _LocationMapState extends State<_LocationMap> {
  static const int _defaultMapZoom = 16;
  static const int _minMapZoom = 3;
  static const int _maxMapZoom = 19;
  static const double _tileSize = 256;
  static const double _mapHeight = 164;

  int _mapZoom = _defaultMapZoom;
  Offset _pendingDragOffset = Offset.zero;
  Offset? _lastFocalPoint;
  bool _isScalingGesture = false;
  double _gestureScale = 1;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final lat = widget.controller.latitude.value;
      final lng = widget.controller.longitude.value;
      return Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onScaleStart: _handleScaleStart,
            onScaleUpdate: _handleScaleUpdate,
            onScaleEnd: _handleScaleEnd,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    height: _mapHeight,
                    decoration: BoxDecoration(
                      border: Border.all(color: CreateTicketView._borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: constraints.maxWidth,
                          height: _mapHeight,
                          child: Transform.scale(
                            scale: _gestureScale,
                            child: _buildTileGrid(
                              latitude: lat,
                              longitude: lng,
                              width: constraints.maxWidth,
                            ),
                          ),
                        ),
                        Container(color: Colors.white.withValues(alpha: 0.1)),
                        const Icon(
                          Icons.location_on_rounded,
                          color: CreateTicketView._dangerColor,
                          size: 44,
                          shadows: [
                            Shadow(
                              color: Color(0x66000000),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        Positioned(
                          left: 10,
                          top: 10,
                          child: _MapChip(text: 'ticket.map.dragHint'.tr),
                        ),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Column(
                            children: [
                              _MapActionButton(
                                icon: Icons.add_rounded,
                                onTap: _canZoomIn ? _zoomIn : null,
                              ),
                              const SizedBox(height: 8),
                              _MapActionButton(
                                icon: Icons.remove_rounded,
                                onTap: _canZoomOut ? _zoomOut : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Obx(() {
              final isLocating = widget.controller.isLocating.value;
              return TextButton.icon(
                onPressed: isLocating
                    ? null
                    : widget.controller.loadCurrentLocation,
                icon: SizedBox(
                  width: 17,
                  height: 17,
                  child: isLocating
                      ? const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CreateTicketView._primaryColor,
                        )
                      : const Icon(Icons.my_location_rounded, size: 17),
                ),
                label: Text('ticket.location.current'.tr),
                style: TextButton.styleFrom(
                  foregroundColor: CreateTicketView._primaryColor,
                  disabledForegroundColor: CreateTicketView._primaryColor,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              );
            }),
          ),
        ],
      );
    });
  }

  bool get _canZoomIn => _mapZoom < _maxMapZoom;

  bool get _canZoomOut => _mapZoom > _minMapZoom;

  Widget _buildTileGrid({
    required double latitude,
    required double longitude,
    required double width,
  }) {
    final centerPixel = _latLngToWorldPixel(latitude, longitude);
    final centerTileX = (centerPixel.dx / _tileSize).floor();
    final centerTileY = (centerPixel.dy / _tileSize).floor();
    final offsetInTile = Offset(
      centerPixel.dx - centerTileX * _tileSize,
      centerPixel.dy - centerTileY * _tileSize,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (var dx = -2; dx <= 2; dx++)
          for (var dy = -2; dy <= 2; dy++)
            Positioned(
              left:
                  width / 2 +
                  dx * _tileSize -
                  offsetInTile.dx +
                  _pendingDragOffset.dx,
              top:
                  _mapHeight / 2 +
                  dy * _tileSize -
                  offsetInTile.dy +
                  _pendingDragOffset.dy,
              width: _tileSize,
              height: _tileSize,
              child: Image.network(
                _tileUrlFor(centerTileX + dx, centerTileY + dy),
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) =>
                    Container(color: const Color(0xFFEFF2F6)),
              ),
            ),
      ],
    );
  }

  void _commitDragOffset() {
    if (_pendingDragOffset == Offset.zero) {
      return;
    }

    final offset = _pendingDragOffset;
    setState(() => _pendingDragOffset = Offset.zero);

    final currentPixel = _latLngToWorldPixel(
      widget.controller.latitude.value,
      widget.controller.longitude.value,
    );

    final nextPixel = Offset(
      currentPixel.dx - offset.dx,
      currentPixel.dy - offset.dy,
    );

    final nextLatLng = _worldPixelToLatLng(nextPixel);
    widget.controller.updateLocation(nextLatLng.$1, nextLatLng.$2);
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _lastFocalPoint = details.focalPoint;
    _isScalingGesture = false;
    _gestureScale = 1;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount > 1) {
      setState(() {
        _isScalingGesture = true;
        _gestureScale = details.scale.clamp(0.85, 1.2);
      });
      return;
    }

    if (_isScalingGesture || _lastFocalPoint == null) {
      return;
    }

    final delta = details.focalPoint - _lastFocalPoint!;
    _lastFocalPoint = details.focalPoint;
    setState(() => _pendingDragOffset += delta);
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    if (_isScalingGesture) {
      setState(() {
        if (_gestureScale >= 1.08 && _canZoomIn) {
          _mapZoom++;
        } else if (_gestureScale <= 0.92 && _canZoomOut) {
          _mapZoom--;
        }
        _gestureScale = 1;
        _isScalingGesture = false;
        _lastFocalPoint = null;
      });
      return;
    }

    _lastFocalPoint = null;
    _commitDragOffset();
  }

  void _zoomIn() {
    if (!_canZoomIn) {
      return;
    }
    setState(() => _mapZoom++);
  }

  void _zoomOut() {
    if (!_canZoomOut) {
      return;
    }
    setState(() => _mapZoom--);
  }

  String _tileUrlFor(int tileX, int tileY) {
    final n = math.pow(2.0, _mapZoom).toInt();
    final wrappedX = tileX.remainder(n);
    final normalizedX = wrappedX < 0 ? wrappedX + n : wrappedX;
    final normalizedY = tileY.clamp(0, n - 1);
    return 'https://tile.openstreetmap.org/$_mapZoom/$normalizedX/$normalizedY.png';
  }

  Offset _latLngToWorldPixel(double latitude, double longitude) {
    final sinLat = math.sin(latitude * math.pi / 180).clamp(-0.9999, 0.9999);
    final scale = _tileSize * math.pow(2.0, _mapZoom);
    final x = (longitude + 180.0) / 360.0 * scale;
    final y =
        (0.5 - math.log((1 + sinLat) / (1 - sinLat)) / (4 * math.pi)) * scale;
    return Offset(x, y);
  }

  (double, double) _worldPixelToLatLng(Offset pixel) {
    final scale = _tileSize * math.pow(2.0, _mapZoom);
    final longitude = pixel.dx / scale * 360.0 - 180.0;
    final n = math.pi - 2.0 * math.pi * pixel.dy / scale;
    final latitude =
        180.0 / math.pi * math.atan(0.5 * (math.exp(n) - math.exp(-n)));
    return (latitude, longitude);
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x1A29306F)),
          ),
          child: Icon(
            icon,
            size: 18,
            color: onTap == null
                ? CreateTicketView._mutedColor.withValues(alpha: 0.55)
                : CreateTicketView._primaryColor,
          ),
        ),
      ),
    );
  }
}

class _MapChip extends StatelessWidget {
  const _MapChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x1A29306F)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          text,
          style: AppTextStyles.caption.copyWith(
            color: CreateTicketView._primaryColor,
            fontSize: AppFontSizes.xs,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.controller, this.onCreated});

  final CreateTicketViewModel controller;
  final VoidCallback? onCreated;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: controller.resetForm,
              style: OutlinedButton.styleFrom(
                foregroundColor: CreateTicketView._primaryColor,
                side: const BorderSide(color: CreateTicketView._primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: AppTextStyles.bodyStrong.copyWith(
                  fontSize: AppFontSizes.md,
                  fontWeight: FontWeight.w900,
                ),
              ),
              child: Text('common.cancel'.tr),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Obx(
            () => SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: controller.isSubmitting.value
                    ? null
                    : () => _submitAndShowSuccess(context),
                style: FilledButton.styleFrom(
                  backgroundColor: CreateTicketView._primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: AppTextStyles.bodyStrong.copyWith(
                    fontSize: AppFontSizes.md,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                child: controller.isSubmitting.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('ticket.action.submit'.tr),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitAndShowSuccess(BuildContext context) async {
    final result = await controller.submit();
    if (result == TicketSubmitResult.failed || !context.mounted) {
      return;
    }

    final queuedOffline = result == TicketSubmitResult.queuedOffline;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _TicketCreatedDialog(
        queuedOffline: queuedOffline,
        onOk: () {
          Navigator.of(dialogContext).pop();
          if (!queuedOffline) {
            onCreated?.call();
          }
        },
      ),
    );
  }
}

class _TicketCreatedDialog extends StatelessWidget {
  const _TicketCreatedDialog({required this.onOk, required this.queuedOffline});

  final VoidCallback onOk;
  final bool queuedOffline;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 38),
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 24,
              offset: Offset(0, 12),
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
                color: Color(0xFFEAF8EF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Color(0xFF2FA866),
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              queuedOffline
                  ? 'ticket.offlineQueuedTitle'.tr
                  : 'ticket.createdTitle'.tr,
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle.copyWith(
                color: CreateTicketView._primaryColor,
                fontSize: AppFontSizes.xl,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              queuedOffline
                  ? 'ticket.offlineQueuedDescription'.tr
                  : 'ticket.createdDescription'.tr,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: const Color(0xFF626878),
                fontSize: AppFontSizes.base,
                height: 1.42,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton(
                onPressed: onOk,
                style: FilledButton.styleFrom(
                  backgroundColor: CreateTicketView._primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: AppTextStyles.bodyStrong.copyWith(
                    fontSize: AppFontSizes.md,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
