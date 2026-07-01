import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaultone_app/main.dart';

void main() {
  testWidgets('shows splash screen by default', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: VaultOneApp()));

    expect(find.text('VaultOne'), findsOneWidget);
    expect(find.text('Secure everything important.'), findsOneWidget);
  });
}
