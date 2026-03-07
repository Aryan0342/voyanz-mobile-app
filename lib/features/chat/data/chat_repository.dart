import 'package:voyanz/features/chat/data/chat_data_source.dart';
import 'package:voyanz/features/chat/models/chat_models.dart';

class ChatRepository {
  final ChatDataSource _ds;

  ChatRepository(this._ds);

  Future<List<ChatGroup>> getGroups() => _ds.getGroups();
  Future<List<ChatMessage>> getMessages(String chgrId) =>
      _ds.getMessages(chgrId);

  Future<void> sendMessage({required String chgrId, required String content}) =>
      _ds.sendMessage(chgrId: chgrId, content: content);

  String getImageUrl(String chmeId) => _ds.getImageUrl(chmeId);
}
