import 'package:dio/dio.dart';
import 'package:voyanz/core/config/api_endpoints.dart';
import 'package:voyanz/features/chat/models/chat_models.dart';

class ChatDataSource {
  final Dio _dio;

  ChatDataSource(this._dio);

  Future<List<ChatGroup>> getGroups() async {
    final response = await _dio.get(ApiEndpoints.chatGroups);
    final body = response.data as Map<String, dynamic>;
    _throwIfApiError(body);
    final list = body['data'] as List? ?? [];
    return list
        .map((e) => ChatGroup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChatMessage>> getMessages(String chgrId) async {
    final page = await getMessagesPage(chgrId, fullHistory: true);
    return page.messages;
  }

  Future<ChatMessagesPage> getMessagesPage(
    String chgrId, {
    int limit = 10,
    int offset = 0,
    bool fullHistory = false,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.chatMessages(chgrId),
      queryParameters: fullHistory
          ? const {'full': '1'}
          : {'limit': limit, 'offset': offset},
    );
    final body = response.data as Map<String, dynamic>;
    _throwIfApiError(body);
    return ChatMessagesPage.fromJson(body);
  }

  /// POST /api/1.0/chat/message  body: { chgr_id, chme_type, chme_text }
  Future<ChatMessage> sendMessage({
    required String chgrId,
    required String content,
    String type = 'text',
  }) async {
    final response = await _dio.post(
      ApiEndpoints.sendChatMessage,
      data: {'chgr_id': chgrId, 'chme_type': type, 'chme_text': content},
    );
    final body = response.data as Map<String, dynamic>;
    _throwIfApiError(body);

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Unexpected chat message response format');
    }

    return ChatMessage.fromJson(data);
  }

  Future<ChatMessage> sendImage({
    required String chgrId,
    required String dataUri,
  }) {
    return sendMessage(chgrId: chgrId, content: dataUri, type: 'image');
  }

  /// Returns the raw image bytes URL for a message image.
  String getImageUrl(String chmeId) => ApiEndpoints.chatImage(chmeId);

  void _throwIfApiError(Map<String, dynamic> body) {
    final topLevelError = body['error'];
    if (topLevelError != null &&
        topLevelError != false &&
        topLevelError != 0) {
      final message = body['message']?.toString() ?? topLevelError.toString();
      throw Exception(message);
    }

    final err = body['err'];
    if (err == null) return;
    if (err == false || err == 0) return;

    if (err is Map<String, dynamic>) {
      final message =
          err['message']?.toString() ??
          err['key']?.toString() ??
          err['code']?.toString() ??
          'API error';
      throw Exception(message);
    }

    throw Exception(err.toString());
  }
}
