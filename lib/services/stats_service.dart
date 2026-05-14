class StatsService {
  StatsService();

  // ========== STATISTICS ==========

  Future<Map<String, dynamic>> getPatientStats(
    String uid, {
    required Future<List<Map<String, dynamic>>> Function({
      required String uid,
      int limit,
    })
    getMeasurementRecords,
  }) async {
    final records = await getMeasurementRecords(uid: uid, limit: 30);
    if (records.isEmpty) {
      return {
        'totalSessions': 0,
        'avgScore': 0,
        'avgSpo2': 0,
        'avgHeartRate': 0,
        'totalApneas': 0,
        'lastSession': null,
      };
    }

    double totalScore = 0;
    double totalSpo2 = 0;
    double totalHR = 0;
    int totalApneas = 0;

    for (final r in records) {
      totalScore += (r['score'] as num?)?.toDouble() ?? 0;
      totalSpo2 += (r['avgSpo2'] ?? r['spo2'] as num?)?.toDouble() ?? 0;
      totalHR += (r['avgHeartRate'] ?? r['heartRate'] as num?)?.toDouble() ?? 0;
      totalApneas += (r['apneas'] as num?)?.toInt() ?? 0;
    }

    final count = records.length;
    return {
      'totalSessions': count,
      'avgScore': (totalScore / count).round(),
      'avgSpo2': (totalSpo2 / count).toStringAsFixed(1),
      'avgHeartRate': (totalHR / count).round(),
      'totalApneas': totalApneas,
      'lastSession': records.first['timestamp'],
    };
  }
}
