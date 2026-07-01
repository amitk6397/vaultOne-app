import 'package:flutter_riverpod/legacy.dart';

import '../models/vault_file.dart';

final vaultFilesProvider = StateProvider<List<VaultFile>>((ref) {
  final now = DateTime.now();
  return [
    VaultFile(
      id: 'sample-1',
      name: 'Home Insurance.pdf',
      extension: 'pdf',
      sizeLabel: '2.4 MB',
      type: VaultFileType.pdf,
      addedAt: now.subtract(const Duration(days: 2)),
      tags: const ['Insurance', 'Home'],
    ),
    VaultFile(
      id: 'sample-2',
      name: 'Passport Scan.jpg',
      extension: 'jpg',
      sizeLabel: '1.1 MB',
      type: VaultFileType.image,
      addedAt: now.subtract(const Duration(days: 5)),
      tags: const ['ID', 'Travel'],
    ),
    VaultFile(
      id: 'sample-3',
      name: 'Tax Sheet.xlsx',
      extension: 'xlsx',
      sizeLabel: '720 KB',
      type: VaultFileType.document,
      addedAt: now.subtract(const Duration(days: 8)),
      tags: const ['Finance'],
    ),
  ];
});

final filesVaultGridProvider = StateProvider<bool>((ref) => true);
final filesVaultSearchProvider = StateProvider<String>((ref) => '');
final filesVaultTagProvider = StateProvider<String>((ref) => 'All');
