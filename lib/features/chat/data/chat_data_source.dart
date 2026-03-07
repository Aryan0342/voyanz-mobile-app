import 'package:dio/dio.dart';
import 'package:voyanz/core/config/api_endpoints.dart';
import 'package:voyanz/features/chat/models/chat_models.dart';

class ChatDataSource {
  final Dio _dio;

  ChatDataSource(this._dio);

  Future<List<ChatGroup>> getGroups() async {
    final response = await _dio.get(ApiEndpoints.chatGroups);
    final body = response.data as Map<String, dynamic>;
    final list = body['data'] as List? ?? [];
    return list
        .map((e) => ChatGroup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChatMessage>> getMessages(String chgrId) async {
    final response = await _dio.get(ApiEndpoints.chatMessages(chgrId));
    final body = response.data as Map<String, dynamic>;
    final list = body['data'] as List? ?? [];
    return list
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/1.0/chat/message  body: { chgr_id, chme_content }
  Future<void> sendMessage({
    required String chgrId,
    required String content,
  }) async {
    await _dio.post(
      ApiEndpoints.sendChatMessage,
      data: {'chgr_id': chgrId, 'chme_content': content},
    );
  }

  /// Returns the raw image bytes URL for a message image.
  String getImageUrl(String chmeId) => ApiEndpoints.chatImage(chmeId);
}
