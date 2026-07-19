import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../shared/widgets/app_loading_indicator.dart';
import '../../notifications/models/app_notification.dart';
import '../../notifications/providers/notification_provider.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);
    final controller = ref.read(notificationProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: AppTextStyles.heading.copyWith(fontSize: 23),
        ),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: state.processing ? null : controller.markAllAsRead,
              child: const Text('Read all'),
            ),
          if (state.items.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value != 'delete_all') return;
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete all notifications?'),
                    content: const Text('This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => context.pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => context.pop(true),
                        child: const Text('Delete all'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) await controller.deleteAll();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'delete_all', child: Text('Delete all')),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: _NotificationBody(state: state, controller: controller),
      ),
    );
  }
}

class _NotificationBody extends StatelessWidget {
  const _NotificationBody({required this.state, required this.controller});

  final NotificationState state;
  final NotificationController controller;

  @override
  Widget build(BuildContext context) {
    if (state.loading && state.items.isEmpty) {
      return const AppLoadingView();
    }
    if (state.error != null && state.items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 160),
          Icon(
            Icons.cloud_off_rounded,
            size: 52,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(state.error!, textAlign: TextAlign.center),
          Center(
            child: TextButton(
              onPressed: controller.load,
              child: const Text('Try again'),
            ),
          ),
        ],
      );
    }
    if (state.items.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 170),
          Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text('No notifications yet', textAlign: TextAlign.center),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      itemCount: state.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 9),
      itemBuilder: (context, index) {
        final item = state.items[index];
        return Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 22),
            decoration: BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_rounded, color: Colors.white),
          ),
          confirmDismiss: (_) => controller.delete(item.id),
          child: _NotificationTile(
            item: item,
            onTap: () async {
              await controller.markAsRead(item.id);
              if (context.mounted && item.route?.startsWith('/') == true) {
                context.push(item.route!);
              }
            },
          ),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      tileColor: item.isRead
          ? colors.surface
          : colors.primaryContainer.withValues(alpha: .42),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: CircleAvatar(
        backgroundColor: colors.primary.withValues(alpha: .12),
        child: Icon(_eventIcon(item.eventType), color: colors.primary),
      ),
      title: Text(
        item.title,
        style: AppTextStyles.label.copyWith(
          fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w900,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(item.body),
          const SizedBox(height: 6),
          Text(
            _formatDate(item.createdAt),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
      trailing: item.isRead
          ? null
          : Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
            ),
    );
  }

  IconData _eventIcon(String event) {
    if (event.contains('subscription')) return Icons.workspace_premium_rounded;
    if (event.contains('payment')) return Icons.payments_rounded;
    return Icons.notifications_rounded;
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day}/${local.month}/${local.year} ${local.hour}:$minute';
  }
}
