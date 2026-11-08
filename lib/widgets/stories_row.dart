import 'package:flutter/material.dart';

import '../features/stories/story_model.dart';
import '../theme/app_theme.dart';

class StoriesRow extends StatelessWidget {
  const StoriesRow({super.key, required this.groups, required this.onTapGroup, required this.onTapAddStory});

  final List<StoryGroup> groups;
  final ValueChanged<StoryGroup> onTapGroup;
  final VoidCallback onTapAddStory;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: groups.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == 0) return _AddStoryBubble(onTap: onTapAddStory);
          final group = groups[index - 1];
          return _StoryBubble(group: group, onTap: () => onTapGroup(group));
        },
      ),
    );
  }
}

class _StoryBubble extends StatelessWidget {
  const _StoryBubble({required this.group, required this.onTap});

  final StoryGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: group.hasUnseen
                    ? const LinearGradient(colors: [AppTheme.primaryGradientStart, AppTheme.primaryGradientEnd])
                    : null,
                color: group.hasUnseen ? null : AppTheme.divider,
              ),
              child: CircleAvatar(
                radius: 29,
                backgroundColor: AppTheme.surface,
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: AppTheme.primary,
                  backgroundImage: group.authorAvatarUrl != null ? NetworkImage(group.authorAvatarUrl!) : null,
                  child: group.authorAvatarUrl == null
                      ? Text(_initials(group.authorName), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              group.authorName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty && parts.first.isNotEmpty ? parts.first[0] : '';
    return first.toUpperCase();
  }
}

class _AddStoryBubble extends StatelessWidget {
  const _AddStoryBubble({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.divider, width: 1.5)),
              child: const Icon(Icons.add_rounded, color: AppTheme.primary, size: 26),
            ),
            const SizedBox(height: 4),
            const Text('Your story', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}
