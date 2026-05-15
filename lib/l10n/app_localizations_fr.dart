// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'SleepApnea Detect';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get appPreferencesTitle => '⚙️ Préférences de l\'application';

  @override
  String get languageLabel => 'Langue';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'Arabe';

  @override
  String get darkModeLabel => 'Mode sombre';

  @override
  String get notificationsLabel => 'Notifications';

  @override
  String get infoSupportTitle => 'ℹ️ Informations et Support';

  @override
  String get helpFaqLabel => 'Aide et FAQ';

  @override
  String get privacyPolicyLabel => 'Politique de confidentialité';

  @override
  String get aboutLabel => 'À propos';

  @override
  String get aboutInProgressMessage => 'Page À propos en préparation.';

  @override
  String get logoutLabel => 'Déconnexion';

  @override
  String get deleteAccountLabel => 'Supprimer compte';

  @override
  String get homeLabel => 'Accueil';

  @override
  String get patientsLabel => 'Patients';

  @override
  String get alertsLabel => 'Alertes';

  @override
  String get settingsShortLabel => 'Param.';

  @override
  String get accountTitle => '👤 Mon Compte';

  @override
  String get editProfileLabel => 'Modifier profil';

  @override
  String get changePasswordLabel => 'Changer mot de passe';

  @override
  String get biometricLoginLabel => 'Connexion biométrique';

  @override
  String get biometricSoonMessage =>
      'Connexion biométrique bientôt disponible.';

  @override
  String get currentPasswordLabel => 'Mot de passe actuel';

  @override
  String get newPasswordLabel => 'Nouveau mot de passe';

  @override
  String get confirmNewPasswordLabel => 'Confirmer le nouveau mot de passe';

  @override
  String get updateLabel => 'Mettre à jour';

  @override
  String get updatingLabel => 'Mise à jour...';

  @override
  String get passwordFillAllFieldsError => 'Veuillez remplir tous les champs.';

  @override
  String get passwordConfirmationMismatchError =>
      'La confirmation ne correspond pas au mot de passe.';

  @override
  String get passwordMinLengthError =>
      'Le mot de passe doit contenir au moins 8 caractères.';

  @override
  String get passwordLettersNumbersError =>
      'Le mot de passe doit contenir des lettres et des chiffres.';

  @override
  String get passwordUpdateSuccessMessage =>
      'Mot de passe mis à jour avec succès.';

  @override
  String passwordUpdateError(Object error) {
    return 'Erreur lors de la mise à jour: $error';
  }

  @override
  String get notificationsTitle => '🔔 Notifications';

  @override
  String get alertsCenterLabel => 'Centre d\'alertes';

  @override
  String get apneaAlertsLabel => 'Alertes apnée';

  @override
  String get remindersLabel => 'Rappels';

  @override
  String get sensorsTitle => '🔌 Capteurs';

  @override
  String get manageDevicesLabel => 'Gérer appareils';

  @override
  String get connectionGuideLabel => 'Guide de connexion';

  @override
  String get historyLabel => 'Historique';

  @override
  String get monitoringShortLabel => 'Surveil.';

  @override
  String get relaxationLabel => 'Détente';

  @override
  String get loginTitle => 'Connexion';

  @override
  String get loginButton => 'Se connecter';

  @override
  String get signUpButton => 'S\'inscrire';

  @override
  String get forgotPasswordButton => 'Mot de passe oublié?';

  @override
  String get roleLabel => 'Rôle :';

  @override
  String get roleRequiredError => 'Veuillez sélectionner un rôle';

  @override
  String get rolePatient => 'Patient';

  @override
  String get roleDoctor => 'Médecin';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailRequiredError => 'Veuillez entrer votre email';

  @override
  String get emailInvalidError => 'Veuillez entrer un email valide';

  @override
  String get passwordLabel => 'Mot de passe';

  @override
  String get passwordRequiredError => 'Veuillez entrer votre mot de passe';

  @override
  String get passwordMin6Error =>
      'Le mot de passe doit contenir au moins 6 caractères';

  @override
  String get showPasswordTooltip => 'Afficher le mot de passe';

  @override
  String get hidePasswordTooltip => 'Masquer le mot de passe';

  @override
  String get unexpectedError => 'Une erreur inattendue est survenue';

  @override
  String get loginErrorGeneric => 'Erreur de connexion';

  @override
  String get loginUserNotFound => 'Aucun compte trouvé avec cet email.';

  @override
  String get loginWrongCredentials => 'Email ou mot de passe incorrect.';

  @override
  String get loginInvalidEmail => 'Email invalide.';

  @override
  String get firebaseAuthNotConfigured =>
      'Firebase Auth n\'est pas configuré (active Email/Mot de passe dans Firebase Console > Authentication > Sign-in method).';

  @override
  String get forgotPasswordTitle => 'Réinitialisation du mot de passe';

  @override
  String get forgotPasswordInstruction =>
      'Entrez votre email pour réinitialiser votre mot de passe';

  @override
  String get sendResetLinkButton => 'Envoyer lien de réinitialisation';

  @override
  String get resetLinkSentMessage =>
      'Lien de réinitialisation envoyé à votre email.';

  @override
  String get resetLinkSendError => 'Erreur lors de l\'envoi du lien.';

  @override
  String get backToLoginButton => '← Retour au login';

  @override
  String get registerTitle => 'Création de compte';

  @override
  String get fullNameLabel => 'Nom complet';

  @override
  String get fullNameRequiredError => 'Veuillez entrer votre nom complet';

  @override
  String get dateOfBirthLabel => 'Date de naissance (AAAA-MM-JJ)';

  @override
  String get dateOfBirthRequiredError =>
      'Veuillez entrer votre date de naissance';

  @override
  String get genderLabel => 'Sexe: ';

  @override
  String get genderMaleShort => 'H';

  @override
  String get genderFemaleShort => 'F';

  @override
  String get genderOther => 'Autre';

  @override
  String get genderRequiredMessage => 'Veuillez sélectionner votre sexe.';

  @override
  String get phoneLabel => 'Téléphone';

  @override
  String get phoneRequiredError => 'Veuillez entrer votre numéro de téléphone';

  @override
  String get profilePhotoUrlOptionalLabel =>
      'Photo de profil (URL) - optionnel';

  @override
  String get urlInvalidError => 'Veuillez entrer une URL valide (http/https)';

  @override
  String get specializationLabel => 'Spécialisation';

  @override
  String get specializationRequiredError => 'Veuillez entrer la spécialisation';

  @override
  String get medicalLicenseNumberLabel => 'Numéro de licence médicale';

  @override
  String get medicalLicenseNumberRequiredError =>
      'Veuillez entrer le numéro de licence';

  @override
  String get yearsOfExperienceLabel => 'Années d\'expérience';

  @override
  String get yearsOfExperienceRequiredError =>
      'Veuillez entrer les années d\'expérience';

  @override
  String get clinicHospitalLabel => 'Clinique / Hôpital';

  @override
  String get clinicHospitalRequiredError =>
      'Veuillez entrer la clinique ou l\'hôpital';

  @override
  String get numberInvalidError => 'Veuillez entrer un nombre valide';

  @override
  String get confirmPasswordLabel => 'Confirmer le mot de passe';

  @override
  String get confirmPasswordRequiredError =>
      'Veuillez confirmer votre mot de passe';

  @override
  String get passwordsDontMatchError =>
      'Les mots de passe ne correspondent pas';

  @override
  String get acceptTermsLabel => 'J\'accepte les CGU';

  @override
  String get acceptMedicalConsentLabel => 'Consentement médical';

  @override
  String get acceptTermsConsentRequiredMessage =>
      'Veuillez accepter les CGU et le consentement médical pour continuer.';

  @override
  String get doctorProfessionalInfoRequiredMessage =>
      'Veuillez compléter les informations professionnelles du médecin.';

  @override
  String get registerEmailAlreadyInUse => 'Cet email est déjà utilisé.';

  @override
  String get registerWeakPassword =>
      'Mot de passe trop faible (minimum 6 caractères).';

  @override
  String get registerErrorGeneric => 'Erreur d\'inscription.';

  @override
  String get registerDatabaseError =>
      'Erreur base de données lors de l\'inscription.';

  @override
  String get firestoreWriteDenied =>
      'Écriture refusée par Firestore. Vérifiez les règles de sécurité.';

  @override
  String get alreadyHaveAccountLoginButton => 'Déjà un compte ? Se connecter';

  @override
  String roleMismatchError(Object role) {
    return 'Le rôle sélectionné ne correspond pas à ce compte ($role).';
  }

  @override
  String get splashFooterVersion => 'v1.0.0';

  @override
  String get greetingMorning => 'Bonjour';

  @override
  String get greetingAfternoon => 'Bon après-midi';

  @override
  String get greetingEvening => 'Bonne nuit';

  @override
  String get scoreExcellent => 'Excellent';

  @override
  String get scoreAverage => 'Moyen';

  @override
  String get scorePoor => 'Mauvais';

  @override
  String get sessionExpiredMessage =>
      'Session expirée. Veuillez vous reconnecter.';

  @override
  String get errorLoadingProfile => 'Erreur chargement profil.';

  @override
  String get errorLoadingMeasurements => 'Erreur chargement mesures.';

  @override
  String get normalLabel => 'Normal';

  @override
  String get moderateLabel => 'Modéré';

  @override
  String get cancelButton => 'Annuler';

  @override
  String get deleteButton => 'Supprimer';

  @override
  String get unknownDate => 'Date inconnue';

  @override
  String get dashboardTitle => 'Tableau de bord';

  @override
  String get sleepScoreLabel => 'Score sommeil';

  @override
  String get outOf100 => 'sur 100';

  @override
  String get eventsLabel => 'Événements';

  @override
  String get avgSpo2Label => 'SpO₂ moyen';

  @override
  String get avgHeartRateLabel => 'FC moyenne';

  @override
  String get temperatureLabel => 'Température';

  @override
  String get stopMonitoringButton => 'Arrêter surveillance';

  @override
  String get startMonitoringButton => 'Démarrer surveillance';

  @override
  String get lastSessionLabel => 'Dernière session : 0h 45min';

  @override
  String get noMeasurementsMessage =>
      'Aucune mesure disponible. Lancez une session pour commencer.';

  @override
  String get sectionOverview => 'Aperçu Global';

  @override
  String get sectionAIAnalysis => 'IA & Analyse de Risque';

  @override
  String get sectionECGSignal => 'Signal ECG en Temps Réel';

  @override
  String get sectionCriticalPatients => 'Patients Critiques';

  @override
  String get sectionQuickActions => 'Actions Rapides';

  @override
  String get statPatients => 'Patients';

  @override
  String get statCritical => 'Critiques';

  @override
  String get statAIAnalyzed => 'IA Analysés';

  @override
  String get statPDFReports => 'Rapports PDF';

  @override
  String get aiRiskPrediction => 'Prédiction IA des Risques';

  @override
  String get ecgLiveLabel => 'Direct - SpO2 96%';

  @override
  String get navReport => 'Rapport';

  @override
  String get navProfileLabel => 'Profil';

  @override
  String get quickActionPDF => 'PDF';

  @override
  String get quickActionStats => 'Stats';

  @override
  String get historyTitle => 'Historique des Nuits';

  @override
  String get searchHint => 'Rechercher...';

  @override
  String get filterAll => 'Toutes';

  @override
  String get filterGood => 'Bonnes';

  @override
  String get filterFair => 'Moyennes';

  @override
  String get filterBad => 'Mauvaises';

  @override
  String get historyLoadError => 'Impossible de charger l\'historique.';

  @override
  String get historyEmpty =>
      'Aucun historique trouvé. Lancez une première surveillance pour voir les données ici.';

  @override
  String scoreEntry(Object score) {
    return 'Score: $score';
  }

  @override
  String apneasEntry(Object count) {
    return 'Apnées: $count';
  }

  @override
  String get alertsAllMarkedRead => 'Toutes les alertes marquées comme lues.';

  @override
  String get alertDeleteError => 'Erreur lors de la suppression.';

  @override
  String get alertsCenterTitle => 'Centre d\'Alertes';

  @override
  String get markAllReadButton => 'Tout lire';

  @override
  String get alertsLoadError => 'Impossible de charger les alertes.';

  @override
  String alertsCriticalSection(Object count) {
    return '🚨 Critiques ($count)';
  }

  @override
  String alertsWarningSection(Object count) {
    return '⚠️ Avertissements ($count)';
  }

  @override
  String alertsInfoSection(Object count) {
    return 'ℹ️ Informations ($count)';
  }

  @override
  String get noActiveAlertsTitle => 'Aucune alerte active';

  @override
  String get allVitalsNormalMessage =>
      'Tout va bien ! Vos paramètres vitaux sont dans les limites normales.';

    @override
    String get startConversationPrompt => 'Démarrez la conversation';

  @override
  String get deleteAlertDialogTitle => 'Supprimer l\'alerte';

  @override
  String get deleteAlertDialogContent => 'Voulez-vous supprimer cette alerte ?';

  @override
  String get devicesTitle => 'Gestion Capteurs';

  @override
  String get connectionStatusLabel => 'État de connexion :';

  @override
  String get deviceConnectedLabel => '🟢 Connecté';

  @override
  String get activeSensorsLabel => 'Capteurs actifs :';

  @override
  String get disconnectButton => 'Déconnecter';

  @override
  String get searchNewDeviceButton => 'Rechercher nouveau';

  @override
  String get accessDeniedTitle => 'Accès refusé';

  @override
  String get accessDeniedMessage =>
      'Vous n\'avez pas l\'autorisation d\'accéder à cette page.';

  @override
  String get backToHomeButton => 'Retour à l\'accueil';
}
