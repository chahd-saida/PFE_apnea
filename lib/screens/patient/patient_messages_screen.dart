import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Formatage des dates en français
import 'package:cloud_firestore/cloud_firestore.dart';  // Base de données Firebase

import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/services/messaging_service.dart'; // Base de données Firebase
import 'package:apnea_project/theme/app_colors.dart';

//Widget avec état car il gère la conversation active, le chargement, l'envoi de messages et le scroll — toutes des opérations dynamiques qui nécessitent setState
class PatientMessagesScreen extends StatefulWidget {
  const PatientMessagesScreen({super.key});

  @override
  State<PatientMessagesScreen> createState() => _PatientMessagesScreenState();
}

class _PatientMessagesScreenState extends State<PatientMessagesScreen> {
  String? _conversationId; // ID Firestore de la conversation active
  String? _doctorName;  // Nom du médecin (affiché dans l'en-tête)
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MessagingService _messagingService = MessagingService();
  bool _isSending = false; // Bloque le double-envoi
  bool _isLoading = true;  // Contrôle l'affichage du spinner initial

  @override
  void initState() {
    super.initState();
    _loadConversation(); // Dès l'ouverture, chercher/créer la conversation
  }

  @override
  void dispose() {
    _messageController.dispose();  // Libère mémoire du champ texte
    _scrollController.dispose(); // Libère mémoire du scroll
    super.dispose();
    //dispose est obligatoire pour ces deux contrôleurs pour éviter les fuites mémoire
  }

  Future<void> _loadConversation() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Lire le profil du patient :Charge le document Firestore du patient connecté pour y lire l'UID de son médecin assigné.
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        debugPrint('❌ Document utilisateur introuvable: ${user.uid}');
        setState(() => _isLoading = false);
        return;
      }

      final data = userDoc.data() ?? {};
      debugPrint('📄 Profil patient: $data');

      // Chercher doctorUid dans plusieurs champs possibles
      final doctorUid =
          (data['doctorUid'] as String?)?.trim() ??
          (data['assignedDoctorId'] as String?)?.trim() ??
          (data['doctor_uid'] as String?)?.trim();
          //L'opérateur ?? en cascade cherche le même champ sous trois nommages possibles (doctorUid, assignedDoctorId, doctor_uid)

      debugPrint('🔑 doctorUid trouvé: $doctorUid');

      if (doctorUid == null || doctorUid.isEmpty) {
        // Pas de médecin assigné → chercher quand même une conversation existante
        final existingConv = await FirebaseFirestore.instance
            .collection('conversations')
            .where('patientUid', isEqualTo: user.uid)
            .limit(1) 
            .get();
            // Utilise la conversation si elle existe, sinon → écran "aucun médecin"

        if (existingConv.docs.isNotEmpty) {
          final conv = existingConv.docs.first.data();
          setState(() {
            _conversationId = existingConv.docs.first.id;
            _doctorName =
                (conv['doctorName'] as String?)?.trim() ?? 'Mon Médecin';
            _isLoading = false;
          });
          return;
        }

        setState(() => _isLoading = false);
        return;
      }

      // Récupérer le nom du médecin
      String dName = (data['doctorName'] as String?)?.trim() ?? '';
      if (dName.isEmpty) {
         // Fallback : aller lire le doc du médecin directement
        try {
          final doctorDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(doctorUid)
              .get();
          dName =
              (doctorDoc.data()?['fullName'] as String?)?.trim() ??
              'Mon Médecin';
        } catch (_) {
          dName = 'Mon Médecin';
        }
      }

      // Créer ou récupérer la conversation
      final convId = await MessagingService().getOrCreateConversation(
        doctorUid: doctorUid,
        patientUid: user.uid,
      );

      debugPrint('✅ Conversation ID: $convId');

      setState(() {
        _conversationId = convId;
        _doctorName = dName;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur _loadConversation: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage(String patientUid, String patientName) async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _conversationId == null || _isSending) return;
  // texte vide, pas de conversation, déjà en cours d'envoi

    setState(() => _isSending = true);
    _messageController.clear(); // Vide le champ immédiatement (UX responsive)

    // Recharge doctorUid depuis Firestore (toujours à jour)
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(patientUid)
        .get();
    final doctorUid = userDoc.data()?['doctorUid'] as String? ?? '';

    try {
      await _messagingService.sendMessage(
        conversationId: _conversationId!,
        senderId: patientUid,
        senderName: patientName,
        text: text,
        recipientUid: doctorUid, // Pour potentielles notifications push
      );
      _scrollToBottom(); // Défile vers le nouveau message
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar( 
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
      ); // Erreur visible
    } finally {
      if (mounted) setState(() => _isSending = false); // Réactive le bouton
    }
  }
