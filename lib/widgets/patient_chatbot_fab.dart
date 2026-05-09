import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PatientChatbotFAB extends StatelessWidget {
  const PatientChatbotFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => context.go('/patient-chatbot'),
      backgroundColor: const Color(0xFF4DBDB8),
      child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
    );
  }
}
