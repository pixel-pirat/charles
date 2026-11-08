class PostItem {
  PostItem({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorUsername,
    this.authorAvatarUrl,
    required this.text,
    required this.mediaUrls,
    required this.mediaType,
    required this.createdAt,
    required this.likeCount,
    required this.commentCount,
    required this.viewCount,
    required this.isLikedByMe,
  });

  factory PostItem.fromJson(Map<String, dynamic> json) => PostItem(
        id: json['id'] as int,
        authorId: json['author_id'] as int,
        authorName: json['author_name'] as String,
        authorUsername: json['author_username'] as String?,
        authorAvatarUrl: json['author_avatar_url'] as String?,
        text: json['text'] as String,
        mediaUrls: (json['media_urls'] as List).cast<String>(),
        mediaType: json['media_type'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        likeCount: json['like_count'] as int,
        commentCount: json['comment_count'] as int,
        viewCount: json['view_count'] as int,
        isLikedByMe: json['is_liked_by_me'] as bool,
      );

  final int id;
  final int authorId;
  final String authorName;
  final String? authorUsername;
  final String? authorAvatarUrl;
  final String text;
  final List<String> mediaUrls;
  final String mediaType;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;
  final int viewCount;
  final bool isLikedByMe;

  PostItem copyWith({int? likeCount, bool? isLikedByMe, int? viewCount}) => PostItem(
        id: id,
        authorId: authorId,
        authorName: authorName,
        authorUsername: authorUsername,
        authorAvatarUrl: authorAvatarUrl,
        text: text,
        mediaUrls: mediaUrls,
        mediaType: mediaType,
        createdAt: createdAt,
        likeCount: likeCount ?? this.likeCount,
        commentCount: commentCount,
        viewCount: viewCount ?? this.viewCount,
        isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      );
}
