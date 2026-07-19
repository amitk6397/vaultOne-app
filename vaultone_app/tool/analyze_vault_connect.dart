import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/physical_file_system.dart';

Future<void> main() async {
  final root = Directory.current.absolute.path;
  final targets = <String>[
    ...Directory('$root/lib/features/vault_connect').listSync(recursive: true)
        .whereType<File>().where((file) => file.path.endsWith('.dart'))
        .map((file) => file.absolute.path),
    '$root/lib/core/security/secure_token_store.dart',
    '$root/lib/features/media/providers/media_provider.dart',
    '$root/lib/features/home/providers/home_customization_provider.dart',
    '$root/lib/features/home/views/home_page_redesigned.dart',
    '$root/lib/routes/app_page.dart',
    '$root/lib/routes/app_routes.dart',
    '$root/lib/data/network_api_service.dart',
    '$root/lib/features/auth/repositories/auth_repository.dart',
    '$root/lib/features/profile/providers/profile_provider.dart',
  ];
  final collection = AnalysisContextCollection(
    includedPaths: [root],
    excludedPaths: ['$root/build', '$root/.dart_tool'],
    resourceProvider: PhysicalResourceProvider.INSTANCE,
  );
  var errors = 0;
  for (final target in targets) {
    final result = await collection.contextFor(target).currentSession.getResolvedUnit(target);
    if (result is! ResolvedUnitResult) {
      stderr.writeln('Could not resolve $target: $result');
      errors++;
      continue;
    }
    for (final diagnostic in result.diagnostics) {
      if (diagnostic.diagnosticCode.name.startsWith('unused_')) continue;
      stdout.writeln('${result.path}:${diagnostic.offset} ${diagnostic.diagnosticCode.name}: ${diagnostic.message}');
      final type = diagnostic.diagnosticCode.type.name;
      if (type == 'COMPILE_TIME_ERROR' || type == 'SYNTACTIC_ERROR') errors++;
    }
  }
  if (errors > 0) {
    stderr.writeln('Vault Connect analysis failed with $errors compile errors.');
    exitCode = 1;
  } else {
    stdout.writeln('Vault Connect targeted analysis passed for ${targets.length} files.');
  }
}
