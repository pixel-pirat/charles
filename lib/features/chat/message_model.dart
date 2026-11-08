class MessageReaction {
  MessageReaction({required this.userId, required this.emoji});

  factory MessageReaction.fromJson(Map<String, dynamic> json) =>
      MessageReaction(userId: json['user_id'] as int, emoji: json['emoji'] as String);

  final int userId;
  final String emoji;
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.text,
    this.mediaUrl,
    this.mediaType,
    required this.createdAt,
    this.deliveredAt,
    this.readAt,
    this.editedAt,
    required this.isDeleted,
    this.replyToMessageId,
    this.replyToSenderId,
    this.replyPreviewText,
    this.replyPreviewMediaType,
    this.linkPreviewUrl,
    this.linkPreviewTitle,
    this.linkPreviewDescription,
    this.linkPreviewImageUrl,
    required this.reactions,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as int,
        senderId: json['sender_id'] as int,
        recipientId: json['recipient_id'] as int,
        text: json['text'] as String,
        mediaUrl: json['media_url'] as String?,
        mediaType: json['media_type'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at'] as String) : null,
        readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
        editedAt: json['edited_at'] != null ? DateTime.parse(json['edited_at'] as String) : null,
        isDeleted: json['is_deleted'] as bool,
        replyToMessageId: json['reply_to_message_id'] as int?,
        replyToSenderId: json['reply_to_sender_id'] as int?,
        replyPreviewText: json['reply_preview_text'] as String?,
        replyPreviewMediaType: json['reply_preview_media_type'] as String?,
        linkPreviewUrl: json['link_preview_url'] as String?,
        linkPreviewTitle: json['link_preview_title'] as String?,
        linkPreviewDescription: json['link_preview_description'] as String?,
        linkPreviewImageUrl: json['link_preview_image_url'] as String?,
        reactions: (json['reactions'] as List).map((r) => MessageReaction.fromJson(r as Map<String, dynamic>)).toList(),
      );

  final int id;
  final int senderId;
  final int recipientId;
  final String text;
  final String? mediaUrl;
  final String? mediaType;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final DateTime? editedAt;
  final bool isDeleted;
  final int? replyToMessageId;
  final int? replyToSenderId;
  final String? replyPreviewText;
  final String? replyPreviewMediaType;
  final String? linkPreviewUrl;
  final String? linkPreviewTitle;
  final String? linkPreviewDescription;
  final String? linkPreviewImageUrl;
  final List<MessageReaction> reactions;
}
