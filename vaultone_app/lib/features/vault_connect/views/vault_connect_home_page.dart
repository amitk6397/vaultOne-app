import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../models/connect_models.dart';
import '../providers/connect_provider.dart';

class VaultConnectHomePage extends ConsumerStatefulWidget {
  const VaultConnectHomePage({super.key});
  @override
  ConsumerState<VaultConnectHomePage> createState() =>
      _VaultConnectHomePageState();
}

class _VaultConnectHomePageState extends ConsumerState<VaultConnectHomePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(vaultConnectProvider.notifier).loadConversations(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vaultConnectProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault Connect'),
        actions: [
          IconButton(
            tooltip: 'Blocked users',
            onPressed: () => context.pushNamed(AppRoutes.connectBlockedName),
            icon: const Icon(Icons.block_rounded),
          ),
          IconButton(
            tooltip: 'New secure chat',
            onPressed: () => context.pushNamed(AppRoutes.connectPermissionName),
            icon: const Icon(Icons.edit_square),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(AppRoutes.connectPermissionName),
        icon: const Icon(Icons.lock_person_rounded),
        label: const Text('New chat'),
        shape: const StadiumBorder(),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(vaultConnectProvider.notifier).loadConversations(),
        child: Builder(
          builder: (context) {
            if (state.isLoading && state.conversations.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.error != null && state.conversations.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 150),
                  const Icon(Icons.cloud_off_rounded, size: 54),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(state.error!, textAlign: TextAlign.center),
                  ),
                  Center(
                    child: FilledButton(
                      onPressed: () => ref
                          .read(vaultConnectProvider.notifier)
                          .loadConversations(),
                      child: const Text('Retry'),
                    ),
                  ),
                ],
              );
            }
            if (state.conversations.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 150),
                  Icon(Icons.forum_outlined, size: 64, color: AppColors.purple),
                  SizedBox(height: 16),
                  Text(
                    'Your private conversations will appear here',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                  ),
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Start a chat with a registered contact. Contact lists are matched securely and are not stored.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount:
                  state.conversations.length +
                  (state.conversationCursor != null ? 1 : 0),
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 76),
              itemBuilder: (context, index) {
                if (index == state.conversations.length) {
                  return TextButton(
                    onPressed: state.loadingMore
                        ? null
                        : () => ref
                              .read(vaultConnectProvider.notifier)
                              .loadConversations(more: true),
                    child: state.loadingMore
                        ? const CircularProgressIndicator()
                        : const Text('Load more'),
                  );
                }
                final item = state.conversations[index];
                final last = item.lastMessage;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 7,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.purple.withValues(alpha: .12),
                    child: Text(
                      item.participant.displayName.isEmpty
                          ? '?'
                          : item.participant.displayName[0].toUpperCase(),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.participant.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (item.lastMessageAt != null)
                        Text(
                          _time(item.lastMessageAt!),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                    ],
                  ),
                  subtitle: Text(
                    item.isBlocked
                        ? 'User blocked'
                        : last == null
                        ? 'Secure conversation'
                        : last.status == ConnectMessageStatus.deleted
                        ? 'This message was deleted'
                        : last.attachments.isNotEmpty
                        ? '🔒 Secure attachment'
                        : last.content ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: item.disappearingSeconds > 0
                      ? const Icon(Icons.timer_outlined, size: 18)
                      : null,
                  onTap: () => context.pushNamed(
                    AppRoutes.connectChatName,
                    pathParameters: {'conversationId': item.id},
                    extra: item,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _time(DateTime date) {
    final now = DateTime.now();
    if (now.difference(date).inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}';
  }
}
