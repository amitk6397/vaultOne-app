import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../documents/providers/digi_locker_provider.dart';
import '../../media/models/media_item.dart';
import '../../media/providers/media_provider.dart';
import '../models/connect_models.dart';
import '../repositories/connect_repository.dart';
import '../services/connect_socket.dart';

final vaultConnectProvider =
    StateNotifierProvider<VaultConnectController, VaultConnectState>((ref) {
      return VaultConnectController(ref, ref.watch(connectRepositoryProvider));
    });

class VaultConnectState {
  const VaultConnectState({
    this.conversations = const [],
    this.messages = const {},
    this.isLoading = false,
    this.loadingMore = false,
    this.error,
    this.conversationCursor,
    this.messageCursors = const {},
    this.typingConversations = const {},
    this.uploadProgress = const {},
  });
  final List<ConnectConversation> conversations;
  final Map<String, List<ConnectMessage>> messages;
  final bool isLoading;
  final bool loadingMore;
  final String? error;
  final String? conversationCursor;
  final Map<String, String?> messageCursors;
  final Set<String> typingConversations;
  final Map<String, double> uploadProgress;

  VaultConnectState copyWith({
    List<ConnectConversation>? conversations,
    Map<String, List<ConnectMessage>>? messages,
    bool? isLoading,
    bool? loadingMore,
    String? error,
    String? conversationCursor,
    Map<String, String?>? messageCursors,
    Set<String>? typingConversations,
    Map<String, double>? uploadProgress,
  }) => VaultConnectState(
    conversations: conversations ?? this.conversations,
    messages: messages ?? this.messages,
    isLoading: isLoading ?? this.isLoading,
    loadingMore: loadingMore ?? this.loadingMore,
    error: error,
    conversationCursor: conversationCursor ?? this.conversationCursor,
    messageCursors: messageCursors ?? this.messageCursors,
    typingConversations: typingConversations ?? this.typingConversations,
    uploadProgress: uploadProgress ?? this.uploadProgress,
  );
}

class VaultConnectController extends StateNotifier<VaultConnectState> {
  VaultConnectController(this._ref, this._repository)
    : super(const VaultConnectState()) {
    _subscription = VaultConnectSocket.instance.events.listen(_onSocket);
    unawaited(VaultConnectSocket.instance.connect());
  }

  final Ref _ref;
  final VaultConnectRepository _repository;
  StreamSubscription<Map<String, dynamic>>? _subscription;

  Future<void> loadConversations({bool more = false}) async {
    if (state.isLoading || state.loadingMore) return;
    state = state.copyWith(isLoading: !more, loadingMore: more);
    try {
      final result = await _repository.conversations(
        cursor: more ? state.conversationCursor : null,
      );
      state = state.copyWith(
        conversations: more
            ? [...state.conversations, ...result.items]
            : result.items,
        conversationCursor: result.cursor,
        isLoading: false,
        loadingMore: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        loadingMore: false,
        error: error.toString(),
      );
    }
  }

  Future<ConnectConversation?> createDirect(int userId) async {
    try {
      final item = await _repository.createDirect(userId);
      state = state.copyWith(
        conversations: [
          item,
          ...state.conversations.where((x) => x.id != item.id),
        ],
      );
      return item;
    } catch (error) {
      state = state.copyWith(error: error.toString());
      return null;
    }
  }

  Future<void> openConversation(String id) async {
    await VaultConnectSocket.instance.connect();
    VaultConnectSocket.instance.join(id);
    await loadMessages(id);
  }

  void leaveConversation(String id) => VaultConnectSocket.instance.leave(id);

