// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Component/ImagePreviewViewer.dart';
import 'package:hcmu_sos/Component/InteractiveTileMap.dart';
import 'package:hcmu_sos/Entity/SupportRequestEntity.dart';
import 'package:hcmu_sos/Navigator/AppRoute.dart';
import 'package:hcmu_sos/Theme/AppTypography.dart';
import 'package:hcmu_sos/Utils/ApiAssetUrl.dart';
import 'package:hcmu_sos/ViewModel/Staff/StaffTicketDetailViewModel.dart';
import 'package:url_launcher/url_launcher.dart';

class StaffTicketDetailView extends GetWidget<StaffTicketDetailViewModel> {
  const StaffTicketDetailView({super.key});

  static const Color _primaryColor = Color(0xFF29306F);
  static const Color _dangerColor = Color(0xFFF82D37);
  static const Color _pageColor = Colors.white;
  static const Color _surfaceColor = Color(0xFFF7F8FC);
  static const Color _borderColor = Color(0xFFE2E4F0);
  static const Color _textColor = Color(0xFF242733);
  static const Color _mutedColor = Color(0xFF7A7D89);
  static const double _cardRadius = 16;
  static const double _controlRadius = 14;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              controller: controller,
              onTransfer: _openTransferSheet,
              onReject: _openRejectSheet,
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value &&
                    controller.detail.value == null) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  );
                }

                final error = controller.errorMessage.value;
                final detail = controller.detail.value;
                if (error != null && detail == null) {
                  return _StateMessage(
                    message: error,
                    onRetry: controller.loadDetail,
                  );
                }
                if (detail == null) {
                  return _StateMessage(
                    message: 'ticket.detail.noData'.tr,
                    onRetry: controller.loadDetail,
                  );
                }

                final timeline = _displayTimeline(detail);
                return RefreshIndicator(
                  color: _primaryColor,
                  onRefresh: controller.loadDetail,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SummarySection(detail: detail),
                        const SizedBox(height: 18),
                        _MetaGrid(detail: detail),
                        if (_hasStudent(detail)) ...[
                          const SizedBox(height: 14),
                          _StudentCard(detail: detail),
                        ],
                        if (_hasLocation(detail.location)) ...[
                          const SizedBox(height: 14),
                          _LocationSection(location: detail.location!),
                        ],
                        if (timeline.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _ProgressSection(
                            detail: detail,
                            timeline: timeline,
                            controller: controller,
                          ),
                        ],
                        if (detail.checklist.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _ChecklistSection(
                            detail: detail,
                            controller: controller,
                          ),
                        ],
                        if (detail.status != SupportRequestStatus.done &&
                            detail.status != SupportRequestStatus.rejected) ...[
                          const SizedBox(height: 14),
                          _AcceptanceDraftSection(controller: controller),
                        ],
                        if (_hasAcceptance(detail.acceptance)) ...[
                          const SizedBox(height: 14),
                          _AcceptanceSection(
                            acceptance: detail.acceptance!,
                            ticketId: detail.id,
                          ),
                        ],
                        if (_hasRating(detail.rating)) ...[
                          const SizedBox(height: 14),
                          _RatingSection(rating: detail.rating!),
                        ],
                        const SizedBox(height: 84),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
          child: Obx(() {
            final detail = controller.detail.value;
            final canStart =
                detail?.status == SupportRequestStatus.pending ||
                detail?.status == SupportRequestStatus.reopened;
            final canComplete =
                detail != null &&
                detail.status == SupportRequestStatus.inProgress;
            final isBusy =
                controller.isUpdatingStatus.value ||
                controller.isSubmittingAcceptance.value ||
                controller.isSubmittingTransfer.value ||
                controller.isRejectingRequest.value ||
                controller.isLoadingTransferOptions.value ||
                controller.isUpdatingChecklist.value;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: detail == null
                            ? null
                            : () => Get.toNamed(
                                AppRoute.commentTicket,
                                arguments: <String, dynamic>{
                                  'thread_id': detail.id,
                                  'incident_code': detail.code,
                                  'incident_title': detail.title,
                                  'status': _statusCode(detail.status),
                                },
                              ),
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 19,
                        ),
                        label: Text('ticket.detail.chat'.tr),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryColor,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(_controlRadius),
                          ),
                          textStyle: AppTextStyles.bodyStrong.copyWith(
                            fontSize: AppFontSizes.md,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed:
                            detail != null &&
                                !isBusy &&
                                (canComplete || canStart)
                            ? () => canStart
                                  ? _confirmStartProcessing(context)
                                  : _confirmComplete(context)
                            : null,
                        icon: isBusy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                canStart
                                    ? Icons.construction_rounded
                                    : Icons.verified_outlined,
                                size: 20,
                              ),
                        label: Text(
                          canStart ? 'status.in_progress'.tr : 'status.done'.tr,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(_controlRadius),
                          ),
                          textStyle: AppTextStyles.bodyStrong.copyWith(
                            fontSize: AppFontSizes.md,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Future<void> _confirmStartProcessing(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (_) => _ConfirmDialog(
        icon: Icons.construction_rounded,
        title: 'staff.ticket.startProcessingConfirmTitle'.tr,
        message: 'staff.ticket.startProcessingConfirmMessage'.tr,
        confirmText: 'status.in_progress'.tr,
      ),
    );
    if (confirmed == true) {
      await controller.updateStatus(
        status: 'in_progress',
        successMessage: 'staff.ticket.startProcessingSuccess',
      );
    }
  }

  Future<void> _openTransferSheet(
    BuildContext context,
    SupportRequestDetailEntity detail,
  ) async {
    final options = await controller.loadTransferOptions();
    if (options == null || !context.mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TransferTaskSheet(
        detail: detail,
        options: options,
        controller: controller,
        detailContext: context,
      ),
    );
  }

  Future<void> _openRejectSheet(
    BuildContext context,
    SupportRequestDetailEntity detail,
  ) async {
    final options =
        controller.transferOptions.value ??
        await controller.loadTransferOptions();
    if (options == null || !context.mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RejectTaskSheet(
        detail: detail,
        reasons: options.reasons,
        controller: controller,
        detailContext: context,
      ),
    );
  }

  Future<void> _confirmComplete(BuildContext context) async {
    if (controller.acceptanceController.text.trim().isEmpty) {
      await controller.completeRequest();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (_) => _ConfirmDialog(
        icon: Icons.verified_rounded,
        title: 'staff.ticket.completeConfirmTitle'.tr,
        message: 'staff.ticket.completeConfirmMessage'.tr,
        confirmText: 'status.done'.tr,
      ),
    );
    if (confirmed == true) {
      await controller.completeRequest();
    }
  }
}

