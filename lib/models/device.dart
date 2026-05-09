class Device {
  const Device({
    required this.id,
    required this.patientUid,
    required this.deviceName,
    required this.deviceType,
    this.serialNumber,
    this.manufacturer,
    this.firmwareVersion,
    this.batteryLevel,
    this.isActive = true,
    this.pairedAt,
    this.lastSyncTime,
  });

  final String id;
  final String patientUid;
  final String deviceName;
  final String deviceType;
  final String? serialNumber;
  final String? manufacturer;
  final String? firmwareVersion;
  final double? batteryLevel;
  final bool isActive;
  final DateTime? pairedAt;
  final DateTime? lastSyncTime;

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'patientUid': patientUid,
      'deviceName': deviceName,
      'deviceType': deviceType,
      'serialNumber': serialNumber,
      'manufacturer': manufacturer,
      'firmwareVersion': firmwareVersion,
      'batteryLevel': batteryLevel,
      'isActive': isActive,
      'pairedAt': pairedAt?.toIso8601String(),
      'lastSyncTime': lastSyncTime?.toIso8601String(),
    };
  }

  factory Device.fromFirestore(Map<String, dynamic> data, String id) {
    return Device(
      id: id,
      patientUid: data['patientUid'] as String? ?? '',
      deviceName: data['deviceName'] as String? ?? '',
      deviceType: data['deviceType'] as String? ?? '',
      serialNumber: data['serialNumber'] as String?,
      manufacturer: data['manufacturer'] as String?,
      firmwareVersion: data['firmwareVersion'] as String?,
      batteryLevel: (data['batteryLevel'] as num?)?.toDouble(),
      isActive: data['isActive'] as bool? ?? true,
      pairedAt: data['pairedAt'] != null
          ? DateTime.parse(data['pairedAt'] as String)
          : null,
      lastSyncTime: data['lastSyncTime'] != null
          ? DateTime.parse(data['lastSyncTime'] as String)
          : null,
    );
  }
}
