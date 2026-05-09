import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:apnea_project/l10n/app_localizations.dart';
import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/theme/app_colors.dart';

class AccessDeniedScreen extends StatelessWidget {
  const AccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final homeRoute = authProvider.role == 'doctor'
        ? RouteNames.doctorDashboard
        : RouteNames.patientDashboard;

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.accessDeniedTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 72, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                l10n.accessDeniedMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => context.go(homeRoute),
                icon: const Icon(Icons.home),
                label: Text(l10n.backToHomeButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
