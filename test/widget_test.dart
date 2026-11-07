import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:viso_app/core/token_storage.dart';
import 'package:viso_app/features/auth/auth_controller.dart';
import 'package:viso_app/main.dart';

/// Avoids the real `flutter_secure_storage` platform channel, which
/// isn't available under `flutter test`.
class _FakeTokenStorage implements TokenStorage {
  @override
  Future<String?> readToken() async => null;

  @override
  Future<void> saveToken(String token) async {}

  @override
  Future<void> clearToken() async {}
}

void main() {
  testWidgets('shows the login screen when signed out', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tokenStorageProvider.overrideWithValue(_FakeTokenStorage())],
        child: const VisoApp(),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Viso'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });
}
