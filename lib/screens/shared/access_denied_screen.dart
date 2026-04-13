import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/router/app_router.dart';

class AccessDeniedScreen extends StatelessWidget {
  const AccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final homeRoute = authProvider.role == 'doctor'
        ? RouteNames.doctorDashboard
        : RouteNames.patientDashboard;

    return Scaffold(
      appBar: AppBar(title: const Text('Acces refuse')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 72, color: Colors.red),
              const SizedBox(height: 12),
              const Text(
                'Vous n\'avez pas l\'autorisation d\'acceder a cette page.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => context.go(homeRoute),
                icon: const Icon(Icons.home),
                label: const Text('Retour a l\'accueil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
