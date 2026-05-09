class ApneaEvent {
  const ApneaEvent({
    required this.id,
    required this.patientUid,
    required this.startTime,
    required this.endTime,
    this.duration,
    this.type,
    this.severity,
    this.spo2Drop,
    this.respiratoryRate,
    this.notes,
    this.sessionId,
  });

  final String id;
  final String patientUid;
  final DateTime startTime;
  final DateTime endTime;
  final int? duration;
  final String? type;
  final String? severity;
  final double? spo2Drop;
  final int? respiratoryRate;
  final String? notes;
  final String? sessionId;

  int get durationInSeconds =>
      duration ?? endTime.difference(startTime).inSeconds;

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'patientUid': patientUid,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'duration': durationInSeconds,
      'type': type,
      'severity': severity,
      'spo2Drop': spo2Drop,
      'respiratoryRate': respiratoryRate,
      'notes': notes,
      'sessionId': sessionId,
    };
  }

  factory ApneaEvent.fromFirestore(Map<String, dynamic> data, String id) {
    return ApneaEvent(
      id: id,
      patientUid: data['patientUid'] as String? ?? '',
      startTime: data['startTime'] != null
          ? DateTime.parse(data['startTime'] as String)
          : DateTime.now(),
      endTime: data['endTime'] != null
          ? DateTime.parse(data['endTime'] as String)
          : DateTime.now(),
      duration: data['duration'] as int?,
      type: data['type'] as String?,
      severity: data['severity'] as String?,
      spo2Drop: (data['spo2Drop'] as num?)?.toDouble(),
      respiratoryRate: data['respiratoryRate'] as int?,
      notes: data['notes'] as String?,
      sessionId: data['sessionId'] as String?,
    );
  }
}
