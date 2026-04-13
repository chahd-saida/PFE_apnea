import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:apnea_project/providers/user_profile_provider.dart';
import 'package:apnea_project/services/firebase_service.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();

  bool _initialized = false;
  bool _isSaving = false;
  bool _isLoadingDoctors = false;

  String? _selectedDoctorUid;
  String? _selectedDoctorName;
  String? _errorMessage;

  List<Map<String, dynamic>> _doctorOptions = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final userProfile = context.read<UserProfileProvider>();
      userProfile.refreshProfile();
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dateOfBirthController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  void _hydrateFromProfile(UserProfileProvider userProfile) {
    final user = userProfile.user;
    _fullNameController.text = userProfile.fullName;
    _emailController.text = userProfile.email;
    _phoneController.text = userProfile.phone;
    _dateOfBirthController.text = _formatDateValue(user?['dateOfBirth']);
    _genderController.text = (user?['gender'] as String?)?.trim() ?? '';
    _selectedDoctorUid = userProfile.doctorUid;
    _selectedDoctorName = userProfile.doctorName;

    setState(() {
      _initialized = true;
    });
  }

  String _formatDateValue(dynamic value) {
    if (value is String) {
      return value.trim();
    }
    DateTime? resolved;
    if (value is Timestamp) {
      resolved = value.toDate();
    } else if (value is DateTime) {
      resolved = value;
    }
    if (resolved == null) {
      return '';
    }
    final year = resolved.year.toString().padLeft(4, '0');
    final month = resolved.month.toString().padLeft(2, '0');
    final day = resolved.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _ensureDoctorsLoaded() async {
    if (_doctorOptions.isNotEmpty || _isLoadingDoctors) {
      return;
    }

    setState(() {
      _isLoadingDoctors = true;
    });

    final doctors = await _firebaseService.getDoctors();
    if (!mounted) {
      return;
    }

    setState(() {
      _doctorOptions = doctors;
      _isLoadingDoctors = false;
    });
  }

  Future<void> _openDoctorSelection() async {
    await _ensureDoctorsLoaded();
    if (!mounted) {
      return;
    }

    if (_doctorOptions.isEmpty) {
      setState(() {
        _errorMessage = 'Aucun médecin disponible pour le moment.';
      });
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        String query = '';
        List<Map<String, dynamic>> filtered = List.from(_doctorOptions);

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Sélectionner un médecin',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Rechercher',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setModalState(() {
                        query = value.trim().toLowerCase();
                        filtered = _doctorOptions.where((doctor) {
                          final name = doctor['fullName'];
                          if (name is String) {
                            return name.toLowerCase().contains(query);
                          }
                          return false;
                        }).toList();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final doctor = filtered[index];
                        final name =
                            (doctor['fullName'] as String?)
                                    ?.trim()
                                    .isNotEmpty ==
                                true
                            ? doctor['fullName'] as String
                            : 'Médecin';
                        final clinic =
                            (doctor['clinicName'] as String?)
                                    ?.trim()
                                    .isNotEmpty ==
                                true
                            ? doctor['clinicName'] as String
                            : null;

                        return ListTile(
                          title: Text(name),
                          subtitle: clinic != null ? Text(clinic) : null,
                          onTap: () {
                            setState(() {
                              _selectedDoctorUid = doctor['uid'] as String?;
                              _selectedDoctorName = name;
                            });
                            Navigator.of(sheetContext).pop();
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleSave(UserProfileProvider userProfile) async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final updates = <String, dynamic>{
      'fullName': _fullNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'dateOfBirth': _dateOfBirthController.text.trim(),
      'gender': _genderController.text.trim(),
    };

    if (_selectedDoctorUid != null && _selectedDoctorUid!.isNotEmpty) {
      updates['doctorUid'] = _selectedDoctorUid;
      updates['doctorName'] = _selectedDoctorName;
    }

    try {
      await userProfile.updateProfile(updates);

      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour avec succès.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _errorMessage = 'Erreur lors de la mise à jour: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = useUser(context);
    final user = userProfile.user;
    final fullName = userProfile.fullName;
    final roleLabel = userProfile.role == 'doctor' ? 'Médecin' : 'Patient';
    final photoUrl = userProfile.profileImageUrl;
    final doctorName = _selectedDoctorName ?? userProfile.doctorName;

    if (!_initialized && userProfile.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil Utilisateur')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_initialized && userProfile.lastError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil Utilisateur')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(userProfile.lastError ?? 'Erreur chargement profil.'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => userProfile.refreshProfile(),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_initialized && user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _hydrateFromProfile(userProfile);
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Utilisateur')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue.shade100,
                    backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                        ? NetworkImage(photoUrl)
                        : null,
                    child: (photoUrl == null || photoUrl.isEmpty)
                        ? const Icon(Icons.person, size: 60, color: Colors.blue)
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    roleLabel,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom complet',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Téléphone'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _dateOfBirthController,
                      decoration: const InputDecoration(
                        labelText: 'Date de naissance',
                        hintText: 'YYYY-MM-DD',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _genderController,
                      decoration: const InputDecoration(labelText: 'Genre'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🏥 Médecin traitant :',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            doctorName ?? 'Non renseigné',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoadingDoctors
                          ? null
                          : _openDoctorSelection,
                      child: Text(
                        _isLoadingDoctors
                            ? 'Chargement...'
                            : 'Modifier médecin',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : () => _handleSave(userProfile),
                icon: const Icon(Icons.save),
                label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
