import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/support_models.dart';
import '../repositories/support_repository.dart';

final helpContentProvider = FutureProvider<AppContent>(
  (ref) => ref.watch(supportRepositoryProvider).fetchContent('help'),
);
final aboutContentProvider = FutureProvider<AppContent>(
  (ref) => ref.watch(supportRepositoryProvider).fetchContent('about'),
);

class SupportChatState {
  const SupportChatState({
    this.messages = const [],
    this.loading = true,
    this.sending = false,
    this.error,
  });
  final List<SupportChatMessage> messages;
  final bool loading, sending;
  final String? error;
}

final supportChatProvider =
    StateNotifierProvider<SupportChatController, SupportChatState>(
      (ref) =>
          SupportChatController(ref.watch(supportRepositoryProvider))..load(),
    );

class SupportChatController extends StateNotifier<SupportChatState> {
  SupportChatController(this._repo) : super(const SupportChatState());
  final SupportRepository _repo;
  Future<void> load() async {
    try {
      state = SupportChatState(
        messages: await _repo.fetchMessages(),
        loading: false,
      );
    } catch (e) {
      state = SupportChatState(loading: false, error: e.toString());
    }
  }

  Future<bool> send(String text) async {
    final value = text.trim();
    if (value.isEmpty || state.sending) return false;
    state = SupportChatState(
      messages: state.messages,
      loading: false,
      sending: true,
    );
    try {
      final row = await _repo.sendMessage(value);
      state = SupportChatState(
        messages: [...state.messages, row],
        loading: false,
      );
      return true;
    } catch (e) {
      state = SupportChatState(
        messages: state.messages,
        loading: false,
        error: e.toString(),
      );
      return false;
    }
  }
}
