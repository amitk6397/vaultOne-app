import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../constants/app_url.dart';
import '../../../core/security/secure_token_store.dart';

class VaultConnectSocket with WidgetsBindingObserver {
  VaultConnectSocket._() {
    WidgetsBinding.instance.addObserver(this);
  }
  static final instance = VaultConnectSocket._();

  final _events = StreamController<Map<String, dynamic>>.broadcast();
  io.Socket? _socket;
  Future<void>? _connecting;
  String? _joinedConversation;

  Stream<Map<String, dynamic>> get events => _events.stream;
  bool get connected => _socket?.connected == true;

  Future<void> connect() async {
    if (connected) return;
    final active = _connecting;
    if (active != null) return active;
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
    final ready = Completer<void>();
    final socket = io.io(
      AppUrl.connectSocketOrigin,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setPath('/socket.io')
          .setAuth({'token': token})
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(1000000)
          .setReconnectionDelay(1000)
          .build(),
    );
    _socket?.dispose();
    _socket = socket;
    socket.onConnect((_) {
      if (!ready.isCompleted) ready.complete();
      final id = _joinedConversation;
      if (id != null) join(id);
    });
    socket.onConnectError((error) {
      debugPrint('Vault Connect Socket.IO connection failed: $error');
      if (!ready.isCompleted) ready.complete();
    });
    socket.onError((error) => debugPrint('Vault Connect Socket.IO: $error'));
    for (final event in const [
      'socket.ready',
      'message.created',
      'message.deleted',
      'message.delivered',
      'message.read',
      'conversation.updated',
      'typing.started',
      'typing.stopped',
      'user.online',
      'user.offline',
      'user.blocked',
    ]) {
      socket.on(event, (data) {
        if (data is Map) {
          _events.add({
            'event': event,
            'data': Map<String, dynamic>.from(data),
          });
        }
      });
    }
    socket.connect();
    await ready.future.timeout(const Duration(seconds: 10), onTimeout: () {});
  }

  void emit(String event, Map<String, dynamic> data) =>
      _socket?.emit(event, data);

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(connect());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      // A background app must be considered offline so FCM can deliver one
      // notification for the new unread-message batch.
      _disconnect(clearJoinedConversation: false);
    }
  }

  void _disconnect({required bool clearJoinedConversation}) {
    if (clearJoinedConversation) _joinedConversation = null;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connecting = null;
  }

  Future<void> close() async {
    _disconnect(clearJoinedConversation: true);
  }
}
