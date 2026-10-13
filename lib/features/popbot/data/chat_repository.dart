import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../core/network/api_exception.dart';

class ChatReply {
  const ChatReply(this.conversationId, this.reply);
  final String conversationId, reply;
}

class ChatRepository {
  ChatRepository(this.dio);
  final Dio dio;
  Future<ChatReply> send(
    String message, {
    String? conversationId,
    int? userId,
    CancelToken? cancelToken,
  }) async {
    final response = await dio.post(
      '/api/v1/chat/message',
      options: Options(receiveTimeout: const Duration(seconds: 60)),
      cancelToken: cancelToken,
      data: {
        'message': message,
        'conversationId': ?conversationId,
        'userId': ?userId,
      },
    );
    final body = response.data;
    if (body is! Map || body['success'] != true || body['data'] is! Map) {
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Không nhận được phản hồi từ PopBot.',
      );
    }
    final data = body['data'] as Map;
    if (data['reply'] is! String ||
        (data['reply'] as String).trim().isEmpty ||
        data['conversationId'] is! String) {
      throw const ApiException(
        type: ApiErrorType.unknown,
        message: 'Phản hồi PopBot không hợp lệ.',
      );
    }
    return ChatReply(data['conversationId'] as String, data['reply'] as String);
  }
}

final chatRepositoryProvider = Provider(
  (ref) => ChatRepository(ref.watch(dioProvider)),
);
