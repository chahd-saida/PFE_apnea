class Doctor {
  const Doctor({
    required this.id,
    required this.fullName,
    required this.email,
    this.specialization,
    this.medicalLicenseNumber,
    this.yearsOfExperience,
    this.clinicName,
    this.phone,
    this.profileImageUrl,
    this.bio,
    this.createdAt,
  });

  final String id;
  final String fullName;
  final String email;
  final String? specialization;
  final String? medicalLicenseNumber;
  final int? yearsOfExperience;
  final String? clinicName;
  final String? phone;
  final String? profileImageUrl;
  final String? bio;
  final DateTime? createdAt;

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'fullName': fullName,
      'email': email,
      'specialization': specialization,
      'medicalLicenseNumber': medicalLicenseNumber,
      'yearsOfExperience': yearsOfExperience,
      'clinicName': clinicName,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'role': 'doctor',
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory Doctor.fromFirestore(Map<String, dynamic> data, String id) {
    return Doctor(
      id: id,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      specialization: data['specialization'] as String?,
      medicalLicenseNumber: data['medicalLicenseNumber'] as String?,
      yearsOfExperience: data['yearsOfExperience'] as int?,
      clinicName: data['clinicName'] as String?,
      phone: data['phone'] as String?,
      profileImageUrl: data['profileImageUrl'] as String?,
      bio: data['bio'] as String?,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : null,
    );
  }
}
