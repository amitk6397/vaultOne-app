import 'package:flutter/widgets.dart';

import '../../core/localization/app_localizations.dart';

String localizedMediaCollectionName(BuildContext context, String name) {
  final key = switch (name.trim().toLowerCase()) {
    'private photos' => 'private_photos',
    'private videos' => 'private_videos',
    'private vault' => 'private_vault',
    _ => null,
  };
  return key == null ? name : context.l10n.tr(key);
}
