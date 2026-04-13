import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:apnea_project/main.dart';
import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/providers/theme_provider.dart';
import 'package:apnea_project/screens/shared/splash_screen.dart';

class MockAuthProvider extends Mock implements AuthProvider {}

class FakeFirebaseUser extends Fake implements User {}

class _MarkerScreen extends StatelessWidget {
  const _MarkerScreen(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(label)));
  }
}

GoRouter _buildTestRouter({
  required AuthProvider authProvider,
  required String initialLocation,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: authProvider,
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const _MarkerScreen('LOGIN'),
      ),
      GoRoute(
        path: RouteNames.doctorDashboard,
        builder: (context, state) => const _MarkerScreen('DOCTOR_DASHBOARD'),
      ),
      GoRoute(
        path: RouteNames.patientDashboard,
        builder: (context, state) => const _MarkerScreen('PATIENT_DASHBOARD'),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (context, state) => const _MarkerScreen('REGISTER'),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (context, state) => const _MarkerScreen('FORGOT_PASSWORD'),
      ),
    ],
    redirect: (context, state) {
      final bool isLoggedIn = authProvider.isLoggedIn;
      final String? role = authProvider.role;

      final bool isAuthRoute =
          state.fullPath == RouteNames.login ||
          state.fullPath == RouteNames.register ||
          state.fullPath == RouteNames.forgotPassword;
      final bool isSplash = state.fullPath == RouteNames.splash;

      if (!isLoggedIn) {
        if (!isAuthRoute && !isSplash) {
          return RouteNames.login;
        }
        return null;
      }

      if (role == null) {
        return isSplash ? null : RouteNames.splash;
      }

      if (isSplash || isAuthRoute) {
        return role == 'doctor'
            ? RouteNames.doctorDashboard
            : RouteNames.patientDashboard;
      }

      if (role == 'doctor' && state.fullPath == RouteNames.patientDashboard) {
        return RouteNames.doctorDashboard;
      }
      if (role == 'patient' && state.fullPath == RouteNames.doctorDashboard) {
        return RouteNames.patientDashboard;
      }

      return null;
    },
  );
}

Widget _buildApp({
  required AuthProvider authProvider,
  required GoRouter router,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
    ],
    child: MyApp(routerOverride: router),
  );
}

void _stubAuthProvider({
  required MockAuthProvider authProvider,
  required bool isLoggedIn,
  required String? role,
  required User? user,
}) {
  when(() => authProvider.addListener(any())).thenAnswer((_) {});
  when(() => authProvider.removeListener(any())).thenAnswer((_) {});
  when(() => authProvider.dispose()).thenAnswer((_) {});
  when(() => authProvider.isLoggedIn).thenReturn(isLoggedIn);
  when(() => authProvider.role).thenReturn(role);
  when(() => authProvider.user).thenReturn(user);
}

void main() {
  setUpAll(() {
    registerFallbackValue(() {});
  });

  testWidgets('App boots to splash', (WidgetTester tester) async {
    final authProvider = MockAuthProvider();
    _stubAuthProvider(
      authProvider: authProvider,
      isLoggedIn: false,
      role: null,
      user: null,
    );

    final router = _buildTestRouter(
      authProvider: authProvider,
      initialLocation: RouteNames.splash,
    );

    await tester.pumpWidget(
      _buildApp(authProvider: authProvider, router: router),
    );
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
  });

  testWidgets('Unauthenticated redirect to login', (WidgetTester tester) async {
    final authProvider = MockAuthProvider();
    _stubAuthProvider(
      authProvider: authProvider,
      isLoggedIn: false,
      role: null,
      user: null,
    );

    final router = _buildTestRouter(
      authProvider: authProvider,
      initialLocation: RouteNames.patientDashboard,
    );

    await tester.pumpWidget(
      _buildApp(authProvider: authProvider, router: router),
    );
    await tester.pumpAndSettle();

    expect(find.text('LOGIN'), findsOneWidget);
  });

  testWidgets('Authenticated doctor redirect', (WidgetTester tester) async {
    final authProvider = MockAuthProvider();
    final fakeUser = FakeFirebaseUser();
    _stubAuthProvider(
      authProvider: authProvider,
      isLoggedIn: true,
      role: 'doctor',
      user: fakeUser,
    );

    final router = _buildTestRouter(
      authProvider: authProvider,
      initialLocation: RouteNames.login,
    );

    await tester.pumpWidget(
      _buildApp(authProvider: authProvider, router: router),
    );
    await tester.pumpAndSettle();

    expect(find.text('DOCTOR_DASHBOARD'), findsOneWidget);
  });

  testWidgets('Authenticated patient redirect', (WidgetTester tester) async {
    final authProvider = MockAuthProvider();
    final fakeUser = FakeFirebaseUser();
    _stubAuthProvider(
      authProvider: authProvider,
      isLoggedIn: true,
      role: 'patient',
      user: fakeUser,
    );

    final router = _buildTestRouter(
      authProvider: authProvider,
      initialLocation: RouteNames.login,
    );

    await tester.pumpWidget(
      _buildApp(authProvider: authProvider, router: router),
    );
    await tester.pumpAndSettle();

    expect(find.text('PATIENT_DASHBOARD'), findsOneWidget);
  });
}
