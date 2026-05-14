import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:apnea_project/providers/user_profile_provider.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/theme/app_colors.dart';
import 'package:apnea_project/widgets/chatbot_fab.dart';

class DoctorProfileScreen extends StatelessWidget {
  const DoctorProfileScreen({super.key});

  Future<void> _openEditDoctorProfileDialog(
    BuildContext context,
    UserProfileProvider doctorProfile,
  ) async {
    final nameController = TextEditingController(text: doctorProfile.fullName);
    final phoneController = TextEditingController(text: doctorProfile.phone);
    final imageController = TextEditingController(
      text: doctorProfile.profileImageUrl ?? '',
    );
    final specializationController = TextEditingController(
      text: doctorProfile.specialization,
    );
    final licenseController = TextEditingController(
      text: doctorProfile.medicalLicenseNumber,
    );
    final experienceController = TextEditingController(
      text: doctorProfile.yearsOfExperience,
    );
    final clinicController = TextEditingController(
      text: doctorProfile.clinicName,
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Modifier profil médecin'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom complet'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Téléphone'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: specializationController,
                  decoration: const InputDecoration(
                    labelText: 'Spécialisation',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: licenseController,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de licence médicale',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: experienceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Années d\'expérience',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: clinicController,
                  decoration: const InputDecoration(
                    labelText: 'Clinique / Hôpital',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: imageController,
                  decoration: const InputDecoration(
                    labelText: 'Photo de profil (URL)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final image = imageController.text.trim();
                await doctorProfile.updateProfile({
                  'fullName': nameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'specialization': specializationController.text.trim(),
                  'medicalLicenseNumber': licenseController.text.trim(),
                  'yearsOfExperience': experienceController.text.trim(),
                  'clinicName': clinicController.text.trim(),
                  'profileImageUrl': image.isEmpty ? null : image,
                });

                if (!dialogContext.mounted) {
                  return;
                }
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profil médecin mis à jour.')),
                );
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
    imageController.dispose();
    specializationController.dispose();
    licenseController.dispose();
    experienceController.dispose();
    clinicController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctorProfile = useDoctorProfile(context);
    if (doctorProfile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil Médecin')),
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.go(RouteNames.accessDenied),
            child: const Text('Accès refusé'),
          ),
        ),
      );
    }

    final doctor = doctorProfile.user;
    final fullName = doctorProfile.fullName;
    final email = doctorProfile.email;
    final phone = doctorProfile.phone;
    final specialization = doctorProfile.specialization;
    final licenseNumber = doctorProfile.medicalLicenseNumber;
    final yearsOfExperience = doctorProfile.yearsOfExperience;
    final clinicName = doctorProfile.clinicName;
    final photoUrl = doctorProfile.profileImageUrl;
    final dateOfBirth = (doctor?['dateOfBirth'] as String?) ?? 'Non renseigné';
    final gender = (doctor?['gender'] as String?) ?? 'Non renseigné';

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Médecin')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                        ? NetworkImage(photoUrl)
                        : null,
                    child: (photoUrl == null || photoUrl.isEmpty)
                        ? const Icon(
                            Icons.local_hospital,
                            size: 56,
                            color: AppColors.primary,
                          )
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Text(
                    'Médecin / Doctor',
                    style: TextStyle(fontSize: 16, color: AppColors.textMedium),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📧 $email', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 5),
                    Text('📱 $phone', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 5),
                    Text(
                      '🩺 $specialization',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '🪪 Licence: $licenseNumber',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '⏳ Expérience: $yearsOfExperience ans',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '🏥 $clinicName',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '🎂 $dateOfBirth',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 5),
                    Text('⚥ $gender', style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  _openEditDoctorProfileDialog(context, doctorProfile);
                },
                icon: const Icon(Icons.edit),
                label: const Text('Modifier profil médecin'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(240, 50),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: const DoctorChatbotFAB(),
    );
  }
}
