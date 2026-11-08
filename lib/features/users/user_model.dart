class PublicUser {
  PublicUser({required this.id, this.fullName, this.username, this.imageUrl, this.bio});

  factory PublicUser.fromJson(Map<String, dynamic> json) => PublicUser(
        id: json['id'] as int,
        fullName: json['full_name'] as String?,
        username: json['username'] as String?,
        imageUrl: json['image_url'] as String?,
        bio: json['bio'] as String?,
      );

  final int id;
  final String? fullName;
  final String? username;
  final String? imageUrl;
  final String? bio;

  String get displayName => (fullName?.isNotEmpty ?? false) ? fullName! : (username?.isNotEmpty ?? false) ? username! : 'Unknown user';

  String get initials {
    final name = displayName.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+'));
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}
