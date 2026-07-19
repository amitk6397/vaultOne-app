import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

const appLanguagePreferenceKey = 'app_language_code';

enum AppLanguage {
  english('en', 'English', 'English'),
  hindi('hi', 'Hindi', 'हिन्दी'),
  bengali('bn', 'Bengali', 'বাংলা'),
  marathi('mr', 'Marathi', 'मराठी'),
  tamil('ta', 'Tamil', 'தமிழ்'),
  telugu('te', 'Telugu', 'తెలుగు'),
  gujarati('gu', 'Gujarati', 'ગુજરાતી'),
  spanish('es', 'Spanish', 'Español'),
  french('fr', 'French', 'Français'),
  arabic('ar', 'Arabic', 'العربية');

  const AppLanguage(this.code, this.englishName, this.nativeName);

  final String code;
  final String englishName;
  final String nativeName;

  Locale get locale => Locale(code);
}

final appLanguageProvider =
    StateNotifierProvider<AppLanguageController, AppLanguage>(
      (ref) => AppLanguageController(),
    );

class AppLanguageController extends StateNotifier<AppLanguage> {
  AppLanguageController({AppLanguage initial = AppLanguage.english})
    : super(initial);

  Future<void> select(AppLanguage language) async {
    state = language;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(appLanguagePreferenceKey, language.code);
  }
}

Future<AppLanguage?> loadSavedAppLanguage() async {
  final preferences = await SharedPreferences.getInstance();
  final savedCode = preferences.getString(appLanguagePreferenceKey);
  if (savedCode == null) return null;
  return AppLanguage.values.firstWhere(
    (language) => language.code == savedCode,
    orElse: () => AppLanguage.english,
  );
}
