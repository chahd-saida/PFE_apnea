import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/providers/user_profile_provider.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/services/firebase_service.dart';
import 'package:apnea_project/theme/app_colors.dart';
import 'package:apnea_project/widgets/doctor_chatbot_fab.dart';

class DoctorMessagesScreen extends StatefulWidget {
  const DoctorMessagesScreen({super.key});

  @override
  State<DoctorMessagesScreen> createState() => _DoctorMessagesScreenState();
}

class _DoctorMessagesScreenState extends State<DoctorMessagesScreen> {
  String? _selectedConversationId;
  String? _selectedPatientName;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String doctorUid, String doctorName) async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _selectedConversationId == null) return;

    _messageController.clear();
    try {
      await _firebaseService.sendMessage(
        conversationId: _selectedConversationId!,
        senderId: doctorUid,
        senderName: doctorName,
        text: text,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur envoi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final doctorProfile = useDoctorProfile(context);
    final doctorName = doctorProfile?.fullName ?? 'Médecin';
    final photoUrl = doctorProfile?.profileImageUrl;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Messagerie')),
        body: const Center(child: Text('Session expirée.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedConversationId == null
              ? 'Messagerie — Dr. $doctorName'
              : _selectedPatientName ?? 'Conversation',
        ),
        leading: _selectedConversationId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _selectedConversationId = null;
                  _selectedPatientName = null;
                }),
              )
            : null,
        actions: [
          if (_selectedConversationId == null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: InkWell(
                onTap: () => context.push(RouteNames.doctorProfile),
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
      body: _selectedConversationId == null
          ? _buildConversationList(user.uid)
          : _buildChatView(user.uid, doctorName),
      floatingActionButton: const DoctorChatbotFAB(),
    );
  }

  Widget _buildConversationList(String doctorUid) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firebaseService.streamConversations(doctorUid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Erreur chargement conversations.'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final conversations = snapshot.data ?? [];

        if (conversations.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucune conversation',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Les patients peuvent vous contacter via leur application.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMedium),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: conversations.length,
          separatorBuilder: (_, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final conv = conversations[index];
            final patientName =
                (conv['patientName'] as String?)?.trim() ?? 'Patient';
            final lastMessage = conv['lastMessage'] as String? ?? '';
            final convId = conv['id'] as String;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: 4,
              ),
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                patientName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                lastMessage.isEmpty ? 'Aucun message' : lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textMedium, fontSize: 13),
              ),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textMedium),
              onTap: () {
                setState(() {
                  _selectedConversationId = convId;
                  _selectedPatientName = patientName;
                });
              },
            );
          },
        );
      },
    );
  }

  Widget _buildChatView(String doctorUid, String doctorName) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _firebaseService.streamMessages(_selectedConversationId!),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Erreur chargement messages.'));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final messages = snapshot.data ?? [];

              if (messages.isEmpty) {
                return const Center(
                  child: Text('Aucun message. Commencez la conversation !'),
                );
              }

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(
                    _scrollController.position.maxScrollExtent,
                  );
                }
              });

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg['senderId'] == doctorUid;
                  return _buildMessageBubble(msg, isMe);
                },
              );
            },
          ),
        ),
        _buildInputBar(doctorUid, doctorName),
      ],
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    final text = msg['text'] as String? ?? '';
    final time = _formatTime(msg['createdAt']);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 8,
          left: isMe ? 64 : 0,
          right: isMe ? 0 : 64,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.surfaceLight,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: isMe ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 11,
                color: isMe ? Colors.white70 : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(String doctorUid, String doctorName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Écrire un message...',
                  hintStyle: TextStyle(color: AppColors.textLight),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(doctorUid, doctorName),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _sendMessage(doctorUid, doctorName),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(dynamic value) {
    if (value == null) return '';
    DateTime? date;
    if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = DateTime.tryParse(value);
    }
    if (date == null) return '';
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}