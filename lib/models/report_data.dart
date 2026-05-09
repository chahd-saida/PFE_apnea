class ReportData {
  const ReportData({
    required this.doctorName,
    required this.generatedAt,
    this.patientId,
    this.patientFullName,
    this.patientAge,
    this.patientGender,
    this.patientMedicalId,
    this.startDate,
    this.endDate,
    this.averageSpo2,
    this.averageHeartRate,
    this.totalApneas,
    this.totalSessions,
    this.measurements = const <Map<String, dynamic>>[],
    this.notes = const <Map<String, dynamic>>[],
    this.includeClinicalData = true,
    this.includeSignalGraphs = true,
    this.includeApneaEvents = true,
    this.includeDoctorDiagnosis = true,
    this.includeRecommendations = true,
  });

  final String doctorName;
  final DateTime generatedAt;
  final String? patientId;
  final String? patientFullName;
  final int? patientAge;
  final String? patientGender;
  final String? patientMedicalId;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? averageSpo2;
  final double? averageHeartRate;
  final int? totalApneas;
  final int? totalSessions;
  final List<Map<String, dynamic>> measurements;
  final List<Map<String, dynamic>> notes;
  final bool includeClinicalData;
  final bool includeSignalGraphs;
  final bool includeApneaEvents;
  final bool includeDoctorDiagnosis;
  final bool includeRecommendations;
}
