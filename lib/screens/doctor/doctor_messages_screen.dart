import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/providers/user_profile_provider.dart';
import 'package:apnea_project/services/messaging_service.dart';
import 'package:apnea_project/services/user_service.dart';
import 'package:apnea_project/theme/app_colors.dart';
import 'package:apnea_project/widgets/doctor_bottom_navigation_bar.dart';

/// Ecran de messagerie pour le docteur
/// Permet de voir la liste des conversations et d'echanger des messages avec les patients
class DoctorMessagesScreen extends StatefulWidget {
  const DoctorMessagesScreen({super.key});

  @override
  State<DoctorMessagesScreen> createState() => _DoctorMessagesScreenState();
}

/// Etat du widget DoctorMessagesScreen
/// Gere l'affichage de la liste des conversations et la vue chat
class _DoctorMessagesScreenState extends State<DoctorMessagesScreen> {
  /// ID de la conversation actuellement selectionnee (null si en liste)
  String? _selectedConversationId;

  /// Nom du patient de la conversation courante
  String? _selectedPatientName;

  /// ID du patient de la conversation courante
  String? _selectedPatientId;

  /// Controleur pour le champ de saisie de message
  final TextEditingController _messageController = TextEditingController();

  /// Controleur pour scrolling auto vers les derniers messages
  final ScrollController _scrollController = ScrollController();

  /// Service pour les operations de messagerie
  final MessagingService _messagingService = MessagingService();

  /// Service pour recuperer les donnees utilisateur
  final UserService _userService = UserService();

  /// Flag indiquant que l'envoi d'un message est en cours
  bool _isSending = false;

  /// Libere les ressources des controleurs au moment du dispose
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Ouvre une conversation existante et met a jour l'UI
  void _openConversation(String convId, String patientName, String patientId) {
    setState(() {
      _selectedConversationId = convId;
      _selectedPatientName = patientName;
      _selectedPatientId = patientId;
    });
  }

  /// Ferme la conversation actuelle et retourne a la liste
  void _closeConversation() {
    setState(() {
      _selectedConversationId = null;
      _selectedPatientName = null;
      _selectedPatientId = null;
    });
  }

