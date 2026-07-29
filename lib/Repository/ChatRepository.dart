// ignore_for_file: file_names

import 'package:hcmu_sos/Entity/ChatThreadEntity.dart';
import 'package:hcmu_sos/Service/ApiCaller.dart';

class ChatRepository {
  ChatRepository({ApiCaller? apiCaller})
    : _apiCaller = apiCaller ?? ApiCaller.getInstance();

  final ApiCaller _apiCaller;

  Future<ChatMessagesPageEntity> getMessages({
    required int threadId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiCaller.getBase<Object?>(
      'chat/threads/$threadId/messages',
      <String, dynamic>{'page': page, 'page_size': pageSize},
    );
    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Could not load messages.',
        code: response.code,
        data: response.raw,
      );
    }

    return ChatMessagesPageEntity.fromJson(response.data);
  }

  Future<ChatMessageEntity> sendMessage({
    required int threadId,
    required String message,
    List<int> attachmentFileIds = const [],
  }) async {
    final response = await _apiCaller.postBase<Object?>(
      'chat/threads/$threadId/messages/send',
      <String, dynamic>{
        'message': message.trim(),
        'attachment_file_ids': attachmentFileIds,
      },
    );
    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Could not send message.',
        code: response.code,
        data: response.raw,
      );
    }

    final data = _asMap(response.data);
    return ChatMessageEntity.fromJson(data['message'] ?? response.data);
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }
}
