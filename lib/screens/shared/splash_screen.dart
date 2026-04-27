import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/router/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), _navigateAfterSplash);
  }

  void _navigateAfterSplash() {
    if (!mounted) {
      return;
    }
    final auth = context.read<AuthProvider>();
    final isLoggedIn = auth.user != null;
    final isLoadingRole = auth.isLoadingRole;
    final role = auth.role;

    if (!isLoggedIn) {
      context.go(RouteNames.login);
      return;
    }
    if (isLoadingRole) {
      _timer = Timer(const Duration(milliseconds: 400), _navigateAfterSplash);
      return;
    }
    if (role == 'doctor') {
      context.go(RouteNames.doctorDashboard);
      return;
    }
    if (role == 'patient') {
      context.go(RouteNames.patientDashboard);
      return;
    }
    context.go(RouteNames.fixProfile);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_hospital, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'SleepApnea Detect',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text(
              '© 2025 - v1.0.0',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
