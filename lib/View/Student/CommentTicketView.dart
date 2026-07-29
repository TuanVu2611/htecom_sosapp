// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Component/ImagePreviewViewer.dart';
import 'package:hcmu_sos/Entity/ChatThreadEntity.dart';
import 'package:hcmu_sos/Theme/AppTypography.dart';
import 'package:hcmu_sos/ViewModel/Student/CommentTicketViewModel.dart';

class CommentTicketView extends GetWidget<CommentTicketViewModel> {
  const CommentTicketView({super.key});

  static const Color _primaryColor = Color(0xFF29306F);
  static const Color _textColor = Color(0xFF242733);
  static const Color _mutedColor = Color(0xFF8A8D99);
  static const Color _pageColor = Color(0xFFF8F9FD);
  static const Color _borderColor = Color(0xFFE7E9F2);
  static const Color _composerColor = Color(0xFFF4F6FA);
  static const Color _mineBubbleColor = Color(0xFFE9ECFF);
  static const Color _mineTextColor = Color(0xFF29306F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _Header(),
            Obx(
              () => _ThreadContextBar(
                thread: controller.thread.value,
                fallbackCode: controller.incidentCode,
                fallbackTitle: controller.incidentTitle,
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.messages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  );
                }

                final error = controller.errorMessage.value;
                if (error != null && controller.messages.isEmpty) {
                  return _StateMessage(
                    message: error,
                    onRetry: controller.loadInitial,
                  );
                }

                if (controller.messages.isEmpty) {
                  return const _EmptyThreadMessage();
                }

                return RefreshIndicator(
                  color: _primaryColor,
                  onRefresh: controller.loadInitial,
                  child: ListView.builder(
                    controller: controller.scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    itemCount:
                        controller.messages.length +
                        (controller.isLoadingMore.value ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (controller.isLoadingMore.value && index == 0) {
                        return const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _primaryColor,
                              ),
                            ),
                          ),
                        );
                      }

                      final offset = controller.isLoadingMore.value ? 1 : 0;
                      final messageIndex = index - offset;
                      final message = controller.messages[messageIndex];

                      final previous = messageIndex > 0
                          ? controller.messages[messageIndex - 1]
                          : null;

                      final next = messageIndex < controller.messages.length - 1
                          ? controller.messages[messageIndex + 1]
                          : null;

                      final showDateSeparator = _shouldShowDateSeparator(
                        previous,
                        message,
                      );

