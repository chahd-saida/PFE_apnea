import 'dart:async';
import 'dart:math';

class MonitoringService {
  final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();
  final Random _random = Random();
  Timer? _timer;

  Stream<Map<String, dynamic>> get stream => _controller.stream;

  void startMonitoring() {
    stopMonitoring();

    // TODO(integration): Replace mock timer emission with real BLE/SDK sensor stream.
    // Connect to ESP32 via flutter_blue_plus package:
    // 1. Scan for device with service UUID
    // 2. Connect and discover characteristics
    // 3. Subscribe to notifications from HR, SpO2, and motion characteristics
    // 4. Parse received byte arrays into { heartRate, spo2, timestamp }
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_controller.isClosed) return;
      _controller.add({
        'heartRate': 60 + _random.nextInt(41),
        'spo2': 95 + _random.nextInt(5),
        'timestamp': DateTime.now(),
        'temperature': 36.0 + (_random.nextDouble() * 1.5),
        'movement': _random.nextDouble(),
      });
    });
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  bool get isMonitoring => _timer != null;

  void dispose() {
    stopMonitoring();
    if (!_controller.isClosed) {
      _controller.close();
    }
  }
}