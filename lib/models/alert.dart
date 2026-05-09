class Alert {
  const Alert({
    required this.id,
    required this.patientUid,
    required this.alertType,
    required this.severity,
    required this.createdAt,
    this.doctorUid,
    this.title,
    this.description,
    this.isRead = false,
    this.isResolved = false,
    this.measurement,
    this.resolvedAt,
  });

  final String id;
  final String patientUid;
  final String alertType;
  final String severity;
  final DateTime createdAt;
  final String? doctorUid;
  final String? title;
  final String? description;
  final bool isRead;
  final bool isResolved;
  final Map<String, dynamic>? measurement;
  final DateTime? resolvedAt;

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'patientUid': patientUid,
      'alertType': alertType,
      'severity': severity,
      'createdAt': createdAt.toIso8601String(),
      'doctorUid': doctorUid,
      'title': title,
      'description': description,
      'isRead': isRead,
      'isResolved': isResolved,
      'measurement': measurement,
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }

  factory Alert.fromFirestore(Map<String, dynamic> data, String id) {
    return Alert(
      id: id,
      patientUid: data['patientUid'] as String? ?? '',
      alertType: data['alertType'] as String? ?? '',
      severity: data['severity'] as String? ?? 'info',
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : DateTime.now(),
      doctorUid: data['doctorUid'] as String?,
      title: data['title'] as String?,
      description: data['description'] as String?,
      isRead: data['isRead'] as bool? ?? false,
      isResolved: data['isResolved'] as bool? ?? false,
      measurement: data['measurement'] as Map<String, dynamic>?,
      resolvedAt: data['resolvedAt'] != null
          ? DateTime.parse(data['resolvedAt'] as String)
          : null,
    );
  }
}
