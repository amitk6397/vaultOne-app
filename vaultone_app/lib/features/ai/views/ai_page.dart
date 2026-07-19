import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_loading_indicator.dart';
import '../../../constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/app_language_controller.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../documents/providers/digi_locker_provider.dart';
import '../../files_vault/providers/files_vault_provider.dart';
import '../../passwords/providers/password_vault_provider.dart';
import '../providers/ai_provider.dart';

class AiPage extends ConsumerStatefulWidget {
  const AiPage({super.key});

  @override
  ConsumerState<AiPage> createState() => _AiPageState();
}

class _AiPageState extends ConsumerState<AiPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final chatState = ref.watch(aiChatProvider);
    ref.listen<AiChatState>(aiChatProvider, (previous, next) {
      if ((previous?.messages.length ?? 0) != next.messages.length) {
        _scrollToBottom();
      }
    });
    return Scaffold(
      appBar: AppPageAppBar(
        title: context.l10n.tr('vaultone_ai'),
        subtitle: context.l10n.tr('ai_subtitle'),
        actions: [
          IconButton(
            tooltip: context.l10n.tr('clear_chat'),
            onPressed: chatState.messages.length <= 1
                ? null
                : () => ref.read(aiChatProvider.notifier).clearMessages(),
            icon: const Icon(Icons.delete_sweep_rounded),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(activeTab: AppNavTab.ai),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                itemCount: chatState.messages.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final message = chatState.messages[index];
                  return Align(
                    alignment: message.fromUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: GestureDetector(
                      onLongPress: () => _showMessageActions(index, message),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 280),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: message.fromUser
                              ? colors.primary
                              : colors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: message.fromUser
                              ? null
                              : Border.all(color: colors.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SelectableText(
                              _localizedMessage(context, message),
                              style: AppTextStyles.body.copyWith(
                                color: message.fromUser
                                    ? colors.onPrimary
                                    : colors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _TinyActionButton(
                                  icon: Icons.copy_rounded,
                                  color: message.fromUser
                                      ? colors.onPrimary
                                      : colors.onSurfaceVariant,
                                  onTap: () => _copyMessage(
                                    _localizedMessage(context, message),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                _TinyActionButton(
                                  icon: Icons.delete_outline_rounded,
                                  color: message.fromUser
                                      ? colors.onPrimary
                                      : colors.onSurfaceVariant,
                                  onTap: () => ref
                                      .read(aiChatProvider.notifier)
                                      .deleteMessage(index),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (chatState.isSending)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Row(
                  children: [
                    AppLoadingIndicator(color: colors.primary, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      context.l10n.tr('ai_thinking'),
                      style: AppTextStyles.body.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: context.l10n.tr('ask_vaultone_ai'),
                        filled: true,
                        fillColor: colors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: chatState.isSending ? null : _send,
                    icon: Icon(
                      chatState.isSending
                          ? Icons.hourglass_top_rounded
                          : Icons.send_rounded,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await ref
        .read(aiChatProvider.notifier)
        .send(text, appContext: _buildAppContext());
  }

  Map<String, dynamic> _buildAppContext() {
    final passwords = ref.read(passwordVaultProvider);
    final files = ref.read(filesVaultProvider);
    final docs = ref.read(digiLockerProvider);
    final activePasswords = passwords.entries
        .where((entry) => !entry.isArchived)
        .toList();
    final activeFiles = files.files.where((file) => !file.isArchived).toList();
    return {
      'language_code': ref.read(appLanguageProvider).code,
      'password_vault': {
        'total': activePasswords.length,
        'weak_count': passwords.weakPasswords,
        'reused_count': passwords.reusedPasswords,
        'entries': activePasswords.take(25).map((entry) {
          return {
            'title': entry.title,
            'username': entry.username,
            'website': entry.website,
            'category': entry.categoryLabel,
            'strength': entry.strengthLabel,
            'favorite': entry.isFavorite,
            'updated_at': entry.updatedAt.toIso8601String(),
            'password_value_included': false,
          };
        }).toList(),
      },
      'secure_notes': {
        'total': passwords.notes.length,
        'notes': passwords.notes.take(20).map((note) {
          return {
            'title': note.title,
            'updated_at': note.updatedAt.toIso8601String(),
            'body_included': false,
          };
        }).toList(),
      },
      'documents': {
        'total': docs.documents.length,
        'expiring_count': docs.expiringCount,
        'verified_count': docs.verifiedCount,
        'items': docs.documents.take(25).map((doc) {
          return {
            'title': doc.title,
            'file_name': doc.fileName,
            'type': doc.typeLabel,
            'issuer': doc.issuer,
            'expiry': doc.expiryLabel,
            'verified': doc.isVerified,
            'favorite': doc.isFavorite,
          };
        }).toList(),
      },
      'file_vault': {
        'total': activeFiles.length,
        'private_count': files.privateCount,
        'favorite_count': files.favoriteCount,
        'items': activeFiles.take(25).map((file) {
          return {
            'name': file.name,
            'type': file.typeLabel,
            'size': file.sizeLabel,
            'tags': file.tags,
            'private': file.isPrivate,
            'favorite': file.isFavorite,
          };
        }).toList(),
      },
    };
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    AppFeedback.showSnackBar(
      context,
      message: context.l10n.tr('message_copied'),
    );
  }

  String _localizedMessage(BuildContext context, AiMessage message) {
    final key = message.translationKey;
    return key == null
        ? message.text
        : context.l10n.tr(key, args: message.translationArgs);
  }

  void _showMessageActions(int index, AiMessage message) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.copy_rounded),
                  title: Text(context.l10n.tr('copy_message')),
                  onTap: () {
                    Navigator.pop(context);
                    _copyMessage(_localizedMessage(this.context, message));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: Text(context.l10n.tr('delete_message')),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(aiChatProvider.notifier).deleteMessage(index);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_sweep_rounded),
                  title: Text(context.l10n.tr('clear_all_chats')),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(aiChatProvider.notifier).clearMessages();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TinyActionButton extends StatelessWidget {
  const _TinyActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 15, color: color.withValues(alpha: .74)),
      ),
    );
  }
}
