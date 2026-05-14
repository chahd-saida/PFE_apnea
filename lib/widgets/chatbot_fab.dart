import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:apnea_project/router/app_router.dart';

class PatientChatbotFAB extends StatelessWidget {
  const PatientChatbotFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => context.push(RouteNames.chatbot('patient')),
      backgroundColor: const Color(0xFF4DBDB8),
      child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
    );
  }
}

class DoctorChatbotFAB extends StatelessWidget {
  const DoctorChatbotFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => context.push(RouteNames.chatbot('doctor')),
      backgroundColor: const Color(0xFF6366F1),
      child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
    );
  }
}
