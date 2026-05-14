import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:provider/provider.dart';

import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/providers/user_profile_provider.dart';
import 'package:apnea_project/screens/doctor/add_patient_screen.dart';
import 'package:apnea_project/services/user_service.dart';
import 'package:apnea_project/services/measurement_service.dart';
import 'package:apnea_project/widgets/chatbot_fab.dart';
import 'package:apnea_project/widgets/doctor_bottom_navigation_bar.dart';
import 'package:apnea_project/theme/app_colors.dart';

class DoctorPatientsListScreen extends StatefulWidget {
  const DoctorPatientsListScreen({super.key});

  @override
  State<DoctorPatientsListScreen> createState() =>
      _DoctorPatientsListScreenState();
}

class _DoctorPatientsListScreenState extends State<DoctorPatientsListScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'Tous';

  /// Détermine le statut d'un patient basé sur la dernière mesure
  String _getPatientStatus(DateTime? lastMeasurement) {
    if (lastMeasurement == null) {
      return 'Inactif';
    }

    final daysSinceLastMeasurement =
        DateTime.now().difference(lastMeasurement).inDays;

    if (daysSinceLastMeasurement <= 1) {
      return 'Actif';
    } else if (daysSinceLastMeasurement <= 7) {
      return 'Actif';
    } else {
      return 'Inactif';
    }
  }

  /// Filtre les patients selon la recherche et le filtre sélectionné
  List<Map<String, dynamic>> _filterPatients(
    List<Map<String, dynamic>> patients,
    Map<String, DateTime?> patientLastMeasurements,
  ) {
    return patients.where((patient) {
      final name = (patient['fullName'] as String?)?.toLowerCase() ?? '';
      final patientUid = patient['uid'] as String? ?? '';

      // Filtre par recherche (nom)
      final matchesSearch =
          _searchQuery.isEmpty || name.contains(_searchQuery.toLowerCase());

      // Filtre par statut
      final status = _getPatientStatus(patientLastMeasurements[patientUid]);
      final matchesFilter =
          _selectedFilter == 'Tous' || status == _selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  /// Collecte les dernières mesures de tous les patients
  Future<Map<String, DateTime?>> _getLastMeasurementsForPatients(
    List<Map<String, dynamic>> patients,
    MeasurementService measurementService,
  ) async {
    final measurements = <String, DateTime?>{};

    for (final patient in patients) {
      final patientUid = patient['uid'] as String? ?? '';
      if (patientUid.isNotEmpty) {
        try {
          final lastMeasurement = await measurementService
              .getPatientLastMeasurementTimestamp(patientUid);
          measurements[patientUid] = lastMeasurement;
        } catch (e) {
          measurements[patientUid] = null;
        }
      }
    }

    return measurements;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final doctorProfile = useDoctorProfile(context);
    final photoUrl = doctorProfile?.profileImageUrl;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mes Patients')),
        body: const Center(
          child: Text('Session expirée. Veuillez vous reconnecter.'),
        ),
      );
    }

    final userService = UserService();
    final measurementService = MeasurementService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Patients'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              onTap: () => context.push(RouteNames.doctorProfile),
              borderRadius: BorderRadius.circular(20),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white24,
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                    ? NetworkImage(photoUrl)
                    : null,
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? const Icon(Icons.person, size: 18, color: Colors.white)
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Rechercher par nom...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: DropdownButton<String>(
                value: _selectedFilter,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedFilter = newValue ?? 'Tous';
                  });
                },
                items: <String>['Tous', 'Actif', 'Inactif']
                    .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text('Filtre: $value'),
                      );
                    })
                    .toList(),
              ),
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: userService.streamDoctorPatients(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Erreur chargement patients.',
                      style: TextStyle(color: AppColors.error),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  );
                }

                final allPatients = snapshot.data ?? <Map<String, dynamic>>[];
                if (allPatients.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Aucun patient assigné pour le moment.'),
                  );
                }

                // Charger les dernières mesures pour tous les patients
                return FutureBuilder<Map<String, DateTime?>>(
                  future: _getLastMeasurementsForPatients(
                    allPatients,
                    measurementService,
                  ),
                  builder: (context, measurementsSnapshot) {
                    if (!measurementsSnapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      );
                    }

                    final patientMeasurements = measurementsSnapshot.data ?? {};
                    final filteredPatients =
                        _filterPatients(allPatients, patientMeasurements);

                    if (filteredPatients.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'Aucun patient avec le statut "$_selectedFilter".'
                              : 'Aucun patient trouvé pour "$_searchQuery".',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: filteredPatients.map((patient) {
                        final patientUid = patient['uid'] as String? ?? '';
                        final fullName =
                            (patient['fullName'] as String?)?.trim().isNotEmpty ==
                                true
                            ? patient['fullName'] as String
                            : 'Patient';
                        final lastMeasurement = patientMeasurements[patientUid];
                        final status = _getPatientStatus(lastMeasurement);
                        final lastDateLabel = lastMeasurement == null
                            ? 'Aucune donnée'
                            : '${lastMeasurement.day.toString().padLeft(2, '0')}/${lastMeasurement.month.toString().padLeft(2, '0')}';

                        return _buildPatientEntry(
                          context,
                          patientId: patientUid,
                          name: fullName,
                          status: status,
                          lastData: lastDateLabel,
                          apneas: '--',
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const AddPatientScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Ajouter patient'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: const DoctorChatbotFAB(),
      bottomNavigationBar: const DoctorBottomNavigationBar(currentIndex: 1),
    );
  }

  Widget _buildPatientEntry(
    BuildContext context, {
    required String patientId,
    required String name,
    required String status,
    required String lastData,
    required String apneas,
  }) {
    // Déterminer la couleur et l'icône basées sur le statut
    Color statusColor = AppColors.success;
    IconData statusIcon = Icons.check_circle;

    switch (status) {
      case 'Actif':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        break;
      case 'Inactif':
        statusColor = AppColors.warning;
        statusIcon = Icons.schedule;
        break;
      case 'En alerte':
        statusColor = AppColors.error;
        statusIcon = Icons.warning_amber_rounded;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(statusIcon, size: 16, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  'Statut: $status',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Dernière donnée: $lastData', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 2),
            Text('Apnées (7j): $apneas', style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          final encodedPatientId = Uri.encodeComponent(patientId);
          context.push(RouteNames.doctorPatientProfile(encodedPatientId));
        },
      ),
    );
  }
}