  /// Affiche un bottom sheet pour choisir un patient et ouvre une conversation
  Future<void> _startNewConversation(
    String doctorUid,
    String doctorName,
  ) async {
    final patients = await _userService.streamDoctorPatients(doctorUid).first;

    if (!mounted) return;
    if (patients.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Aucun patient assigné.')));
      return;
    }

    // Afficher la bottom sheet de sélection
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PatientPickerSheet(
        patients: patients,
        isDark: Theme.of(context).brightness == Brightness.dark,
        onSelect: (patient) async {
          Navigator.of(ctx).pop();
          final patientUid = patient['uid'] as String? ?? '';
          final patientName =
              (patient['fullName'] as String?)?.trim() ?? 'Patient';

          // Créer ou récupérer la conversation
          final convId = await _messagingService.getOrCreateConversation(
            doctorUid: doctorUid,
            patientUid: patientUid,
          );

          if (!mounted) return;
          _openConversation(convId, patientName, patientUid);
        },
      ),
    );
  }

  /// Envoie un message dans la conversation actuelle
  /// Effectue les validations et met a jour Firestore
  Future<void> _sendMessage(String doctorUid, String doctorName) async {
    /// Recupere et nettoie le texte du message
    final text = _messageController.text.trim();
    if (text.isEmpty || _selectedConversationId == null || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await _messagingService.sendMessage(
        conversationId: _selectedConversationId!,
        senderId: doctorUid,
        senderName: 'Dr. $doctorName',
        text: text,
        recipientUid: _selectedPatientId,
      );
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  /// Scroll automatique vers le dernier message avec animation
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        /// Anime le scroll jusqu'au bas avec courbe easeOut
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Construit l'interface principale
  /// Affiche soit la liste des conversations, soit la vue chat selon l'etat
  @override
  Widget build(BuildContext context) {
    /// Recupere l'utilisateur connecte et son profil
    final user = context.watch<AuthProvider>().user;
    final doctorProfile = useDoctorProfile(context);
    final doctorName = doctorProfile?.fullName ?? 'Médecin';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Session expirée.')));
    }

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : const Color(0xFFF8FAFC),
      bottomNavigationBar: _selectedConversationId == null
          ? const DoctorBottomNavigationBar(currentIndex: 2)
          : null,
      body: SafeArea(
        child: _selectedConversationId == null
            ? _buildConversationList(user.uid, doctorName, isDark)
            : _buildChatView(user.uid, doctorName, isDark),
      ),
    );
  }

  /// ===== SECTION: LISTE DES CONVERSATIONS =====
  /// Affiche les conversations existantes du docteur
  /// Permet de selectionner une conversation pour ouvrir la vue chat

  Widget _buildConversationList(
    String doctorUid,
    String doctorName,
    bool isDark,
  ) {
    return Column(
      children: [
        _buildHeader(doctorName, isDark),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _messagingService.streamConversations(doctorUid),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final convs = snap.data ?? [];
              if (convs.isEmpty) {
                return _buildEmptyState(doctorUid, doctorName, isDark);
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: convs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _ConversationTile(
                  conv: convs[i],
                  isDark: isDark,
                  onTap: () => _openConversation(
                    convs[i]['id'] as String,
                    (convs[i]['patientName'] as String?) ?? 'Patient',
                    (convs[i]['patientUid'] as String?) ?? '',
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// En-tete de la liste des conversations
  /// Affiche titre + nom du docteur
  Widget _buildHeader(String doctorName, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.chat_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Messagerie',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
              Text(
                'Dr. $doctorName',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Etat vide: Affiche quand aucune conversation n'existe
  /// Propose de creer un nouveau message
  Widget _buildEmptyState(String doctorUid, String doctorName, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucune conversation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Démarrez une conversation\navec l\'un de vos patients.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textMedium,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _startNewConversation(doctorUid, doctorName),
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('Nouveau message'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ===== SECTION: VUE CHAT =====
  /// Affiche l'historique des messages et la barre de saisie
  /// Permet d'envoyer et de recevoir des messages en temps reel

  Widget _buildChatView(String doctorUid, String doctorName, bool isDark) {
    return Column(
      children: [
        _buildChatHeader(isDark),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _messagingService.streamMessages(_selectedConversationId!),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final messages = snap.data ?? [];
              if (messages.isEmpty) {
                return Center(
                  child: Text(
                    'Démarrez la conversation 👋',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textMedium,
                    ),
                  ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: messages.length,
                itemBuilder: (context, i) {
                  final msg = messages[i];
                  final isMe = msg['senderId'] == doctorUid;
                  final showDate =
                      i == 0 ||
                      _shouldShowDate(
                        messages[i - 1]['createdAt'],
                        msg['createdAt'],
                      );
                  return Column(
                    children: [
                      if (showDate)
                        _buildDateSeparator(msg['createdAt'], isDark),
                      _MessageBubble(msg: msg, isMe: isMe, isDark: isDark),
                    ],
                  );
                },
              );
            },
          ),
        ),
        _buildInputBar(doctorUid, doctorName, isDark),
      ],
    );
  }

  /// En-tete de la vue chat
  /// Affiche avatar + nom du patient + indicateur statut (online/offline)
  Widget _buildChatHeader(bool isDark) {
    /// Prend la premiere lettre du nom pour l'avatar
    final initial = (_selectedPatientName?.isNotEmpty == true)
        ? _selectedPatientName![0].toUpperCase()
        : 'P';
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
            onPressed: _closeConversation,
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
                  _selectedPatientName ?? 'Patient',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isDark ? Colors.white : AppColors.textDark,
                  ),
                ),
                Text(
                  'Patient',
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

  /// Barre de saisie des messages avec champ texte + bouton envoyer
  /// Support du multi-ligne et capitalisation des phrases
  Widget _buildInputBar(String doctorUid, String doctorName, bool isDark) {
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
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textDark,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Écrire un message…',
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
                onSubmitted: (_) => _sendMessage(doctorUid, doctorName),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendMessage(doctorUid, doctorName),
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
                      child: CircularProgressIndicator(
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

  /// Separateur de date entre les messages
  /// Affiche: "Aujourd'hui" | "Hier" | "JJ MMM YYYY"
  Widget _buildDateSeparator(dynamic raw, bool isDark) {
    /// Convertit le raw timestamp en DateTime
    final dt = _toDateTime(raw);
    if (dt == null) return const SizedBox.shrink();

    /// Determine le label a afficher selon la date
    final now = DateTime.now();
    String label;
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      label = "Aujourd'hui";
    } else if (now.difference(dt).inDays == 1) {
      label = 'Hier';
    } else {
      label = DateFormat('d MMMM yyyy', 'fr').format(dt);
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

  /// Determine s'il faut afficher un separateur de date entre deux messages
  /// Retourne true si les dates sont differentes
  bool _shouldShowDate(dynamic prev, dynamic curr) {
    final a = _toDateTime(prev);
    final b = _toDateTime(curr);
    if (a == null || b == null) return false;
    return a.day != b.day || a.month != b.month || a.year != b.year;
  }

  /// Utilitaire: Convertit differents formats de timestamp en DateTime
  /// Gere: Firestore Timestamp, String ISO 8601
  static DateTime? _toDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}

/// ===== WIDGET: BOTTOM SHEET SELECTION PATIENT =====
/// Permet de choisir un patient pour demarrer une nouvelle conversation

class _PatientPickerSheet extends StatefulWidget {
  const _PatientPickerSheet({
    required this.patients,
    required this.isDark,
    required this.onSelect,
  });

  final List<Map<String, dynamic>> patients;
  final bool isDark;
  final void Function(Map<String, dynamic>) onSelect;

  @override
  State<_PatientPickerSheet> createState() => _PatientPickerSheetState();
}

/// Etat du bottom sheet de selection de patient
class _PatientPickerSheetState extends State<_PatientPickerSheet> {
  /// Champ de recherche pour filtrer les patients
  String _search = '';

  @override
  Widget build(BuildContext context) {
    /// Filtre les patients selon la recherche (par nom)
    final filtered = widget.patients.where((p) {
      final name = (p['fullName'] as String?)?.toLowerCase() ?? '';
      return _search.isEmpty || name.contains(_search.toLowerCase());
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          /// Handle de dragage (barre grise en haut)
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          /// Titre avec nombre de patients
          ///  Titre
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text(
                  'Choisir un patient',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: widget.isDark ? Colors.white : AppColors.textDark,
                  ),
                ),
                const Spacer(),
                Text(
                  '${filtered.length} patient${filtered.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),

          /// Barre de recherche pour filtrer les patients par nom
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: TextStyle(
                  color: widget.isDark ? Colors.white : AppColors.textDark,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Rechercher un patient…',
                  hintStyle: TextStyle(
                    color: widget.isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textMedium,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: widget.isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textMedium,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Liste patients
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'Aucun patient trouvé',
                      style: TextStyle(
                        color: widget.isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textMedium,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, i) {
                      final p = filtered[i];
                      final name =
                          (p['fullName'] as String?)?.trim() ?? 'Patient';
                      final initial = name.isNotEmpty
                          ? name[0].toUpperCase()
                          : 'P';
                      final age = p['age'];
                      final gender = p['gender'] as String? ?? '';

                      return GestureDetector(
                        onTap: () => widget.onSelect(p),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: widget.isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: widget.isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.grey.shade100,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.primary.withValues(
                                  alpha: 0.12,
                                ),
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: widget.isDark
                                            ? Colors.white
                                            : AppColors.textDark,
                                      ),
                                    ),
                                    if (age != null || gender.isNotEmpty)
                                      Text(
                                        [
                                          if (age != null) '$age ans',
                                          if (gender.isNotEmpty) gender,
                                        ].join(' · '),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: widget.isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.textMedium,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: widget.isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textMedium,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── TUILE CONVERSATION ────────────────────────────────────────────

/// Widget stateless pour afficher une conversation dans la liste
class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conv,
    required this.isDark,
    required this.onTap,
  });

  final Map<String, dynamic> conv;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final patientName = (conv['patientName'] as String?)?.trim() ?? 'Patient';
    final lastMessage = (conv['lastMessage'] as String?) ?? '';
    final initial = patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P';
    final updatedAt = _formatTime(conv['lastMessageAt']);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.shade100,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        patientName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isDark ? Colors.white : AppColors.textDark,
                        ),
                      ),
                      Text(
                        updatedAt,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage.isEmpty ? 'Aucun message' : lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey,
              size: 18,
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
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    return DateFormat('d MMM', 'fr').format(dt);
  }
}

// ── BULLE MESSAGE ─────────────────────────────────────────────────

/// Widget pour afficher une bulle de message (envoyee ou recue)
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
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
            bottomLeft: Radius.circular(isMe ? 18 : 4),
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
