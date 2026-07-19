import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/media_provider.dart';
import '../widgets/media_widgets.dart';

class DeletedMediaPage extends ConsumerWidget {
  const DeletedMediaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final controller = ref.read(mediaLibraryProvider.notifier);
    final deleted = controller.visibleItems(includeDeleted: true);

    return MediaPageShell(
      title: context.l10n.tr('deleted_media'),
      subtitle: context.l10n.tr('deleted_media_description'),
      icon: Icons.restore_from_trash_rounded,
      children: [
        if (deleted.isEmpty)
          MediaEmptyState(
            title: context.l10n.tr('trash_empty'),
            subtitle: context.l10n.tr('trash_empty_description'),
          )
        else
          for (final item in deleted) ...[
            ListTile(
              tileColor: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colors.outlineVariant),
              ),
              leading: SizedBox(
                width: 58,
                height: 58,
                child: MediaThumbnail(item: item),
              ),
              title: Text(item.title),
              subtitle: Text(
                '${context.l10n.tr(item.kind.name)} • ${item.sizeLabel}',
              ),
              trailing: Wrap(
                spacing: 6,
                children: [
                  TextButton(
                    onPressed: () async {
                      await controller.permanentlyDeleteItem(item.id);
                    },
                    child: Text(context.l10n.tr('delete')),
                  ),
                  FilledButton(
                    onPressed: () => controller.restoreItem(item.id),
                    child: Text(context.l10n.tr('restore')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}
