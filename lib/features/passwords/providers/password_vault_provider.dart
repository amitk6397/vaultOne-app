import 'package:flutter_riverpod/legacy.dart';

final passwordSearchProvider = StateProvider<String>((ref) => '');
final selectedPasswordCategoryProvider = StateProvider<String>((ref) => 'All');
final generatedPasswordProvider = StateProvider<String>(
  (ref) => 'V@ultOne-92#Secure',
);
final passwordLengthProvider = StateProvider<double>((ref) => 16);
final includeSymbolsProvider = StateProvider<bool>((ref) => true);
final includeNumbersProvider = StateProvider<bool>((ref) => true);
final includeUppercaseProvider = StateProvider<bool>((ref) => true);
