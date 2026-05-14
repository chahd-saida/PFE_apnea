// lib/screens/shared/chatbot_screen.dart
// Chatbot IA unifié — Patient (LLaMA 3.1-8B) + Médecin (LLaMA 3.3-70B)
// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:apnea_project/theme/app_colors.dart';

// ── Config Groq ──────────────────────────────────────────────────────────────
const String _groqApiKey = 'YOUR_GROQ_API_KEY_HERE';
const String _groqBaseUrl = 'https://api.groq.com/openai/v1/chat/completions';

// Modèles selon le rôle
const String _modelPatient = 'llama-3.1-8b-instant'; // rapide, léger
const String _modelDoctor = 'llama-3.3-70b-versatile'; // puissant, clinique

// ── Prompts système ───────────────────────────────────────────────────────────
const String _promptPatient = '''
Tu es ApneaBot, un assistant médical intelligent spécialisé dans l'apnée du sommeil, intégré dans l'application Apnea Detect.

Tes domaines d'expertise :
- Apnée du sommeil (obstructive, centrale, mixte) : causes, symptômes, traitements
- Interprétation des données : SpO₂, fréquence cardiaque, température nocturne
- Hygiène du sommeil : routines, environnement, alimentation, exercice
- Techniques de relaxation et de respiration

Tes règles :
- Réponds TOUJOURS en français, de façon claire et empathique
- Ne pose PAS de diagnostic définitif — encourage à consulter un médecin
- Garde les réponses concises (max 200 mots)
- Si l'utilisateur partage des valeurs (SpO₂ < 90%, FC > 100 bpm), commente-les cliniquement
- Propose toujours une action concrète à la fin
''';

const String _promptDoctor = '''
Tu es DoctorBot, un assistant clinique spécialisé en pneumologie et médecine du sommeil, intégré dans l'application Apnea Detect pour les médecins.

Tes domaines d'expertise :
- Diagnostic et classification des apnées (AHI, IAH, AASM 2023)
- Interprétation des polysomnographies et polygraphies
- Protocoles thérapeutiques : PPC, VNI, orthèses d'avancement mandibulaire, chirurgie
- Analyse des données capteurs : SpO₂, ECG (AD8232), accéléromètre (MPU6050)
- Recommandations basées sur le modèle Stacking IA v4

Tes règles :
- Réponds TOUJOURS en français avec terminologie médicale appropriée
- Fournis des recommandations cliniques précises et référencées
- Analyse les données chiffrées avec rigueur (seuils, tendances, anomalies)
- Max 300 mots par réponse sauf demande explicite de détails
''';

// ── Suggestions par rôle ──────────────────────────────────────────────────────
const _suggestionsPatient = [
  ('💤', "Qu'est-ce que l'apnée du sommeil ?"),
  ('📊', 'Mon SpO₂ est à 88%, est-ce dangereux ?'),
  ('❤️', 'Ma FC nocturne dépasse 100 bpm'),
  ('💊', "Quels sont les traitements de l'apnée ?"),
  ('🌙', 'Comment améliorer mon hygiène du sommeil ?'),
  ('🧘', 'Techniques de relaxation avant le coucher'),
];

const _suggestionsDoctor = [
  ('📋', 'Interpréter un IAH de 25 événements/h'),
  ('🫁', 'Critères PPC vs orthèse mandibulaire'),
  ('📉', 'SpO₂ moyenne 91% — recommandations ?'),
  ('🧠', 'Apnée centrale vs obstructive : différences'),
  ('💊', 'Protocole suivi post-PPC à 3 mois'),
  ('📊', 'Analyser score IA Stacking v4 : 0.82'),
];

// ── Message model ─────────────────────────────────────────────────────────────
enum _MsgStatus { normal, loading, error }

class _Message {
  final String content;
  final bool isUser;
  final DateTime time;
  final _MsgStatus status;
  const _Message({
    required this.content,
    required this.isUser,
    required this.time,
    this.status = _MsgStatus.normal,
  });
}

// ── SCREEN ────────────────────────────────────────────────────────────────────
class ChatbotScreen extends StatefulWidget {
  final String role; // 'patient' ou 'doctor'
  const ChatbotScreen({super.key, required this.role});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  late final AnimationController _pulseCtrl;
  late final AnimationController _dotCtrl;

  final List<_Message> _messages = [];
  final List<Map<String, String>> _history = [];

