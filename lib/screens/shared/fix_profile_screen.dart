// Fixed: Added a dedicated screen for unresolved or missing user role/profile.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:apnea_project/router/app_router.dart';

class FixProfileScreen extends StatelessWidget {
  const FixProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Incomplet')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'Votre profil est incomplet ou votre role est introuvable.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const Text(
                'Veuillez vous reconnecter ou contacter le support pour corriger votre compte.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go(RouteNames.login),
                icon: const Icon(Icons.login),
                label: const Text('Se reconnecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
