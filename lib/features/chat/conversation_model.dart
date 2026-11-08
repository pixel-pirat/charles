class ConversationSummary {
  ConversationSummary({
    required this.partnerId,
    this.partnerName,
    this.partnerUsername,
    this.partnerAvatarUrl,
    required this.lastMessageText,
    this.lastMessageMediaType,
    required this.lastMessageAt,
    required this.lastMessageIsMine,
    required this.unreadCount,
    required this.partnerIsOnline,
    required this.isMuted,
    required this.isPinned,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) => ConversationSummary(
        partnerId: json['partner_id'] as int,
        partnerName: json['partner_name'] as String?,
        partnerUsername: json['partner_username'] as String?,
        partnerAvatarUrl: json['partner_avatar_url'] as String?,
        lastMessageText: json['last_message_text'] as String,
        lastMessageMediaType: json['last_message_media_type'] as String?,
        lastMessageAt: DateTime.parse(json['last_message_at'] as String),
        lastMessageIsMine: json['last_message_is_mine'] as bool,
        unreadCount: json['unread_count'] as int,
        partnerIsOnline: json['partner_is_online'] as bool,
        isMuted: json['is_muted'] as bool,
        isPinned: json['is_pinned'] as bool,
      );

  final int partnerId;
  final String? partnerName;
  final String? partnerUsername;
  final String? partnerAvatarUrl;
  final String lastMessageText;
  final String? lastMessageMediaType;
  final DateTime lastMessageAt;
  final bool lastMessageIsMine;
  final int unreadCount;
  final bool partnerIsOnline;
  final bool isMuted;
  final bool isPinned;

  String get displayName => partnerName ?? partnerUsername ?? 'Unknown user';
}