  bool _isLoading = false;
  bool _showSuggestions = true;

  // ── Config selon rôle ─────────────────────────────────────────────────────
  bool get _isDoctor => widget.role == 'doctor';
  String get _model => _isDoctor ? _modelDoctor : _modelPatient;
  String get _prompt => _isDoctor ? _promptDoctor : _promptPatient;
  String get _botName => _isDoctor ? 'DoctorBot' : 'ApneaBot';
  String get _modelLabel => _isDoctor ? 'LLaMA 3.3-70B' : 'LLaMA 3.1-8B';
  Color get _accentColor => _isDoctor
      ? const Color(0xFF6366F1) // violet médecin
      : const Color(0xFF4DBDB8); // teal patient
  List<(String, String)> get _suggestions =>
      _isDoctor ? _suggestionsDoctor : _suggestionsPatient;

  String get _welcomeMessage => _isDoctor
      ? 'Bonjour Docteur 👨‍⚕️ Je suis **DoctorBot**, votre assistant clinique spécialisé en pneumologie et médecine du sommeil.\n\nJe peux vous aider à :\n• 📋 Interpréter les données capteurs de vos patients\n• 🫁 Analyser les résultats du modèle IA v4\n• 💊 Recommander des protocoles thérapeutiques\n• 📊 Discuter des cas cliniques complexes\n\nComment puis-je vous assister ?'
      : 'Bonjour ! 👋 Je suis **ApneaBot**, votre assistant IA spécialisé dans le sommeil.\n\nJe peux vous aider à :\n• 📊 Interpréter vos données de monitoring\n• 💊 Répondre à vos questions sur l\'apnée\n• 🌙 Améliorer votre qualité de sommeil\n• 🧘 Proposer des exercices de relaxation\n\nComment puis-je vous aider ?';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _messages.add(
      _Message(content: _welcomeMessage, isUser: false, time: DateTime.now()),
    );
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _pulseCtrl.dispose();
    _dotCtrl.dispose();
    super.dispose();
  }

  // ── Envoi message ─────────────────────────────────────────────────────────
  Future<void> _sendMessage(String text) async {
    final msg = text.trim();
    if (msg.isEmpty || _isLoading) return;

    _textCtrl.clear();
    _focusNode.unfocus();

    setState(() {
      _showSuggestions = false;
      _isLoading = true;
      _messages.add(_Message(content: msg, isUser: true, time: DateTime.now()));
      _messages.add(
        _Message(
          content: '',
          isUser: false,
          time: DateTime.now(),
          status: _MsgStatus.loading,
        ),
      );
    });
    _scrollToBottom();
    _history.add({'role': 'user', 'content': msg});

    try {
      final response = await http
          .post(
            Uri.parse(_groqBaseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_groqApiKey',
            },
            body: jsonEncode({
              'model': _model,
              'max_tokens': _isDoctor ? 2048 : 1024,
              'temperature': 0.7,
              'messages': [
                {'role': 'system', 'content': _prompt},
                ..._history,
              ],
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final reply = data['choices'][0]['message']['content'] as String;
        _history.add({'role': 'assistant', 'content': reply});
        setState(() {
          _messages.removeLast();
          _messages.add(
            _Message(content: reply, isUser: false, time: DateTime.now()),
          );
          _isLoading = false;
        });
      } else {
        final err = jsonDecode(response.body);
        final errMsg =
            err['error']?['message'] ?? 'Erreur ${response.statusCode}';
        _handleError(errMsg);
      }
    } catch (e) {
      _handleError(
        e.toString().contains('TimeoutException')
            ? 'Délai dépassé. Réessayez.'
            : 'Connexion impossible. Vérifiez votre réseau.',
      );
    }
    _scrollToBottom();
  }

  void _handleError(String msg) {
    if (_history.isNotEmpty && _history.last['role'] == 'user') {
      _history.removeLast();
    }
    setState(() {
      _messages.removeLast();
      _messages.add(
        _Message(
          content: '❌ $msg',
          isUser: false,
          time: DateTime.now(),
          status: _MsgStatus.error,
        ),
      );
      _isLoading = false;
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _history.clear();
      _showSuggestions = true;
      _messages.add(
        _Message(
          content: 'Conversation réinitialisée ✨\nComment puis-je vous aider ?',
          isUser: false,
          time: DateTime.now(),
        ),
      );
    });
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0E1A)
          : const Color(0xFFF0F4FF),
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(isDark),
      body: SafeArea(
        child: Column(
          children: [
            _buildBanner(),
            Expanded(child: _buildMessageList(isDark)),
            if (_showSuggestions) _buildSuggestions(),
            _buildInputBar(isDark),
          ],
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(bool isDark) => AppBar(
    backgroundColor: isDark ? const Color(0xFF0D1117) : Colors.white,
    elevation: 0,
    leading: IconButton(
      icon: Icon(
        Icons.arrow_back_ios_new,
        color: isDark ? Colors.white : AppColors.textDark,
        size: 18,
      ),
      onPressed: () => context.canPop() ? context.pop() : context.go('/'),
    ),
    title: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isDoctor
                  ? [const Color(0xFF6366F1), const Color(0xFF4F46E5)]
                  : [const Color(0xFF4DBDB8), const Color(0xFF1E3A8A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: _accentColor.withValues(alpha: 0.4),
                blurRadius: 10,
              ),
            ],
          ),
          child: Icon(
            _isDoctor
                ? Icons.medical_services_rounded
                : Icons.smart_toy_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _botName,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textDark,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) => Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF10B981),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF10B981,
                          ).withValues(alpha: 0.4 + 0.4 * _pulseCtrl.value),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Groq · $_modelLabel',
                  style: TextStyle(color: Colors.grey[500], fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    actions: [
      PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: Colors.grey[500]),
        color: isDark ? const Color(0xFF161D2E) : Colors.white,
        onSelected: (v) {
          if (v == 'clear') _clearChat();
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'clear',
            child: Row(
              children: [
                Icon(Icons.refresh_rounded, color: Colors.grey[600], size: 18),
                const SizedBox(width: 8),
                const Text('Réinitialiser'),
              ],
            ),
          ),
        ],
      ),
    ],
  );

  // ── Banner avertissement ──────────────────────────────────────────────────
  Widget _buildBanner() => Container(
    margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: _accentColor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _accentColor.withValues(alpha: 0.2)),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline_rounded, color: _accentColor, size: 13),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _isDoctor
                ? 'Outil d\'aide à la décision — ne remplace pas le jugement clinique'
                : 'Conseils généraux uniquement — consultez votre médecin pour un diagnostic',
            style: TextStyle(color: Colors.grey[600], fontSize: 10.5),
          ),
        ),
      ],
    ),
  );

  // ── Liste messages ────────────────────────────────────────────────────────
  Widget _buildMessageList(bool isDark) => ListView.builder(
    controller: _scrollCtrl,
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
    itemCount: _messages.length,
    itemBuilder: (_, i) {
      final msg = _messages[i];
      final showTime =
          i == 0 || msg.time.difference(_messages[i - 1].time).inMinutes > 3;
      return Column(
        children: [
          if (showTime) _buildTimestamp(msg.time),
          msg.isUser
              ? _UserBubble(message: msg, accentColor: _accentColor)
              : _BotBubble(
                  message: msg,
                  isDark: isDark,
                  dotCtrl: _dotCtrl,
                  accentColor: _accentColor,
                  isDoctor: _isDoctor,
                ),
        ],
      );
    },
  );

  Widget _buildTimestamp(DateTime t) {
    final diff = DateTime.now().difference(t);
    final label = diff.inSeconds < 30
        ? 'À l\'instant'
        : diff.inMinutes < 60
        ? 'Il y a ${diff.inMinutes} min'
        : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        label,
        style: TextStyle(color: Colors.grey[500], fontSize: 10.5),
      ),
    );
  }

  // ── Suggestions ───────────────────────────────────────────────────────────
  Widget _buildSuggestions() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 0, 6),
        child: Text(
          'Questions fréquentes',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: _suggestions.length,
          itemBuilder: (_, i) {
            final (emoji, text) = _suggestions[i];
            return GestureDetector(
              onTap: () => _sendMessage(text),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _accentColor.withValues(alpha: 0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 5),
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _isDoctor
                            ? const Color(0xFF4F46E5)
                            : const Color(0xFF1E3A8A),
                      ),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 8),
    ],
  );

  // ── Barre de saisie ───────────────────────────────────────────────────────
  Widget _buildInputBar(bool isDark) => Container(
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF0D1117) : Colors.white,
      border: Border(
        top: BorderSide(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
    child: Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161D2E) : const Color(0xFFF4F7FF),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _accentColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    focusNode: _focusNode,
                    maxLines: 4,
                    minLines: 1,
                    enabled: !_isLoading,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sendMessage,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textDark,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: _isDoctor
                          ? 'Question clinique...'
                          : 'Posez votre question…',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _isLoading ? null : () => _sendMessage(_textCtrl.text),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: _isLoading
                  ? null
                  : LinearGradient(
                      colors: _isDoctor
                          ? [const Color(0xFF6366F1), const Color(0xFF4F46E5)]
                          : [const Color(0xFF4DBDB8), const Color(0xFF1E3A8A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: _isLoading ? Colors.grey[300] : null,
              shape: BoxShape.circle,
              boxShadow: _isLoading
                  ? []
                  : [
                      BoxShadow(
                        color: _accentColor.withValues(alpha: 0.4),
                        blurRadius: 10,
                      ),
                    ],
            ),
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ],
    ),
  );
}

