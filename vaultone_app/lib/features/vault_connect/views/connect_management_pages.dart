import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../files_vault/providers/files_vault_provider.dart';
import '../../media/providers/media_provider.dart';
import '../models/connect_models.dart';
import '../providers/connect_provider.dart';
import '../repositories/connect_repository.dart';
import 'chat_detail_page.dart';

class AttachmentPreviewPage extends ConsumerStatefulWidget {
  const AttachmentPreviewPage({
    super.key,
    required this.conversationId,
    required this.file,
  });
  final String conversationId;
  final PickedConnectFile file;
  @override
  ConsumerState<AttachmentPreviewPage> createState() =>
      _AttachmentPreviewPageState();
}

class _AttachmentPreviewPageState extends ConsumerState<AttachmentPreviewPage> {
  bool sending = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Attachment preview')),
    body: Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.file.kind == 'image'
                        ? Icons.image_rounded
                        : widget.file.kind == 'video'
                        ? Icons.movie_rounded
                        : Icons.description_rounded,
                    size: 88,
                    color: AppColors.purple,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    widget.file.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<int>(
                    future: File(widget.file.path).length(),
                    builder: (_, value) => Text(
                      value.hasData
                          ? _size(value.data!)
                          : 'Reading secure file…',
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'A private transfer copy will be sent. Your original file will not be changed.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: SizedBox(
        height: 52,
        child: FilledButton.icon(
          onPressed: sending
              ? null
              : () async {
                  setState(() => sending = true);
                  await ref
                      .read(vaultConnectProvider.notifier)
                      .sendFile(
                        widget.conversationId,
                        File(widget.file.path),
                        widget.file.kind,
                        widget.file.mime,
                      );
                  if (context.mounted) context.pop();
                },
          icon: sending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_rounded),
          label: const Text('Send securely'),
        ),
      ),
    ),
  );
  String _size(int bytes) => bytes < 1024 * 1024
      ? '${(bytes / 1024).toStringAsFixed(0)} KB'
      : '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
}

class VaultConnectFilePickerPage extends ConsumerWidget {
  const VaultConnectFilePickerPage({super.key, required this.conversationId});
  final String conversationId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref
        .watch(filesVaultProvider)
        .files
        .where((x) => !x.isArchived && x.path != null);
    final media = ref
        .watch(mediaLibraryProvider)
        .items
        .where((x) => !x.isDeleted && x.path != null);
    final picks = <PickedConnectFile>[
      for (final item in files)
        PickedConnectFile(
          path: item.path!,
          name: item.name,
          kind: item.type.name == 'image'
              ? 'image'
              : item.type.name == 'video'
              ? 'video'
              : 'document',
          mime: _mimeFor(item.name),
        ),
      for (final item in media)
        PickedConnectFile(
          path: item.path!,
          name: item.title,
          kind: item.kind.name == 'photo' ? 'image' : 'video',
          mime: _mimeFor(item.title),
        ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Send from Vault')),
      body: picks.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No locally available Vault files found.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              itemCount: picks.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, index) {
                final item = picks[index];
                return ListTile(
                  leading: Icon(
                    item.kind == 'image'
                        ? Icons.image
                        : item.kind == 'video'
                        ? Icons.movie
                        : Icons.description,
                    color: AppColors.purple,
                  ),
                  title: Text(item.name),
                  subtitle: Text('Private ${item.kind}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.pushReplacementNamed(
                    AppRoutes.connectPreviewName,
                    pathParameters: {'conversationId': conversationId},
                    extra: item,
                  ),
                );
              },
            ),
    );
  }

  String _mimeFor(String name) {
    final ext = name.split('.').last.toLowerCase();
    if (['jpg', 'jpeg'].contains(ext)) return 'image/jpeg';
    if (ext == 'png') return 'image/png';
    if (['mp4', 'mov', 'm4v'].contains(ext)) return 'video/mp4';
    if (ext == 'pdf') return 'application/pdf';
    if (ext == 'zip') return 'application/zip';
    return 'application/octet-stream';
  }
}

class SharedMediaDocumentsPage extends ConsumerWidget {
  const SharedMediaDocumentsPage({super.key, required this.conversationId});
  final String conversationId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages =
        ref.watch(vaultConnectProvider).messages[conversationId] ?? const [];
    final attachments = messages.expand((x) => x.attachments).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Shared media & documents')),
      body: attachments.isEmpty
          ? const Center(child: Text('No shared files'))
          : ListView.builder(
              itemCount: attachments.length,
              itemBuilder: (_, index) {
                final item = attachments[index];
                return ListTile(
                  leading: Icon(
                    item.fileType == 'image'
                        ? Icons.image
                        : item.fileType == 'video'
                        ? Icons.movie
                        : Icons.description,
                  ),
                  title: Text(item.fileName),
                  subtitle: Text(_size(item.fileSize)),
                  onTap: () => ref
                      .read(vaultConnectProvider.notifier)
                      .openSecurely(item),
                );
              },
            ),
    );
  }

  String _size(int bytes) => bytes < 1024 * 1024
      ? '${(bytes / 1024).toStringAsFixed(0)} KB'
      : '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
}

