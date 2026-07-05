import 'package:voyanz/core/config/mock_backend.dart';
import 'package:voyanz/features/chat/data/chat_data_source.dart';
import 'package:voyanz/features/chat/models/chat_models.dart';

class ChatRepository {
  final ChatDataSource _ds;

  ChatRepository(this._ds);

  Future<List<ChatGroup>> getGroups() async {
    if (kUseMockBackend) {
      return const [
        ChatGroup(
          chgrId: 'chat-001',
          name: 'Guidance Session',
          otherUserName: 'Amelie Laurent',
          lastMessage: 'I am ready whenever you are.',
          lastMessageDate: '2026-03-07T09:00:00Z',
        ),
        ChatGroup(
          chgrId: 'chat-002',
          name: 'Follow-up',
          otherUserName: 'Noah Bennett',
          lastMessage: 'Would you like a weekly forecast?',
          lastMessageDate: '2026-03-06T18:20:00Z',
        ),
      ];
    }
    return _ds.getGroups();
  }

  Future<List<ChatMessage>> getMessages(String chgrId) async {
    if (kUseMockBackend) {
      return [
        ChatMessage(
          chmeId: 'msg-${chgrId}a',
          chgrId: chgrId,
          senderCoId: 'pro-001',
          senderName: 'Advisor',
          content: 'Welcome to Voyanz. How can I support you today?',
          createdAt: '2026-03-07T09:00:00Z',
        ),
        ChatMessage(
          chmeId: 'msg-${chgrId}b',
          chgrId: chgrId,
          senderCoId: 'mock-user-001',
          senderName: 'You',
          content: 'I want insight about my career direction.',
          createdAt: '2026-03-07T09:01:00Z',
        ),
      ];
    }
    return _ds.getMessages(chgrId);
  }

  Future<ChatMessagesPage> getMessagesPage(
    String chgrId, {
    int limit = 10,
    int offset = 0,
    bool fullHistory = false,
  }) async {
    if (kUseMockBackend) {
      final messages = await getMessages(chgrId);
      return ChatMessagesPage(
        messages: messages,
        total: messages.length,
        limit: messages.length,
        offset: 0,
        hasMoreOlder: false,
        fullHistory: true,
      );
    }
    return _ds.getMessagesPage(
      chgrId,
      limit: limit,
      offset: offset,
      fullHistory: fullHistory,
    );
  }

  Future<ChatMessage> sendMessage({
    required String chgrId,
    required String content,
  }) async {
    if (kUseMockBackend) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return ChatMessage(
        chmeId: DateTime.now().millisecondsSinceEpoch.toString(),
        chgrId: chgrId,
        senderCoId: 'mock-user-001',
        senderName: 'You',
        type: 'text',
        content: content,
        createdAt: DateTime.now().toIso8601String(),
      );
    }
    return _ds.sendMessage(chgrId: chgrId, content: content);
  }

  Future<ChatMessage> sendImage({
    required String chgrId,
    required String dataUri,
  }) async {
    if (kUseMockBackend) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return ChatMessage(
        chmeId: DateTime.now().millisecondsSinceEpoch.toString(),
        chgrId: chgrId,
        senderCoId: 'mock-user-001',
        senderName: 'You',
        type: 'image',
        content: '',
        createdAt: DateTime.now().toIso8601String(),
      );
    }
    return _ds.sendImage(chgrId: chgrId, dataUri: dataUri);
  }

  String getImageUrl(String chmeId) {
    if (kUseMockBackend) {
      return '';
    }
    return _ds.getImageUrl(chmeId);
  }
}
