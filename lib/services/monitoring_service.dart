import 'dart:async';
import 'dart:math';

/// Énumération des phases de monitoring: phase normale et phase d'apnée
enum _Phase { normal, apnea }

/// Service de simulation du monitoring médical
/// Génère un stream de données vitales réalistes alternant entre:
/// - Phase NORMAL: fréquence cardiaque, SpO2 et température stables
/// - Phase APNEA: SpO2 qui chute progressivement, fréquence cardiaque qui augmente
/// Les données sont mises à jour toutes les 500ms
class MonitoringService {
  /// Contrôleur stream en mode broadcast pour diffuser les données de monitoring à plusieurs écouteurs
  final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Générateur de nombres aléatoires pour les variations naturelles des vitals
  final Random _random = Random();

  /// Timer pour déclencher les mises à jour périodiques
  Timer? _timer;

  /// Durée de la phase normale (20 secondes) avant de passer en apnée
  static const Duration _normalDuration = Duration(seconds: 20);

  /// Durée de la phase d'apnée (15 secondes) avant de revenir à la normal
  static const Duration _apneaDuration = Duration(seconds: 15);

  /// Phase actuelle du monitoring
  _Phase _currentPhase = _Phase.normal;

  /// Timestamp du début de la phase actuelle (utilisé pour le calcul de progression)
  DateTime _phaseStart = DateTime.now();

  /// Expose le stream des données de monitoring pour que les écouteurs s'y abonnent
  Stream<Map<String, dynamic>> get stream => _controller.stream;

  /// Démarre le monitoring en continu
  /// - Réinitialise l'état (phase normale, timestamp)
  /// - Configure un timer qui déclenche une mise à jour toutes les 500ms
  /// - À chaque cycle, vérifie si une transition de phase doit survenir
  /// - Envoie les données mises à jour via le stream
  void startMonitoring() {
    stopMonitoring();
    _currentPhase = _Phase.normal;
    _phaseStart = DateTime.now();

    // Timer périodique: mise à jour toutes les 500ms (simule une fréquence d'échantillonnage de 2Hz)
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      // Vérifier que le contrôleur n'est pas fermé
      if (_controller.isClosed) return;

      // Calculer le temps écoulé depuis le début de la phase actuelle
      final elapsed = DateTime.now().difference(_phaseStart);

      // Transition: phase normale → apnée (après 20 secondes)
      if (_currentPhase == _Phase.normal && elapsed >= _normalDuration) {
        _currentPhase = _Phase.apnea;
        _phaseStart = DateTime.now();
      }
      // Transition: phase apnée → normale (après 15 secondes)
      else if (_currentPhase == _Phase.apnea && elapsed >= _apneaDuration) {
        _currentPhase = _Phase.normal;
        _phaseStart = DateTime.now();
      }

      // Générer les données vitales et les envoyer via le stream
      _controller.add(_buildPayload());
    });
  }

  /// Construit les données vitales simulées en fonction de la phase actuelle
  /// Retourne une map contenant: FC, SpO2, température, mouvement et timestamps
  /// Les valeurs varient progressivement durant la phase d'apnée pour un réalisme accru
  Map<String, dynamic> _buildPayload() {
    final isApnea = _currentPhase == _Phase.apnea;

    // Calculer la progression dans la phase actuelle (0.0 → 1.0)
    final elapsed = DateTime.now().difference(_phaseStart);
    final phaseDur = isApnea ? _apneaDuration : _normalDuration;
    final progress = (elapsed.inMilliseconds / phaseDur.inMilliseconds).clamp(
      0.0,
      1.0,
    );

    double heartRate;
    double spo2;
    double temperature;

    if (!isApnea) {
      // ═══════════════════════════════════════════════════════════════════
      // PHASE NORMALE: vitals stables dans les plages saines
      // FC: 60–80 bpm | SpO₂: 96–99% | Temp: 36.3–37.1°C
      // ═══════════════════════════════════════════════════════════════════
      heartRate = 60 + _random.nextDouble() * 20; // Variation aléatoire: ±10
      spo2 = 96 + _random.nextDouble() * 3; // SpO2 normale
      temperature =
          36.3 + _random.nextDouble() * 0.8; // Température corporelle normale
    } else {
      // ═══════════════════════════════════════════════════════════════════
      // PHASE APNEA: vitals dégradées et évoluant progressivement
      // SpO₂ chute: 95→83% | FC augmente: 72→110 bpm
      // ═══════════════════════════════════════════════════════════════════

      // SpO2 qui diminue progressivement pendant l'apnée (chute de 12%)
      final spo2Base = 95 - progress * 12;
      spo2 = (spo2Base + _random.nextDouble() * 2 - 1).clamp(80.0, 100.0);

      // Fréquence cardiaque qui augmente progressivement
      // Phase 1 (0-60% d'apnée): montée linéaire de 72 à 110 bpm
      // Phase 2 (60-100% d'apnée): fluctuations autour de 110 bpm
      final hrBase = progress < 0.6
          ? 72 +
                progress *
                    63 // Montée progressive: 72 + (0-0.6)*63 = 72-110
          : 110 + _random.nextDouble() * 8 - 4; // Fluctuations autour de 110
      heartRate = hrBase.clamp(45.0, 130.0);

      // La température reste légèrement élevée pendant l'apnée
      temperature = 37.0 + _random.nextDouble() * 0.5;
    }

    return {
      'heartRate': heartRate,
      'spo2': spo2,
      'timestamp': DateTime.now(),
      'temperature': temperature,
      // Mouvement: réduit pendant l'apnée, normal en phase normale
      'movement': isApnea
          ? 0.05 +
                _random.nextDouble() *
                    0.1 // 0.05-0.15 (apnée)
          : 0.10 + _random.nextDouble() * 0.3, // 0.10-0.40 (normal)
      // Métadonnées de simulation (pour debug/affichage)
      '_simPhase': isApnea ? 'apnea' : 'normal',
      '_simProgress': progress, // Progression dans la phase (0.0-1.0)
    };
  }

  /// Arrête le monitoring en cours
  /// - Annule le timer périodique
  /// - Réinitialise la référence du timer
  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  /// Vérifie si le monitoring est actuellement actif
  /// Retourne true si un timer est en cours, false sinon
  bool get isMonitoring => _timer != null;

  /// Nettoie les ressources du service
  /// - Arrête le monitoring s'il est en cours
  /// - Ferme le stream controller pour libérer la mémoire
  /// À appeler lors de la suppression du widget/provider
  void dispose() {
    stopMonitoring();
    if (!_controller.isClosed) _controller.close();
  }
}
