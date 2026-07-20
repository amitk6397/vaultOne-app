import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../models/connect_models.dart';
import '../providers/connect_provider.dart';

class PickedConnectFile {
  const PickedConnectFile({
    required this.path,
    required this.name,
    required this.kind,
    required this.mime,
  });
  final String path;
  final String name;
  final String kind;
  final String mime;
}

class ChatDetailPage extends ConsumerStatefulWidget {
  const ChatDetailPage({super.key, required this.conversation});
  final ConnectConversation conversation;
  @override
  ConsumerState<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends ConsumerState<ChatDetailPage> {
  final composer = TextEditingController();
  final scroll = ScrollController();
  Timer? typingTimer;
  int currentUserId = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      currentUserId =
          (await SharedPreferences.getInstance()).getInt('user_id') ?? 0;
      await ref
          .read(vaultConnectProvider.notifier)
          .openConversation(widget.conversation.id);
      if (mounted) setState(() {});
    });
    scroll.addListener(_paginate);
  }

  @override
  void dispose() {
    typingTimer?.cancel();
    ref
        .read(vaultConnectProvider.notifier)
        .leaveConversation(widget.conversation.id);
    composer.dispose();
    scroll.dispose();
    super.dispose();
  }

  void _paginate() {
    if (scroll.hasClients &&
        scroll.position.pixels >= scroll.position.maxScrollExtent - 120) {
      ref
          .read(vaultConnectProvider.notifier)
          .loadMessages(widget.conversation.id, more: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vaultConnectProvider);
    final messages = state.messages[widget.conversation.id] ?? const [];
    final currentConversation = state.conversations
        .where((item) => item.id == widget.conversation.id)
        .firstOrNull;
    final conversation = currentConversation ?? widget.conversation;
    final blocked = conversation.isBlocked;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            child: Text(
              widget.conversation.participant.displayName[0].toUpperCase(),
            ),
          ),
          title: Text(
            widget.conversation.participant.displayName,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            state.typingConversations.contains(widget.conversation.id)
                ? 'typing…'
                : 'Private chat',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        actions: [
          if (conversation.disappearingSeconds > 0)
            const Icon(Icons.timer_outlined, size: 19),
          IconButton(
            onPressed: () async {
              final refreshed = await ref
                  .read(vaultConnectProvider.notifier)
                  .refreshConversation(widget.conversation.id);
              if (!context.mounted) return;
              context.pushNamed(
                AppRoutes.connectSettingsName,
                pathParameters: {'conversationId': widget.conversation.id},
                extra: refreshed ?? widget.conversation,
              );
            },
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          if (conversation.disappearingSeconds > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(7),
              color: AppColors.purple.withValues(alpha: .08),
              child: const Text(
                'New messages disappear automatically',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ),
          Expanded(
            child: state.isLoading && messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                ? const _EmptyChat()
                : ListView.builder(
                    controller: scroll,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (_, index) {
                      final message = messages[index];
                      final next = index + 1 < messages.length
                          ? messages[index + 1]
                          : null;
                      final showDate =
                          next == null ||
                          !_sameDay(message.createdAt, next.createdAt);
                      return Column(
                        children: [
                          if (showDate) _DateSeparator(message.createdAt),
                          _MessageBubble(
                            message: message,
                            mine: message.senderUserId == currentUserId,
                            onRetry: () => ref
                                .read(vaultConnectProvider.notifier)
                                .retry(message),
                            onDelete: () => _delete(message),
                            onAttachment: _attachmentActions,
                          ),
                        ],
                      );
                    },
                  ),
          ),
          if (state.uploadProgress.isNotEmpty)
            LinearProgressIndicator(value: state.uploadProgress.values.last),
          if (blocked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Text(
                'You cannot send messages in this blocked conversation.',
                textAlign: TextAlign.center,
              ),
            )
          else
            _Composer(
              controller: composer,
              onChanged: (_) {
                ref
                    .read(vaultConnectProvider.notifier)
                    .typing(widget.conversation.id, true);
                typingTimer?.cancel();
                typingTimer = Timer(
                  const Duration(seconds: 2),
                  () => ref
                      .read(vaultConnectProvider.notifier)
                      .typing(widget.conversation.id, false),
                );
              },
              onAttach: _attachments,
              onSend: () {
                final text = composer.text;
                composer.clear();
                ref
                    .read(vaultConnectProvider.notifier)
                    .typing(widget.conversation.id, false);
                ref
                    .read(vaultConnectProvider.notifier)
                    .sendText(widget.conversation.id, text);
              },
            ),
        ],
      ),
    );
  }

  Future<void> _attachments() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => const AttachmentSourceBottomSheet(),
    );
    if (source == null || !mounted) return;
    if (source == 'vault') {
      context.pushNamed(
        AppRoutes.connectVaultPickerName,
        pathParameters: {'conversationId': widget.conversation.id},
      );
      return;
    }
    XFile? image;
    FilePickerResult? result;
    if (source == 'gallery') {
      image = await ImagePicker().pickImage(source: ImageSource.gallery);
    }
    if (source == 'camera') {
      image = await ImagePicker().pickImage(source: ImageSource.camera);
    }
    if (source == 'video') {
      image = await ImagePicker().pickVideo(source: ImageSource.gallery);
    }
    if (source == 'document') {
      result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const [
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'ppt',
          'pptx',
          'txt',
          'csv',
          'zip',
        ],
      );
    }
    final path = image?.path ?? result?.files.single.path;
    if (path == null || !mounted) return;
    final name = image?.name ?? result!.files.single.name;
    final kind = source == 'video'
        ? 'video'
        : source == 'document'
        ? 'document'
        : 'image';
    final picked = PickedConnectFile(
      path: path,
      name: name,
      kind: kind,
      mime: _mime(name, kind),
    );
    final mode = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.send_outlined),
              title: const Text('Send only'),
              onTap: () => Navigator.pop(context, 'send'),
            ),
            ListTile(
              leading: const Icon(Icons.lock_rounded),
              title: const Text('Save to Vault and send'),
              subtitle: const Text('A Vault copy is saved before transfer'),
              onTap: () => Navigator.pop(context, 'save_and_send'),
            ),
          ],
        ),
      ),
    );
    if (mode == null || !mounted) return;
    if (mode == 'save_and_send') {
      final authenticated = await LocalAuthentication().authenticate(
        localizedReason: 'Authenticate to save this file in your Vault',
        options: const AuthenticationOptions(stickyAuth: true),
      );
      if (!authenticated) return;
      await ref
          .read(vaultConnectProvider.notifier)
          .saveDeviceFileToVault(
            path: picked.path,
            fileName: picked.name,
            kind: picked.kind,
          );
    }
    if (!mounted) return;
    context.pushNamed(
      AppRoutes.connectPreviewName,
      pathParameters: {'conversationId': widget.conversation.id},
      extra: picked,
    );
  }

  Future<void> _delete(ConnectMessage message) async {
    final choice = await showModalBottomSheet<bool>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_remove_outlined),
              title: const Text('Delete for me'),
              onTap: () => Navigator.pop(context, false),
            ),
            if (message.senderUserId == currentUserId)
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Delete for everyone'),
                subtitle: const Text('Available for 24 hours'),
                onTap: () => Navigator.pop(context, true),
              ),
          ],
        ),
      ),
    );
    if (choice != null) {
      await ref
          .read(vaultConnectProvider.notifier)
          .deleteMessage(message, everyone: choice);
    }
  }

  Future<void> _attachmentActions(ConnectAttachment item) async {
    if (item.localPath != null) {
      if (item.fileType == 'image') {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => Dialog(
            child: InteractiveViewer(
              child: Image.file(File(item.localPath!), fit: BoxFit.contain),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              item.uploadStatus == 'uploading'
                  ? 'Upload in progress…'
                  : 'Upload failed. Tap the error icon to retry.',
            ),
          ),
        );
      }
      return;
    }
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('Open securely'),
              onTap: () => Navigator.pop(context, 'open'),
            ),
            ListTile(
              leading: const Icon(Icons.lock_rounded),
              title: const Text('Save to My Vault'),
              onTap: () => Navigator.pop(context, 'vault'),
            ),
            ListTile(
              leading: const Icon(Icons.save_alt_rounded),
              title: const Text('Export to device'),
              onTap: () => Navigator.pop(context, 'export'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    try {
      if (action == 'open') {
        if (item.fileType == 'image') {
          final path = await ref
              .read(vaultConnectProvider.notifier)
              .download(item);
          if (!mounted) return;
          await showDialog<void>(
            context: context,
            builder: (dialogContext) => Dialog.fullscreen(
              child: Scaffold(
                backgroundColor: Colors.black,
                appBar: AppBar(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  title: Text(item.fileName),
                  leading: IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ),
                body: Center(
                  child: InteractiveViewer(
                    minScale: .5,
                    maxScale: 5,
                    child: Image.file(File(path), fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          );
        } else {
          await ref.read(vaultConnectProvider.notifier).openSecurely(item);
        }
      }
      if (action == 'export') {
        await ref.read(vaultConnectProvider.notifier).exportToDevice(item);
      }
      if (action == 'vault') {
        final allowed = await LocalAuthentication().authenticate(
          localizedReason: 'Authenticate to save this file in your Vault',
          options: const AuthenticationOptions(stickyAuth: true),
        );
        if (!allowed) return;
        final saved = await ref
            .read(vaultConnectProvider.notifier)
            .saveToVault(item);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                saved
                    ? 'Saved securely to your Vault'
                    : 'This file is already saved in your Vault',
              ),
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.onAttach,
    required this.onChanged,
  });
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onAttach,
            icon: const Icon(Icons.add_circle_outline),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Secure message',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          IconButton.filled(
            onPressed: onSend,
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    ),
  );
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline_rounded, size: 46, color: AppColors.purple),
          SizedBox(height: 12),
          Text(
            'Private conversation',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
          ),
          SizedBox(height: 7),
          Text(
            'Messages and secure files are visible only to conversation members.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator(this.date);
  final DateTime date;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Chip(
      label: Text(
        '${date.day}/${date.month}/${date.year}',
        style: const TextStyle(fontSize: 11),
      ),
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.mine,
    required this.onRetry,
    required this.onDelete,
    required this.onAttachment,
  });
  final ConnectMessage message;
  final bool mine;
  final VoidCallback onRetry;
  final VoidCallback onDelete;
  final ValueChanged<ConnectAttachment> onAttachment;

  @override
  Widget build(BuildContext context) {
    final deleted =
        message.status == ConnectMessageStatus.deleted ||
        message.status == ConnectMessageStatus.expired;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onDelete,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 310),
          margin: const EdgeInsets.only(bottom: 5),
          padding: const EdgeInsets.fromLTRB(12, 9, 9, 6),
          decoration: BoxDecoration(
            color: mine
                ? AppColors.purple
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(17),
              topRight: const Radius.circular(17),
              bottomLeft: Radius.circular(mine ? 17 : 4),
              bottomRight: Radius.circular(mine ? 4 : 17),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (deleted)
                Text(
                  message.status == ConnectMessageStatus.expired
                      ? 'This message expired'
                      : 'This message was deleted',
                  style: TextStyle(
                    color: mine ? Colors.white70 : null,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else ...[
                if (message.content?.isNotEmpty == true)
                  Text(
                    message.content!,
                    style: TextStyle(
                      color: mine ? Colors.white : null,
                      fontSize: 15,
                    ),
                  ),
                for (final attachment in message.attachments)
                  InkWell(
                    onTap: () => onAttachment(attachment),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            attachment.fileType == 'image' &&
                                    attachment.localPath != null
                                ? Icons.check_circle_outline
                                : attachment.fileType == 'image'
                                ? Icons.image
                                : attachment.fileType == 'video'
                                ? Icons.movie
                                : Icons.description,
                            color: mine ? Colors.white : AppColors.purple,
                          ),
                          const SizedBox(width: 8),
                          if (attachment.fileType == 'image' &&
                              attachment.localPath != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(attachment.localPath!),
                                width: 54,
                                height: 54,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              attachment.fileName,
                              style: TextStyle(
                                color: mine ? Colors.white : null,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Icon(
                            Icons.lock,
                            size: 14,
                            color: mine ? Colors.white70 : AppColors.purple,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 10,
                      color: mine
                          ? Colors.white70
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (mine) ...[
                    const SizedBox(width: 4),
                    _StatusIcon(message.status, onRetry),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon(this.status, this.retry);
  final ConnectMessageStatus status;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) {
    if (status == ConnectMessageStatus.failed) {
      return InkWell(
        onTap: retry,
        child: const Icon(Icons.error_outline, size: 16, color: Colors.orange),
      );
    }
    if (status == ConnectMessageStatus.pending ||
        status == ConnectMessageStatus.uploading) {
      return const SizedBox(
        width: 13,
        height: 13,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: Colors.white70,
        ),
      );
    }
    return Icon(
      status == ConnectMessageStatus.read
          ? Icons.done_all
          : status == ConnectMessageStatus.delivered
          ? Icons.done_all
          : Icons.done,
      size: 16,
      color: status == ConnectMessageStatus.read
          ? Colors.lightBlueAccent
          : Colors.white70,
    );
  }
}

class AttachmentSourceBottomSheet extends StatelessWidget {
  const AttachmentSourceBottomSheet({super.key});
  @override
  Widget build(BuildContext context) {
    const values = [
      ('vault', Icons.lock_rounded, 'Send from Vault'),
      ('gallery', Icons.photo_library_outlined, 'Gallery'),
      ('video', Icons.video_library_outlined, 'Video'),
      ('document', Icons.description_outlined, 'Document'),
      ('camera', Icons.camera_alt_outlined, 'Camera'),
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share securely',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final value in values)
                  SizedBox(
                    width: 96,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.pop(context, value.$1),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            CircleAvatar(child: Icon(value.$2)),
                            const SizedBox(height: 7),
                            Text(
                              value.$3,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _mime(String name, String kind) {
  final extension = name.split('.').last.toLowerCase();
  if (kind == 'image') {
    return extension == 'png'
        ? 'image/png'
        : extension == 'webp'
        ? 'image/webp'
        : 'image/jpeg';
  }
  if (kind == 'video') return extension == 'webm' ? 'video/webm' : 'video/mp4';
  return extension == 'pdf'
      ? 'application/pdf'
      : extension == 'zip'
      ? 'application/zip'
      : 'application/octet-stream';
}
