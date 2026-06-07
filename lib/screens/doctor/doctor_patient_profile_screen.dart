import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/theme/app_colors.dart';
import 'package:apnea_project/widgets/chatbot_fab.dart';

/// Ecran affichant le profil complet d'un patient
/// Affiche: infos personnelles, medicales, statistiques, historique des nuits
class DoctorPatientProfileScreen extends StatelessWidget {
  const DoctorPatientProfileScreen({super.key, required this.patientId});

  /// ID du patient (URL-encode) dont on affiche le profil
  final String patientId;

  /// Recupere le nom du medecin assigne
  /// Cherche dans differents champs possibles de Firestore
  String _resolveDoctorName(Map<String, dynamic> data) {
    /// Cherche dans tous les champs possibles
    for (final key in ['doctorName', 'assignedDoctorName', 'doctorFullName']) {
      final v = data[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    // Si doctorUid présent mais pas le nom → afficher l'uid tronqué
    final uid = data['doctorUid'] as String?;
    if (uid != null && uid.isNotEmpty) {
      return 'Médecin (${uid.substring(0, 6)}...)';
    }
    return 'Non assigné';
  }

  /// Formate un timestamp en JJ/MM/YYYY
  /// Gere: Firestore Timestamp, DateTime natif, String ISO 8601
  String _formatDate(dynamic value) {
    DateTime? date;
    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = DateTime.tryParse(value);
    }

    if (date == null) {
      return 'Date inconnue';
    }
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  /// Formate un timestamp en JJ/MM/YYYY HH:MM
  /// Gere: Firestore Timestamp, DateTime natif, String ISO 8601
  String _formatDateTime(dynamic value) {
    DateTime? date;
    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = DateTime.tryParse(value);
    }

    if (date == null) {
      return 'Date inconnue';
    }
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} à $hour:$minute';
  }

  /// Calcule l'age du patient a partir de sa date de naissance
  /// Retourne null si la date est invalide
  int? _computeAge(dynamic rawDob) {
    DateTime? dob;
    if (rawDob is Timestamp) {
      dob = rawDob.toDate();
    } else if (rawDob is DateTime) {
      dob = rawDob;
    } else if (rawDob is String) {
      dob = DateTime.tryParse(rawDob);
    }
    if (dob == null) {
      return null;
    }

    final now = DateTime.now();
    var age = now.year - dob.year;
    final hadBirthday =
        now.month > dob.month || (now.month == dob.month && now.day >= dob.day);
    if (!hadBirthday) {
      age -= 1;
    }
    return age;
  }

  /// Determine le statut du patient (Actif/Inactif) selon la derniere mesure
  /// Retourne textes comme "Actif (Aujourd'hui)" | "Actif (Hier)" | "Inactif"
  String _getStatusBadge(dynamic lastMeasurement) {
    if (lastMeasurement == null) {
      return 'Pas de données';
    }

    DateTime? lastDate;
    if (lastMeasurement is Timestamp) {
      lastDate = lastMeasurement.toDate();
    } else if (lastMeasurement is DateTime) {
      lastDate = lastMeasurement;
    }

    if (lastDate == null) {
      return 'Pas de données';
    }

    final now = DateTime.now();
    final diff = now.difference(lastDate);

    if (diff.inDays == 0) {
      return 'Actif (Aujourd\'hui)';
    } else if (diff.inDays == 1) {
      return 'Actif (Hier)';
    } else if (diff.inDays <= 7) {
      return 'Actif (${diff.inDays} j)';
    } else {
      return 'Inactif (${diff.inDays} j)';
    }
  }

  /// Construit l'interface du profil patient
  /// Affiche: header + infos contact/personnelles + stats + historique
  @override
  Widget build(BuildContext context) {
    /// Streams Firestore pour charger les donnees en temps reel
    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(patientId)
        .snapshots();

    final nightsQuery = FirebaseFirestore.instance
        .collection('measurements')
        .where('uid', isEqualTo: patientId)
        .limit(10)
        .snapshots();

    final statsQuery = FirebaseFirestore.instance
        .collection('measurements')
        .where('uid', isEqualTo: patientId)
        .snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userDoc,
      builder: (context, userSnapshot) {
        if (userSnapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profil Patient')),
            body: const Center(
              child: Text('Erreur chargement profil patient.'),
            ),
            floatingActionButton: const DoctorChatbotFAB(),
          );
        }
        if (!userSnapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profil Patient')),
            body: const Center(child: CircularProgressIndicator()),
            floatingActionButton: const DoctorChatbotFAB(),
          );
        }

