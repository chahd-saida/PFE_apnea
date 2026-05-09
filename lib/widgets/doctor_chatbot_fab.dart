import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DoctorChatbotFAB extends StatelessWidget {
  const DoctorChatbotFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => context.go('/doctor-chatbot'),
      backgroundColor: const Color(0xFF6366F1),
      child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
    );
  }
}
