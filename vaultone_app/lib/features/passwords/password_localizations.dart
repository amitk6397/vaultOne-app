import 'package:flutter/widgets.dart';

import '../../core/localization/app_localizations.dart';
import 'models/password_entry.dart';

String localizedPasswordCategory(
  BuildContext context,
  PasswordCategory category,
) => context.l10n.tr('password_category_${category.name}');

String localizedPasswordCategoryName(BuildContext context, String name) {
  if (name == 'All') return context.l10n.tr('all');
  final category = PasswordCategory.values.firstWhere(
    (item) => item.name.toLowerCase() == name.toLowerCase(),
    orElse: () => PasswordCategory.other,
  );
  return localizedPasswordCategory(context, category);
}

String localizedPasswordStrength(BuildContext context, int score) {
  final key = switch (score) {
    0 || 1 => 'strength_weak',
    2 => 'strength_fair',
    3 => 'strength_good',
    _ => 'strength_strong',
  };
  return context.l10n.tr(key);
}
