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

  factory ChatGroup.fromJson(Map<String, dynamic> json) {
    final contacts = json['contacts'];
    Map<String, dynamic>? firstContact;
    if (contacts is List) {
      for (final item in contacts) {
        if (item is Map<String, dynamic>) {
          firstContact = item;
          break;
        }
      }
    }

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
          json['other_user_name'] as String? ??
          firstContact?['co_fullname'] as String? ??
          firstContact?['co_firstname'] as String?,
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
          contact['co_firstname'] as String? ??
          json['co_fullname'] as String? ??
          json['co_name'] as String?,
      type: type,
      content:
          rawText ??
          (json['chme_content'] as String?) ??
          _stripHtml(htmlText ?? ''),
      imageUrl: json['chme_image'] as String?,
      createdAt:
          json['createdAt'] as String? ??
          json['chme_created_at'] as String? ??
          json['updatedAt'] as String?,
    );
  }
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
