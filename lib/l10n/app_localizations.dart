import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('ar'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'SleepApnea Detect'**
  String get appTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @appPreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'App Preferences'**
  String get appPreferencesTitle;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get languageFrench;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get languageArabic;

  /// No description provided for @darkModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkModeLabel;

  /// No description provided for @notificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsLabel;

  /// No description provided for @infoSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Information & Support'**
  String get infoSupportTitle;

  /// No description provided for @helpFaqLabel.
  ///
  /// In en, this message translates to:
  /// **'Help & FAQ'**
  String get helpFaqLabel;

  /// No description provided for @privacyPolicyLabel.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicyLabel;

  /// No description provided for @aboutLabel.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutLabel;

  /// No description provided for @aboutInProgressMessage.
  ///
  /// In en, this message translates to:
  /// **'About page is under preparation.'**
  String get aboutInProgressMessage;

  /// No description provided for @logoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logoutLabel;

  /// No description provided for @deleteAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountLabel;

  /// No description provided for @homeLabel.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeLabel;

  /// No description provided for @patientsLabel.
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get patientsLabel;

  /// No description provided for @alertsLabel.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alertsLabel;

  /// No description provided for @settingsShortLabel.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsShortLabel;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get accountTitle;

  /// No description provided for @editProfileLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfileLabel;

  /// No description provided for @changePasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePasswordLabel;

  /// No description provided for @biometricLoginLabel.
  ///
  /// In en, this message translates to:
  /// **'Biometric login'**
  String get biometricLoginLabel;

  /// No description provided for @biometricSoonMessage.
  ///
  /// In en, this message translates to:
  /// **'Biometric login will be available soon.'**
  String get biometricSoonMessage;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPasswordLabel;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordLabel;

  /// No description provided for @confirmNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPasswordLabel;

  /// No description provided for @updateLabel.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateLabel;

  /// No description provided for @updatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Updating...'**
  String get updatingLabel;

  /// No description provided for @passwordFillAllFieldsError.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields.'**
  String get passwordFillAllFieldsError;

  /// No description provided for @passwordConfirmationMismatchError.
  ///
  /// In en, this message translates to:
  /// **'Confirmation does not match the password.'**
  String get passwordConfirmationMismatchError;

  /// No description provided for @passwordMinLengthError.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get passwordMinLengthError;

  /// No description provided for @passwordLettersNumbersError.
  ///
  /// In en, this message translates to:
  /// **'Password must contain letters and numbers.'**
  String get passwordLettersNumbersError;

  /// No description provided for @passwordUpdateSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully.'**
  String get passwordUpdateSuccessMessage;

  /// No description provided for @passwordUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Update failed: {error}'**
  String passwordUpdateError(Object error);

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @alertsCenterLabel.
  ///
  /// In en, this message translates to:
  /// **'Alerts center'**
  String get alertsCenterLabel;

  /// No description provided for @apneaAlertsLabel.
  ///
  /// In en, this message translates to:
  /// **'Apnea alerts'**
  String get apneaAlertsLabel;

  /// No description provided for @remindersLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersLabel;

  /// No description provided for @sensorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sensors'**
  String get sensorsTitle;

  /// No description provided for @manageDevicesLabel.
  ///
  /// In en, this message translates to:
  /// **'Manage devices'**
  String get manageDevicesLabel;

  /// No description provided for @connectionGuideLabel.
  ///
  /// In en, this message translates to:
  /// **'Connection guide'**
  String get connectionGuideLabel;

  /// No description provided for @historyLabel.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyLabel;

  /// No description provided for @monitoringShortLabel.
  ///
  /// In en, this message translates to:
  /// **'Monitor'**
  String get monitoringShortLabel;

  /// No description provided for @relaxationLabel.
  ///
  /// In en, this message translates to:
  /// **'Relax'**
  String get relaxationLabel;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginTitle;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginButton;

  /// No description provided for @signUpButton.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUpButton;

  /// No description provided for @forgotPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordButton;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role:'**
  String get roleLabel;

  /// No description provided for @roleRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please select a role'**
  String get roleRequiredError;

  /// No description provided for @rolePatient.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get rolePatient;

  /// No description provided for @roleDoctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get roleDoctor;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get emailRequiredError;

  /// No description provided for @emailInvalidError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get emailInvalidError;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get passwordRequiredError;

  /// No description provided for @passwordMin6Error.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMin6Error;

  /// No description provided for @showPasswordTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPasswordTooltip;

  /// No description provided for @hidePasswordTooltip.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePasswordTooltip;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get unexpectedError;

  /// No description provided for @loginErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Login error'**
  String get loginErrorGeneric;

  /// No description provided for @loginUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email.'**
  String get loginUserNotFound;

  /// No description provided for @loginWrongCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get loginWrongCredentials;

  /// No description provided for @loginInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email.'**
  String get loginInvalidEmail;

  /// No description provided for @firebaseAuthNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Firebase Auth is not configured (enable Email/Password in Firebase Console > Authentication > Sign-in method).'**
  String get firebaseAuthNotConfigured;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordInstruction.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to reset your password'**
  String get forgotPasswordInstruction;

  /// No description provided for @sendResetLinkButton.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLinkButton;

  /// No description provided for @resetLinkSentMessage.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent to your email.'**
  String get resetLinkSentMessage;

  /// No description provided for @resetLinkSendError.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset link.'**
  String get resetLinkSendError;

  /// No description provided for @backToLoginButton.
  ///
  /// In en, this message translates to:
  /// **'← Back to login'**
  String get backToLoginButton;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerTitle;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullNameLabel;

  /// No description provided for @fullNameRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get fullNameRequiredError;

  /// No description provided for @dateOfBirthLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of birth (YYYY-MM-DD)'**
  String get dateOfBirthLabel;

  /// No description provided for @dateOfBirthRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your date of birth'**
  String get dateOfBirthRequiredError;

  /// No description provided for @genderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender: '**
  String get genderLabel;

  /// No description provided for @genderMaleShort.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get genderMaleShort;

  /// No description provided for @genderFemaleShort.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get genderFemaleShort;

  /// No description provided for @genderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genderOther;

  /// No description provided for @genderRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please select your gender.'**
  String get genderRequiredMessage;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @phoneRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get phoneRequiredError;

  /// No description provided for @profilePhotoUrlOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile photo (URL) - optional'**
  String get profilePhotoUrlOptionalLabel;

  /// No description provided for @urlInvalidError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid URL (http/https)'**
  String get urlInvalidError;

  /// No description provided for @specializationLabel.
  ///
  /// In en, this message translates to:
  /// **'Specialization'**
  String get specializationLabel;

  /// No description provided for @specializationRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please enter the specialization'**
  String get specializationRequiredError;

  /// No description provided for @medicalLicenseNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Medical license number'**
  String get medicalLicenseNumberLabel;

  /// No description provided for @medicalLicenseNumberRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please enter the license number'**
  String get medicalLicenseNumberRequiredError;

  /// No description provided for @yearsOfExperienceLabel.
  ///
  /// In en, this message translates to:
  /// **'Years of experience'**
  String get yearsOfExperienceLabel;

  /// No description provided for @yearsOfExperienceRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please enter years of experience'**
  String get yearsOfExperienceRequiredError;

  /// No description provided for @clinicHospitalLabel.
  ///
  /// In en, this message translates to:
  /// **'Clinic / Hospital'**
  String get clinicHospitalLabel;

  /// No description provided for @clinicHospitalRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please enter the clinic or hospital'**
  String get clinicHospitalRequiredError;

  /// No description provided for @numberInvalidError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get numberInvalidError;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @confirmPasswordRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get confirmPasswordRequiredError;

  /// No description provided for @passwordsDontMatchError.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDontMatchError;

  /// No description provided for @acceptTermsLabel.
  ///
  /// In en, this message translates to:
  /// **'I accept the Terms of Use'**
  String get acceptTermsLabel;

  /// No description provided for @acceptMedicalConsentLabel.
  ///
  /// In en, this message translates to:
  /// **'Medical consent'**
  String get acceptMedicalConsentLabel;

  /// No description provided for @acceptTermsConsentRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please accept the Terms of Use and medical consent to continue.'**
  String get acceptTermsConsentRequiredMessage;

  /// No description provided for @doctorProfessionalInfoRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please complete the doctor\'s professional information.'**
  String get doctorProfessionalInfoRequiredMessage;

  /// No description provided for @registerEmailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already in use.'**
  String get registerEmailAlreadyInUse;

  /// No description provided for @registerWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak (minimum 6 characters).'**
  String get registerWeakPassword;

  /// No description provided for @registerErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Registration error.'**
  String get registerErrorGeneric;

  /// No description provided for @registerDatabaseError.
  ///
  /// In en, this message translates to:
  /// **'Database error during registration.'**
  String get registerDatabaseError;

  /// No description provided for @firestoreWriteDenied.
  ///
  /// In en, this message translates to:
  /// **'Firestore write denied. Please check security rules.'**
  String get firestoreWriteDenied;

  /// No description provided for @alreadyHaveAccountLoginButton.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAccountLoginButton;

  /// No description provided for @roleMismatchError.
  ///
  /// In en, this message translates to:
  /// **'The selected role does not match this account ({role}).'**
  String roleMismatchError(Object role);

  /// No description provided for @splashFooterVersion.
  ///
  /// In en, this message translates to:
  /// **'v1.0.0'**
  String get splashFooterVersion;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @scoreExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get scoreExcellent;

  /// No description provided for @scoreAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get scoreAverage;

  /// No description provided for @scorePoor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get scorePoor;

  /// No description provided for @sessionExpiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please reconnect.'**
  String get sessionExpiredMessage;

  /// No description provided for @errorLoadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile loading error.'**
  String get errorLoadingProfile;

  /// No description provided for @errorLoadingMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Measurement loading error.'**
  String get errorLoadingMeasurements;

  /// No description provided for @normalLabel.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normalLabel;

  /// No description provided for @moderateLabel.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get moderateLabel;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @unknownDate.
  ///
  /// In en, this message translates to:
  /// **'Unknown date'**
  String get unknownDate;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @sleepScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Sleep score'**
  String get sleepScoreLabel;

  /// No description provided for @outOf100.
  ///
  /// In en, this message translates to:
  /// **'out of 100'**
  String get outOf100;

  /// No description provided for @eventsLabel.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get eventsLabel;

  /// No description provided for @avgSpo2Label.
  ///
  /// In en, this message translates to:
  /// **'Avg SpO₂'**
  String get avgSpo2Label;

  /// No description provided for @avgHeartRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg HR'**
  String get avgHeartRateLabel;

  /// No description provided for @temperatureLabel.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperatureLabel;

  /// No description provided for @stopMonitoringButton.
  ///
  /// In en, this message translates to:
  /// **'Stop monitoring'**
  String get stopMonitoringButton;

  /// No description provided for @startMonitoringButton.
  ///
  /// In en, this message translates to:
  /// **'Start monitoring'**
  String get startMonitoringButton;

  /// No description provided for @lastSessionLabel.
  ///
  /// In en, this message translates to:
  /// **'Last session: 0h 45min'**
  String get lastSessionLabel;

  /// No description provided for @noMeasurementsMessage.
  ///
  /// In en, this message translates to:
  /// **'No measurements available. Start a session to begin.'**
  String get noMeasurementsMessage;

  /// No description provided for @sectionOverview.
  ///
  /// In en, this message translates to:
  /// **'Global Overview'**
  String get sectionOverview;

  /// No description provided for @sectionAIAnalysis.
  ///
  /// In en, this message translates to:
  /// **'AI & Risk Analysis'**
  String get sectionAIAnalysis;

  /// No description provided for @sectionECGSignal.
  ///
  /// In en, this message translates to:
  /// **'Real-time ECG Signal'**
  String get sectionECGSignal;

  /// No description provided for @sectionCriticalPatients.
  ///
  /// In en, this message translates to:
  /// **'Critical Patients'**
  String get sectionCriticalPatients;

  /// No description provided for @sectionQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get sectionQuickActions;

  /// No description provided for @statPatients.
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get statPatients;

  /// No description provided for @statCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get statCritical;

  /// No description provided for @statAIAnalyzed.
  ///
  /// In en, this message translates to:
  /// **'AI Analyzed'**
  String get statAIAnalyzed;

  /// No description provided for @statPDFReports.
  ///
  /// In en, this message translates to:
  /// **'PDF Reports'**
  String get statPDFReports;

  /// No description provided for @aiRiskPrediction.
  ///
  /// In en, this message translates to:
  /// **'AI Risk Prediction'**
  String get aiRiskPrediction;

  /// No description provided for @ecgLiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Live - SpO2 96%'**
  String get ecgLiveLabel;

  /// No description provided for @navReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get navReport;

  /// No description provided for @navProfileLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfileLabel;

  /// No description provided for @quickActionPDF.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get quickActionPDF;

  /// No description provided for @quickActionStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get quickActionStats;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Night History'**
  String get historyTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchHint;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get filterGood;

  /// No description provided for @filterFair.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get filterFair;

  /// No description provided for @filterBad.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get filterBad;

  /// No description provided for @historyLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load history.'**
  String get historyLoadError;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No history found. Start a monitoring session to see data here.'**
  String get historyEmpty;

  /// No description provided for @scoreEntry.
  ///
  /// In en, this message translates to:
  /// **'Score: {score}'**
  String scoreEntry(Object score);

  /// No description provided for @apneasEntry.
  ///
  /// In en, this message translates to:
  /// **'Apneas: {count}'**
  String apneasEntry(Object count);

  /// No description provided for @alertsAllMarkedRead.
  ///
  /// In en, this message translates to:
  /// **'All alerts marked as read.'**
  String get alertsAllMarkedRead;

  /// No description provided for @alertDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Error during deletion.'**
  String get alertDeleteError;

  /// No description provided for @alertsCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts Center'**
  String get alertsCenterTitle;

  /// No description provided for @markAllReadButton.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllReadButton;

  /// No description provided for @alertsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load alerts.'**
  String get alertsLoadError;

  /// No description provided for @alertsCriticalSection.
  ///
  /// In en, this message translates to:
  /// **'🚨 Critical ({count})'**
  String alertsCriticalSection(Object count);

  /// No description provided for @alertsWarningSection.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Warnings ({count})'**
  String alertsWarningSection(Object count);

  /// No description provided for @alertsInfoSection.
  ///
  /// In en, this message translates to:
  /// **'ℹ️ Information ({count})'**
  String alertsInfoSection(Object count);

  /// No description provided for @noActiveAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'No active alerts'**
  String get noActiveAlertsTitle;

  /// No description provided for @allVitalsNormalMessage.
  ///
  /// In en, this message translates to:
  /// **'All good! Your vital signs are within normal limits.'**
  String get allVitalsNormalMessage;

  /// No description provided for @deleteAlertDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete alert'**
  String get deleteAlertDialogTitle;

  /// No description provided for @deleteAlertDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete this alert?'**
  String get deleteAlertDialogContent;

  /// No description provided for @devicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Sensor Management'**
  String get devicesTitle;

  /// No description provided for @connectionStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Connection status:'**
  String get connectionStatusLabel;

  /// No description provided for @deviceConnectedLabel.
  ///
  /// In en, this message translates to:
  /// **'🟢 Connected'**
  String get deviceConnectedLabel;

  /// No description provided for @activeSensorsLabel.
  ///
  /// In en, this message translates to:
  /// **'Active sensors:'**
  String get activeSensorsLabel;

  /// No description provided for @disconnectButton.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnectButton;

  /// No description provided for @searchNewDeviceButton.
  ///
  /// In en, this message translates to:
  /// **'Search new device'**
  String get searchNewDeviceButton;

  /// No description provided for @accessDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Access Denied'**
  String get accessDeniedTitle;

  /// No description provided for @accessDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to access this page.'**
  String get accessDeniedMessage;

  /// No description provided for @backToHomeButton.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get backToHomeButton;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
