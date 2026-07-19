import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vaultone_app/main.dart';
import 'package:vaultone_app/core/localization/app_localizations.dart';
import 'package:vaultone_app/core/localization/app_language_controller.dart';
import 'package:vaultone_app/shared/widgets/app_loading_indicator.dart';

void main() {
  testWidgets('shows splash screen by default', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: VaultOneApp()));

    expect(find.text('VaultOne'), findsOneWidget);
    expect(find.byType(AppLoadingIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
    expect(find.text('Choose your language'), findsOneWidget);
  });

  test('English and Hindi translations resolve the same semantic key', () {
    expect(
      const AppLocalizations(Locale('en')).tr('choose_language'),
      'Choose your language',
    );
    expect(
      const AppLocalizations(Locale('hi')).tr('choose_language'),
      'अपनी भाषा चुनें',
    );
  });

  test(
    'language changes immediately and persists for the next launch',
    () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(appLanguageProvider.notifier)
          .select(AppLanguage.hindi);

      expect(container.read(appLanguageProvider), AppLanguage.hindi);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(appLanguagePreferenceKey), 'hi');
      expect(await loadSavedAppLanguage(), AppLanguage.hindi);
    },
  );

  test('unsupported locale falls back to English translations', () {
    expect(
      const AppLocalizations(Locale('de')).tr('choose_language'),
      'Choose your language',
    );
  });
}
