import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../shared/widgets/app_loading_indicator.dart';
import '../../../constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/api_exception.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../models/response/policy_page_response.dart';
import '../providers/policy_provider.dart';
import '../providers/support_provider.dart';

class PrivacyPolicyPage extends ConsumerWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policyAsync = ref.watch(privacyPolicyProvider);

    return policyAsync.when(
      loading: () => _LoadingInfoPage(title: context.l10n.tr('privacy_policy')),
      error: (error, _) => _ErrorInfoPage(
        title: context.l10n.tr('privacy_policy'),
        message: context.l10n.tr(
          'policy_load_error_detail',
          args: {'error': readableApiError(error)},
        ),
        onRetry: () => ref.invalidate(privacyPolicyProvider),
      ),
      data: (policy) => _InfoPage(
        title: policy.title.isEmpty
            ? context.l10n.tr('privacy_policy')
            : policy.title,
        icon: Icons.privacy_tip_rounded,
        color: AppColors.success,
        sections: policy.sections,
      ),
    );
  }
}

class _LoadingInfoPage extends StatelessWidget {
  const _LoadingInfoPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppPageAppBar(
        title: title,
        onBack: () => context.goNamed(AppRoutes.profileName),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AppLoadingIndicator(color: AppColors.purple, size: 44),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorInfoPage extends StatelessWidget {
  const _ErrorInfoPage({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppPageAppBar(
        title: title,
        onBack: () => context.goNamed(AppRoutes.profileName),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.purple,
                        size: 42,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.l10n.tr('unable_to_load_policy'),
                        style: AppTextStyles.label.copyWith(fontSize: 17),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: onRetry,
                        child: Text(context.l10n.tr('retry')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(aboutContentProvider)
        .when(
          loading: () =>
              _LoadingInfoPage(title: context.l10n.tr('about_vaultone')),
          error: (error, _) => _ErrorInfoPage(
            title: context.l10n.tr('about_vaultone'),
            message: readableApiError(error),
            onRetry: () => ref.invalidate(aboutContentProvider),
          ),
          data: (page) => _InfoPage(
            title: page.title,
            subtitle: page.subtitle,
            icon: Icons.info_rounded,
            color: AppColors.blue,
            sections: page.sections,
          ),
        );
  }
}

class SupportPage extends ConsumerStatefulWidget {
  const SupportPage({super.key});
  @override
  ConsumerState<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends ConsumerState<SupportPage> {
  final _message = TextEditingController();
  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ref
        .watch(helpContentProvider)
        .when(
          loading: () =>
              _LoadingInfoPage(title: context.l10n.tr('help_and_support')),
          error: (error, _) => _ErrorInfoPage(
            title: context.l10n.tr('help_and_support'),
            message: readableApiError(error),
            onRetry: () => ref.invalidate(helpContentProvider),
          ),
          data: (page) => _InfoPage(
            title: page.title,
            subtitle: page.subtitle,
            icon: Icons.help_rounded,
            color: AppColors.cyan,
            sections: page.sections,
            footer: _SupportChat(messageController: _message),
          ),
        );
  }
}

class _SupportChat extends ConsumerWidget {
  const _SupportChat({required this.messageController});
  final TextEditingController messageController;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chat = ref.watch(supportChatProvider);
    final controller = ref.read(supportChatProvider.notifier);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Chat with support',
                  style: AppTextStyles.heading.copyWith(fontSize: 20),
                ),
              ),
              IconButton(
                onPressed: chat.loading ? null : controller.load,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (chat.loading)
            const AppLoadingIndicator(size: 34)
          else if (chat.messages.isEmpty)
            const Text('Send your first message to our support team.')
          else
            ...chat.messages.map(
              (item) => Align(
                alignment: item.fromUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: item.fromUser
                        ? AppColors.blue
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    item.message,
                    style: TextStyle(
                      color: item.fromUser ? Colors.white : null,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: messageController,
                  maxLines: 3,
                  minLines: 1,
                  decoration: const InputDecoration(
                    hintText: 'Type your message...',
                  ),
                ),
              ),
              IconButton.filled(
                onPressed: chat.sending
                    ? null
                    : () async {
                        if (await controller.send(messageController.text)) {
                          messageController.clear();
                        }
                      },
                icon: chat.sending
                    ? const AppLoadingIndicator(size: 22)
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPage extends StatelessWidget {
  const _InfoPage({
    required this.title,
    required this.icon,
    required this.color,
    required this.sections,
    this.subtitle = '',
    this.footer,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<PolicySectionResponse> sections;
  final String subtitle;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppPageAppBar(
        title: title,
        onBack: () => context.goNamed(AppRoutes.profileName),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.heading,
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
            ],
            const SizedBox(height: 18),
            if (sections.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Text(
                  context.l10n.tr('no_policy_data'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body,
                ),
              )
            else
              ...sections.map(
                (section) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.title,
                        style: AppTextStyles.label.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(section.body, style: AppTextStyles.body),
                    ],
                  ),
                ),
              ),
            if (footer != null) ...[const SizedBox(height: 8), footer!],
          ],
        ),
      ),
    );
  }
}
