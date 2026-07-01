import 'package:flutter_riverpod/legacy.dart';

final loginPasswordVisibleProvider = StateProvider<bool>((ref) => false);
final rememberMeProvider = StateProvider<bool>((ref) => true);
final registerPasswordVisibleProvider = StateProvider<bool>((ref) => false);
final registerConfirmPasswordVisibleProvider = StateProvider<bool>(
  (ref) => false,
);
final termsAcceptedProvider = StateProvider<bool>((ref) => true);
final otpCodeProvider = StateProvider<String>((ref) => '');
