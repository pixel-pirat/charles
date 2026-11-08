import '../../core/api_client.dart';
import 'conversation_model.dart';
import 'message_model.dart';

class ChatRepository {
  ChatRepository(this._api);

  final ApiClient _api;

  Future<List<ConversationSummary>> conversations() async {
    final json = await _api.get('/chat/conversations');
    return (json['conversations'] as List).map((c) => ConversationSummary.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<List<ConversationSummary>> archivedConversations() async {
    final json = await _api.get('/chat/conversations/archived');
    return (json['conversations'] as List).map((c) => ConversationSummary.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<List<ChatMessage>> messages(int partnerId) async {
    final json = await _api.get('/chat/messages/$partnerId');
    return (json['messages'] as List).map((m) => ChatMessage.fromJson(m as Map<String, dynamic>)).toList();
  }

  Future<ChatMessage> sendMessage({
    required int recipientId,
    required String text,
    String? mediaUrl,
    String? mediaType,
    int? replyToMessageId,
  }) async {
    final json = await _api.post('/chat/messages', data: {
      'recipient_id': recipientId,
      'text': text,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'reply_to_message_id': replyToMessageId,
    });
    return ChatMessage.fromJson(json['message'] as Map<String, dynamic>);
  }

  Future<void> markRead(int partnerId) => _api.post('/chat/conversations/$partnerId/read');

  Future<ChatMessage> react(int messageId, String emoji) async {
    final json = await _api.post('/chat/messages/$messageId/react', data: {'emoji': emoji});
    return ChatMessage.fromJson(json['message'] as Map<String, dynamic>);
  }

  Future<ChatMessage> edit(int messageId, String text) async {
    final json = await _api.patch('/chat/messages/$messageId', data: {'text': text});
    return ChatMessage.fromJson(json['message'] as Map<String, dynamic>);
  }

  Future<ChatMessage> deleteForEveryone(int messageId) async {
    final json = await _api.deleteExpectingBody('/chat/messages/$messageId');
    return ChatMessage.fromJson(json['message'] as Map<String, dynamic>);
  }

  Future<void> deleteForMe(int messageId) => _api.post('/chat/messages/$messageId/delete_for_me');

  Future<ChatMessage> forward(int messageId, int toRecipientId) async {
    final json = await _api.post('/chat/messages/$messageId/forward', data: {'recipient_id': toRecipientId});
    return ChatMessage.fromJson(json['message'] as Map<String, dynamic>);
  }

  Future<void> block(int userId) => _api.post('/chat/blocks/$userId');
  Future<void> unblock(int userId) => _api.delete('/chat/blocks/$userId');

  Future<void> mute(int partnerId) => _api.post('/chat/mutes/$partnerId');
  Future<void> unmute(int partnerId) => _api.delete('/chat/mutes/$partnerId');

  Future<void> pin(int partnerId) => _api.post('/chat/pins/$partnerId');
  Future<void> unpin(int partnerId) => _api.delete('/chat/pins/$partnerId');

  Future<void> archive(int partnerId) => _api.post('/chat/archives/$partnerId');
  Future<void> unarchive(int partnerId) => _api.delete('/chat/archives/$partnerId');

  Future<void> star(int messageId) => _api.post('/chat/stars/$messageId');
  Future<void> unstar(int messageId) => _api.delete('/chat/stars/$messageId');

  Future<List<ChatMessage>> starredMessages() async {
    final json = await _api.get('/chat/stars');
    return (json['messages'] as List).map((m) => ChatMessage.fromJson(m as Map<String, dynamic>)).toList();
  }
}
