import 'dart:convert';
import 'dart:io';

import 'package:vaultone_app/core/localization/translations/en.dart';

const targets = <String, String>{
  'bengaliTranslations': 'bn',
  'marathiTranslations': 'mr',
  'tamilTranslations': 'ta',
  'teluguTranslations': 'te',
  'gujaratiTranslations': 'gu',
  'spanishTranslations': 'es',
  'frenchTranslations': 'fr',
  'arabicTranslations': 'ar',
};

const targetFiles = <String, String>{
  'bengaliTranslations': 'bn.dart',
  'marathiTranslations': 'mr.dart',
  'tamilTranslations': 'ta.dart',
  'teluguTranslations': 'te.dart',
  'gujaratiTranslations': 'gu.dart',
  'spanishTranslations': 'es.dart',
  'frenchTranslations': 'fr.dart',
  'arabicTranslations': 'ar.dart',
};

const delimiter = '\nZXSPLITVAULTONEXZ\n';

Future<void> main() async {
  final results = await Future.wait(
    targets.entries.map(_translateLanguage),
  );
  for (var targetIndex = 0; targetIndex < targets.length; targetIndex++) {
    final target = targets.entries.elementAt(targetIndex);
    final translated = results[targetIndex];
    final output = StringBuffer();
    output.writeln('const ${target.key} = <String, String>{');
    for (final entry in translated.entries) {
      final encodedValue = jsonEncode(entry.value).replaceAll(r'$', r'\$');
      output.writeln('  ${jsonEncode(entry.key)}: $encodedValue,');
    }
    output.writeln('};\n');
    final fileName = targetFiles[target.key]!;
    await File('lib/core/localization/translations/$fileName')
        .writeAsString(output.toString());
    stdout.writeln('$fileName generated successfully.');
  }
}

Future<Map<String, String>> _translateLanguage(
  MapEntry<String, String> target,
) async {
  stdout.writeln('Translating ${target.key} (${target.value})...');
  final translated = <String, String>{};
  final entries = englishTranslations.entries.toList();
  for (var start = 0; start < entries.length; start += 12) {
    final end = (start + 12).clamp(0, entries.length);
    final chunk = entries.sublist(start, end);
    final protected = chunk.map((entry) => _protect(entry.value)).toList();
    var values = await _translateBatch(protected, target.value);
    if (values.length != chunk.length) {
      values = [];
      for (final value in protected) {
        values.add(await _translate(value, target.value));
      }
    }
    for (var index = 0; index < chunk.length; index++) {
      translated[chunk[index].key] = _restore(
        values[index],
        chunk[index].value,
      );
    }
    stdout.writeln('${target.value}: $end/${entries.length}');
  }
  return translated;
}

String _protect(String value) {
  return value;
}

String _restore(String value, String original) {
  return value;
}

Future<List<String>> _translateBatch(List<String> values, String language) async {
  final translated = await _translate(values.join(delimiter), language);
  return translated.split(RegExp(r'\s*ZXSPLITVAULTONEXZ\s*'));
}

Future<String> _translate(String text, String language) async {
  final uri = Uri.https('translate.googleapis.com', '/translate_a/single', {
    'client': 'gtx',
    'sl': 'en',
    'tl': language,
    'dt': 't',
    'q': text,
  });
  Object? lastError;
  for (var attempt = 1; attempt <= 4; attempt++) {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 20));
      final response = await request.close().timeout(const Duration(seconds: 20));
      final body = await utf8.decoder
          .bind(response)
          .join()
          .timeout(const Duration(seconds: 20));
      client.close();
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}: $body');
      }
      final decoded = jsonDecode(body) as List<dynamic>;
      final segments = decoded.first as List<dynamic>;
      return segments
          .map((segment) => (segment as List<dynamic>).first as String)
          .join();
    } catch (error) {
      lastError = error;
      await Future<void>.delayed(Duration(seconds: attempt * 2));
    }
  }
  throw StateError('Translation failed for $language: $lastError');
}
