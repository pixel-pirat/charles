import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import 'chat_repository.dart';
import 'chat_socket_service.dart';
import 'conversation_model.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(apiClientProvider));
});

/// One socket/lobby-presence connection shared for the app's lifetime.
final chatSocketServiceProvider = Provider<ChatSocketService>((ref) {
  return ChatSocketService(ref.watch(tokenStorageProvider));
});

final conversationsControllerProvider =
    AsyncNotifierProvider<ConversationsController, List<ConversationSummary>>(ConversationsController.new);

class ConversationsController extends AsyncNotifier<List<ConversationSummary>> {
  @override
  Future<List<ConversationSummary>> build() => ref.read(chatRepositoryProvider).conversations();

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => ref.read(chatRepositoryProvider).conversations());
  }
}
