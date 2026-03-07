class ChatGroup {
  final String chgrId;
  final String? name;
  final String? lastMessage;
  final String? lastMessageDate;
  final String? otherUserName;
  final String? otherUserAvatar;

  const ChatGroup({
    required this.chgrId,
    this.name,
    this.lastMessage,
    this.lastMessageDate,
    this.otherUserName,
    this.otherUserAvatar,
  });

  factory ChatGroup.fromJson(Map<String, dynamic> json) {
    return ChatGroup(
      chgrId: json['chgr_id']?.toString() ?? '',
      name: json['chgr_name'] as String?,
      lastMessage: json['chgr_last_message'] as String?,
      lastMessageDate: json['chgr_last_message_date'] as String?,
      otherUserName: json['other_user_name'] as String?,
      otherUserAvatar: json['other_user_avatar'] as String?,
    );
  }
}

class ChatMessage {
  final String chmeId;
  final String? chgrId;
  final String? senderCoId;
  final String? senderName;
  final String? content;
  final String? imageUrl;
  final String? createdAt;

  const ChatMessage({
    required this.chmeId,
    this.chgrId,
    this.senderCoId,
    this.senderName,
    this.content,
    this.imageUrl,
    this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      chmeId: json['chme_id']?.toString() ?? '',
      chgrId: json['chgr_id']?.toString(),
      senderCoId: json['co_id']?.toString(),
      senderName: json['co_name'] as String?,
      content: json['chme_content'] as String?,
      imageUrl: json['chme_image'] as String?,
      createdAt: json['chme_created_at'] as String?,
    );
  }
}
