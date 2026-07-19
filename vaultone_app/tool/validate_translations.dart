import 'dart:io';

import 'package:vaultone_app/core/localization/translations/ar.dart';
import 'package:vaultone_app/core/localization/translations/bn.dart';
import 'package:vaultone_app/core/localization/translations/en.dart';
import 'package:vaultone_app/core/localization/translations/es.dart';
import 'package:vaultone_app/core/localization/translations/fr.dart';
import 'package:vaultone_app/core/localization/translations/gu.dart';
import 'package:vaultone_app/core/localization/translations/mr.dart';
import 'package:vaultone_app/core/localization/translations/ta.dart';
import 'package:vaultone_app/core/localization/translations/te.dart';

void main() {
  final translations = <String, Map<String, String>>{
    'bn': bengaliTranslations,
    'mr': marathiTranslations,
    'ta': tamilTranslations,
    'te': teluguTranslations,
    'gu': gujaratiTranslations,
    'es': spanishTranslations,
    'fr': frenchTranslations,
    'ar': arabicTranslations,
  };
  var hasError = false;
  for (final language in translations.entries) {
    final missing = englishTranslations.keys.toSet().difference(
      language.value.keys.toSet(),
    );
    final extra = language.value.keys.toSet().difference(
      englishTranslations.keys.toSet(),
    );
    var placeholderErrors = 0;
    for (final source in englishTranslations.entries) {
      final translated = language.value[source.key];
      if (translated == null) continue;
      if (_placeholders(source.value) != _placeholders(translated)) {
        placeholderErrors++;
      }
    }
    stdout.writeln(
      '${language.key}: ${language.value.length} keys, '
      '${missing.length} missing, ${extra.length} extra, '
      '$placeholderErrors placeholder errors',
    );
    hasError |= missing.isNotEmpty || extra.isNotEmpty || placeholderErrors > 0;
  }
  if (hasError) throw StateError('Translation validation failed.');
}

String _placeholders(String value) {
  final matches = RegExp(r'\{[^}]+\}')
      .allMatches(value)
      .map((match) => match.group(0)!)
      .toList()
    ..sort();
  return matches.join('|');
}
