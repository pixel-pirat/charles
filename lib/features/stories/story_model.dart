class StoryItem {
  StoryItem({
    required this.id,
    required this.mediaUrl,
    required this.mediaType,
    required this.createdAt,
    required this.viewCount,
    required this.isSeenByMe,
  });

  factory StoryItem.fromJson(Map<String, dynamic> json) => StoryItem(
        id: json['id'] as int,
        mediaUrl: json['media_url'] as String,
        mediaType: json['media_type'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        viewCount: json['view_count'] as int,
        isSeenByMe: json['is_seen_by_me'] as bool,
      );

  final int id;
  final String mediaUrl;
  final String mediaType;
  final DateTime createdAt;
  final int viewCount;
  final bool isSeenByMe;
}

class StoryGroup {
  StoryGroup({
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.hasUnseen,
    required this.stories,
  });

  factory StoryGroup.fromJson(Map<String, dynamic> json) => StoryGroup(
        authorId: json['author_id'] as int,
        authorName: json['author_name'] as String,
        authorAvatarUrl: json['author_avatar_url'] as String?,
        hasUnseen: json['has_unseen'] as bool,
        stories: (json['stories'] as List).map((s) => StoryItem.fromJson(s as Map<String, dynamic>)).toList(),
      );

  final int authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final bool hasUnseen;
  final List<StoryItem> stories;
}
