class Measurement {
  const Measurement({
    required this.id,
    required this.patientUid,
    required this.timestamp,
    this.spo2,
    this.heartRate,
    this.temperature,
    this.respiratoryRate,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.notes,
    this.deviceId,
  });

  final String id;
  final String patientUid;
  final DateTime timestamp;
  final double? spo2;
  final int? heartRate;
  final double? temperature;
  final int? respiratoryRate;
  final int? bloodPressureSystolic;
  final int? bloodPressureDiastolic;
  final String? notes;
  final String? deviceId;

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'patientUid': patientUid,
      'timestamp': timestamp.toIso8601String(),
      'spo2': spo2,
      'heartRate': heartRate,
      'temperature': temperature,
      'respiratoryRate': respiratoryRate,
      'bloodPressureSystolic': bloodPressureSystolic,
      'bloodPressureDiastolic': bloodPressureDiastolic,
      'notes': notes,
      'deviceId': deviceId,
    };
  }

  factory Measurement.fromFirestore(Map<String, dynamic> data, String id) {
    return Measurement(
      id: id,
      patientUid: data['patientUid'] as String? ?? '',
      timestamp: data['timestamp'] != null
          ? DateTime.parse(data['timestamp'] as String)
          : DateTime.now(),
      spo2: (data['spo2'] as num?)?.toDouble(),
      heartRate: data['heartRate'] as int?,
      temperature: (data['temperature'] as num?)?.toDouble(),
      respiratoryRate: data['respiratoryRate'] as int?,
      bloodPressureSystolic: data['bloodPressureSystolic'] as int?,
      bloodPressureDiastolic: data['bloodPressureDiastolic'] as int?,
      notes: data['notes'] as String?,
      deviceId: data['deviceId'] as String?,
    );
  }
}
