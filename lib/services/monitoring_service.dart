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
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _controller.add({
        'heartRate': 60 + _random.nextInt(41),
        'spo2': 95 + _random.nextInt(5),
        'timestamp': DateTime.now(),
      });
    });
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stopMonitoring();
    _controller.close();
  }
}