//Défilement automatique
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Session expirée.')));
    }

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark), // En-tête avec infos médecin
            Expanded(child: _buildBody(user.uid, isDark)), // Zone messages (scrollable)
            if (_conversationId != null) // Barre de saisie (uniquement si conversation active)
              _buildInputBar(user.uid, user.displayName ?? 'Patient', isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final initial = (_doctorName?.isNotEmpty == true)
        ? _doctorName![0].toUpperCase() // Ex: "Dr Martin" → "D"
        : 'M'; // Fallback si nom inconnu
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.shade100,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
            onPressed: () => Navigator.of(context).maybePop(),
            color: isDark ? Colors.white70 : AppColors.textDark,
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isLoading ? 'Chargement…' : (_doctorName ?? 'Mon Médecin'),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isDark ? Colors.white : AppColors.textDark,
                  ),
                ),
                Text(
                  'Médecin traitant',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          if (_conversationId != null)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(String patientUid, bool isDark) {
    if (_isLoading) {  //CircularProgressIndicator
      return const Center(child: CircularProgressIndicator());
    }

    if (_conversationId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_search_rounded,
                  size: 48,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Aucun médecin assigné',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vous pourrez envoyer des messages\nune fois qu\'un médecin vous est assigné.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textMedium,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _messagingService.streamMessages(_conversationId!),
      builder: (context, snap) {
            // Chaque nouveau message Firestore déclenche une reconstruction automatique

        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final messages = snap.data ?? [];
        if (messages.isEmpty) {
          return Center(
            child: Text(
              'Envoyez un message à votre médecin 👋',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textMedium,
              ),
            ),
          );
        }
            // Défilement automatique après reconstruction
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(
              _scrollController.position.maxScrollExtent,
            );
          }
        });
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: messages.length,
          itemBuilder: (context, i) {
            final msg = messages[i];
            final isMe = msg['senderId'] == patientUid;// Différencie patient/médecin
            final showDate =
                i == 0 ||
                _shouldShowDate(messages[i - 1]['createdAt'], msg['createdAt']);
            return Column(
              children: [
                if (showDate) _buildDateSeparator(msg['createdAt'], isDark),// Séparateur de date si changement de jour
                _PatientMessageBubble(msg: msg, isMe: isMe, isDark: isDark),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInputBar(String patientUid, String patientName, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.shade100,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences, // S'agrandit avec le contenu
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textDark,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Écrire à votre médecin…',
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textMedium,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(patientUid, patientName), // Envoi via clavier "Entrée"

              ),
            ),
          ),
          const SizedBox(width: 8),
          // Bouton d'envoi circulaire
          GestureDetector(
            onTap: () => _sendMessage(patientUid, patientName),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator( // Spinner pendant envoi
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(dynamic raw, bool isDark) {
    final dt = _toDateTime(raw);
    if (dt == null) return const SizedBox.shrink();
    final now = DateTime.now();
    String label;
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      label = "Aujourd'hui";
    } else if (now.difference(dt).inDays == 1) {
      label = 'Hier';
    } else {
      label = DateFormat('d MMMM yyyy', 'fr').format(dt);   // Ex: "3 juin 2026" en français grâce au package intl
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.shade200,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textMedium,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.shade200,
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowDate(dynamic prev, dynamic curr) {
     // Affiche le séparateur si le message actuel est un jour différent du précédent
    final a = _toDateTime(prev);
    final b = _toDateTime(curr);
    if (a == null || b == null) return false;
    return a.day != b.day || a.month != b.month || a.year != b.year;
  }

  static DateTime? _toDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate(); // Format Firestore
    if (raw is String) return DateTime.tryParse(raw); // Format ISO8601
    return null;
  }
}

class _PatientMessageBubble extends StatelessWidget {
  const _PatientMessageBubble({
    required this.msg,
    required this.isMe,
    required this.isDark,
  });

  final Map<String, dynamic> msg;
  final bool isMe;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final text = (msg['text'] as String?) ?? '';
    final time = _formatTime(msg['createdAt']);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
       // Mes messages → droite (bleu) | Messages médecin → gauche (blanc)
      child: Container(
        margin: EdgeInsets.only(
          bottom: 4,
          left: isMe ? 64 : 0,
          right: isMe ? 0 : 64,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.primary
              : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4), // Coin "pointant" vers l'expéditeur
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          border: isMe
              ? null
              : Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.grey.shade200,
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  (msg['senderName'] as String?) ?? 'Médecin', // Nom affiché uniquement pour les messages reçus
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isMe
                    ? Colors.white
                    : (isDark ? Colors.white : AppColors.textDark),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 10,
                color: isMe
                    ? Colors.white.withValues(alpha: 0.7)
                    : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textMedium),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(dynamic raw) {
    if (raw == null) return '';
    DateTime? dt;
    if (raw is Timestamp) dt = raw.toDate();
    if (raw is String) dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    return DateFormat('HH:mm').format(dt);
  }
}
