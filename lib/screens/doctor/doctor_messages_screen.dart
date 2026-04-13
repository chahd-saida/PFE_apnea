import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:apnea_project/providers/user_profile_provider.dart';
import 'package:apnea_project/router/app_router.dart';

class DoctorMessagesScreen extends StatelessWidget {
  const DoctorMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final doctorProfile = useDoctorProfile(context);
    final doctorName = doctorProfile?.fullName ?? 'Médecin';
    final photoUrl = doctorProfile?.profileImageUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text('Messagerie - Dr. $doctorName'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              onTap: () => context.pushNamed(RouteNames.doctorProfile),
              borderRadius: BorderRadius.circular(20),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white24,
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                    ? NetworkImage(photoUrl)
                    : null,
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? const Icon(Icons.person, size: 18, color: Colors.white)
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildMessageBubble(
                  'Bonjour Dr. $doctorName, comment va Ahmed ?',
                  true,
                  '10:30',
                ),
                _buildMessageBubble(
                  'Bonjour, Fatima. Ahmed va bien, ses paramètres sont stables.',
                  false,
                  '10:35',
                ),
                _buildMessageBubble('Super, merci !', true, '10:36'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Écrire un message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: () {
                    // Send message logic
                  },
                  mini: true,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String message, bool isMe, String time) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[100] : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: isMe
                ? const Radius.circular(15)
                : const Radius.circular(0),
            bottomRight: isMe
                ? const Radius.circular(0)
                : const Radius.circular(15),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 5),
            Text(
              time,
              style: const TextStyle(fontSize: 10, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
