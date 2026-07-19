import 'package:flutter/widgets.dart';

import '../../core/localization/app_localizations.dart';
import 'models/vault_file.dart';

String localizedVaultFileType(BuildContext context, VaultFileType type) {
  return context.l10n.tr('vault_file_type_${type.name}');
}

String localizedVaultFileSize(BuildContext context, VaultFile file) {
  return file.sizeBytes <= 0 ? context.l10n.tr('unknown_size') : file.sizeLabel;
}
