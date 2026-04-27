class Patient {
  const Patient({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.age,
    required this.sexe,
    this.dateNaissance,
    this.telephone,
    this.email,
    this.notesMedicales,
    this.doctorUid,
  });

  final String id;
  final String nom;
  final String prenom;
  final int age;
  final String sexe;
  final DateTime? dateNaissance;
  final String? telephone;
  final String? email;
  final String? notesMedicales;
  final String? doctorUid;

  String get fullName => '$prenom $nom'.trim();

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'firstName': prenom,
      'lastName': nom,
      'fullName': fullName,
      'age': age,
      'dateOfBirth': dateNaissance?.toIso8601String(),
      'gender': sexe,
      'phone': telephone,
      'email': email,
      'medicalNotes': notesMedicales,
      'role': 'patient',
      'doctorUid': doctorUid,
      'createdAt': DateTime.now(),
    };
  }
}