  Future<void> loadMessages(String id, {bool more = false}) async {
    if (state.loadingMore) return;
    state = state.copyWith(isLoading: !more, loadingMore: more);
    try {
      final result = await _repository.messages(
        id,
        cursor: more ? state.messageCursors[id] : null,
      );
      final current = state.messages[id] ?? const <ConnectMessage>[];
      final merged = more ? [...current, ...result.items] : result.items;
      final cursors = {...state.messageCursors, id: result.cursor};
      state = state.copyWith(
        messages: {...state.messages, id: merged},
        messageCursors: cursors,
        isLoading: false,
        loadingMore: false,
      );
      await _acknowledge(id, result.items);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        loadingMore: false,
        error: error.toString(),
      );
    }
  }

  Future<void> sendText(String conversationId, String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;
    final clientId = 'flutter-${DateTime.now().microsecondsSinceEpoch}';
    final pending = ConnectMessage(
      id: clientId,
      clientMessageId: clientId,
      conversationId: conversationId,
      senderUserId: userId,
      messageType: 'text',
      content: clean,
      createdAt: DateTime.now(),
      status: ConnectMessageStatus.pending,
    );
    _prepend(conversationId, pending);
    try {
      final sent = await _repository.send(
        conversationId: conversationId,
        clientMessageId: clientId,
        content: clean,
      );
      _replaceClient(conversationId, clientId, sent);
    } catch (_) {
      _replaceClient(
        conversationId,
        clientId,
        pending.copyWith(status: ConnectMessageStatus.failed),
      );
    }
  }

  Future<void> retry(ConnectMessage message) async {
    _replaceClient(
      message.conversationId,
      message.clientMessageId,
      message.copyWith(status: ConnectMessageStatus.pending),
    );
    try {
      final sent = await _repository.send(
        conversationId: message.conversationId,
        clientMessageId: message.clientMessageId,
        messageType: message.messageType,
        content: message.content,
        attachmentIds: message.attachments.map((x) => x.id).toList(),
      );
      _replaceClient(message.conversationId, message.clientMessageId, sent);
    } catch (_) {
      _replaceClient(
        message.conversationId,
        message.clientMessageId,
        message.copyWith(status: ConnectMessageStatus.failed),
      );
    }
  }

  Future<void> sendFile(
    String conversationId,
    File file,
    String kind,
    String mime,
  ) async {
    final key = file.path;
    state = state.copyWith(uploadProgress: {...state.uploadProgress, key: 0});
    File? transferCopy;
    try {
      final directory = await getTemporaryDirectory();
      transferCopy = await file.copy(
        p.join(
          directory.path,
          'vault_connect_transfer_${DateTime.now().microsecondsSinceEpoch}${p.extension(file.path)}',
        ),
      );
      final attachment = await _repository.upload(
        conversationId,
        transferCopy,
        kind,
        mime,
        onProgress: (value) {
          state = state.copyWith(
            uploadProgress: {...state.uploadProgress, key: value},
          );
        },
      );
      final clientId = 'flutter-file-${DateTime.now().microsecondsSinceEpoch}';
      final message = await _repository.send(
        conversationId: conversationId,
        clientMessageId: clientId,
        messageType: kind,
        attachmentIds: [attachment.id],
      );
      _prepend(conversationId, message);
    } catch (error) {
      state = state.copyWith(error: error.toString());
    } finally {
      if (transferCopy != null && await transferCopy.exists()) {
        await transferCopy.delete();
      }
      final progress = {...state.uploadProgress}..remove(key);
      state = state.copyWith(uploadProgress: progress);
    }
  }

  Future<void> saveDeviceFileToVault({
    required String path,
    required String fileName,
    required String kind,
  }) async {
    final source = File(path);
    if (!await source.exists()) {
      throw StateError('Selected file is unavailable');
    }
    if (kind == 'image' || kind == 'video') {
      await _ref
          .read(mediaLibraryProvider.notifier)
          .importReceivedMedia(
            sourcePath: path,
            fileName: fileName,
            kind: kind == 'image' ? MediaKind.photo : MediaKind.video,
          );
    } else {
      await _ref.read(digiLockerProvider.notifier).importFiles([
        PlatformFile(name: fileName, path: path, size: await source.length()),
      ], 'other');
    }
  }

  Future<void> deleteMessage(
    ConnectMessage message, {
    required bool everyone,
  }) async {
    await _repository.deleteMessage(message.id, everyone: everyone);
    if (everyone) {
      _replaceClient(
        message.conversationId,
        message.clientMessageId,
        message.copyWith(status: ConnectMessageStatus.deleted),
      );
    } else {
      final values = <ConnectMessage>[
        ...(state.messages[message.conversationId] ?? const <ConnectMessage>[]),
      ]..removeWhere((x) => x.id == message.id);
      state = state.copyWith(
        messages: {...state.messages, message.conversationId: values},
      );
    }
  }

  Future<void> setDisappearing(String id, int seconds) =>
      _repository.disappearing(id, seconds);
  Future<void> clearConversation(String id) async {
    await _repository.clear(id);
    state = state.copyWith(messages: {...state.messages, id: const []});
  }

  Future<void> block(ConnectConversation item) =>
      _repository.block(item.participant.id);
  Future<void> report(
    ConnectConversation item,
    String category,
    String description,
  ) => _repository.report(
    userId: item.participant.id,
    conversationId: item.id,
    category: category,
    description: description,
  );

  Future<String> download(ConnectAttachment item) async {
    final directory = await getTemporaryDirectory();
    final target = p.join(
      directory.path,
      'vault_connect_${item.id}_${item.fileName}',
    );
    return _repository.download(
      item,
      target,
      onProgress: (value) {
        state = state.copyWith(
          uploadProgress: {...state.uploadProgress, item.id: value},
        );
      },
    );
  }

  Future<void> openSecurely(ConnectAttachment item) async {
    final path = await download(item);
    await OpenFilex.open(path);
  }

  Future<void> exportToDevice(ConnectAttachment item) async {
    final path = await download(item);
    final bytes = await File(path).readAsBytes();
    await FilePicker.saveFile(
      dialogTitle: 'Export secure file',
      fileName: item.fileName,
      bytes: bytes,
    );
    await File(path).delete();
  }

  Future<bool> saveToVault(ConnectAttachment item) async {
    final box = await Hive.openBox<dynamic>('vault_connect_saved_attachments');
    if (box.containsKey(item.id)) return false;
    final path = await download(item);
    final file = File(path);
    try {
      if (item.fileType == 'image' || item.fileType == 'video') {
        await _ref
            .read(mediaLibraryProvider.notifier)
            .importReceivedMedia(
              sourcePath: path,
              fileName: item.fileName,
              kind: item.fileType == 'image'
                  ? MediaKind.photo
                  : MediaKind.video,
            );
      } else {
        await _ref.read(digiLockerProvider.notifier).importFiles([
          PlatformFile(
            name: item.fileName,
            path: path,
            size: await file.length(),
          ),
        ], 'other');
      }
      await box.put(item.id, DateTime.now().toIso8601String());
      return true;
    } finally {
      if (await file.exists()) await file.delete();
    }
  }

  void typing(String id, bool active) =>
      VaultConnectSocket.instance.typing(id, active);

  Future<void> _acknowledge(
    String conversationId,
    List<ConnectMessage> items,
  ) async {
    final userId =
        (await SharedPreferences.getInstance()).getInt('user_id') ?? 0;
    for (final item in items.where(
      (x) => x.senderUserId != userId && x.status != ConnectMessageStatus.read,
    )) {
      unawaited(_repository.delivered(item.id));
      unawaited(_repository.read(item.id));
    }
  }

  void _prepend(String id, ConnectMessage message) {
    final values = [
      message,
      ...(state.messages[id] ?? const <ConnectMessage>[]).where(
        (x) => x.clientMessageId != message.clientMessageId,
      ),
    ];
    state = state.copyWith(messages: {...state.messages, id: values});
  }

  void _replaceClient(String id, String clientId, ConnectMessage message) {
    final values = <ConnectMessage>[
      ...(state.messages[id] ?? const <ConnectMessage>[]),
    ];
    final index = values.indexWhere((x) => x.clientMessageId == clientId);
    if (index < 0) {
      values.insert(0, message);
    } else {
      values[index] = message;
    }
    state = state.copyWith(messages: {...state.messages, id: values});
  }

  void _onSocket(Map<String, dynamic> packet) {
    final event = packet['event']?.toString();
    final data = packet['data'];
    if (data is! Map) return;
    final json = Map<String, dynamic>.from(data);
    if (event == 'message.created') {
      final message = ConnectMessage.fromJson(json);
      _prepend(message.conversationId, message);
    } else if (event == 'message.deleted') {
      final id = json['conversation_id']?.toString() ?? '';
      final values = (state.messages[id] ?? const <ConnectMessage>[])
          .map(
            (x) => x.id == json['message_id']
                ? x.copyWith(status: ConnectMessageStatus.deleted)
                : x,
          )
          .toList();
      state = state.copyWith(messages: {...state.messages, id: values});
    } else if (event == 'message.delivered' || event == 'message.read') {
      for (final entry in state.messages.entries) {
        final values = entry.value
            .map(
              (x) => x.id == json['message_id']
                  ? x.copyWith(
                      status: event == 'message.read'
                          ? ConnectMessageStatus.read
                          : ConnectMessageStatus.delivered,
                    )
                  : x,
            )
            .toList();
        state = state.copyWith(
          messages: {...state.messages, entry.key: values},
        );
      }
    } else if (event == 'typing.started' || event == 'typing.stopped') {
      final id = json['conversation_id']?.toString() ?? '';
      final values = {...state.typingConversations};
      event == 'typing.started' ? values.add(id) : values.remove(id);
      state = state.copyWith(typingConversations: values);
    } else if (event == 'user.blocked') {
      unawaited(loadConversations());
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
