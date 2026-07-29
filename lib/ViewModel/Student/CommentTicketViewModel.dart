// ignore_for_file: file_names

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Entity/ChatThreadEntity.dart';
import 'package:hcmu_sos/Repository/ChatRepository.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';
import 'package:hcmu_sos/Utils/Utils.dart';
import 'package:image_picker/image_picker.dart';

class ChatImageDraft {
  const ChatImageDraft({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;
}

class CommentTicketViewModel extends GetxController {
  CommentTicketViewModel({ChatRepository? chatRepository})
    : _chatRepository = chatRepository ?? ChatRepository();

  static const int pageSize = 20;
  static const int maxImageBytes = 5 * 1024 * 1024;

  final ChatRepository _chatRepository;
  final ImagePicker _imagePicker = ImagePicker();

  final messageController = TextEditingController();
  final scrollController = ScrollController();
  final thread = Rxn<ChatThreadEntity>();
  final messages = <ChatMessageEntity>[].obs;
  final selectedImage = Rxn<ChatImageDraft>();
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final isSending = false.obs;
  final errorMessage = RxnString();

  late final int threadId;
  late final String incidentCode;
  late final String incidentTitle;
  late final String? status;

  int _page = 1;
  bool _hasMore = false;

  @override
  void onInit() {
    super.onInit();
    _readArguments();
    scrollController.addListener(_onScroll);
  }

  @override
  void onReady() {
    super.onReady();
    loadInitial();
  }

  Future<void> loadInitial() async {
    if (isLoading.value || threadId <= 0) {
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;
    _page = 1;
    try {
      final result = await _chatRepository.getMessages(
        threadId: threadId,
        page: _page,
        pageSize: pageSize,
      );
      thread.value = result.thread;
      _hasMore = result.hasMore;
      messages.assignAll(_normalizeMessages(result.messages));
      _scrollToBottomSoon();
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      Utils.showSnackbar(title: 'ticket.chat.title'.tr, content: error.message);
    } catch (_) {
      errorMessage.value = 'ticket.chat.loadFailed'.tr;
      Utils.showSnackbar(
        title: 'ticket.chat.title'.tr,
        content: 'ticket.chat.loadFailed'.tr,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> syncIncomingMessage({int? expectedMessageId}) async {
    if (threadId <= 0 || isLoading.value || isLoadingMore.value) {
      return;
    }

    if (expectedMessageId != null &&
        messages.any((item) => item.messageId == expectedMessageId)) {
      return;
    }

    try {
      final wasNearBottom = _isNearBottom();
      final result = await _chatRepository.getMessages(
        threadId: threadId,
        page: 1,
        pageSize: pageSize,
      );
      thread.value = result.thread;
      _hasMore = result.hasMore;

      final latestMessages = _normalizeMessages(result.messages);
      final existingIds = messages.map((message) => message.messageId).toSet();
      final incomingMessages = latestMessages
          .where((message) => !existingIds.contains(message.messageId))
          .toList();

      if (incomingMessages.isEmpty) {
        return;
      }

      for (final message in incomingMessages) {
        _appendMessage(message);
      }

      if (wasNearBottom) {
        _scrollToBottomSoon();
      }
    } on ApiException catch (error) {
      Utils.showSnackbar(title: 'ticket.chat.title'.tr, content: error.message);
    } catch (_) {}
  }

  Future<void> loadMore() async {
    if (!_hasMore || isLoadingMore.value || isLoading.value) {
      return;
    }

    isLoadingMore.value = true;
    try {
      final result = await _chatRepository.getMessages(
        threadId: threadId,
        page: _page + 1,
        pageSize: pageSize,
      );
      _page += 1;
      _hasMore = result.hasMore;
      final olderMessages = _normalizeMessages(result.messages);
      final existingIds = messages.map((message) => message.messageId).toSet();
      messages.insertAll(
        0,
        olderMessages.where(
          (message) => !existingIds.contains(message.messageId),
        ),
      );
    } on ApiException catch (error) {
      Utils.showSnackbar(title: 'ticket.chat.title'.tr, content: error.message);
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> pickImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (image == null) {
        return;
      }

      final bytes = await image.readAsBytes();
      if (bytes.lengthInBytes > maxImageBytes) {
        Utils.showSnackbar(
          title: 'ticket.chat.title'.tr,
          content: 'ticket.validation.photoTooLarge'.tr,
        );
        return;
      }

      selectedImage.value = ChatImageDraft(
        bytes: bytes,
        fileName: image.name,
        mimeType: image.mimeType ?? _mimeTypeFromFileName(image.name),
      );
    } catch (_) {
      Utils.showSnackbar(
        title: 'ticket.chat.title'.tr,
        content: 'auth.imagePickFailed'.tr,
      );
    }
  }

  void removeImage() {
    selectedImage.value = null;
  }

  Future<void> send() async {
    if (isSending.value) {
      return;
    }

    final text = messageController.text.trim();
    final image = selectedImage.value;
    if (text.isEmpty && image == null) {
      return;
    }

    isSending.value = true;
    try {
      final attachmentIds = <int>[];
      if (image != null) {
        attachmentIds.add(
          await Utils.uploadFile(
            bytes: image.bytes,
            fileName: image.fileName,
            mimeType: image.mimeType,
            purpose: 'report_image',
          ),
        );
      }
      //print('---------------- Attachment IDs: $attachmentIds');

      final sentMessage = await _chatRepository.sendMessage(
        threadId: threadId,
        message: text,
        attachmentFileIds: attachmentIds,
      );
      messageController.clear();
      selectedImage.value = null;
      _appendMessage(sentMessage);
      _scrollToBottomSoon();
    } on ApiException catch (error) {
      Utils.showSnackbar(title: 'ticket.chat.title'.tr, content: error.message);
    } catch (_) {
      Utils.showSnackbar(
        title: 'ticket.chat.title'.tr,
        content: 'ticket.chat.sendFailed'.tr,
      );
    } finally {
      isSending.value = false;
    }
  }

  void _readArguments() {
    final args = Get.arguments;
    if (args is Map) {
      threadId = _asInt(args['thread_id'] ?? args['threadId'] ?? args['id']);
      incidentCode = _asString(args['incident_code'] ?? args['code']) ?? '';
      incidentTitle = _asString(args['incident_title'] ?? args['title']) ?? '';
      status = _asString(args['status']);
      return;
    }

    threadId = args is int ? args : 0;
    incidentCode = '';
    incidentTitle = '';
    status = null;
  }

  List<ChatMessageEntity> _normalizeMessages(List<ChatMessageEntity> raw) {
    final normalized = raw.toList()
      ..sort((a, b) {
        final aDate = a.createdAt;
        final bDate = b.createdAt;
        if (aDate == null && bDate == null) {
          return a.messageId.compareTo(b.messageId);
        }
        if (aDate == null) {
          return -1;
        }
        if (bDate == null) {
          return 1;
        }
        return aDate.compareTo(bDate);
      });
    return normalized;
  }

  void _appendMessage(ChatMessageEntity message) {
    final existingIndex = messages.indexWhere(
      (item) => item.messageId == message.messageId,
    );
    if (existingIndex >= 0) {
      messages[existingIndex] = message;
      return;
    }
    messages.add(message);
  }

  void _onScroll() {
    if (!scrollController.hasClients) {
      return;
    }
    if (scrollController.position.pixels <= 80) {
      loadMore();
    }
  }

  bool _isNearBottom() {
    if (!scrollController.hasClients) {
      return true;
    }
    final position = scrollController.position;
    return (position.maxScrollExtent - position.pixels) <= 120;
  }

  void _scrollToBottomSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) {
        return;
      }
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  String _mimeTypeFromFileName(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      _ => 'image/jpeg',
    };
  }

  static int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static String? _asString(Object? value) {
    if (value == null || value == false) {
      return null;
    }
    return value.toString();
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    messageController.dispose();
    super.onClose();
  }
}
