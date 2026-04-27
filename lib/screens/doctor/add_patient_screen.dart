import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'package:apnea_project/models/patient.dart';
import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/services/firebase_service.dart';

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();

  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime? _dateNaissance;
  String? _sexe;
  bool _manualId = false;
  bool _isSaving = false;
  bool _isFormValid = false;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _idController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 30),
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        _dateNaissance = picked;
      });
      _onFormChanged();
    }
  }

  int _computeAge(DateTime dob) {
    final now = DateTime.now();
    var age = now.year - dob.year;
    final hasBirthdayPassed =
        (now.month > dob.month) ||
        (now.month == dob.month && now.day >= dob.day);
    if (!hasBirthdayPassed) {
      age -= 1;
    }
    return age;
  }

  String? _validateRequired(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label est obligatoire.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Format email invalide.';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final phoneRegex = RegExp(r'^[0-9+\s()-]{8,20}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Numéro de téléphone invalide.';
    }
    return null;
  }

  void _onFormChanged() {
    final formValid = _formKey.currentState?.validate() ?? false;
    final dateValid = _dateNaissance != null;
    final sexeValid = _sexe != null && _sexe!.isNotEmpty;
    final finalValid = formValid && dateValid && sexeValid;

    if (finalValid != _isFormValid) {
      setState(() {
        _isFormValid = finalValid;
      });
    }
  }

  Future<void> _savePatient() async {
    FocusScope.of(context).unfocus();
    _onFormChanged();
    if (!_isFormValid || _dateNaissance == null || _sexe == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez corriger les champs invalides.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final doctorUid = context.read<AuthProvider>().user?.uid;
    if (doctorUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expirée. Reconnectez-vous.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final generatedId = _firebaseService.newDocumentId('users');
      final patientId = _manualId ? _idController.text.trim() : generatedId;

      final patient = Patient(
        id: patientId,
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        age: _computeAge(_dateNaissance!),
        sexe: _sexe!,
        dateNaissance: _dateNaissance,
        telephone: _telephoneController.text.trim().isEmpty
            ? null
            : _telephoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        notesMedicales: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        doctorUid: doctorUid,
      );

      await _firebaseService.addPatient(patient);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient ajouté avec succès.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } on FirebaseException catch (e) {
      if (!mounted) return;
      final message = switch (e.code) {
        'permission-denied' =>
          'Permission refusée: vérifiez les règles Firestore et votre session.',
        'already-exists' => 'Un patient avec cet identifiant existe déjà.',
        _ => 'Échec de sauvegarde: ${e.message ?? e.code}',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Échec de sauvegarde: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ageText = _dateNaissance == null
        ? '-'
        : _computeAge(_dateNaissance!).toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter patient')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: _onFormChanged,
          child: Column(
            children: [
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom *',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (v) => _validateRequired(v, 'Nom'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _prenomController,
                decoration: const InputDecoration(
                  labelText: 'Prénom *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => _validateRequired(v, 'Prénom'),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickBirthDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date de naissance *',
                    prefixIcon: const Icon(Icons.calendar_month_outlined),
                    errorText: _dateNaissance == null
                        ? 'Date de naissance obligatoire.'
                        : null,
                  ),
                  child: Text(
                    _dateNaissance == null
                        ? 'Sélectionner une date'
                        : '${_dateNaissance!.day.toString().padLeft(2, '0')}/${_dateNaissance!.month.toString().padLeft(2, '0')}/${_dateNaissance!.year}',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Âge',
                  prefixIcon: Icon(Icons.cake_outlined),
                ),
                controller: TextEditingController(text: ageText),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Sexe *',
                  prefixIcon: Icon(Icons.wc_outlined),
                ),
                initialValue: _sexe,
                items: const [
                  DropdownMenuItem(value: 'Homme', child: Text('Homme')),
                  DropdownMenuItem(value: 'Femme', child: Text('Femme')),
                  DropdownMenuItem(value: 'Autre', child: Text('Autre')),
                ],
                onChanged: (v) {
                  setState(() => _sexe = v);
                  _onFormChanged();
                },
                validator: (v) =>
                    v == null || v.isEmpty ? 'Sexe est obligatoire.' : null,
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                value: _manualId,
                title: const Text('Saisir l\'identifiant patient manuellement'),
                onChanged: (v) {
                  setState(() {
                    _manualId = v;
                    if (!v) {
                      _idController.clear();
                    }
                  });
                  _onFormChanged();
                },
              ),
              if (_manualId) ...[
                TextFormField(
                  controller: _idController,
                  decoration: const InputDecoration(
                    labelText: 'Identifiant patient *',
                    prefixIcon: Icon(Icons.perm_identity_outlined),
                  ),
                  validator: (v) {
                    if (!_manualId) return null;
                    return _validateRequired(v, 'Identifiant patient');
                  },
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _telephoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                validator: _validatePhone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notes médicales',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: (_isSaving || !_isFormValid) ? null : _savePatient,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
