import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/module_storage_controller.dart';

Future<ModuleStorageTarget?> chooseModuleStorage(
  BuildContext context,
  WidgetRef ref,
  StorageModule module, {
  bool force = false,
}) async {
  final current = ref.read(moduleStorageProvider).targetFor(module);
  if (!force && current != null) return current;
  final selected = await showModalBottomSheet<ModuleStorageTarget>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose storage',
              style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text('Where should ${moduleLabel(module)} be saved?'),
            const SizedBox(height: 16),
            _StorageChoice(
              icon: Icons.phone_android_rounded,
              title: 'On this device',
              subtitle: 'Available offline and stored only on this device',
              selected: current == ModuleStorageTarget.local,
              onTap: () => Navigator.pop(
                sheetContext,
                ModuleStorageTarget.local,
              ),
            ),
            const SizedBox(height: 10),
            _StorageChoice(
              icon: Icons.cloud_done_rounded,
              title: 'Vault database',
              subtitle: 'Securely sync with your VaultOne account',
              selected: current == ModuleStorageTarget.database,
              onTap: () => Navigator.pop(
                sheetContext,
                ModuleStorageTarget.database,
              ),
            ),
          ],
        ),
      ),
    ),
  );
  if (selected != null) {
    await ref.read(moduleStorageProvider.notifier).setTarget(module, selected);
  }
  return selected;
}

String moduleLabel(StorageModule module) => switch (module) {
  StorageModule.videos => 'Private videos',
  StorageModule.photos => 'Private photos',
  StorageModule.digiLocker => 'Digi Locker documents',
  StorageModule.fileVault => 'File Vault files',
};

class _StorageChoice extends StatelessWidget {
  const _StorageChoice({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outlineVariant,
      ),
    ),
    leading: Icon(icon),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
    subtitle: Text(subtitle),
    trailing: selected
        ? Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary)
        : null,
  );
}
