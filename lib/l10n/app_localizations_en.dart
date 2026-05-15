// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SleepApnea Detect';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appPreferencesTitle => 'App Preferences';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageFrench => 'French';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'Arabic';

  @override
  String get darkModeLabel => 'Dark mode';

  @override
  String get notificationsLabel => 'Notifications';

  @override
  String get infoSupportTitle => 'Information & Support';

  @override
  String get helpFaqLabel => 'Help & FAQ';

  @override
  String get privacyPolicyLabel => 'Privacy policy';

  @override
  String get aboutLabel => 'About';

  @override
  String get aboutInProgressMessage => 'About page is under preparation.';

  @override
  String get logoutLabel => 'Log out';

  @override
  String get deleteAccountLabel => 'Delete account';

  @override
  String get homeLabel => 'Home';

  @override
  String get patientsLabel => 'Patients';

  @override
  String get alertsLabel => 'Alerts';

  @override
  String get settingsShortLabel => 'Settings';

  @override
  String get accountTitle => 'My Account';

  @override
  String get editProfileLabel => 'Edit profile';

  @override
  String get changePasswordLabel => 'Change password';

  @override
  String get biometricLoginLabel => 'Biometric login';

  @override
  String get biometricSoonMessage => 'Biometric login will be available soon.';

  @override
  String get currentPasswordLabel => 'Current password';

  @override
  String get newPasswordLabel => 'New password';

  @override
  String get confirmNewPasswordLabel => 'Confirm new password';

  @override
  String get updateLabel => 'Update';

  @override
  String get updatingLabel => 'Updating...';

  @override
  String get passwordFillAllFieldsError => 'Please fill in all fields.';

  @override
  String get passwordConfirmationMismatchError =>
      'Confirmation does not match the password.';

  @override
  String get passwordMinLengthError =>
      'Password must be at least 8 characters.';

  @override
  String get passwordLettersNumbersError =>
      'Password must contain letters and numbers.';

  @override
  String get passwordUpdateSuccessMessage => 'Password updated successfully.';

  @override
  String passwordUpdateError(Object error) {
    return 'Update failed: $error';
  }

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get alertsCenterLabel => 'Alerts center';

  @override
  String get apneaAlertsLabel => 'Apnea alerts';

  @override
  String get remindersLabel => 'Reminders';

  @override
  String get sensorsTitle => 'Sensors';

  @override
  String get manageDevicesLabel => 'Manage devices';

  @override
  String get connectionGuideLabel => 'Connection guide';

  @override
  String get historyLabel => 'History';

  @override
  String get monitoringShortLabel => 'Monitor';

  @override
  String get relaxationLabel => 'Relax';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginButton => 'Sign in';

  @override
  String get signUpButton => 'Sign up';

  @override
  String get forgotPasswordButton => 'Forgot password?';

  @override
  String get roleLabel => 'Role:';

  @override
  String get roleRequiredError => 'Please select a role';

  @override
  String get rolePatient => 'Patient';

  @override
  String get roleDoctor => 'Doctor';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailRequiredError => 'Please enter your email';

  @override
  String get emailInvalidError => 'Please enter a valid email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordRequiredError => 'Please enter your password';

  @override
  String get passwordMin6Error => 'Password must be at least 6 characters';

  @override
  String get showPasswordTooltip => 'Show password';

  @override
  String get hidePasswordTooltip => 'Hide password';

  @override
  String get unexpectedError => 'An unexpected error occurred';

  @override
  String get loginErrorGeneric => 'Login error';

  @override
  String get loginUserNotFound => 'No account found with this email.';

  @override
  String get loginWrongCredentials => 'Incorrect email or password.';

  @override
  String get loginInvalidEmail => 'Invalid email.';

  @override
  String get firebaseAuthNotConfigured =>
      'Firebase Auth is not configured (enable Email/Password in Firebase Console > Authentication > Sign-in method).';

  @override
  String get forgotPasswordTitle => 'Reset password';

  @override
  String get forgotPasswordInstruction =>
      'Enter your email to reset your password';

  @override
  String get sendResetLinkButton => 'Send reset link';

  @override
  String get resetLinkSentMessage => 'Password reset link sent to your email.';

  @override
  String get resetLinkSendError => 'Failed to send reset link.';

  @override
  String get backToLoginButton => '← Back to login';

  @override
  String get registerTitle => 'Create account';

  @override
  String get fullNameLabel => 'Full name';

  @override
  String get fullNameRequiredError => 'Please enter your full name';

  @override
  String get dateOfBirthLabel => 'Date of birth (YYYY-MM-DD)';

  @override
  String get dateOfBirthRequiredError => 'Please enter your date of birth';

  @override
  String get genderLabel => 'Gender: ';

  @override
  String get genderMaleShort => 'M';

  @override
  String get genderFemaleShort => 'F';

  @override
  String get genderOther => 'Other';

  @override
  String get genderRequiredMessage => 'Please select your gender.';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get phoneRequiredError => 'Please enter your phone number';

  @override
  String get profilePhotoUrlOptionalLabel => 'Profile photo (URL) - optional';

  @override
  String get urlInvalidError => 'Please enter a valid URL (http/https)';

  @override
  String get specializationLabel => 'Specialization';

  @override
  String get specializationRequiredError => 'Please enter the specialization';

  @override
  String get medicalLicenseNumberLabel => 'Medical license number';

  @override
  String get medicalLicenseNumberRequiredError =>
      'Please enter the license number';

  @override
  String get yearsOfExperienceLabel => 'Years of experience';

  @override
  String get yearsOfExperienceRequiredError =>
      'Please enter years of experience';

  @override
  String get clinicHospitalLabel => 'Clinic / Hospital';

  @override
  String get clinicHospitalRequiredError =>
      'Please enter the clinic or hospital';

  @override
  String get numberInvalidError => 'Please enter a valid number';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get confirmPasswordRequiredError => 'Please confirm your password';

  @override
  String get passwordsDontMatchError => 'Passwords do not match';

  @override
  String get acceptTermsLabel => 'I accept the Terms of Use';

  @override
  String get acceptMedicalConsentLabel => 'Medical consent';

  @override
  String get acceptTermsConsentRequiredMessage =>
      'Please accept the Terms of Use and medical consent to continue.';

  @override
  String get doctorProfessionalInfoRequiredMessage =>
      'Please complete the doctor\'s professional information.';

  @override
  String get registerEmailAlreadyInUse => 'This email is already in use.';

  @override
  String get registerWeakPassword =>
      'Password is too weak (minimum 6 characters).';

  @override
  String get registerErrorGeneric => 'Registration error.';

  @override
  String get registerDatabaseError => 'Database error during registration.';

  @override
  String get firestoreWriteDenied =>
      'Firestore write denied. Please check security rules.';

  @override
  String get alreadyHaveAccountLoginButton =>
      'Already have an account? Sign in';

  @override
  String roleMismatchError(Object role) {
    return 'The selected role does not match this account ($role).';
  }

  @override
  String get splashFooterVersion => 'v1.0.0';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get scoreExcellent => 'Excellent';

  @override
  String get scoreAverage => 'Average';

  @override
  String get scorePoor => 'Poor';

  @override
  String get sessionExpiredMessage => 'Session expired. Please reconnect.';

  @override
  String get errorLoadingProfile => 'Profile loading error.';

  @override
  String get errorLoadingMeasurements => 'Measurement loading error.';

  @override
  String get normalLabel => 'Normal';

  @override
  String get moderateLabel => 'Moderate';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get deleteButton => 'Delete';

  @override
  String get unknownDate => 'Unknown date';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get sleepScoreLabel => 'Sleep score';

  @override
  String get outOf100 => 'out of 100';

  @override
  String get eventsLabel => 'Events';

  @override
  String get avgSpo2Label => 'Avg SpO₂';

  @override
  String get avgHeartRateLabel => 'Avg HR';

  @override
  String get temperatureLabel => 'Temperature';

  @override
  String get stopMonitoringButton => 'Stop monitoring';

  @override
  String get startMonitoringButton => 'Start monitoring';

  @override
  String get lastSessionLabel => 'Last session: 0h 45min';

  @override
  String get noMeasurementsMessage =>
      'No measurements available. Start a session to begin.';

  @override
  String get sectionOverview => 'Global Overview';

  @override
  String get sectionAIAnalysis => 'AI & Risk Analysis';

  @override
  String get sectionECGSignal => 'Real-time ECG Signal';

  @override
  String get sectionCriticalPatients => 'Critical Patients';

  @override
  String get sectionQuickActions => 'Quick Actions';

  @override
  String get statPatients => 'Patients';

  @override
  String get statCritical => 'Critical';

  @override
  String get statAIAnalyzed => 'AI Analyzed';

  @override
  String get statPDFReports => 'PDF Reports';

  @override
  String get aiRiskPrediction => 'AI Risk Prediction';

  @override
  String get ecgLiveLabel => 'Live - SpO2 96%';

  @override
  String get navReport => 'Report';

  @override
  String get navProfileLabel => 'Profile';

  @override
  String get quickActionPDF => 'PDF';

  @override
  String get quickActionStats => 'Stats';

  @override
  String get historyTitle => 'Night History';

  @override
  String get searchHint => 'Search...';

  @override
  String get filterAll => 'All';

  @override
  String get filterGood => 'Good';

  @override
  String get filterFair => 'Average';

  @override
  String get filterBad => 'Poor';

  @override
  String get historyLoadError => 'Unable to load history.';

  @override
  String get historyEmpty =>
      'No history found. Start a monitoring session to see data here.';

  @override
  String scoreEntry(Object score) {
    return 'Score: $score';
  }

  @override
  String apneasEntry(Object count) {
    return 'Apneas: $count';
  }

  @override
  String get alertsAllMarkedRead => 'All alerts marked as read.';

  @override
  String get alertDeleteError => 'Error during deletion.';

  @override
  String get alertsCenterTitle => 'Alerts Center';

  @override
  String get markAllReadButton => 'Mark all read';

  @override
  String get alertsLoadError => 'Unable to load alerts.';

  @override
  String alertsCriticalSection(Object count) {
    return '🚨 Critical ($count)';
  }

  @override
  String alertsWarningSection(Object count) {
    return '⚠️ Warnings ($count)';
  }

  @override
  String alertsInfoSection(Object count) {
    return 'ℹ️ Information ($count)';
  }

  @override
  String get noActiveAlertsTitle => 'No active alerts';

  @override
  String get allVitalsNormalMessage =>
      'All good! Your vital signs are within normal limits.';

    @override
    String get startConversationPrompt => 'Start a conversation';

  @override
  String get deleteAlertDialogTitle => 'Delete alert';

  @override
  String get deleteAlertDialogContent => 'Do you want to delete this alert?';

  @override
  String get devicesTitle => 'Sensor Management';

  @override
  String get connectionStatusLabel => 'Connection status:';

  @override
  String get deviceConnectedLabel => '🟢 Connected';

  @override
  String get activeSensorsLabel => 'Active sensors:';

  @override
  String get disconnectButton => 'Disconnect';

  @override
  String get searchNewDeviceButton => 'Search new device';

  @override
  String get accessDeniedTitle => 'Access Denied';

  @override
  String get accessDeniedMessage =>
      'You don\'t have permission to access this page.';

  @override
  String get backToHomeButton => 'Back to home';
}
