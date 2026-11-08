import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phoenix_socket/phoenix_socket.dart';

import '../../theme/app_theme.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/profile_avatar.dart';
import '../auth/auth_controller.dart';
import 'chat_controller.dart';
import 'message_model.dart';

const _reactionEmojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

class ChatConversationScreen extends ConsumerStatefulWidget {
  const ChatConversationScreen({super.key, required this.partnerId, required this.partnerName, this.partnerAvatarUrl});

  final int partnerId;
  final String partnerName;
  final String? partnerAvatarUrl;

  @override
  ConsumerState<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends ConsumerState<ChatConversationScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  bool _partnerTyping = false;
  ChatMessage? _replyTo;
  PhoenixChannel? _channel;
  StreamSubscription<Message>? _subscription;
  Timer? _typingResetTimer;
  late final int _myId;

  @override
  void initState() {
    super.initState();
    _myId = ref.read(authControllerProvider).value!.id;
    _load();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _typingResetTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _roomTopic {
    final ids = [_myId, widget.partnerId]..sort();
    return 'room:${ids[0]}-${ids[1]}';
  }

  Future<void> _load() async {
    final repo = ref.read(chatRepositoryProvider);
    final history = await repo.messages(widget.partnerId);
    if (!mounted) return;
    setState(() {
      _messages = history;
      _loading = false;
    });
    unawaited(repo.markRead(widget.partnerId));
    unawaited(_joinChannel());
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _joinChannel() async {
    final channel = await ref.read(chatSocketServiceProvider).joinRoom(_roomTopic);
    _channel = channel;
    _subscription = channel.messages.listen(_onChannelMessage);
  }

  void _onChannelMessage(Message message) {
    switch (message.event.value) {
      case 'new_message':
        final incoming = ChatMessage.fromJson(Map<String, dynamic>.from(message.payload as Map));
        if (_messages.any((m) => m.id == incoming.id)) return;
        setState(() => _messages = [..._messages, incoming]);
        if (incoming.senderId == widget.partnerId) {
          unawaited(ref.read(chatRepositoryProvider).markRead(widget.partnerId));
        }
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      case 'message_updated':
        final updated = ChatMessage.fromJson(Map<String, dynamic>.from(message.payload as Map));
        final index = _messages.indexWhere((m) => m.id == updated.id);
        if (index == -1) return;
        setState(() => _messages = [..._messages]..[index] = updated);
      case 'typing':
        final payload = Map<String, dynamic>.from(message.payload as Map);
        if (payload['user_id'] == widget.partnerId) {
          setState(() => _partnerTyping = payload['is_typing'] as bool);
        }
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _onTextChanged(String _) {
    _channel?.push('typing', {'is_typing': true});
    _typingResetTimer?.cancel();
    _typingResetTimer = Timer(const Duration(seconds: 2), () {
      _channel?.push('typing', {'is_typing': false});
    });
  }

  Future<void> _send({String? mediaUrl, String? mediaType}) async {
    final text = _textController.text.trim();
    if (text.isEmpty && mediaUrl == null) return;

    setState(() => _sending = true);
    _textController.clear();
    final replyTo = _replyTo;
    setState(() => _replyTo = null);

    try {
      final sent = await ref.read(chatRepositoryProvider).sendMessage(
            recipientId: widget.partnerId,
            text: text,
            mediaUrl: mediaUrl,
            mediaType: mediaType,
            replyToMessageId: replyTo?.id,
          );
      if (!_messages.any((m) => m.id == sent.id)) {
        setState(() => _messages = [..._messages, sent]);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not send that message.')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _attachAndSendImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;

    setState(() => _sending = true);
    try {
      final url = await ref.read(apiClientProvider).uploadFile(file.path);
      await _send(mediaUrl: url, mediaType: 'image');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not upload that photo.')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _replaceMessage(ChatMessage updated) {
    final index = _messages.indexWhere((m) => m.id == updated.id);
    if (index == -1) return;
    setState(() => _messages = [..._messages]..[index] = updated);
  }

  Future<void> _showMessageActions(ChatMessage message) async {
    final isMine = message.senderId == _myId;
    final repo = ref.read(chatRepositoryProvider);

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _reactionEmojis
                    .map(
                      (emoji) => IconButton(
                        onPressed: () async {
                          Navigator.of(sheetContext).pop();
                          final updated = await repo.react(message.id, emoji);
                          _replaceMessage(updated);
                        },
                        icon: Text(emoji, style: const TextStyle(fontSize: 22)),
                      ),
                    )
                    .toList(),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.reply_rounded),
              title: const Text('Reply'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                setState(() => _replyTo = message);
              },
            ),
            if (isMine && !message.isDeleted && message.mediaUrl == null)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final newText = await _promptForText(message.text);
                  if (newText != null && newText.trim().isNotEmpty) {
                    final updated = await repo.edit(message.id, newText.trim());
                    _replaceMessage(updated);
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined),
              title: const Text('Delete for me'),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                await repo.deleteForMe(message.id);
                setState(() => _messages = _messages.where((m) => m.id != message.id).toList());
              },
            ),
            if (isMine && !message.isDeleted)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete for everyone', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final updated = await repo.deleteForEveryone(message.id);
                  _replaceMessage(updated);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<String?> _promptForText(String initial) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit message'),
        content: TextField(controller: controller, autofocus: true, maxLines: 4),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(controller.text), child: const Text('Save')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            ProfileAvatar(imageUrl: widget.partnerAvatarUrl, initials: _initials(widget.partnerName), radius: 17),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.partnerName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  if (_partnerTyping)
                    const Text('typing…', style: TextStyle(fontSize: 11.5, color: AppTheme.primary)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return ChatBubble(
                        message: message,
                        isMine: message.senderId == _myId,
                        onLongPress: () => _showMessageActions(message),
                      );
                    },
                  ),
          ),
          if (_replyTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: AppTheme.divider,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Replying to: ${_replyTo!.isDeleted ? "deleted message" : _replyTo!.text}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => setState(() => _replyTo = null),
                  ),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image_outlined, color: AppTheme.primary),
                    onPressed: _sending ? null : _attachAndSendImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      onChanged: _onTextChanged,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Message…',
                        filled: true,
                        fillColor: AppTheme.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(22)), borderSide: BorderSide.none),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: _sending
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send_rounded, color: AppTheme.primary),
                    onPressed: _sending ? null : () => _send(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty && parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}
