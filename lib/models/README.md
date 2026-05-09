# 📊 Modèles de Données - Apnea Project

## 📁 Structure des Modèles

Ce dossier contient toutes les classes de modèles de données pour l'application Apnea Project. Chaque modèle représente une entité du système.

---

## 🏥 Modèles Principaux

### 1. **Patient** 
**Fichier**: `patient.dart`  
**Fonctionnalité**: Représente les informations d'un patient  
**Champs clés**:
- `id`: Identifiant unique du patient
- `nom`, `prenom`: Nom et prénom du patient
- `age`: Âge du patient
- `sexe`: Genre du patient
- `dateNaissance`: Date de naissance
- `telephone`, `email`: Informations de contact
- `notesMedicales`: Historique médical
- `doctorUid`: ID du médecin assigné

**Méthodes**:
- `toFirestore()`: Convertit en format Firebase
- `fullName`: Propriété calculée (nom complet)

---

### 2. **Doctor**
**Fichier**: `doctor.dart`  
**Fonctionnalité**: Représente les informations d'un médecin  
**Champs clés**:
- `id`: Identifiant unique du médecin
- `fullName`: Nom complet
- `email`: Email professionnel
- `specialization`: Spécialité médicale (ex: Pneumologie)
- `medicalLicenseNumber`: Numéro de licence médicale
- `yearsOfExperience`: Années d'expérience
- `clinicName`: Nom de la clinique
- `phone`: Numéro de téléphone
- `profileImageUrl`: Photo de profil
- `bio`: Biographie professionnelle

**Méthodes**:
- `toFirestore()`: Sauvegarde dans Firebase
- `fromFirestore()`: Charge depuis Firebase

---

