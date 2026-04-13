import 'package:flutter/material.dart';

class RelaxationContentScreen extends StatelessWidget {
  const RelaxationContentScreen({
    super.key,
    required this.title,
    required this.contentType,
  });

  final String title;
  final String contentType;

  String get _typeLabel {
    switch (contentType) {
      case 'meditation':
        return 'Meditation';
      case 'video':
        return 'Video';
      case 'article':
        return 'Article';
      case 'create-meditation':
        return 'Creation meditation';
      case 'add-video':
        return 'Ajout video';
      case 'add-article':
        return 'Ajout article';
      default:
        return 'Contenu';
    }
  }

  IconData get _typeIcon {
    switch (contentType) {
      case 'meditation':
      case 'create-meditation':
        return Icons.self_improvement;
      case 'video':
      case 'add-video':
        return Icons.video_library;
      case 'article':
      case 'add-article':
        return Icons.article;
      default:
        return Icons.spa;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_typeLabel)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_typeIcon, size: 64),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Ecran $_typeLabel en preparation.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
