import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../constants/app_url.dart';
import '../../../core/security/secure_token_store.dart';

class VaultConnectSocket {
  VaultConnectSocket._();
  static final instance = VaultConnectSocket._();

  final _events = StreamController<Map<String, dynamic>>.broadcast();
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnect;
  Future<void>? _connecting;
  bool _closed = false;
  int _attempt = 0;
  String? _joinedConversation;

  Stream<Map<String, dynamic>> get events => _events.stream;
  bool get connected => _channel != null;

  Future<void> connect() async {
    _closed = false;
    if (_channel != null) return;
    final activeAttempt = _connecting;
    if (activeAttempt != null) return activeAttempt;
    final attempt = _connectOnce();
    _connecting = attempt;
    try {
      await attempt;
    } finally {
      if (identical(_connecting, attempt)) _connecting = null;
    }
  }

  Future<void> _connectOnce() async {
    final token = await SecureTokenStore.instance.accessToken();
    if (token == null || token.isEmpty) return;
    final uri = AppUrl.connectSocketUri(token);
    try {
      final channel = WebSocketChannel.connect(uri);
      await channel.ready;
      _channel = channel;
      _attempt = 0;
      _subscription = channel.stream.listen(
        (raw) {
          final decoded = jsonDecode(raw.toString());
          if (decoded is Map) _events.add(Map<String, dynamic>.from(decoded));
        },
        onDone: () => _lost(channel),
        onError: (Object error) {
          debugPrint('Vault Connect socket: $error');
          _lost(channel);
        },
        cancelOnError: true,
      );
      if (_joinedConversation != null) join(_joinedConversation!);
    } catch (error) {
      debugPrint('Vault Connect connection failed: $error');
      _lost();
    }
  }

  void emit(String event, Map<String, dynamic> data) {
    _channel?.sink.add(jsonEncode({'event': event, 'data': data}));
  }

  void join(String id) {
    _joinedConversation = id;
    emit('conversation.join', {'conversation_id': id});
  }

  void leave(String id) {
    emit('conversation.leave', {'conversation_id': id});
    if (_joinedConversation == id) _joinedConversation = null;
  }

  void typing(String id, bool active) =>
      emit(active ? 'typing.start' : 'typing.stop', {'conversation_id': id});

  void _lost([WebSocketChannel? source]) {
    if (source != null && !identical(_channel, source)) return;
    _subscription?.cancel();
    _subscription = null;
    _channel = null;
    if (_closed || _reconnect?.isActive == true) return;
    final delay = Duration(seconds: (1 << _attempt.clamp(0, 5).toInt()));
    _attempt++;
    _reconnect = Timer(delay, connect);
  }

  Future<void> close() async {
    _closed = true;
    _reconnect?.cancel();
    await _subscription?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _connecting = null;
  }
}