### 3. **Device**
**Fichier**: `device.dart`  
**Fonctionnalité**: Représente un appareil de monitoring (capteur d'apnée)  
**Champs clés**:
- `id`: Identifiant unique de l'appareil
- `patientUid`: Patient propriétaire de l'appareil
- `deviceName`: Nom de l'appareil
- `deviceType`: Type (ex: CPAP, Pulse Oximeter)
- `serialNumber`: Numéro de série
- `manufacturer`: Fabricant
- `firmwareVersion`: Version du firmware
- `batteryLevel`: Niveau de batterie (%)
- `isActive`: État d'activation
- `pairedAt`: Date d'appairage
- `lastSyncTime`: Dernière synchronisation

---

### 4. **Measurement**
**Fichier**: `measurement.dart`  
**Fonctionnalité**: Représente une mesure vitale (SpO2, FC, etc.)  
**Champs clés**:
- `id`: Identifiant unique
- `patientUid`: Patient concerné
- `timestamp`: Date et heure de la mesure
- `spo2`: Saturation en oxygène (%)
- `heartRate`: Fréquence cardiaque (bpm)
- `temperature`: Température corporelle (°C)
- `respiratoryRate`: Fréquence respiratoire
- `bloodPressureSystolic`: Tension systolique
- `bloodPressureDiastolic`: Tension diastolique
- `notes`: Notes additionnelles
- `deviceId`: Appareil ayant pris la mesure

---

### 5. **Alert**
**Fichier**: `alert.dart`  
**Fonctionnalité**: Représente une alerte système ou médicale  
**Champs clés**:
- `id`: Identifiant unique
- `patientUid`: Patient concerné
- `alertType`: Type d'alerte (SpO2_CRITICAL, HR_ABNORMAL, etc.)
- `severity`: Sévérité (critical, warning, info)
- `createdAt`: Date de création
- `doctorUid`: Médecin notifié
- `title`: Titre de l'alerte
- `description`: Description détaillée
- `isRead`: Marquée comme lue
- `isResolved`: Marquée comme résolue
- `measurement`: Données de mesure associées
- `resolvedAt`: Date de résolution

**Types de sévérité**: critical | warning | info

---

### 6. **ApneaEvent**
**Fichier**: `apnea_event.dart`  
**Fonctionnalité**: Représente un événement d'apnée détecté  
**Champs clés**:
- `id`: Identifiant unique
- `patientUid`: Patient concerné
- `startTime`: Heure de début
- `endTime`: Heure de fin
- `duration`: Durée de l'événement (secondes)
- `type`: Type d'apnée (obstructive, centrale, mixte)
- `severity`: Sévérité (mild, moderate, severe)
- `spo2Drop`: Baisse de SpO2 pendant l'événement
- `respiratoryRate`: Fréquence respiratoire durant l'événement
- `notes`: Notes cliniques
- `sessionId`: Session de sommeil associée

---

### 7. **SleepSession**
**Fichier**: `sleep_session.dart`  
**Fonctionnalité**: Représente une session de sommeil complète  
**Champs clés**:
- `id`: Identifiant unique
- `patientUid`: Patient
- `startTime`: Heure d'endormissement
- `endTime`: Heure de réveil
- `duration`: Durée du sommeil (minutes)
- `totalApneaEvents`: Nombre total d'apnées
- `averageSpo2`: SpO2 moyen pendant la nuit
- `lowestSpo2`: SpO2 minimum atteint
- `averageHeartRate`: Fréquence cardiaque moyenne
- `sleepQuality`: Qualité du sommeil (good, fair, poor)
- `notes`: Observations du patient
- `deviceId`: Appareil utilisé

---

### 8. **Message**
**Fichier**: `message.dart`  
**Fonctionnalité**: Représente un message entre médecin et patient  
**Champs clés**:
- `id`: Identifiant unique
- `senderId`: ID de l'expéditeur
- `receiverId`: ID du destinataire
- `content`: Contenu du message
- `timestamp`: Date d'envoi
- `attachmentUrl`: URL de la pièce jointe (optionnel)
- `attachmentType`: Type de fichier joint
- `isRead`: Message lu ou non
- `type`: Type de message (text, image, file)

---

### 9. **RelaxationContent**
**Fichier**: `relaxation_content.dart`  
**Fonctionnalité**: Représente un contenu de relaxation (méditation, musique, etc.)  
**Champs clés**:
- `id`: Identifiant unique
- `title`: Titre du contenu
- `category`: Catégorie (meditation, breathing, music)
- `description`: Description
- `imageUrl`: Image de couverture
- `audioUrl`: URL du fichier audio
- `duration`: Durée en secondes
- `instructorName`: Nom de l'instructeur
- `difficulty`: Niveau (beginner, intermediate, advanced)
- `rating`: Note moyenne (0-5)
- `reviewCount`: Nombre d'avis
- `createdAt`: Date de création

---

### 10. **ReportData**
**Fichier**: `report_data.dart`  
**Fonctionnalité**: Représente les données d'un rapport PDF médical  
**Champs clés**:
- `doctorName`: Nom du médecin
- `generatedAt`: Date de génération
- `patientId`, `patientFullName`, `patientAge`, `patientGender`: Infos patient
- `startDate`, `endDate`: Période du rapport
- `averageSpo2`, `averageHeartRate`: Moyennes vitales
- `totalApneas`, `totalSessions`: Statistiques globales
- `measurements`: Liste des mesures incluses
- `notes`: Notes médicales incluses
- Flags d'inclusion: `includeClinicalData`, `includeSignalGraphs`, etc.

---

## 🔄 Utilisation des Modèles

### Import Simple
```dart
import 'package:apnea_project/models/patient.dart';
```

### Import Global (Recommandé)
```dart
import 'package:apnea_project/models/models.dart';

// Maintenant vous avez accès à tous les modèles
Patient p = Patient(...);
Doctor d = Doctor(...);
Device dev = Device(...);
```

### Exemple de Création
```dart
final patient = Patient(
  id: 'patient_123',
  nom: 'Dupont',
  prenom: 'Jean',
  age: 45,
  sexe: 'M',
);

// Sauvegarde dans Firebase
final data = patient.toFirestore();
await firebaseService.savePatient(data);
```

### Conversion Firebase
```dart
// Chargement depuis Firebase
final data = await firebaseService.getPatient(id);
final patient = Patient.fromFirestore(data, id);
```

---

## 📊 Diagramme des Relations

```
Patient (1) ─── (N) Measurement
   │
   ├── Doctor (1:N)
   │
   ├── Device (1:N)
   │
   ├── SleepSession (1:N)
   │
   ├── ApneaEvent (1:N)
   │
   ├── Alert (1:N)
   │
   └── Message (N:N avec Doctor)

Doctor (1) ─── (N) Message

RelaxationContent (indépendant)

ReportData (agrégation des autres)
```

---

## ✅ Checklist de Développement

- [x] Patient - Gestion des profils patients
- [x] Doctor - Gestion des profils médecins
- [x] Device - Gestion des appareils
- [x] Measurement - Enregistrement des vitales
- [x] Alert - Système d'alerte
- [x] ApneaEvent - Détection d'apnées
- [x] SleepSession - Sessions de sommeil
- [x] Message - Communication médecin-patient
- [x] RelaxationContent - Contenu thérapeutique
- [x] ReportData - Rapports médicaux

---

## 🚀 Prochaines Étapes

1. **Intégration Firebase**: Mettre à jour les services pour utiliser les nouveaux modèles
2. **Migration des données**: Adapter les appels existants aux nouveaux modèles
3. **Tests unitaires**: Créer des tests pour chaque modèle
4. **Documentation API**: Ajouter des examples d'utilisation

---

**Créé**: 2024-05  
**Version**: 1.0  
**Status**: ✅ Production Ready
