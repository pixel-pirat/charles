import 'package:phoenix_socket/phoenix_socket.dart';

import '../../core/api_client.dart';
import '../../core/token_storage.dart';

/// Owns a single [PhoenixSocket] connection for the app's lifetime,
/// joins the lobby channel once (so this user shows as online to
/// everyone else's conversations list), and hands out joined room
/// channels for open chat screens.
class ChatSocketService {
  ChatSocketService(this._tokenStorage);

  final TokenStorage _tokenStorage;
  PhoenixSocket? _socket;
  Future<PhoenixSocket>? _connecting;
  final Set<String> _joinedTopics = {};

  Future<PhoenixSocket> _ensureConnected() {
    final existing = _socket;
    if (existing != null && existing.isConnected) return Future.value(existing);
    return _connecting ??= _connect().whenComplete(() => _connecting = null);
  }

  Future<PhoenixSocket> _connect() async {
    final token = await _tokenStorage.readToken();
    if (token == null) throw StateError('Cannot open the chat socket while signed out.');
    final socket = PhoenixSocket(_websocketUrl(), socketOptions: PhoenixSocketOptions(params: {'token': token}));
    await socket.connect();
    _socket = socket;
    return socket;
  }

  /// Joins once per app session — the server tracks this user as
  /// online in Phoenix.Presence for as long as this channel stays
  /// open, which is what GET /api/chat/conversations reads to show
  /// each partner's online badge.
  Future<void> joinLobby() async {
    if (_joinedTopics.contains('lobby')) return;
    final socket = await _ensureConnected();
    final channel = socket.addChannel(topic: 'lobby');
    _joinedTopics.add('lobby');
    await channel.join().future;
  }

  /// Joins (or returns the already-joined) channel for [roomTopic] —
  /// e.g. "room:2-5" from `Chat.conversation_topic/2` on the backend.
  Future<PhoenixChannel> joinRoom(String roomTopic) async {
    final socket = await _ensureConnected();
    final channel = socket.addChannel(topic: roomTopic);
    if (!_joinedTopics.contains(roomTopic)) {
      _joinedTopics.add(roomTopic);
      await channel.join().future;
    }
    return channel;
  }

  String _websocketUrl() {
    final apiUri = Uri.parse(apiBaseUrl());
    final scheme = apiUri.scheme == 'https' ? 'wss' : 'ws';
    return Uri(scheme: scheme, host: apiUri.host, port: apiUri.hasPort ? apiUri.port : null, path: '/socket/websocket')
        .toString();
  }
}
