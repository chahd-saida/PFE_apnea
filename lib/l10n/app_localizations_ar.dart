// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'SleepApnea Detect';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get appPreferencesTitle => 'تفضيلات التطبيق';

  @override
  String get languageLabel => 'اللغة';

  @override
  String get languageFrench => 'الفرنسية';

  @override
  String get languageEnglish => 'الإنجليزية';

  @override
  String get languageArabic => 'العربية';

  @override
  String get darkModeLabel => 'الوضع الداكن';

  @override
  String get notificationsLabel => 'الإشعارات';

  @override
  String get infoSupportTitle => 'معلومات ودعم';

  @override
  String get helpFaqLabel => 'مساعدة والأسئلة الشائعة';

  @override
  String get privacyPolicyLabel => 'سياسة الخصوصية';

  @override
  String get aboutLabel => 'حول';

  @override
  String get aboutInProgressMessage => 'صفحة حول قيد التحضير.';

  @override
  String get logoutLabel => 'تسجيل الخروج';

  @override
  String get deleteAccountLabel => 'حذف الحساب';

  @override
  String get homeLabel => 'الرئيسية';

  @override
  String get patientsLabel => 'المرضى';

  @override
  String get alertsLabel => 'التنبيهات';

  @override
  String get settingsShortLabel => 'الإعدادات';

  @override
  String get accountTitle => 'حسابي';

  @override
  String get editProfileLabel => 'تعديل الملف الشخصي';

  @override
  String get changePasswordLabel => 'تغيير كلمة المرور';

  @override
  String get biometricLoginLabel => 'تسجيل الدخول بالبصمة';

  @override
  String get biometricSoonMessage => 'تسجيل الدخول بالبصمة سيكون متاحا قريبا.';

  @override
  String get currentPasswordLabel => 'كلمة المرور الحالية';

  @override
  String get newPasswordLabel => 'كلمة المرور الجديدة';

  @override
  String get confirmNewPasswordLabel => 'تأكيد كلمة المرور الجديدة';

  @override
  String get updateLabel => 'تحديث';

  @override
  String get updatingLabel => 'جار التحديث...';

  @override
  String get passwordFillAllFieldsError => 'يرجى ملء جميع الحقول.';

  @override
  String get passwordConfirmationMismatchError =>
      'التأكيد لا يطابق كلمة المرور.';

  @override
  String get passwordMinLengthError =>
      'يجب أن تكون كلمة المرور 8 أحرف على الأقل.';

  @override
  String get passwordLettersNumbersError =>
      'يجب أن تحتوي كلمة المرور على أحرف وأرقام.';

  @override
  String get passwordUpdateSuccessMessage => 'تم تحديث كلمة المرور بنجاح.';

  @override
  String passwordUpdateError(Object error) {
    return 'فشل التحديث: $error';
  }

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get alertsCenterLabel => 'مركز التنبيهات';

  @override
  String get apneaAlertsLabel => 'تنبيهات انقطاع النفس';

  @override
  String get remindersLabel => 'التذكيرات';

  @override
  String get sensorsTitle => 'المستشعرات';

  @override
  String get manageDevicesLabel => 'إدارة الأجهزة';

  @override
  String get connectionGuideLabel => 'دليل الاتصال';

  @override
  String get historyLabel => 'السجل';

  @override
  String get monitoringShortLabel => 'مراقبة';

  @override
  String get relaxationLabel => 'استرخاء';

  @override
  String get loginTitle => 'تسجيل الدخول';

  @override
  String get loginButton => 'تسجيل الدخول';

  @override
  String get signUpButton => 'إنشاء حساب';

  @override
  String get forgotPasswordButton => 'هل نسيت كلمة المرور؟';

  @override
  String get roleLabel => 'الدور:';

  @override
  String get roleRequiredError => 'يرجى اختيار دور';

  @override
  String get rolePatient => 'مريض';

  @override
  String get roleDoctor => 'طبيب';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get emailRequiredError => 'يرجى إدخال بريدك الإلكتروني';

  @override
  String get emailInvalidError => 'يرجى إدخال بريد إلكتروني صحيح';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get passwordRequiredError => 'يرجى إدخال كلمة المرور';

  @override
  String get passwordMin6Error => 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';

  @override
  String get showPasswordTooltip => 'إظهار كلمة المرور';

  @override
  String get hidePasswordTooltip => 'إخفاء كلمة المرور';

  @override
  String get unexpectedError => 'حدث خطأ غير متوقع';

  @override
  String get loginErrorGeneric => 'خطأ في تسجيل الدخول';

  @override
  String get loginUserNotFound => 'لا يوجد حساب بهذا البريد الإلكتروني.';

  @override
  String get loginWrongCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String get loginInvalidEmail => 'بريد إلكتروني غير صحيح.';

  @override
  String get firebaseAuthNotConfigured =>
      'لم يتم إعداد Firebase Auth (فعّل تسجيل البريد/كلمة المرور من Firebase Console > Authentication > Sign-in method).';

  @override
  String get forgotPasswordTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get forgotPasswordInstruction =>
      'أدخل بريدك الإلكتروني لإعادة تعيين كلمة المرور';

  @override
  String get sendResetLinkButton => 'إرسال رابط إعادة التعيين';

  @override
  String get resetLinkSentMessage =>
      'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني.';

  @override
  String get resetLinkSendError => 'تعذر إرسال رابط إعادة التعيين.';

  @override
  String get backToLoginButton => '← العودة لتسجيل الدخول';

  @override
  String get registerTitle => 'إنشاء حساب';

  @override
  String get fullNameLabel => 'الاسم الكامل';

  @override
  String get fullNameRequiredError => 'يرجى إدخال الاسم الكامل';

  @override
  String get dateOfBirthLabel => 'تاريخ الميلاد (YYYY-MM-DD)';

  @override
  String get dateOfBirthRequiredError => 'يرجى إدخال تاريخ الميلاد';

  @override
  String get genderLabel => 'الجنس: ';

  @override
  String get genderMaleShort => 'ذ';

  @override
  String get genderFemaleShort => 'أ';

  @override
  String get genderOther => 'آخر';

  @override
  String get genderRequiredMessage => 'يرجى اختيار الجنس.';

  @override
  String get phoneLabel => 'الهاتف';

  @override
  String get phoneRequiredError => 'يرجى إدخال رقم الهاتف';

  @override
  String get profilePhotoUrlOptionalLabel =>
      'صورة الملف الشخصي (URL) - اختياري';

  @override
  String get urlInvalidError => 'يرجى إدخال رابط صحيح (http/https)';

  @override
  String get specializationLabel => 'التخصص';

  @override
  String get specializationRequiredError => 'يرجى إدخال التخصص';

  @override
  String get medicalLicenseNumberLabel => 'رقم رخصة مزاولة المهنة';

  @override
  String get medicalLicenseNumberRequiredError => 'يرجى إدخال رقم الرخصة';

  @override
  String get yearsOfExperienceLabel => 'سنوات الخبرة';

  @override
  String get yearsOfExperienceRequiredError => 'يرجى إدخال سنوات الخبرة';

  @override
  String get clinicHospitalLabel => 'العيادة / المستشفى';

  @override
  String get clinicHospitalRequiredError =>
      'يرجى إدخال اسم العيادة أو المستشفى';

  @override
  String get numberInvalidError => 'يرجى إدخال رقم صحيح';

  @override
  String get confirmPasswordLabel => 'تأكيد كلمة المرور';

  @override
  String get confirmPasswordRequiredError => 'يرجى تأكيد كلمة المرور';

  @override
  String get passwordsDontMatchError => 'كلمتا المرور غير متطابقتين';

  @override
  String get acceptTermsLabel => 'أوافق على شروط الاستخدام';

  @override
  String get acceptMedicalConsentLabel => 'الموافقة الطبية';

  @override
  String get acceptTermsConsentRequiredMessage =>
      'يرجى الموافقة على شروط الاستخدام والموافقة الطبية للمتابعة.';

  @override
  String get doctorProfessionalInfoRequiredMessage =>
      'يرجى استكمال معلومات الطبيب المهنية.';

  @override
  String get registerEmailAlreadyInUse =>
      'هذا البريد الإلكتروني مستخدم بالفعل.';

  @override
  String get registerWeakPassword => 'كلمة المرور ضعيفة (6 أحرف على الأقل).';

  @override
  String get registerErrorGeneric => 'خطأ أثناء إنشاء الحساب.';

  @override
  String get registerDatabaseError => 'خطأ في قاعدة البيانات أثناء التسجيل.';

  @override
  String get firestoreWriteDenied =>
      'تم رفض الكتابة في Firestore. تحقق من قواعد الأمان.';

  @override
  String get alreadyHaveAccountLoginButton => 'لديك حساب بالفعل؟ تسجيل الدخول';

  @override
  String roleMismatchError(Object role) {
    return 'الدور المحدد لا يطابق هذا الحساب ($role).';
  }

  @override
  String get splashFooterVersion => 'v1.0.0';

  @override
  String get greetingMorning => 'صباح الخير';

  @override
  String get greetingAfternoon => 'مساء الخير';

  @override
  String get greetingEvening => 'تصبح على خير';

  @override
  String get scoreExcellent => 'ممتاز';

  @override
  String get scoreAverage => 'متوسط';

  @override
  String get scorePoor => 'ضعيف';

  @override
  String get sessionExpiredMessage => 'انتهت الجلسة. يرجى إعادة الاتصال.';

  @override
  String get errorLoadingProfile => 'خطأ في تحميل الملف الشخصي.';

  @override
  String get errorLoadingMeasurements => 'خطأ في تحميل القياسات.';

  @override
  String get normalLabel => 'طبيعي';

  @override
  String get moderateLabel => 'معتدل';

  @override
  String get cancelButton => 'إلغاء';

  @override
  String get deleteButton => 'حذف';

  @override
  String get unknownDate => 'تاريخ غير معروف';

  @override
  String get dashboardTitle => 'لوحة القيادة';

  @override
  String get sleepScoreLabel => 'نقاط النوم';

  @override
  String get outOf100 => 'من 100';

  @override
  String get eventsLabel => 'الأحداث';

  @override
  String get avgSpo2Label => 'متوسط SpO₂';

  @override
  String get avgHeartRateLabel => 'متوسط ضربات القلب';

  @override
  String get temperatureLabel => 'الحرارة';

  @override
  String get stopMonitoringButton => 'إيقاف المراقبة';

  @override
  String get startMonitoringButton => 'بدء المراقبة';

  @override
  String get lastSessionLabel => 'آخر جلسة: 0س 45د';

  @override
  String get noMeasurementsMessage => 'لا توجد قياسات متاحة. ابدأ جلسة للبدء.';

  @override
  String get sectionOverview => 'نظرة عامة';

  @override
  String get sectionAIAnalysis => 'الذكاء الاصطناعي وتحليل المخاطر';

  @override
  String get sectionECGSignal => 'إشارة تخطيط القلب الفوري';

  @override
  String get sectionCriticalPatients => 'المرضى الحرجون';

  @override
  String get sectionQuickActions => 'إجراءات سريعة';

  @override
  String get statPatients => 'المرضى';

  @override
  String get statCritical => 'الحرجون';

  @override
  String get statAIAnalyzed => 'محللو الذكاء الاصطناعي';

  @override
  String get statPDFReports => 'تقارير PDF';

  @override
  String get aiRiskPrediction => 'توقع المخاطر بالذكاء الاصطناعي';

  @override
  String get ecgLiveLabel => 'مباشر - SpO2 96%';

  @override
  String get navReport => 'تقرير';

  @override
  String get navProfileLabel => 'الملف الشخصي';

  @override
  String get quickActionPDF => 'PDF';

  @override
  String get quickActionStats => 'إحصاء';

  @override
  String get historyTitle => 'سجل الليالي';

  @override
  String get searchHint => 'بحث...';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterGood => 'جيدة';

  @override
  String get filterFair => 'متوسطة';

  @override
  String get filterBad => 'سيئة';

  @override
  String get historyLoadError => 'تعذر تحميل السجل.';

  @override
  String get historyEmpty =>
      'لا يوجد سجل. ابدأ جلسة مراقبة لرؤية البيانات هنا.';

  @override
  String scoreEntry(Object score) {
    return 'النتيجة: $score';
  }

  @override
  String apneasEntry(Object count) {
    return 'الانقطاعات: $count';
  }

  @override
  String get alertsAllMarkedRead => 'تم تحديد جميع التنبيهات كمقروءة.';

  @override
  String get alertDeleteError => 'خطأ أثناء الحذف.';

  @override
  String get alertsCenterTitle => 'مركز التنبيهات';

  @override
  String get markAllReadButton => 'تحديد الكل كمقروء';

  @override
  String get alertsLoadError => 'تعذر تحميل التنبيهات.';

  @override
  String alertsCriticalSection(Object count) {
    return '🚨 حرجة ($count)';
  }

  @override
  String alertsWarningSection(Object count) {
    return '⚠️ تحذيرات ($count)';
  }

  @override
  String alertsInfoSection(Object count) {
    return 'ℹ️ معلومات ($count)';
  }

  @override
  String get noActiveAlertsTitle => 'لا توجد تنبيهات نشطة';

  @override
  String get allVitalsNormalMessage =>
      'كل شيء على ما يرام! معدلاتك الحيوية ضمن الحدود الطبيعية.';

  @override
  String get startConversationPrompt => 'ابدأ المحادثة';

  @override
  String get deleteAlertDialogTitle => 'حذف التنبيه';

  @override
  String get deleteAlertDialogContent => 'هل تريد حذف هذا التنبيه؟';

  @override
  String get devicesTitle => 'إدارة المستشعرات';

  @override
  String get connectionStatusLabel => 'حالة الاتصال:';

  @override
  String get deviceConnectedLabel => '🟢 متصل';

  @override
  String get activeSensorsLabel => 'المستشعرات النشطة:';

  @override
  String get disconnectButton => 'فصل';

  @override
  String get searchNewDeviceButton => 'البحث عن جهاز جديد';

  @override
  String get accessDeniedTitle => 'رفض الوصول';

  @override
  String get accessDeniedMessage => 'ليس لديك إذن للوصول إلى هذه الصفحة.';

  @override
  String get backToHomeButton => 'العودة إلى الرئيسية';
}
