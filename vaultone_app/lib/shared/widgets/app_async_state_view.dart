import 'package:flutter/material.dart';

import 'app_loading_indicator.dart';

class AppAsyncStateView extends StatelessWidget {
  const AppAsyncStateView({
    super.key,
    required this.loading,
    required this.isEmpty,
    required this.child,
    this.error,
    this.onRetry,
    this.emptyTitle = 'Nothing here yet',
    this.emptyIcon = Icons.inbox_outlined,
  });

  final bool loading;
  final bool isEmpty;
  final String? error;
  final VoidCallback? onRetry;
  final String emptyTitle;
  final IconData emptyIcon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (loading && isEmpty) return const AppLoadingView();
    if (error != null && isEmpty) {
      return _StateMessage(
        icon: Icons.cloud_off_rounded,
        message: error!,
        actionLabel: onRetry == null ? null : 'Try again',
        onAction: onRetry,
      );
    }
    if (isEmpty) return _StateMessage(icon: emptyIcon, message: emptyTitle);
    return child;
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onAction != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
