import 'package:flutter/material.dart';

import '../features/posts/post_model.dart';
import '../theme/app_theme.dart';
import 'profile_avatar.dart';

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, required this.onLike});

  final PostItem post;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProfileAvatar(imageUrl: post.authorAvatarUrl, initials: _initials(post.authorName), radius: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppTheme.textPrimary)),
                      Text(_timeAgo(post.createdAt), style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            if (post.text.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(post.text, style: const TextStyle(fontSize: 14.5, color: AppTheme.textPrimary, height: 1.35)),
            ],
            if (post.mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Image.network(
                    post.mediaUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(color: AppTheme.divider),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                _ActionChip(
                  icon: post.isLikedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: post.isLikedByMe ? AppTheme.likeRed : AppTheme.textSecondary,
                  label: '${post.likeCount}',
                  onTap: onLike,
                ),
                const SizedBox(width: 18),
                _ActionChip(
                  icon: Icons.remove_red_eye_outlined,
                  color: AppTheme.textSecondary,
                  label: '${post.viewCount}',
                  onTap: null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty && parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().toUtc().difference(time.toUtc());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.color, required this.label, required this.onTap});

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