        /// Extraction des donnees du patient avec valeurs par defaut
        final data = userSnapshot.data?.data() ?? <String, dynamic>{};
        final fullName =
            (data['fullName'] as String?)?.trim().isNotEmpty == true
            ? data['fullName'] as String
            : 'Patient';
        final gender = (data['gender'] as String?) ?? 'Non renseigné';
        final email = (data['email'] as String?) ?? 'Non renseigné';
        final phone = (data['phone'] as String?) ?? 'Non renseigné';
        final medicalNotes = (data['medicalNotes'] as String?) ?? '';
        final assignedDoctor = _resolveDoctorName(data);
        final age = _computeAge(data['dateOfBirth']);
        final dateOfBirth = _formatDate(data['dateOfBirth']);
        final createdAt = _formatDate(data['createdAt']);

        return Scaffold(
          appBar: AppBar(
            title: Text(fullName),
            elevation: 0,
            backgroundColor: AppColors.primary,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ===== SECTION: EN-TETE PATIENT =====
                /// Avatar avec initiale + nom + age + statut
                Center(
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.transparent,
                          child: Text(
                            fullName.isNotEmpty
                                ? fullName[0].toUpperCase()
                                : 'P',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        age != null ? '$age ans' : 'Âge inconnu',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textMedium,
                        ),
                      ),
                      const SizedBox(height: 12),

                      /// Badge de statut (Actif/Inactif) base sur dernier enregistrement
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: nightsQuery,
                        builder: (context, nightsSnapshot) {
                          if (!nightsSnapshot.hasData) {
                            return _buildBadge(
                              'Chargement…',
                              AppColors.textMedium,
                            );
                          }

                          final docs = nightsSnapshot.data!.docs;

                          if (docs.isEmpty) {
                            return _buildBadge(
                              'Pas de données',
                              AppColors.warning,
                            );
                          }

                          // Trier côté client par timestamp décroissant
                          final sorted = [...docs]
                            ..sort((a, b) {
                              final aRaw = a.data()['timestamp'];
                              final bRaw = b.data()['timestamp'];
                              DateTime? aTime, bTime;
                              if (aRaw is Timestamp)
                                aTime = aRaw.toDate();
                              else if (aRaw is String)
                                aTime = DateTime.tryParse(aRaw);
                              if (bRaw is Timestamp)
                                bTime = bRaw.toDate();
                              else if (bRaw is String)
                                bTime = DateTime.tryParse(bRaw);
                              if (aTime == null && bTime == null) return 0;
                              if (aTime == null) return 1;
                              if (bTime == null) return -1;
                              return bTime.compareTo(aTime);
                            });

                          final lastMeasurement = sorted.first
                              .data()['timestamp'];
                          final statusText = _getStatusBadge(lastMeasurement);
                          final isActive = statusText.startsWith('Actif');

                          return _buildBadge(
                            statusText,
                            isActive ? AppColors.success : AppColors.warning,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                /// ===== SECTION: INFORMATIONS CONTACT =====
                _buildSectionTitle('Informations de contact'),
                const SizedBox(height: 8),
                _buildInfoCard(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: email,
                ),
                _buildInfoCard(
                  icon: Icons.phone_outlined,
                  label: 'Téléphone',
                  value: phone,
                ),
                const SizedBox(height: 16),

                /// ===== SECTION: INFORMATIONS PERSONNELLES =====
                _buildSectionTitle('Informations personnelles'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.wc_outlined,
                        label: 'Sexe',
                        value: gender,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.cake_outlined,
                        label: 'Né le',
                        value: dateOfBirth,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                /// ===== SECTION: INFORMATIONS MEDICALES =====
                _buildSectionTitle('Informations médicales'),
                const SizedBox(height: 8),

                if (medicalNotes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.note_outlined,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Notes médicales',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            medicalNotes,
                            style: const TextStyle(color: AppColors.textBody),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                /// ===== SECTION: MEDECIN ASSIGNE =====
                Card(
                  elevation: 2,
                  color: AppColors.primary.withOpacity(0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Médecin assigné',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMedium,
                              ),
                            ),
                            Text(
                              assignedDoctor,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                /// ===== SECTION: STATISTIQUES =====
                /// Affiche: nombre total de nuits, score moyen, total des apnees
                _buildSectionTitle('Statistiques'),
                const SizedBox(height: 8),

                /// Stream pour calculer les statistiques globales
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: statsQuery,
                  builder: (context, statsSnapshot) {
                    /// Initialise les variables de calcul
                    int totalNights = 0;
                    double avgScore = 0;
                    int totalApneas = 0;

                    /// Calcul des statistiques a partir de tous les documents
                    if (statsSnapshot.hasData) {
                      final docs = statsSnapshot.data!.docs;
                      totalNights = docs.length;
                      if (totalNights > 0) {
                        double sumScore = 0;
                        for (final doc in docs) {
                          final score = doc['score'] as num? ?? 0;
                          final apneas = doc['apneas'] as num? ?? 0;
                          sumScore += score.toDouble();
                          totalApneas += apneas.toInt();
                        }
                        avgScore = sumScore / totalNights;
                      }
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Nuits',
                            totalNights.toString(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Score moy.',
                            avgScore.toStringAsFixed(1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Apnées total',
                            totalApneas.toString(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                /// ===== SECTION: HISTORIQUE NUITS =====
                /// Affiche les 10 dernieres nuits avec acces a l'analyse detaillee
                _buildSectionTitle('5 dernières nuits'),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: nightsQuery,
                  builder: (context, nightsSnapshot) {
                    if (nightsSnapshot.hasError) {
                      return Card(
                        color: AppColors.error.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: AppColors.error),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Erreur chargement historique nuits.',
                                  style: TextStyle(color: AppColors.error),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    if (!nightsSnapshot.hasData) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final docs = nightsSnapshot.data!.docs;

                    // Trier côté client par timestamp décroissant
                    final sorted = [...docs]
                      ..sort((a, b) {
                        final aRaw = a.data()['timestamp'];
                        final bRaw = b.data()['timestamp'];
                        DateTime? aTime, bTime;
                        if (aRaw is Timestamp)
                          aTime = aRaw.toDate();
                        else if (aRaw is String)
                          aTime = DateTime.tryParse(aRaw);
                        if (bRaw is Timestamp)
                          bTime = bRaw.toDate();
                        else if (bRaw is String)
                          bTime = DateTime.tryParse(bRaw);
                        if (aTime == null && bTime == null) return 0;
                        if (aTime == null) return 1;
                        if (bTime == null) return -1;
                        return bTime.compareTo(aTime);
                      });

                    if (sorted.isEmpty) {
                      return Card(
                        color: AppColors.warning.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppColors.warning,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Aucune nuit enregistrée.',
                                  style: TextStyle(color: AppColors.warning),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: sorted.map((doc) {
                        final night = doc.data();
                        final score =
                            (night['score'] as num?)?.toStringAsFixed(1) ??
                            '--';
                        final apneas = night['apneas'] ?? '--';
                        final spo2 =
                            (night['spo2'] as num?)?.toStringAsFixed(1) ?? '--';
                        final duration = night['duration'] ?? '--';
                        final date = _formatDate(night['timestamp']);
                        final dateTime = _formatDateTime(night['timestamp']);

                        return GestureDetector(
                          onTap: () {
                            context.push(
                              RouteNames.doctorAnalysis(
                                Uri.encodeComponent(patientId),
                                Uri.encodeComponent(date),
                              ),
                            );
                          },
                          child: Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        date,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(
                                            0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          'Score: $score',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    dateTime,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMedium,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildMetricBadge(
                                        'Apnées',
                                        apneas.toString(),
                                      ),
                                      _buildMetricBadge('SpO₂', '$spo2%'),
                                      _buildMetricBadge('Durée', '$duration h'),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Cliquez pour voir l\'analyse détaillée →',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMedium,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Date d'inscription
                Center(
                  child: Text(
                    'Patient inscrit le $createdAt',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          floatingActionButton: const DoctorChatbotFAB(),
        );
      },
    );
  }

  /// Helper: Affiche un titre de section avec styling
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }

  /// Helper: Carte pour afficher une info personnelle/contact
  /// Affiche: icone + label + valeur
  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMedium,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Helper: Carte pour afficher une statistique
  /// Affiche: grande valeur + petit label
  Widget _buildStatCard(String label, String value) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textMedium),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Helper: Badge pour afficher une metrique d'une nuit
  /// Affiche: valeur + label (ex: "5 Apnees")
  Widget _buildMetricBadge(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textMedium),
        ),
      ],
    );
  }

  /// Helper: Badge colore pour afficher le statut du patient
  /// Affiche: "Actif" | "Inactif" | "Pas de donnees"
  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
