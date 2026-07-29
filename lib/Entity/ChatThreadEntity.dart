// ignore_for_file: file_names

import 'package:hcmu_sos/Utils/ApiAssetUrl.dart';

class ChatThreadEntity {
  const ChatThreadEntity({
    required this.threadId,
    required this.incidentCode,
    required this.incidentTitle,
    this.partnerId,
    this.partnerName,
    this.partnerAvatarUrl,
    this.status,
  });

  final int threadId;
  final String incidentCode;
  final String incidentTitle;
  final int? partnerId;
  final String? partnerName;
  final String? partnerAvatarUrl;
  final String? status;

  factory ChatThreadEntity.fromJson(Object? json) {
    final data = _asMap(json);
    return ChatThreadEntity(
      threadId: _asInt(data['thread_id'] ?? data['id']),
      incidentCode: _asString(data['incident_code']) ?? '',
      incidentTitle: _asString(data['incident_title']) ?? '',
      partnerId: _asNullableInt(data['partner_id']),
      partnerName: _asString(data['partner_name']),
      partnerAvatarUrl: ApiAssetUrl.resolve(_asString(data['partner_avatar_url'])),
      status: _asString(data['status']),
    );
  }
}

class ChatMessageEntity {
  const ChatMessageEntity({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.isMine,
    this.senderAvatarUrl,
    this.createdAt,
    this.attachments = const [],
  });

  final int messageId;
  final int senderId;
  final String senderName;
  final String message;
  final bool isMine;
  final String? senderAvatarUrl;
  final DateTime? createdAt;
  final List<ChatAttachmentEntity> attachments;

  factory ChatMessageEntity.fromJson(Object? json) {
    final data = _asMap(json);
    return ChatMessageEntity(
      messageId: _asInt(data['message_id'] ?? data['id']),
      senderId: _asInt(data['sender_id']),
      senderName: _asString(data['sender_name']) ?? '',
      senderAvatarUrl: ApiAssetUrl.resolve(_asString(data['sender_avatar_url'])),
      message: _asString(data['message'] ?? data['body']) ?? '',
      isMine: data['is_mine'] == true,
      createdAt: _asDateTime(data['created_at']),
      attachments: _list(data['attachments'])
          .map(ChatAttachmentEntity.fromJson)
          .toList(),
    );
  }
}

class ChatAttachmentEntity {
  const ChatAttachmentEntity({
    required this.id,
    this.name,
    this.url,
    this.mimeType,
  });

  final int id;
  final String? name;
  final String? url;
  final String? mimeType;

  bool get isImage => mimeType?.toLowerCase().startsWith('image/') == true;

  factory ChatAttachmentEntity.fromJson(Object? json) {
    final data = _asMap(json);
    return ChatAttachmentEntity(
      id: _asInt(data['id'] ?? data['file_id'] ?? data['attachment_id']),
      name: _asString(data['name'] ?? data['file_name']),
      url: ApiAssetUrl.resolve(_asString(data['url'] ?? data['download_url'])),
      mimeType: _asString(data['mime_type'] ?? data['mimetype']),
    );
  }
}

class ChatMessagesPageEntity {
  const ChatMessagesPageEntity({
    required this.thread,
    required this.messages,
    required this.hasMore,
  });

  final ChatThreadEntity thread;
  final List<ChatMessageEntity> messages;
  final bool hasMore;

  factory ChatMessagesPageEntity.fromJson(Object? json) {
    final data = _asMap(json);
    return ChatMessagesPageEntity(
      thread: ChatThreadEntity.fromJson(data['thread']),
      messages: _list(data['messages']).map(ChatMessageEntity.fromJson).toList(),
      hasMore: data['has_more'] == true,
    );
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}

List<Object?> _list(Object? value) {
  return value is List ? value : const <Object?>[];
}

String? _asString(Object? value) {
  if (value == null || value == false) {
    return null;
  }
  return value.toString();
}

int _asInt(Object? value) {
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

int? _asNullableInt(Object? value) {
  if (value == null || value == false) {
    return null;
  }
  final parsed = _asInt(value);
  return parsed == 0 ? null : parsed;
}

DateTime? _asDateTime(Object? value) {
  final text = _asString(value);
  return text == null ? null : DateTime.tryParse(text)?.toLocal();
}