class _TransferTaskSheet extends StatefulWidget {
  const _TransferTaskSheet({
    required this.detail,
    required this.options,
    required this.controller,
    required this.detailContext,
  });

  final SupportRequestDetailEntity detail;
  final StaffTransferOptionsEntity options;
  final StaffTicketDetailViewModel controller;
  final BuildContext detailContext;

  @override
  State<_TransferTaskSheet> createState() => _TransferTaskSheetState();
}

class _TransferTaskSheetState extends State<_TransferTaskSheet> {
  final _reasonController = TextEditingController();
  StaffTransferDepartmentEntity? _department;
  StaffTransferStaffEntity? _staff;

  @override
  void initState() {
    super.initState();
    _department = widget.options.departments.isEmpty
        ? null
        : widget.options.departments.first;
    _staff = _filteredStaffs().isEmpty ? null : _filteredStaffs().first;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  List<StaffTransferStaffEntity> _filteredStaffs() {
    final departmentName = _department?.name.trim().toLowerCase();
    if (departmentName == null || departmentName.isEmpty) {
      return widget.options.staffs;
    }
    return widget.options.staffs
        .where(
          (staff) => staff.department?.trim().toLowerCase() == departmentName,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final staffs = _filteredStaffs();
    return _ActionSheetContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetHandle(),
          Text(
            'staff.ticket.transferTitle'.tr,
            style: AppTextStyles.subtitle.copyWith(
              color: StaffTicketDetailView._textColor,
              fontSize: AppFontSizes.lg,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'staff.ticket.transferSubtitle'.trParams({
              'code': widget.detail.code,
            }),
            style: AppTextStyles.caption.copyWith(
              color: StaffTicketDetailView._mutedColor,
              fontSize: AppFontSizes.base,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: StaffTicketDetailView._borderColor),
          const SizedBox(height: 16),
          Text(
            'staff.ticket.department'.tr,
            style: AppTextStyles.bodyStrong.copyWith(
              color: StaffTicketDetailView._textColor,
              fontSize: AppFontSizes.base,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<StaffTransferDepartmentEntity>(
            initialValue: _department,
            items: widget.options.departments
                .map(
                  (department) => DropdownMenuItem(
                    value: department,
                    child: Text(department.name),
                  ),
                )
                .toList(),
            onChanged: (department) {
              setState(() {
                _department = department;
                final filtered = _filteredStaffs();
                _staff = filtered.isEmpty ? null : filtered.first;
              });
            },
            decoration: _sheetInputDecoration(),
          ),
          const SizedBox(height: 16),
          Text(
            'staff.ticket.receiver'.tr,
            style: AppTextStyles.bodyStrong.copyWith(
              color: StaffTicketDetailView._textColor,
              fontSize: AppFontSizes.base,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          if (staffs.isEmpty)
            _EmptySheetMessage(message: 'staff.ticket.noTransferStaff'.tr)
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: staffs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, index) {
                  final staff = staffs[index];
                  return _TransferStaffOption(
                    staff: staff,
                    selected: _staff?.id == staff.id,
                    onTap: () => setState(() => _staff = staff),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          _RequiredLabel(text: 'staff.ticket.transferReason'.tr),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            minLines: 3,
            maxLines: 4,
            decoration: _sheetInputDecoration(
              hintText: 'staff.ticket.transferReasonHint'.tr,
            ),
          ),
          const SizedBox(height: 18),
          Obx(
            () => FilledButton(
              onPressed: widget.controller.isSubmittingTransfer.value
                  ? null
                  : () async {
                      final success = await widget.controller.transferRequest(
                        departmentId: _department?.id,
                        targetStaffId: _staff?.id,
                        reason: _reasonController.text,
                      );
                      if (success && context.mounted) {
                        Navigator.of(context).pop();
                      }
                      if (success && widget.detailContext.mounted) {
                        await _showAssignmentActionSuccess(
                          widget.detailContext,
                          title: 'staff.ticket.transferSuccessTitle'.tr,
                          message: 'staff.ticket.transferSuccess'.tr,
                          icon: Icons.swap_horiz_rounded,
                        );
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: StaffTicketDetailView._primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    StaffTicketDetailView._controlRadius,
                  ),
                ),
              ),
              child: widget.controller.isSubmittingTransfer.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('auth.submitRequest'.tr),
            ),
          ),
        ],
      ),
    );
  }
}

class _RejectTaskSheet extends StatefulWidget {
  const _RejectTaskSheet({
    required this.detail,
    required this.reasons,
    required this.controller,
    required this.detailContext,
  });

  final SupportRequestDetailEntity detail;
  final List<String> reasons;
  final StaffTicketDetailViewModel controller;
  final BuildContext detailContext;

  @override
  State<_RejectTaskSheet> createState() => _RejectTaskSheetState();
}

class _RejectTaskSheetState extends State<_RejectTaskSheet> {
  final _reasonController = TextEditingController();
  String? _selectedReason;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ActionSheetContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetHandle(),
          Text(
            'staff.ticket.rejectTitle'.tr,
            style: AppTextStyles.subtitle.copyWith(
              color: StaffTicketDetailView._textColor,
              fontSize: AppFontSizes.lg,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'staff.ticket.rejectSubtitle'.trParams({
              'code': widget.detail.code,
            }),
            style: AppTextStyles.caption.copyWith(
              color: StaffTicketDetailView._mutedColor,
              fontSize: AppFontSizes.base,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: StaffTicketDetailView._borderColor),
          const SizedBox(height: 14),
          if (widget.reasons.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.reasons
                  .map(
                    (reason) => ChoiceChip(
                      selected: _selectedReason == reason,
                      label: Text(reason),
                      onSelected: (_) {
                        setState(() {
                          _selectedReason = reason;
                          _reasonController.text = reason;
                        });
                      },
                      selectedColor: StaffTicketDetailView._primaryColor,
                      labelStyle: AppTextStyles.caption.copyWith(
                        color: _selectedReason == reason
                            ? Colors.white
                            : StaffTicketDetailView._primaryColor,
                        fontSize: AppFontSizes.base,
                        fontWeight: FontWeight.w900,
                      ),
                      side: const BorderSide(
                        color: StaffTicketDetailView._borderColor,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 16),
          _RequiredLabel(text: 'staff.ticket.rejectReason'.tr),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            minLines: 3,
            maxLines: 4,
            decoration: _sheetInputDecoration(
              hintText: 'staff.ticket.rejectReasonHint'.tr,
            ),
          ),
          const SizedBox(height: 18),
          Obx(
            () => FilledButton(
              onPressed: widget.controller.isRejectingRequest.value
                  ? null
                  : () async {
                      final success = await widget.controller.rejectRequest(
                        reason: _reasonController.text,
                      );
                      if (success && context.mounted) {
                        Navigator.of(context).pop();
                      }
                      if (success && widget.detailContext.mounted) {
                        await _showAssignmentActionSuccess(
                          widget.detailContext,
                          title: 'staff.ticket.rejectSuccessTitle'.tr,
                          message: 'staff.ticket.rejectSuccess'.tr,
                          icon: Icons.block_rounded,
                        );
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: StaffTicketDetailView._primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    StaffTicketDetailView._controlRadius,
                  ),
                ),
              ),
              child: widget.controller.isRejectingRequest.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('auth.submitRequest'.tr),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showAssignmentActionSuccess(
  BuildContext context, {
  required String title,
  required String message,
  required IconData icon,
}) async {
  final agreed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.42),
    builder: (_) => _SuccessDialog(
      title: title,
      message: message,
      icon: icon,
      confirmText: 'common.agree'.tr,
    ),
  );
  if (agreed != true) {
    return;
  }
  Get.back<dynamic>(result: const <String, dynamic>{'reload': true});
}

class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog({
    required this.title,
    required this.message,
    required this.icon,
    required this.confirmText,
  });

  final String title;
  final String message;
  final IconData icon;
  final String confirmText;

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
                color: Color(0xFFE5F8EE),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Color(0xFF21AD57), size: 33),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle.copyWith(
                color: StaffTicketDetailView._textColor,
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
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: StaffTicketDetailView._primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(confirmText),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionSheetContainer extends StatelessWidget {
  const _ActionSheetContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 10,
        right: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 10,
      ),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(child: child),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 38,
        height: 5,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFD7D8E5),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _TransferStaffOption extends StatelessWidget {
  const _TransferStaffOption({
    required this.staff,
    required this.selected,
    required this.onTap,
  });

  final StaffTransferStaffEntity staff;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? StaffTicketDetailView._primaryColor
                  : StaffTicketDetailView._borderColor,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                color: selected
                    ? StaffTicketDetailView._primaryColor
                    : StaffTicketDetailView._borderColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              _Avatar(name: staff.name, imageUrl: staff.avatarUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'staff.ticket.staff'.tr,
                      style: AppTextStyles.caption.copyWith(
                        color: StaffTicketDetailView._mutedColor,
                        fontSize: AppFontSizes.xs,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      staff.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: StaffTicketDetailView._textColor,
                        fontSize: AppFontSizes.md,
                        fontWeight: FontWeight.w900,
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

class _RequiredLabel extends StatelessWidget {
  const _RequiredLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: text,
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
      style: AppTextStyles.bodyStrong.copyWith(
        color: StaffTicketDetailView._textColor,
        fontSize: AppFontSizes.base,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _EmptySheetMessage extends StatelessWidget {
  const _EmptySheetMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StaffTicketDetailView._surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: StaffTicketDetailView._borderColor),
      ),
      child: Text(
        message,
        style: AppTextStyles.body.copyWith(
          color: StaffTicketDetailView._mutedColor,
          fontSize: AppFontSizes.base,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

InputDecoration _sheetInputDecoration({String? hintText}) {
  return InputDecoration(
    hintText: hintText,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: StaffTicketDetailView._borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: StaffTicketDetailView._primaryColor,
        width: 1.3,
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.controller,
    required this.onTransfer,
    required this.onReject,
  });

  final StaffTicketDetailViewModel controller;
  final Future<void> Function(
    BuildContext context,
    SupportRequestDetailEntity detail,
  )
  onTransfer;
  final Future<void> Function(
    BuildContext context,
    SupportRequestDetailEntity detail,
  )
  onReject;

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
            color: StaffTicketDetailView._textColor,
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Text(
              'ticket.detail.title'.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.subtitle.copyWith(
                color: StaffTicketDetailView._textColor,
                fontSize: AppFontSizes.xl,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Obx(() {
            final detail = controller.detail.value;
            final canManage =
                detail?.status == SupportRequestStatus.pending ||
                detail?.status == SupportRequestStatus.reopened;
            final isBusy =
                controller.isSubmittingTransfer.value ||
                controller.isRejectingRequest.value ||
                controller.isLoadingTransferOptions.value;
            if (!canManage || detail == null) {
              return const SizedBox(width: 40, height: 40);
            }

            return PopupMenuButton<_StaffTicketHeaderAction>(
              enabled: !isBusy,
              tooltip: 'Tùy chọn',
              icon: const Icon(Icons.menu_rounded, size: 26),
              color: Colors.white,
              iconColor: StaffTicketDetailView._textColor,
              surfaceTintColor: Colors.white,
              elevation: 12,
              offset: const Offset(0, 42),
              constraints: const BoxConstraints(minWidth: 236),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(
                  color: StaffTicketDetailView._borderColor,
                ),
              ),
              onSelected: (action) {
                switch (action) {
                  case _StaffTicketHeaderAction.transfer:
                    onTransfer(context, detail);
                  case _StaffTicketHeaderAction.reject:
                    onReject(context, detail);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<_StaffTicketHeaderAction>(
                  value: _StaffTicketHeaderAction.transfer,
                  padding: EdgeInsets.zero,
                  child: _HeaderPopupItem(
                    icon: Icons.swap_horiz_rounded,
                    color: StaffTicketDetailView._primaryColor,
                    label: 'staff.ticket.transferAction'.tr,
                  ),
                ),
                PopupMenuItem<_StaffTicketHeaderAction>(
                  value: _StaffTicketHeaderAction.reject,
                  padding: EdgeInsets.zero,
                  child: _HeaderPopupItem(
                    icon: Icons.block_rounded,
                    color: StaffTicketDetailView._dangerColor,
                    label: 'staff.ticket.rejectAction'.tr,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

enum _StaffTicketHeaderAction { transfer, reject }

class _HeaderPopupItem extends StatelessWidget {
  const _HeaderPopupItem({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Row(
        children: [
          const SizedBox(width: 14),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyStrong.copyWith(
                color: StaffTicketDetailView._textColor,
                fontSize: AppFontSizes.md,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.detail});

  final SupportRequestDetailEntity detail;

  @override
  Widget build(BuildContext context) {
    final status = _StatusStyle.fromStatus(detail.status);
    final priority = _PriorityStyle.fromPriority(detail.priority);
    final images = _displayImages(detail.images);
    final imageUrls = _imageUrls(images);
    final heroPrefix = 'staff-ticket-${detail.id}-images';
    return Column(
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
            _CodePill(code: detail.code),
            const SizedBox(width: 8),
            Flexible(child: _StatusPill(style: status)),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          detail.title,
          style: AppTextStyles.subtitle.copyWith(
            color: StaffTicketDetailView._textColor,
            fontSize: AppFontSizes.lg,
            fontWeight: FontWeight.w900,
            height: 1.25,
          ),
        ),
        if (_hasText(detail.description)) ...[
          const SizedBox(height: 8),
          Text(
            detail.description!,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(
              color: const Color(0xFF555B69),
              fontSize: AppFontSizes.base,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (images.isNotEmpty) ...[
          _SectionTitle('ticket.detail.conditionImages'.tr),
          const SizedBox(height: 8),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, index) => _ImageTile(
                imageUrl: imageUrls[index],
                imageUrls: imageUrls,
                initialIndex: index,
                heroTagPrefix: heroPrefix,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MetaGrid extends StatelessWidget {
  const _MetaGrid({required this.detail});

  final SupportRequestDetailEntity detail;

  @override
  Widget build(BuildContext context) {
    final items = [
      if (_hasText(detail.incidentType?.name))
        _MetaItem(
          icon: _iconForIncident(detail.incidentType?.code),
          label: 'ticket.detail.incidentType'.tr,
          value: detail.incidentType!.name,
        ),
      _MetaItem(
        icon: Icons.fact_check_outlined,
        label: 'ticket.detail.priority'.tr,
        value: _priorityLabel(detail.priority),
      ),
      if (_hasText(detail.location?.text))
        _MetaItem(
          icon: Icons.location_on_outlined,
          label: 'ticket.detail.location'.tr,
          value: detail.location!.text!,
        ),
      if (detail.createdAt != null)
        _MetaItem(
          icon: Icons.calendar_month_outlined,
          label: 'ticket.detail.createdAt'.tr,
          value: _formatDateTime(detail.createdAt!),
        ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: StaffTicketDetailView._borderColor),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _MetaRow(item: items[i]),
            if (i != items.length - 1)
              const Divider(
                height: 1,
                indent: 58,
                endIndent: 14,
                color: Color(0xFFE8EAF2),
              ),
          ],
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.item});

  final _MetaItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.icon,
              color: StaffTicketDetailView._primaryColor,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: AppTextStyles.caption.copyWith(
                    color: StaffTicketDetailView._mutedColor,
                    fontSize: AppFontSizes.sm,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: StaffTicketDetailView._primaryColor,
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

class _MetaItem {
  const _MetaItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.detail});

  final SupportRequestDetailEntity detail;

  @override
  Widget build(BuildContext context) {
    final student = detail.student;
    final reporter = detail.reporter;
    final name = _firstText(
      student?.name,
      reporter?.name,
      'student.home.defaultUser'.tr,
    )!;
    final phone = _firstText(student?.phone, reporter?.phone, null);
    final code = _firstText(student?.studentCode, reporter?.code, null);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(StaffTicketDetailView._cardRadius),
        border: Border.all(color: StaffTicketDetailView._borderColor),
      ),
      child: Row(
        children: [
          _Avatar(name: name, imageUrl: student?.avatarUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'staff.ticket.studentNeedingSupport'.tr,
                  style: AppTextStyles.caption.copyWith(
                    color: StaffTicketDetailView._mutedColor,
                    fontSize: AppFontSizes.xs,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: StaffTicketDetailView._textColor,
                    fontSize: AppFontSizes.md,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (_hasText(code))
                  Text(
                    code!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: StaffTicketDetailView._mutedColor,
                      fontSize: AppFontSizes.base,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          _PhoneButton(phone: phone),
        ],
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({
    required this.detail,
    required this.timeline,
    required this.controller,
  });

  final SupportRequestDetailEntity detail;
  final List<RequestTimelineEntity> timeline;
  final StaffTicketDetailViewModel controller;

  @override
  Widget build(BuildContext context) {
    final options = _nextStatusOptions(detail, timeline);
    return _SectionCard(
      title: 'ticket.detail.timeline'.tr,
      child: Column(
        children: [
          for (var i = 0; i < timeline.length; i++)
            _TimelineStep(
              item: timeline[i],
              isLast: i == timeline.length - 1,
              isCurrent: timeline[i].status == _statusCode(detail.status),
            ),
          if (options.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
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
                    'staff.ticket.quickUpdate'.tr,
                    style: AppTextStyles.bodyStrong.copyWith(
                      color: StaffTicketDetailView._primaryColor,
                      fontSize: AppFontSizes.md,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: options
                        .map(
                          (option) => FilledButton.icon(
                            onPressed: controller.isUpdatingStatus.value
                                ? null
                                : () => _confirmStatus(context, option),
                            icon: Icon(option.icon, size: 18),
                            label: Text(option.label),
                            style: FilledButton.styleFrom(
                              backgroundColor: option.color,
                              foregroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              textStyle: AppTextStyles.caption.copyWith(
                                fontSize: AppFontSizes.base,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmStatus(
    BuildContext context,
    _StatusUpdateOption option,
  ) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (_) => _ConfirmDialog(
        icon: option.icon,
        title: 'staff.ticket.updateProgressConfirmTitle'.tr,
        message: 'staff.ticket.updateProgressConfirmMessage'.trParams({
          'status': option.label,
        }),
        confirmText: 'staff.ticket.update'.tr,
        inputController: reasonController,
        inputHint: 'staff.ticket.reasonHint'.tr,
      ),
    );
    if (confirmed == true) {
      await controller.updateStatus(
        status: option.status,
        reason: reasonController.text,
      );
    }
    reasonController.dispose();
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.item,
    required this.isLast,
    required this.isCurrent,
  });

  final RequestTimelineEntity item;
  final bool isLast;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final reached = item.reached || isCurrent;
    final dotColor = reached
        ? const Color(0xFF4B5FBA)
        : const Color(0xFFCBD0DC);
    final lineColor = reached
        ? const Color(0xFFB7BFE6)
        : const Color(0xFFE1E4EE);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 34,
            height: 64,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!isLast)
                  Positioned(
                    top: 30,
                    bottom: -8,
                    child: Container(width: 2, color: lineColor),
                  ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: reached ? dotColor : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: dotColor, width: 1.4),
                    boxShadow: reached
                        ? const [
                            BoxShadow(
                              color: Color(0x184B5FBA),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    reached ? Icons.check_rounded : Icons.circle_outlined,
                    color: reached ? Colors.white : dotColor,
                    size: 17,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              constraints: const BoxConstraints(minHeight: 58),
              decoration: BoxDecoration(
                color: isCurrent ? const Color(0xFFF1F4FF) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCurrent
                      ? const Color(0xFFDDE3FA)
                      : const Color(0xFFECEEF5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyStrong.copyWith(
                            color: StaffTicketDetailView._textColor,
                            fontSize: AppFontSizes.md,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                        ),
                      ),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8ECFF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'staff.ticket.current'.tr,
                            style: AppTextStyles.caption.copyWith(
                              color: StaffTicketDetailView._primaryColor,
                              fontSize: AppFontSizes.xs,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        item.date == null
                            ? Icons.more_horiz_rounded
                            : Icons.access_time_rounded,
                        color: StaffTicketDetailView._mutedColor,
                        size: 15,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          item.date == null
                              ? _timelineDescription(
                                  item.status,
                                  reached,
                                  isCurrent,
                                )
                              : _formatDateTime(item.date!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: StaffTicketDetailView._mutedColor,
                            fontSize: AppFontSizes.base,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistSection extends StatefulWidget {
  const _ChecklistSection({required this.detail, required this.controller});

  final SupportRequestDetailEntity detail;
  final StaffTicketDetailViewModel controller;

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
    if (oldWidget.detail != widget.detail) {
      _selectedItems = _initialSelectedItems();
    }
  }

  Set<String> _initialSelectedItems() {
    return widget.detail.checklist
        .where((item) => item.isDone)
        .map((item) => item.name.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
  }

  List<RequestChecklistEntity> _sortedChecklist() {
    final items = widget.detail.checklist.toList();
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
      widget.detail.status != SupportRequestStatus.done &&
      widget.detail.status != SupportRequestStatus.rejected;

  bool get _hasChanges {
    final initial = _initialSelectedItems();
    if (initial.length != _selectedItems.length) {
      return true;
    }
    return !_selectedItems.containsAll(initial);
  }

  Future<void> _submitChecklist() async {
    final payload = _sortedChecklist()
        .where((item) => _selectedItems.contains(item.name.trim()))
        .map(
          (item) => <String, dynamic>{
            'id': item.id,
            'name': item.name,
            'is_done': true,
            'check_date': item.checkDate?.toIso8601String() ?? false,
            'sequence': item.sequence,
          },
        )
        .toList();
    await widget.controller.updateChecklist(checklist: payload);
  }

  @override
  Widget build(BuildContext context) {
    final items = _sortedChecklist();
    return _SectionCard(
      title: 'staff.ticket.processingGuide'.tr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    (item) => Padding(
                      padding: EdgeInsets.only(
                        bottom: item == items.last ? 0 : 10,
                      ),
                      child: _ChecklistItemTile(
                        item: item,
                        isChecked: _selectedItems.contains(item.name.trim()),
                        enabled: _canEdit && !item.isDone,
                        onChanged: (value) {
                          final itemName = item.name.trim();
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
                    backgroundColor: StaffTicketDetailView._primaryColor,
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
        ? StaffTicketDetailView._mutedColor
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
                  : StaffTicketDetailView._borderColor,
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
                  activeColor: StaffTicketDetailView._primaryColor,
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
                        color: StaffTicketDetailView._textColor,
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

class _AcceptanceDraftSection extends StatelessWidget {
  const _AcceptanceDraftSection({required this.controller});

  final StaffTicketDetailViewModel controller;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'ticket.detail.acceptance'.tr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller.acceptanceController,
            minLines: 3,
            maxLines: 4,
            maxLength: 500,
            style: AppTextStyles.body.copyWith(
              color: StaffTicketDetailView._textColor,
              fontSize: AppFontSizes.md,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'staff.ticket.acceptanceHint'.tr,
              counterText: '',
              filled: true,
              fillColor: StaffTicketDetailView._surfaceColor,
              contentPadding: const EdgeInsets.all(14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: StaffTicketDetailView._borderColor,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: StaffTicketDetailView._primaryColor,
                  width: 1.3,
                ),
              ),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(
                  () => Text(
                    '${'ticket.detail.acceptanceImages'.tr} '
                    '(${controller.acceptanceImages.length}/$maxStaffAcceptanceImages)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: StaffTicketDetailView._mutedColor,
                      fontSize: AppFontSizes.base,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => SizedBox(
                    height: 96,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount:
                          controller.acceptanceImages.length +
                          (controller.acceptanceImages.length <
                                  maxStaffAcceptanceImages
                              ? 1
                              : 0),
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (_, index) {
                        if (index == controller.acceptanceImages.length) {
                          return _AddPhotoTile(
                            onTap: controller.pickAcceptanceImages,
                          );
                        }
                        final image = controller.acceptanceImages[index];
                        return _DraftPhotoTile(
                          draft: image,
                          onRemove: () =>
                              controller.removeAcceptanceImage(image),
                        );
                      },
                    ),
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

class _AcceptanceSection extends StatelessWidget {
  const _AcceptanceSection({required this.acceptance, required this.ticketId});

  final RequestAcceptanceEntity acceptance;
  final int ticketId;

  @override
  Widget build(BuildContext context) {
    final images = _displayImages(acceptance.images);
    final imageUrls = _imageUrls(images);
    return _SectionCard(
      title: 'staff.ticket.acceptanceSubmitted'.tr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_hasText(acceptance.note))
            Text(
              acceptance.note!,
              style: AppTextStyles.body.copyWith(
                color: StaffTicketDetailView._textColor,
                fontSize: AppFontSizes.md,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          if (acceptance.date != null) ...[
            const SizedBox(height: 6),
            Text(
              _formatDateTime(acceptance.date!),
              style: AppTextStyles.caption.copyWith(
                color: StaffTicketDetailView._mutedColor,
                fontSize: AppFontSizes.base,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (imageUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: imageUrls.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, index) => _ImageTile(
                  imageUrl: imageUrls[index],
                  imageUrls: imageUrls,
                  initialIndex: index,
                  heroTagPrefix: 'staff-ticket-$ticketId-acceptance',
                  width: 126,
                  height: 96,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RatingSection extends StatelessWidget {
  const _RatingSection({required this.rating});

  final RequestRatingEntity rating;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'ticket.detail.rating'.tr,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFAEC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFFE7AA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF2CA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFFFB820),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(
                          5,
                          (index) => Icon(
                            index < rating.rating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: const Color(0xFFFFB820),
                            size: 21,
                          ),
                        ),
                      ),
                      if (rating.createdAt != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          _formatDateTime(rating.createdAt!),
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFF8A7280),
                            fontSize: AppFontSizes.base,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (_hasText(rating.comment)) ...[
              const SizedBox(height: 10),
              Text(
                rating.comment!,
                style: AppTextStyles.body.copyWith(
                  color: const Color(0xFF4E5562),
                  fontSize: AppFontSizes.md,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LocationSection extends StatelessWidget {
  const _LocationSection({required this.location});

  final RequestLocationEntity location;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'ticket.detail.location'.tr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_hasText(location.text))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: StaffTicketDetailView._surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: StaffTicketDetailView._borderColor),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.place_outlined,
                    color: StaffTicketDetailView._primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      location.text!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: StaffTicketDetailView._textColor,
                        fontSize: AppFontSizes.md,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (location.latitude != null && location.longitude != null) ...[
            const SizedBox(height: 10),
            InteractiveTileMap(
              latitude: location.latitude!,
              longitude: location.longitude!,
              primaryColor: StaffTicketDetailView._primaryColor,
              dangerColor: StaffTicketDetailView._dangerColor,
              borderColor: StaffTicketDetailView._borderColor,
              onDirections: () =>
                  _openDirections(location.latitude!, location.longitude!),
            ),
          ],
        ],
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
              child: Icon(
                icon,
                color: StaffTicketDetailView._primaryColor,
                size: 33,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle.copyWith(
                color: StaffTicketDetailView._textColor,
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
                minLines: 2,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: inputHint,
                  filled: true,
                  fillColor: StaffTicketDetailView._surfaceColor,
                  contentPadding: const EdgeInsets.all(12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: StaffTicketDetailView._borderColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: StaffTicketDetailView._primaryColor,
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
                      foregroundColor: StaffTicketDetailView._mutedColor,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('common.cancel'.tr),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: StaffTicketDetailView._primaryColor,
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
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(StaffTicketDetailView._cardRadius),
        border: Border.all(color: StaffTicketDetailView._borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyStrong.copyWith(
              color: StaffTicketDetailView._textColor,
              fontSize: AppFontSizes.md,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({
    required this.imageUrl,
    required this.imageUrls,
    required this.initialIndex,
    required this.heroTagPrefix,
    this.width = 214,
    this.height = 130,
  });

  final String imageUrl;
  final List<String> imageUrls;
  final int initialIndex;
  final String heroTagPrefix;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final heroTag = ImagePreviewViewer.heroTag(heroTagPrefix, initialIndex);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => ImagePreviewViewer.show(
          context,
          imageUrls: imageUrls,
          initialIndex: initialIndex,
          heroTagPrefix: heroTagPrefix,
        ),
        borderRadius: BorderRadius.circular(StaffTicketDetailView._cardRadius),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            StaffTicketDetailView._cardRadius,
          ),
          child: Hero(
            tag: heroTag,
            child: Image.network(
              imageUrl,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: width,
                height: height,
                color: StaffTicketDetailView._surfaceColor,
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: StaffTicketDetailView._mutedColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DraftPhotoTile extends StatelessWidget {
  const _DraftPhotoTile({required this.draft, required this.onRemove});

  final StaffAcceptanceImageDraft draft;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            draft.bytes,
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
    return Container(
      width: 96,
      height: 96,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7EAF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EF)),
            ),
            child: const Icon(
              Icons.add_photo_alternate_outlined,
              color: StaffTicketDetailView._primaryColor,
              size: 28,
            ),
          ),
        ),
      ),
    );
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
      width: 46,
      height: 46,
      decoration: const BoxDecoration(
        color: Color(0xFFE7E6F4),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: ClipOval(
        child: imageUrl == null
            ? Text(
                initials.isEmpty ? 'SV' : initials,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: StaffTicketDetailView._primaryColor,
                  fontSize: AppFontSizes.md,
                  fontWeight: FontWeight.w900,
                ),
              )
            : Image.network(
                imageUrl!,
                width: 46,
                height: 46,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: Text(
                    initials.isEmpty ? 'SV' : initials,
                    style: AppTextStyles.bodyStrong.copyWith(
                      color: StaffTicketDetailView._primaryColor,
                      fontSize: AppFontSizes.md,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _PhoneButton extends StatelessWidget {
  const _PhoneButton({this.phone});

  final String? phone;

  @override
  Widget build(BuildContext context) {
    final enabled = _hasText(phone);
    return InkWell(
      onTap: enabled ? () => _callPhone(phone!) : null,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFF21AD57) : const Color(0xFFF1F2F5),
          shape: BoxShape.circle,
          border: enabled ? null : Border.all(color: const Color(0xFFE2E4F0)),
          boxShadow: enabled
              ? const [
                  BoxShadow(
                    color: Color(0x3321AD57),
                    blurRadius: 12,
                    offset: Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Icon(
          Icons.phone_rounded,
          color: enabled ? Colors.white : StaffTicketDetailView._mutedColor,
          size: 21,
        ),
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
        color: StaffTicketDetailView._surfaceColor,
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
          Flexible(
            child: Text(
              style.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: style.foreground,
                fontSize: AppFontSizes.base,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.bodyStrong.copyWith(
        color: StaffTicketDetailView._textColor,
        fontSize: AppFontSizes.md,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.message, required this.onRetry});

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
              Icons.assignment_late_outlined,
              color: StaffTicketDetailView._primaryColor,
              size: 42,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: StaffTicketDetailView._mutedColor,
                fontSize: AppFontSizes.md,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onRetry, child: Text('common.retry'.tr)),
          ],
        ),
      ),
    );
  }
}

class _StatusUpdateOption {
  const _StatusUpdateOption({
    required this.status,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String status;
  final String label;
  final IconData icon;
  final Color color;
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
        label: 'status.pending'.tr,
        foreground: Colors.white,
        background: const Color(0xFF18A8BA),
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
        foreground: Colors.white,
        background: StaffTicketDetailView._dangerColor,
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
        color: StaffTicketDetailView._dangerColor,
      ),
    };
  }
}

List<_StatusUpdateOption> _nextStatusOptions(
  SupportRequestDetailEntity detail,
  List<RequestTimelineEntity> timeline,
) {
  if (detail.status == SupportRequestStatus.done ||
      detail.status == SupportRequestStatus.rejected) {
    return const <_StatusUpdateOption>[];
  }

  final current = _statusCode(detail.status);
  final statuses = timeline
      .where((item) => !item.reached)
      .map((item) => item.status.toLowerCase())
      .where((status) => status.isNotEmpty && status != current)
      .where((status) => status != 'rejected')
      .where((status) => status != 'done')
      .toSet();

  return statuses
      .map(_statusUpdateOption)
      .whereType<_StatusUpdateOption>()
      .toList();
}

_StatusUpdateOption? _statusUpdateOption(String status) {
  return switch (status) {
    'in_progress' => _StatusUpdateOption(
      status: 'in_progress',
      label: 'status.in_progress'.tr,
      icon: Icons.construction_rounded,
      color: const Color(0xFF4B5FBA),
    ),
    'reopened' => _StatusUpdateOption(
      status: 'reopened',
      label: 'status.reopened'.tr,
      icon: Icons.refresh_rounded,
      color: const Color(0xFF2D6CDF),
    ),
    'done' => _StatusUpdateOption(
      status: 'done',
      label: 'status.done'.tr,
      icon: Icons.verified_outlined,
      color: const Color(0xFF21AD57),
    ),
    _ => null,
  };
}

String _priorityLabel(SupportRequestPriority priority) {
  return switch (priority) {
    SupportRequestPriority.normal => 'priority.normal'.tr,
    SupportRequestPriority.high => 'priority.high'.tr,
    SupportRequestPriority.urgent => 'priority.urgent'.tr,
  };
}

IconData _iconForIncident(String? code) {
  return switch (code?.toLowerCase()) {
    'medical' || 'health' || 'y_te' => Icons.monitor_heart_outlined,
    'security' || 'antt' => Icons.shield_outlined,
    'environment' || 'moi_truong' => Icons.recycling_rounded,
    'infrastructure' || 'ha_tang' => Icons.foundation_outlined,
    'disaster' || 'thien_tai' => Icons.thunderstorm_outlined,
    'fire' || 'chay_no' => Icons.local_fire_department_outlined,
    _ => Icons.warning_amber_rounded,
  };
}

String _formatDateTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$hour:$minute - $day/$month/${value.year}';
}

String _statusCode(SupportRequestStatus status) {
  return switch (status) {
    SupportRequestStatus.pending => 'pending',
    SupportRequestStatus.inProgress => 'in_progress',
    SupportRequestStatus.reopened => 'reopened',
    SupportRequestStatus.done => 'done',
    SupportRequestStatus.rejected => 'rejected',
  };
}

String _timelineDescription(String status, bool reached, bool isCurrent) {
  if (isCurrent) {
    return 'staff.ticket.timeline.current'.tr;
  }
  if (reached) {
    return 'ticket.detail.timeline.stepDone'.tr;
  }
  return switch (status) {
    'done' => 'ticket.detail.timeline.donePending'.tr,
    'in_progress' => 'ticket.detail.timeline.inProgressPending'.tr,
    'reopened' => 'ticket.detail.timeline.reopenedPending'.tr,
    _ => 'ticket.detail.timeline.stepPending'.tr,
  };
}

bool _hasText(String? value) {
  return value != null && value.trim().isNotEmpty;
}

bool _hasStudent(SupportRequestDetailEntity detail) {
  return _hasText(detail.student?.name) || _hasText(detail.reporter?.name);
}

bool _hasLocation(RequestLocationEntity? location) {
  return location != null &&
      (_hasText(location.text) ||
          (location.latitude != null && location.longitude != null));
}

bool _hasAcceptance(RequestAcceptanceEntity? acceptance) {
  if (acceptance == null) {
    return false;
  }
  return _hasText(acceptance.note) ||
      _displayImages(acceptance.images).isNotEmpty;
}

bool _hasRating(RequestRatingEntity? rating) {
  if (rating == null) {
    return false;
  }
  return rating.rating > 0 || _hasText(rating.comment);
}

String? _firstText(String? first, String? second, String? fallback) {
  if (_hasText(first)) {
    return first!.trim();
  }
  if (_hasText(second)) {
    return second!.trim();
  }
  return fallback;
}

List<RequestImageEntity> _displayImages(List<RequestImageEntity> images) {
  return images
      .where((image) => ApiAssetUrl.resolve(image.url) != null)
      .toList();
}

List<String> _imageUrls(List<RequestImageEntity> images) {
  return images
      .map((image) => ApiAssetUrl.resolve(image.url))
      .whereType<String>()
      .toList();
}

List<RequestTimelineEntity> _displayTimeline(
  SupportRequestDetailEntity detail,
) {
  return detail.timeline.where((item) {
    if (!_hasText(item.label)) {
      return false;
    }
    if (item.status.toLowerCase() != 'rejected') {
      return true;
    }
    return detail.status == SupportRequestStatus.rejected &&
        (item.reached || item.date != null);
  }).toList();
}

Future<void> _callPhone(String phone) async {
  final normalizedPhone = phone.replaceAll(RegExp(r'\s+'), '');
  final uri = Uri(scheme: 'tel', path: normalizedPhone);
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched) {
    Get.snackbar(
      'ticket.detail.contact'.tr,
      phone,
      snackPosition: SnackPosition.BOTTOM,
    );
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
