import 'package:flutter_riverpod/legacy.dart';

import '../../../data/api_exception.dart';
import '../repositories/ai_repository.dart';

final aiChatProvider = StateNotifierProvider<AiChatNotifier, AiChatState>(
  (ref) => AiChatNotifier(ref.watch(aiRepositoryProvider)),
);

const _welcomeMessage = AiMessage(
  text: '',
  fromUser: false,
  translationKey: 'ai_welcome_message',
);

class AiChatState {
  const AiChatState({required this.messages, this.isSending = false});

  final List<AiMessage> messages;
  final bool isSending;

  AiChatState copyWith({List<AiMessage>? messages, bool? isSending}) {
    return AiChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
    );
  }
}

class AiMessage {
  const AiMessage({
    required this.text,
    required this.fromUser,
    this.translationKey,
    this.translationArgs = const {},
  });

  final String text;
  final bool fromUser;
  final String? translationKey;
  final Map<String, String> translationArgs;
}

class AiChatNotifier extends StateNotifier<AiChatState> {
  AiChatNotifier(this._repository)
    : super(const AiChatState(messages: [_welcomeMessage]));

  final AiRepository _repository;

  Future<void> send(String text, {Map<String, dynamic>? appContext}) async {
    final message = text.trim();
    if (message.isEmpty || state.isSending) return;
    state = state.copyWith(
      isSending: true,
      messages: [
        ...state.messages,
        AiMessage(text: message, fromUser: true),
      ],
    );
    try {
      final reply = await _repository.sendMessage(
        message,
        appContext: appContext,
      );
      state = state.copyWith(
        isSending: false,
        messages: [
          ...state.messages,
          AiMessage(text: reply, fromUser: false),
        ],
      );
    } catch (error) {
      state = state.copyWith(
        isSending: false,
        messages: [
          ...state.messages,
          AiMessage(
            text: '',
            fromUser: false,
            translationKey: 'ai_connection_failed',
            translationArgs: {'error': readableApiError(error)},
          ),
        ],
      );
    }
  }

  void deleteMessage(int index) {
    if (index < 0 || index >= state.messages.length) return;
    final messages = [...state.messages]..removeAt(index);
    state = state.copyWith(
      messages: messages.isEmpty ? const [_welcomeMessage] : messages,
    );
  }

  void clearMessages() {
    state = state.copyWith(messages: const [_welcomeMessage]);
  }
}
