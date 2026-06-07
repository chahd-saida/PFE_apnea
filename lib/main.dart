import 'package:apnea_project/providers/patient_provider.dart';
import 'package:apnea_project/providers/report_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:apnea_project/l10n/app_localizations.dart';

import 'firebase_options.dart';

import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/providers/locale_provider.dart';
import 'package:apnea_project/providers/theme_provider.dart';
import 'package:apnea_project/providers/user_profile_provider.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/services/settings_service.dart';
import 'package:apnea_project/theme/app_theme.dart' as project_theme;
import 'package:apnea_project/providers/monitoring_provider.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ── CORRECTION : enregistrer le handler background AVANT init ────────────
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // ── CORRECTION : initialiser le service de notifications ─────────────────
  await NotificationService().init();

  final authProvider = AuthProvider();
  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();
  final localeProvider = LocaleProvider(SettingsService());
  await localeProvider.loadLocale();
  final appRouter = createAppRouter(
    authProvider,
    initialLocation: RouteNames.splash,
  );

  runApp(
    MultiProvider(
      providers: [
        // ── CORRECTION : MonitoringProvider déclaré une seule fois ───────
        ChangeNotifierProvider<MonitoringProvider>(
          create: (_) => MonitoringProvider(),
        ),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProxyProvider<AuthProvider, UserProfileProvider>(
          create: (_) => UserProfileProvider(),
          update: (_, auth, userProfileProvider) {
            final provider = userProfileProvider ?? UserProfileProvider();
            provider.bindAuth(auth);
            return provider;
          },
        ),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
        ChangeNotifierProvider(create: (_) => PatientProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: MyApp(routerOverride: appRouter),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.routerOverride});
  final GoRouter? routerOverride;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // ── Resauvegarder le token quand l'app revient au premier plan ────────
    // (couvre le cas où l'utilisateur était déjà connecté au démarrage)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshTokenOnStartup();
    });
  }

  Future<void> _refreshTokenOnStartup() async {
    try {
      await NotificationService().refreshTokenIfLoggedIn();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final router =
        widget.routerOverride ?? createAppRouter(context.read<AuthProvider>());

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      locale: localeProvider.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: project_theme.AppTheme.theme,
      darkTheme: project_theme.AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
