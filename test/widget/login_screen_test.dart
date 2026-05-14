import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/screens/auth/login_screen.dart';
import 'package:apnea_project/services/auth_service.dart';
import 'package:apnea_project/services/user_service.dart';

class _FakeAuthProvider extends AuthProvider {
  _FakeAuthProvider()
    : super(
        authService: AuthService(),
        userService: UserService(),
        listenToAuthChanges: false,
      );
}

void main() {
  testWidgets('LoginScreen validates required fields', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const LoginScreen()),
      ],
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: _FakeAuthProvider(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.tap(find.text('Se connecter'));
    await tester.pump();

    expect(find.text('Veuillez sélectionner un rôle'), findsOneWidget);
    expect(find.text('Veuillez entrer votre email'), findsOneWidget);
    expect(find.text('Veuillez entrer votre mot de passe'), findsOneWidget);
  });
}
