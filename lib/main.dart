import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: VisoApp()));
}

class VisoApp extends StatelessWidget {
  const VisoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Viso',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const _AuthGate(),
    );
  }
}

/// Shows the signed-in [HomeScreen] or [LoginScreen] depending on
/// whether a stored token exists and still validates against the
/// backend (checked once, in [AuthController.build]).
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return authState.when(
      data: (user) => user != null ? const HomeScreen() : const LoginScreen(),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const LoginScreen(),
    );
  }
}
