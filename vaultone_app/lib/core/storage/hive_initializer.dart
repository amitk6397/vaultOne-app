import 'package:hive_flutter/hive_flutter.dart';

Future<void>? _hiveInitialization;

/// Starts Hive once and lets the Flutter splash render while it initializes.
Future<void> ensureHiveInitialized() {
  return _hiveInitialization ??= Hive.initFlutter();
}
