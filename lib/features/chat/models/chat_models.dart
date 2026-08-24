class ChatGroup {
  final String chgrId;
  final String? name;
  final String? lastMessage;
  final String? lastMessageDate;
  final String? otherUserName;
  final String? otherUserAvatar;
  final bool isArchived;
  final bool? lastMessageRead;

  const ChatGroup({
    required this.chgrId,
    this.name,
    this.lastMessage,
    this.lastMessageDate,
    this.otherUserName,
    this.otherUserAvatar,
    this.isArchived = false,
    this.lastMessageRead,
  });

  factory ChatGroup.fromJson(
    Map<String, dynamic> json, {
    String? myCoId,
    String? myRole,
  }) {
    final contacts = json['contacts'];
    final myType = myRole?.toString().trim().toLowerCase();
    Map<String, dynamic>? firstContact;
    Map<String, dynamic>? otherContact;
    if (contacts is List) {
      for (final item in contacts) {
        if (item is! Map<String, dynamic>) continue;
        firstContact ??= item;
        final coId = item['co_id']?.toString();
        final type = item['co_type']?.toString().trim().toLowerCase();
        final isSelf =
            (myCoId != null && myCoId.isNotEmpty && coId == myCoId) ||
            (myType != null && myType.isNotEmpty && type == myType);
        if (!isSelf) {
          otherContact ??= item;
        }
      }
    }
    final other = otherContact ?? firstContact;

    final rawOtherName = json['other_user_name']?.toString();
    return ChatGroup(
      chgrId: json['chgr_id']?.toString() ?? '',
      name: json['chgr_name'] as String?,
      lastMessage:
          json['lastmessage'] as String? ??
          json['chgr_last_message'] as String?,
      lastMessageDate:
          json['lastmessagedate'] as String? ??
          json['chgr_last_message_date'] as String?,
      otherUserName:
          (rawOtherName != null && rawOtherName.isNotEmpty)
              ? rawOtherName
              : other?['co_fullname']?.toString() ??
                    other?['co_firstname']?.toString(),
      otherUserAvatar: json['other_user_avatar'] as String?,
      isArchived: _readBool(json['archived']) ?? false,
      lastMessageRead: _readBool(json['lastmessageread']),
    );
  }
}

class ChatMessage {
  final String chmeId;
  final String? chgrId;
  final String? senderCoId;
  final String? senderName;
  final String type;
  final String? content;
  final String? imageUrl;
  final String? createdAt;

  const ChatMessage({
    required this.chmeId,
    this.chgrId,
    this.senderCoId,
    this.senderName,
    this.type = 'text',
    this.content,
    this.imageUrl,
    this.createdAt,
  });

  bool get isImage => type == 'image';

  int? get numericId => int.tryParse(chmeId);

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final contact = json['contact'] is Map<String, dynamic>
        ? json['contact'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final type = json['chme_type']?.toString() ?? 'text';
    final rawText = json['chme_text_raw']?.toString();
    final htmlText = json['chme_text']?.toString();

    return ChatMessage(
      chmeId: json['chme_id']?.toString() ?? '',
      chgrId: json['chgr_id']?.toString(),
      senderCoId: json['co_id']?.toString() ?? contact['co_id']?.toString(),
      senderName:
          contact['co_fullname'] as String? ??
          contact['co_firstname'] as String?,
      type: type,
      content: rawText ?? _stripHtml(htmlText ?? ''),
      createdAt: json['createdAt'] as String? ?? json['updatedAt'] as String?,
    );
  }
}

class ChatMessagesPage {
  final List<ChatMessage> messages;
  final ChatGroup? group;
  final int total;
  final int limit;
  final int offset;
  final bool hasMoreOlder;
  final bool fullHistory;

  const ChatMessagesPage({
    required this.messages,
    this.group,
    this.total = 0,
    this.limit = 10,
    this.offset = 0,
    this.hasMoreOlder = false,
    this.fullHistory = false,
  });

  factory ChatMessagesPage.fromJson(Map<String, dynamic> json) {
    final list = json['data'] as List? ?? const [];
    final messages = list
        .whereType<Map<String, dynamic>>()
        .map(ChatMessage.fromJson)
        .toList()
      ..sort(_compareMessages);

    final groupJson = json['group'];
    final meta = json['meta'] is Map<String, dynamic>
        ? json['meta'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return ChatMessagesPage(
      messages: messages,
      group: groupJson is Map<String, dynamic>
          ? ChatGroup.fromJson(groupJson)
          : null,
      total: _readInt(meta['total']) ?? messages.length,
      limit: _readInt(meta['limit']) ?? messages.length,
      offset: _readInt(meta['offset']) ?? 0,
      hasMoreOlder: _readBool(meta['hasMoreOlder']) ?? false,
      fullHistory: _readBool(meta['fullHistory']) ?? false,
    );
  }
}

int _compareMessages(ChatMessage a, ChatMessage b) {
  final aId = a.numericId;
  final bId = b.numericId;
  if (aId != null && bId != null) return aId.compareTo(bId);
  if (aId != null) return -1;
  if (bId != null) return 1;
  return a.chmeId.compareTo(b.chmeId);
}

int? _readInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool? _readBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value.toString().trim().toLowerCase();
  if (text == 'true' || text == '1') return true;
  if (text == 'false' || text == '0') return false;
  return null;
}

String? _stripHtml(String value) {
  final text = value
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .trim();
  return text.isEmpty ? null : text;
}
