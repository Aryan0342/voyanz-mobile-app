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
      lastMessage: _stripEmptySender(
        json['lastmessage'] as String? ??
            json['chgr_last_message'] as String?,
      ),
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

  /// True for the server's AI "thinking" placeholder, which streams into the
  /// real answer. Its label is fr/en only server-side, so the UI shows its
  /// own translation instead (Amaury, 2026-09-21).
  final bool isAiThinking;

  const ChatMessage({
    required this.chmeId,
    this.chgrId,
    this.senderCoId,
    this.senderName,
    this.type = 'text',
    this.content,
    this.imageUrl,
    this.createdAt,
    this.isAiThinking = false,
  });

  bool get isImage => type == 'image';

  /// The server's placeholder labels. They are replaced by the first
  /// `chat_message_chunk` of the answer.
  static const _thinkingLabels = <String>{
    'notre voyante ia réfléchit',
    'notre voyant ia réfléchit',
    'our ai psychic is thinking',
    'our ai is thinking',
  };

  static bool _isThinkingLabel(String text) {
    final normalized = text
        .toLowerCase()
        .replaceAll(RegExp(r'[.…\s]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty || normalized.length > 60) return false;
    if (_thinkingLabels.contains(normalized)) return true;
    // Tolerate wording variants of the same short status line.
    return normalized.endsWith('réfléchit') ||
        normalized.endsWith('is thinking');
  }

  int? get numericId => int.tryParse(chmeId);

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final contact = json['contact'] is Map<String, dynamic>
        ? json['contact'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final type = json['chme_type']?.toString() ?? 'text';
    final rawText = json['chme_text_raw']?.toString();
    final htmlText = json['chme_text']?.toString();
    // An empty `chme_text_raw` must not hide the HTML text.
    final plainText = (rawText != null && rawText.trim().isNotEmpty)
        ? rawText
        : _stripHtml(htmlText ?? '') ?? '';

    return ChatMessage(
      chmeId: json['chme_id']?.toString() ?? '',
      chgrId: json['chgr_id']?.toString(),
      senderCoId: json['co_id']?.toString() ?? contact['co_id']?.toString(),
      senderName:
          contact['co_fullname'] as String? ??
          contact['co_firstname'] as String?,
      type: type,
      content: plainText,
      createdAt: json['createdAt'] as String? ?? json['updatedAt'] as String?,
      // The server marks its placeholder with the `chat-ai-thinking` class
      // (seen in production, 2026-09-21); the label match is a fallback.
      isAiThinking:
          type == 'text' &&
          ((htmlText ?? '').contains('chat-ai-thinking') ||
              _isThinkingLabel(plainText)),
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

/// The server formats `lastmessage` as "Sender : text". AI assistants have an
/// empty sender name, which left a stray ": Bonjour…" in the conversation list.
String? _stripEmptySender(String? preview) {
  if (preview == null) return null;
  return preview.replaceFirst(RegExp(r'^\s*:\s*'), '');
}