class ChatSettingsPage extends ConsumerWidget {
  const ChatSettingsPage({super.key, required this.conversation});
  final ConnectConversation conversation;
  static const options = {
    0: 'Off',
    3600: '1 hour',
    86400: '24 hours',
    604800: '7 days',
    2592000: '30 days',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(vaultConnectProvider).conversations;
    final current = conversations
        .where((item) => item.id == conversation.id)
        .firstOrNull;
    final item = current ?? conversation;
    return Scaffold(
      appBar: AppBar(title: const Text('Chat settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Disappearing messages'),
            subtitle: Text(options[item.disappearingSeconds] ?? 'Off'),
            onTap: () async {
              final selected = await showModalBottomSheet<int>(
                context: context,
                builder: (_) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final option in options.entries)
                        RadioListTile<int>(
                          value: option.key,
                          groupValue: item.disappearingSeconds,
                          title: Text(option.value),
                          onChanged: (value) => Navigator.pop(context, value),
                        ),
                    ],
                  ),
                ),
              );
              if (selected != null) {
                await ref
                    .read(vaultConnectProvider.notifier)
                    .setDisappearing(item.id, selected);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.perm_media_outlined),
            title: const Text('Shared media & documents'),
            onTap: () => context.pushNamed(
              AppRoutes.connectSharedName,
              pathParameters: {'conversationId': item.id},
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined),
            title: const Text('Clear conversation'),
            subtitle: const Text('Clears history only for you'),
            onTap: () async {
              final yes = await _confirm(context, 'Clear this conversation?');
              if (yes) {
                await ref
                    .read(vaultConnectProvider.notifier)
                    .clearConversation(item.id);
              }
            },
          ),
          ListTile(
            leading: Icon(
              item.blockedByMe ? Icons.lock_open_rounded : Icons.block,
              color: Colors.red,
            ),
            title: Text(item.blockedByMe ? 'Unblock user' : 'Block user'),
            subtitle: item.isBlocked && !item.blockedByMe
                ? const Text('This user has blocked messaging')
                : null,
            enabled: !item.isBlocked || item.blockedByMe,
            onTap: () async {
              final yes = await _confirm(
                context,
                item.blockedByMe
                    ? 'Unblock ${item.participant.displayName}?'
                    : 'Block ${item.participant.displayName}?',
              );
              if (yes) {
                final controller = ref.read(vaultConnectProvider.notifier);
                if (item.blockedByMe) {
                  await controller.unblock(item);
                } else {
                  await controller.block(item);
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.flag_outlined, color: Colors.red),
            title: const Text('Report user'),
            onTap: () =>
                context.pushNamed(AppRoutes.connectReportName, extra: item),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirm(BuildContext context, String title) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      ) ??
      false;
}

class BlockedUsersPage extends ConsumerStatefulWidget {
  const BlockedUsersPage({super.key});
  @override
  ConsumerState<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends ConsumerState<BlockedUsersPage> {
  late Future<List<Map<String, dynamic>>> future;
  final Set<int> unblocking = <int>{};
  @override
  void initState() {
    super.initState();
    future = ref.read(connectRepositoryProvider).blockedUsers();
  }

  void refresh() => setState(
    () => future = ref.read(connectRepositoryProvider).blockedUsers(),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Blocked users')),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (_, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }
        final rows = snapshot.data ?? const [];
        if (rows.isEmpty) return const Center(child: Text('No blocked users'));
        return ListView.builder(
          itemCount: rows.length,
          itemBuilder: (_, index) {
            final user = Map<String, dynamic>.from(rows[index]['user'] as Map);
            return ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.person_off_outlined),
              ),
              title: Text(user['full_name']?.toString() ?? 'VaultOne user'),
              subtitle: Text(user['phone']?.toString() ?? ''),
              trailing: TextButton(
                onPressed: unblocking.contains((user['id'] as num).toInt())
                    ? null
                    : () => _unblock((user['id'] as num).toInt()),
                child: unblocking.contains((user['id'] as num).toInt())
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Unblock'),
              ),
            );
          },
        );
      },
    ),
  );

  Future<void> _unblock(int userId) async {
    setState(() => unblocking.add(userId));
    try {
      await ref.read(connectRepositoryProvider).unblock(userId);
      ref.invalidate(vaultConnectProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User unblocked successfully')),
      );
      refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not unblock user: $error')));
    } finally {
      if (mounted) setState(() => unblocking.remove(userId));
    }
  }
}

class ReportUserPage extends ConsumerStatefulWidget {
  const ReportUserPage({super.key, required this.conversation});
  final ConnectConversation conversation;
  @override
  ConsumerState<ReportUserPage> createState() => _ReportUserPageState();
}

class _ReportUserPageState extends ConsumerState<ReportUserPage> {
  String category = 'spam';
  final description = TextEditingController();
  bool submitting = false;
  static const categories = {
    'spam': 'Spam',
    'harassment': 'Harassment',
    'abusive_content': 'Abusive content',
    'fraud_or_scam': 'Fraud or scam',
    'illegal_content': 'Illegal content',
    'privacy_violation': 'Privacy violation',
    'other': 'Other',
  };
  @override
  void dispose() {
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Report user')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Only the evidence you explicitly select is submitted. Admins cannot browse your private conversation.',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 18),
        DropdownButtonFormField<String>(
          initialValue: category,
          decoration: const InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final x in categories.entries)
              DropdownMenuItem(value: x.key, child: Text(x.value)),
          ],
          onChanged: (value) => setState(() => category = value ?? category),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: description,
          minLines: 4,
          maxLines: 8,
          maxLength: 4000,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: submitting
              ? null
              : () async {
                  setState(() => submitting = true);
                  try {
                    await ref
                        .read(vaultConnectProvider.notifier)
                        .report(
                          widget.conversation,
                          category,
                          description.text,
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Report submitted')),
                      );
                      context.pop();
                    }
                  } finally {
                    if (mounted) setState(() => submitting = false);
                  }
                },
          icon: const Icon(Icons.flag_outlined),
          label: const Text('Submit report'),
        ),
      ],
    ),
  );
}