                      return Column(
                        children: [
                          if (showDateSeparator)
                            _DateSeparator(date: message.createdAt),
                          _MessageRow(
                            message: message,
                            previous: previous,
                            next: next,
                          ),
                        ],
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _Composer(),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 18, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back<void>(),
            icon: const Icon(Icons.chevron_left_rounded, size: 30),
            color: CommentTicketView._textColor,
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Text(
              'ticket.chat.title'.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.subtitle.copyWith(
                color: CommentTicketView._textColor,
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

class _ThreadContextBar extends StatelessWidget {
  const _ThreadContextBar({
    required this.thread,
    required this.fallbackCode,
    required this.fallbackTitle,
  });

  final ChatThreadEntity? thread;
  final String fallbackCode;
  final String fallbackTitle;

  @override
  Widget build(BuildContext context) {
    final code = _firstText(fallbackCode, thread?.incidentCode, '--');
    final title = _firstText(fallbackTitle, thread?.incidentTitle, '');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CommentTicketView._borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color: CommentTicketView._primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: CommentTicketView._mutedColor,
                    fontSize: AppFontSizes.xs,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: CommentTicketView._textColor,
                    fontSize: AppFontSizes.sm,
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

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});

  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final text = _formatDateSeparator(date);

    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: CommentTicketView._borderColor),
          ),
          child: Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: CommentTicketView._mutedColor,
              fontSize: AppFontSizes.xs,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({required this.message, this.previous, this.next});

  final ChatMessageEntity message;
  final ChatMessageEntity? previous;
  final ChatMessageEntity? next;

  @override
  Widget build(BuildContext context) {
    final mine = message.isMine;
    final startsGroup = !_sameSender(previous, message);
    final endsGroup = !_sameSender(message, next);

    return Padding(
      padding: EdgeInsets.only(
        top: startsGroup ? 10 : 2,
        bottom: endsGroup ? 12 : 3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: mine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!mine) ...[
            endsGroup
                ? _Avatar(
                    name: message.senderName,
                    imageUrl: message.senderAvatarUrl,
                  )
                : const SizedBox(width: 36),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Align(
              alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
              child: _MessageBubble(
                message: message,
                startsGroup: startsGroup,
                endsGroup: endsGroup,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatefulWidget {
  const _MessageBubble({
    required this.message,
    required this.startsGroup,
    required this.endsGroup,
  });

  final ChatMessageEntity message;
  final bool startsGroup;
  final bool endsGroup;

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with SingleTickerProviderStateMixin {
  bool _showTime = false;

  @override
  Widget build(BuildContext context) {
    final mine = widget.message.isMine;
    final imageAttachments = widget.message.attachments
        .where((attachment) => attachment.url != null)
        .toList();
    final imageUrls = imageAttachments
        .map((attachment) => attachment.url!)
        .where((url) => url.trim().isNotEmpty)
        .toList();
    final heroTagPrefix = 'chat-message-${widget.message.messageId}-images';

    final shouldShowTime = widget.endsGroup || _showTime;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() => _showTime = !_showTime);
      },
      child: IntrinsicWidth(
        child: Container(
          constraints: const BoxConstraints(minWidth: 72, maxWidth: 286),
          padding: const EdgeInsets.fromLTRB(13, 9, 13, 8),
          decoration: BoxDecoration(
            color: mine ? CommentTicketView._mineBubbleColor : Colors.white,
            borderRadius: _bubbleRadius(
              mine,
              widget.startsGroup,
              widget.endsGroup,
            ),
            border: Border.all(
              color: mine
                  ? const Color(0xFFDCE1FF)
                  : CommentTicketView._borderColor,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.startsGroup && !mine)
                Text(
                  widget.message.senderName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: CommentTicketView._primaryColor,
                    fontSize: AppFontSizes.base,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
              if (widget.message.message.trim().isNotEmpty) ...[
                SizedBox(height: widget.startsGroup && !mine ? 4 : 0),
                Text(
                  widget.message.message,
                  style: AppTextStyles.body.copyWith(
                    color: mine
                        ? CommentTicketView._mineTextColor
                        : CommentTicketView._textColor,
                    fontSize: AppFontSizes.base,
                    fontWeight: FontWeight.w500,
                    height: 1.38,
                  ),
                ),
              ],
              if (imageUrls.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (var index = 0; index < imageUrls.length; index++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: _MessageImageTile(
                      imageUrl: imageUrls[index],
                      imageUrls: imageUrls,
                      initialIndex: index,
                      heroTagPrefix: heroTagPrefix,
                    ),
                  ),
              ],
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: shouldShowTime
                    ? Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            _formatTime(widget.message.createdAt),
                            style: AppTextStyles.caption.copyWith(
                              color: mine
                                  ? CommentTicketView._mineTextColor
                                        .withOpacity(0.58)
                                  : CommentTicketView._mutedColor,
                              fontSize: AppFontSizes.xs,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageImageTile extends StatelessWidget {
  const _MessageImageTile({
    required this.imageUrl,
    required this.imageUrls,
    required this.initialIndex,
    required this.heroTagPrefix,
  });

  final String imageUrl;
  final List<String> imageUrls;
  final int initialIndex;
  final String heroTagPrefix;

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
        borderRadius: BorderRadius.circular(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Hero(
            tag: heroTag,
            child: Image.network(
              imageUrl,
              width: 218,
              height: 140,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 218,
                height: 118,
                color: const Color(0xFFF1F2F6),
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: CommentTicketView._mutedColor,
                ),
              ),
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
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFE0DFEF),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: ClipOval(
        child: imageUrl == null
            ? Text(
                initials.isEmpty ? 'CB' : initials,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: CommentTicketView._primaryColor,
                  fontSize: AppFontSizes.sm,
                  fontWeight: FontWeight.w900,
                ),
              )
            : Image.network(
                imageUrl!,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: Text(
                    initials.isEmpty ? 'CB' : initials,
                    style: AppTextStyles.bodyStrong.copyWith(
                      color: CommentTicketView._primaryColor,
                      fontSize: AppFontSizes.sm,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

BorderRadius _bubbleRadius(bool mine, bool startsGroup, bool endsGroup) {
  const round = Radius.circular(18);
  const soft = Radius.circular(7);

  if (mine) {
    return BorderRadius.only(
      topLeft: round,
      topRight: startsGroup ? round : soft,
      bottomLeft: round,
      bottomRight: endsGroup ? soft : round,
    );
  }

  return BorderRadius.only(
    topLeft: startsGroup ? round : soft,
    topRight: round,
    bottomLeft: endsGroup ? soft : round,
    bottomRight: round,
  );
}

bool _sameSender(ChatMessageEntity? first, ChatMessageEntity? second) {
  if (first == null || second == null) return false;

  return first.senderId == second.senderId && first.isMine == second.isMine;
}

class _Composer extends GetWidget<CommentTicketViewModel> {
  const _Composer();

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            boxShadow: [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 16,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(() {
                final image = controller.selectedImage.value;

                if (image == null) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            image.bytes,
                            width: 74,
                            height: 74,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: -7,
                          right: -7,
                          child: InkWell(
                            onTap: controller.removeImage,
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
                    ),
                  ),
                );
              }),
              Container(
                padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
                decoration: BoxDecoration(
                  color: CommentTicketView._composerColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: CommentTicketView._borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: CommentTicketView._borderColor,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: controller.pickImage,
                          child: const Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 18,
                            color: CommentTicketView._primaryColor,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: controller.messageController,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                        style: AppTextStyles.body.copyWith(
                          color: CommentTicketView._textColor,
                          fontSize: AppFontSizes.md,
                        ),
                        decoration: InputDecoration(
                          hintText: 'ticket.chat.placeholder'.tr,
                          hintStyle: AppTextStyles.body.copyWith(
                            color: const Color(0xFF9AA1AE),
                            fontSize: AppFontSizes.md,
                            fontWeight: FontWeight.w600,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 9,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Obx(
                      () => _SendButton(
                        isSending: controller.isSending.value,
                        onTap: controller.send,
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

class _SendButton extends StatelessWidget {
  const _SendButton({required this.isSending, required this.onTap});

  final bool isSending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isSending ? null : onTap,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: 38,
        height: 38,
        child: isSending
            ? const Padding(
                padding: EdgeInsets.all(9),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: CommentTicketView._primaryColor,
                ),
              )
            : SvgPicture.asset(
                'assets/icon/icon_button_send.svg',
                width: 38,
                height: 38,
              ),
      ),
    );
  }
}

class _EmptyThreadMessage extends StatelessWidget {
  const _EmptyThreadMessage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(34, 10, 34, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: CommentTicketView._borderColor),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.forum_outlined,
                color: CommentTicketView._primaryColor,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ticket.chat.empty'.tr,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyStrong.copyWith(
                color: CommentTicketView._textColor,
                fontSize: AppFontSizes.md,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'ticket.chat.emptyHint'.tr,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: CommentTicketView._mutedColor,
                fontSize: AppFontSizes.base,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ),
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
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: CommentTicketView._borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                color: CommentTicketView._primaryColor,
                size: 42,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: CommentTicketView._mutedColor,
                  fontSize: AppFontSizes.md,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: CommentTicketView._primaryColor,
                  side: const BorderSide(
                    color: CommentTicketView._primaryColor,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('common.retry'.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _shouldShowDateSeparator(
  ChatMessageEntity? previous,
  ChatMessageEntity current,
) {
  final currentDate = current.createdAt;
  if (currentDate == null) return false;

  final previousDate = previous?.createdAt;
  if (previousDate == null) return true;

  return previousDate.year != currentDate.year ||
      previousDate.month != currentDate.month ||
      previousDate.day != currentDate.day;
}

String _formatDateSeparator(DateTime? value) {
  if (value == null) return '';

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(value.year, value.month, value.day);

  if (date == today) return 'Hôm nay';
  if (date == today.subtract(const Duration(days: 1))) return 'Hôm qua';

  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';
}

String _firstText(String? first, String? second, String fallback) {
  if (first != null && first.trim().isNotEmpty) return first.trim();
  if (second != null && second.trim().isNotEmpty) return second.trim();
  return fallback;
}

String _formatTime(DateTime? value) {
  if (value == null) return '';

  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');

  return '$hour:$minute';
}
