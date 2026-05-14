import 'dart:async';
import 'dart:math';

enum _Phase { normal, apnea }

class MonitoringService {
  final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();
  final Random _random = Random();
  Timer? _timer;

  static const Duration _normalDuration = Duration(seconds: 20);
  static const Duration _apneaDuration = Duration(seconds: 15);

  _Phase _currentPhase = _Phase.normal;
  DateTime _phaseStart = DateTime.now();

  Stream<Map<String, dynamic>> get stream => _controller.stream;

  void startMonitoring() {
    stopMonitoring();
    _currentPhase = _Phase.normal;
    _phaseStart = DateTime.now();

    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_controller.isClosed) return;

      final elapsed = DateTime.now().difference(_phaseStart);
      if (_currentPhase == _Phase.normal && elapsed >= _normalDuration) {
        _currentPhase = _Phase.apnea;
        _phaseStart = DateTime.now();
      } else if (_currentPhase == _Phase.apnea && elapsed >= _apneaDuration) {
        _currentPhase = _Phase.normal;
        _phaseStart = DateTime.now();
      }

      _controller.add(_buildPayload());
    });
  }

  Map<String, dynamic> _buildPayload() {
    final isApnea = _currentPhase == _Phase.apnea;

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
      // ── NORMAL : FC 60–80 | SpO₂ 96–99 | Temp 36.3–37.1
      heartRate = 60 + _random.nextDouble() * 20;
      spo2 = 96 + _random.nextDouble() * 3;
      temperature = 36.3 + _random.nextDouble() * 0.8;
    } else {
      // ── APNÉE : SpO₂ chute 95→83, FC monte 72→110
      final spo2Base = 95 - progress * 12;
      spo2 = (spo2Base + _random.nextDouble() * 2 - 1).clamp(80.0, 100.0);

      final hrBase = progress < 0.6
          ? 72 + progress * 63
          : 110 + _random.nextDouble() * 8 - 4;
      heartRate = hrBase.clamp(45.0, 130.0);

      temperature = 37.0 + _random.nextDouble() * 0.5;
    }

    return {
      'heartRate': heartRate,
      'spo2': spo2,
      'timestamp': DateTime.now(),
      'temperature': temperature,
      'movement': isApnea
          ? 0.05 + _random.nextDouble() * 0.1
          : 0.10 + _random.nextDouble() * 0.3,
      '_simPhase': isApnea ? 'apnea' : 'normal',
      '_simProgress': progress,
    };
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  bool get isMonitoring => _timer != null;

  void dispose() {
    stopMonitoring();
    if (!_controller.isClosed) _controller.close();
  }
}
