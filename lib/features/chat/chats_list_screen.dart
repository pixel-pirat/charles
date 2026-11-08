import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../../widgets/profile_avatar.dart';
import '../users/discover_screen.dart';
import 'chat_controller.dart';
import 'chat_conversation_screen.dart';
import 'conversation_model.dart';

class ChatsListScreen extends ConsumerWidget {
  const ChatsListScreen({super.key});

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty && parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().toUtc().difference(time.toUtc());
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DiscoverScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(conversationsControllerProvider.notifier).refresh(),
        child: conversations.when(
          data: (list) => list.isEmpty
              ? ListView(
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('No conversations yet.', style: TextStyle(color: AppTheme.textSecondary))),
                    ),
                  ],
                )
              : ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, indent: 76),
                  itemBuilder: (context, index) => _ConversationTile(
                    conversation: list[index],
                    initials: _initials(list[index].displayName),
                    timeLabel: _timeAgo(list[index].lastMessageAt),
                  ),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => ref.read(conversationsControllerProvider.notifier).refresh(),
              child: const Text('Could not load chats — tap to retry'),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.initials, required this.timeLabel});

  final ConversationSummary conversation;
  final String initials;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.unreadCount > 0;

    return ListTile(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatConversationScreen(
            partnerId: conversation.partnerId,
            partnerName: conversation.displayName,
            partnerAvatarUrl: conversation.partnerAvatarUrl,
          ),
        ),
      ),
      leading: Stack(
        children: [
          ProfileAvatar(imageUrl: conversation.partnerAvatarUrl, initials: initials, radius: 26),
          if (conversation.partnerIsOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: AppTheme.tagGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.surface, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(conversation.displayName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
          if (conversation.isPinned) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.push_pin, size: 14, color: AppTheme.textSecondary)),
          if (conversation.isMuted) const Icon(Icons.volume_off, size: 14, color: AppTheme.textSecondary),
        ],
      ),
      subtitle: Text(
        '${conversation.lastMessageIsMine ? "You: " : ""}${conversation.lastMessageText}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: hasUnread ? AppTheme.textPrimary : AppTheme.textSecondary,
          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(timeLabel, style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary)),
          if (hasUnread) ...[
            const SizedBox(height: 4),
            CircleAvatar(
              radius: 9,
              backgroundColor: AppTheme.primary,
              child: Text('${conversation.unreadCount}', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }
}