// ── USER BUBBLE ───────────────────────────────────────────────────────────────
class _UserBubble extends StatelessWidget {
  final _Message message;
  final Color accentColor;
  const _UserBubble({required this.message, required this.accentColor});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: message.content));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message copié'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, left: 50),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accentColor, accentColor.withValues(alpha: 0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          message.content,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ),
    ),
  );
}

// ── BOT BUBBLE ────────────────────────────────────────────────────────────────
class _BotBubble extends StatelessWidget {
  final _Message message;
  final bool isDark;
  final bool isDoctor;
  final AnimationController dotCtrl;
  final Color accentColor;
  const _BotBubble({
    required this.message,
    required this.isDark,
    required this.dotCtrl,
    required this.accentColor,
    required this.isDoctor,
  });

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 30,
          height: 30,
          margin: const EdgeInsets.only(right: 8, bottom: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDoctor
                  ? [const Color(0xFF6366F1), const Color(0xFF4F46E5)]
                  : [const Color(0xFF4DBDB8), const Color(0xFF1E3A8A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isDoctor ? Icons.medical_services_rounded : Icons.smart_toy_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
        Flexible(
          child: GestureDetector(
            onLongPress: message.status != _MsgStatus.loading
                ? () {
                    Clipboard.setData(ClipboardData(text: message.content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Réponse copiée'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                : null,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10, right: 50),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.status == _MsgStatus.error
                    ? const Color(0xFFFFEBEE)
                    : isDark
                    ? const Color(0xFF161D2E)
                    : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(
                  color: message.status == _MsgStatus.error
                      ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                      : isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.withValues(alpha: 0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: message.status == _MsgStatus.loading
                  ? _buildTypingIndicator()
                  : _buildText(isDark),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildTypingIndicator() => AnimatedBuilder(
    animation: dotCtrl,
    builder: (_, __) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Réflexion en cours',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(width: 6),
        ...List.generate(3, (i) {
          final offset = (dotCtrl.value * 3 - i).clamp(0.0, 1.0);
          final bounce = (offset < 0.5 ? offset : 1 - offset) * 2;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 6,
            height: 6,
            transform: Matrix4.translationValues(0, -4 * bounce, 0),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.5 + 0.5 * bounce),
              shape: BoxShape.circle,
            ),
          );
        }),
      ],
    ),
  );

  Widget _buildText(bool isDark) {
    final lines = message.content.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.trim().isEmpty) return const SizedBox(height: 4);
        final spans = <TextSpan>[];
        final parts = line.split('**');
        for (int i = 0; i < parts.length; i++) {
          if (parts[i].isEmpty) continue;
          spans.add(
            TextSpan(
              text: parts[i],
              style: TextStyle(
                fontWeight: i % 2 == 1 ? FontWeight.bold : FontWeight.normal,
                color: message.status == _MsgStatus.error
                    ? const Color(0xFFEF4444)
                    : isDark
                    ? Colors.white.withValues(alpha: 0.9)
                    : AppColors.textDark,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          );
        }
        return Padding(
          padding: EdgeInsets.only(bottom: line.startsWith('•') ? 2 : 0),
          child: RichText(
            text: TextSpan(
              children: spans.isEmpty
                  ? [
                      TextSpan(
                        text: line,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.9)
                              : AppColors.textDark,
                          fontSize: 13.5,
                          height: 1.5,
                        ),
                      ),
                    ]
                  : spans,
            ),
          ),
        );
      }).toList(),
    );
  }
}
