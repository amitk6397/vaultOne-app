import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'translations/en.dart';
import 'translations/hi.dart';
import 'translations/ar.dart';
import 'translations/bn.dart';
import 'translations/es.dart';
import 'translations/fr.dart';
import 'translations/gu.dart';
import 'translations/mr.dart';
import 'translations/ta.dart';
import 'translations/te.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('bn'),
    Locale('mr'),
    Locale('ta'),
    Locale('te'),
    Locale('gu'),
    Locale('es'),
    Locale('fr'),
    Locale('ar'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String tr(String key, {Map<String, Object>? args}) {
    final localized = switch (locale.languageCode) {
      'hi' => hindiTranslations[key],
      'bn' => bengaliTranslations[key],
      'mr' => marathiTranslations[key],
      'ta' => tamilTranslations[key],
      'te' => teluguTranslations[key],
      'gu' => gujaratiTranslations[key],
      'es' => spanishTranslations[key],
      'fr' => frenchTranslations[key],
      'ar' => arabicTranslations[key],
      _ => englishTranslations[key],
    };
    var value = localized ?? englishTranslations[key] ?? key;
    args?.forEach((name, replacement) {
      value = value.replaceAll('{$name}', replacement.toString());
    });
    return value;
  }
}

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.any(
        (supported) => supported.languageCode == locale.languageCode,
      );

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
