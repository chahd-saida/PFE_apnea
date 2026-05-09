class SleepSession {
  const SleepSession({
    required this.id,
    required this.patientUid,
    required this.startTime,
    required this.endTime,
    this.duration,
    this.totalApneaEvents,
    this.averageSpo2,
    this.lowestSpo2,
    this.averageHeartRate,
    this.sleepQuality,
    this.notes,
    this.deviceId,
  });

  final String id;
  final String patientUid;
  final DateTime startTime;
  final DateTime endTime;
  final int? duration;
  final int? totalApneaEvents;
  final double? averageSpo2;
  final double? lowestSpo2;
  final int? averageHeartRate;
  final String? sleepQuality;
  final String? notes;
  final String? deviceId;

  int get durationInMinutes =>
      duration ?? endTime.difference(startTime).inMinutes;

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'patientUid': patientUid,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'duration': durationInMinutes,
      'totalApneaEvents': totalApneaEvents,
      'averageSpo2': averageSpo2,
      'lowestSpo2': lowestSpo2,
      'averageHeartRate': averageHeartRate,
      'sleepQuality': sleepQuality,
      'notes': notes,
      'deviceId': deviceId,
    };
  }

  factory SleepSession.fromFirestore(Map<String, dynamic> data, String id) {
    return SleepSession(
      id: id,
      patientUid: data['patientUid'] as String? ?? '',
      startTime: data['startTime'] != null
          ? DateTime.parse(data['startTime'] as String)
          : DateTime.now(),
      endTime: data['endTime'] != null
          ? DateTime.parse(data['endTime'] as String)
          : DateTime.now(),
      duration: data['duration'] as int?,
      totalApneaEvents: data['totalApneaEvents'] as int?,
      averageSpo2: (data['averageSpo2'] as num?)?.toDouble(),
      lowestSpo2: (data['lowestSpo2'] as num?)?.toDouble(),
      averageHeartRate: data['averageHeartRate'] as int?,
      sleepQuality: data['sleepQuality'] as String?,
      notes: data['notes'] as String?,
      deviceId: data['deviceId'] as String?,
    );
  }
}
