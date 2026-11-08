import 'package:flutter/material.dart';

import '../features/chat/message_model.dart';
import '../theme/app_theme.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message, required this.isMine, required this.onLongPress});

  final ChatMessage message;
  final bool isMine;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMine ? AppTheme.primary : AppTheme.cardBackground;
    final textColor = isMine ? Colors.white : AppTheme.textPrimary;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMine ? 16 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 16),
            ),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.replyPreviewText != null) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: (isMine ? Colors.white : AppTheme.primary).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    message.replyPreviewText!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.85)),
                  ),
                ),
              ],
              if (message.isDeleted)
                Text('This message was deleted', style: TextStyle(fontStyle: FontStyle.italic, color: textColor.withValues(alpha: 0.7)))
              else ...[
                if (message.mediaUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(message.mediaUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox.shrink()),
                  ),
                  if (message.text.isNotEmpty) const SizedBox(height: 6),
                ],
                if (message.text.isNotEmpty) Text(message.text, style: TextStyle(fontSize: 14.5, color: textColor)),
              ],
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_time(message.createdAt), style: TextStyle(fontSize: 10.5, color: textColor.withValues(alpha: 0.65))),
                  if (message.editedAt != null) ...[
                    const SizedBox(width: 4),
                    Text('edited', style: TextStyle(fontSize: 10, color: textColor.withValues(alpha: 0.55))),
                  ],
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.deliveredAt != null || message.readAt != null ? Icons.done_all_rounded : Icons.done_rounded,
                      size: 14,
                      color: message.readAt != null ? Colors.lightBlueAccent : textColor.withValues(alpha: 0.7),
                    ),
                  ],
                ],
              ),
              if (message.reactions.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: _groupedReactions(message).entries
                      .map((e) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
                            child: Text('${e.key} ${e.value}', style: const TextStyle(fontSize: 11)),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Map<String, int> _groupedReactions(ChatMessage message) {
    final counts = <String, int>{};
    for (final r in message.reactions) {
      counts[r.emoji] = (counts[r.emoji] ?? 0) + 1;
    }
    return counts;
  }

  String _time(DateTime time) {
    final local = time.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
