import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_language_controller.dart';
import '../../core/localization/app_localizations.dart';

Future<void> showLanguageSelectorSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final selected = await showModalBottomSheet<AppLanguage>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (sheetContext) => const LanguageSelectorSheet(),
  );
  if (selected == null) return;
  await ref.read(appLanguageProvider.notifier).select(selected);
}

class LanguageSelectorSheet extends ConsumerWidget {
  const LanguageSelectorSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(appLanguageProvider);
    final navigationInset = MediaQuery.viewPaddingOf(context).bottom;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .72,
      child: Padding(
        padding: EdgeInsets.only(bottom: navigationInset + 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: Text(
                context.l10n.tr('select_language'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                itemCount: AppLanguage.values.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final language = AppLanguage.values[index];
                  return _LanguageOption(
                    language: language,
                    label: language.nativeName,
                    subtitle: language.englishName,
                    selected: selected == language,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.language,
    required this.label,
    required this.subtitle,
    required this.selected,
  });

  final AppLanguage language;
  final String label;
  final String subtitle;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => Navigator.pop(context, language),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      leading: const Icon(Icons.translate_rounded),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: label == subtitle ? null : Text(subtitle),
      trailing: selected
          ? Icon(
              Icons.check_circle_rounded,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
    );
  }
}
