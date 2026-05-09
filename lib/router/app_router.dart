import 'package:go_router/go_router.dart';

import 'package:apnea_project/providers/auth_provider.dart';
import 'package:apnea_project/screens/auth/forgot_password_screen.dart';
import 'package:apnea_project/screens/auth/login_screen.dart';
import 'package:apnea_project/screens/auth/register_screen.dart';
import 'package:apnea_project/screens/doctor/dashboard_doctor_screen.dart';
import 'package:apnea_project/screens/doctor/doctor_alerts_center_screen.dart';
import 'package:apnea_project/screens/doctor/doctor_analysis_screen.dart';
import 'package:apnea_project/screens/doctor/doctor_messages_screen.dart';
import 'package:apnea_project/screens/doctor/doctor_patient_profile_screen.dart';
import 'package:apnea_project/screens/doctor/doctor_patients_list_screen.dart';
import 'package:apnea_project/screens/doctor/doctor_profile_screen.dart';
import 'package:apnea_project/screens/doctor/doctor_reports_screen.dart';
import 'package:apnea_project/screens/doctor/doctor_settings_screen.dart';
import 'package:apnea_project/screens/patient/dashboard_patient_screen.dart';
import 'package:apnea_project/screens/patient/devices_screen.dart';
import 'package:apnea_project/screens/patient/history_screen.dart';
import 'package:apnea_project/screens/patient/night_detail_screen.dart';
import 'package:apnea_project/screens/patient/patient_alerts_screen.dart';
import 'package:apnea_project/screens/patient/patient_profile_screen.dart';
import 'package:apnea_project/screens/patient/patient_settings_screen.dart';
import 'package:apnea_project/screens/patient/relaxation_content_screen.dart';
import 'package:apnea_project/screens/patient/realtime_monitoring_screen.dart';
import 'package:apnea_project/screens/patient/relaxation_screen.dart';
import 'package:apnea_project/screens/shared/export_report_screen.dart';
import 'package:apnea_project/screens/shared/access_denied_screen.dart';
import 'package:apnea_project/screens/shared/fix_profile_screen.dart';
import 'package:apnea_project/screens/shared/help_screen.dart';
import 'package:apnea_project/screens/shared/logout_screen.dart';
import 'package:apnea_project/screens/shared/privacy_screen.dart';
import 'package:apnea_project/screens/shared/splash_screen.dart';
import 'package:apnea_project/screens/shared/chatbot_screen.dart';
import 'package:apnea_project/screens/doctor/doctor_chatbot_screen.dart';
import 'package:apnea_project/screens/patient/patient_chatbot_screen.dart';

class RouteNames {
  static const authPrefix = '/auth';
  static const doctorPrefix = '/doctor';
  static const patientPrefix = '/patient';
  static const nightDetailPrefix = '/night-detail/';

  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  static const patientDashboard = '/patient-dashboard';
  static const patientHistory = '/patient-history';
  static const realtimeMonitoring = '/realtime-monitoring';
  static const relaxation = '/relaxation';
  static const patientSettings = '/patient-settings';
  static const patientDevices = '/patient-devices';
  static const patientAlerts = '/patient-alerts';
  static const patientProfile = '/patient-profile';
  static const meditationDetailPath = '/meditation-detail/:title';
  static const videoDetailPath = '/video-detail/:title';
  static const articleDetailPath = '/article-detail/:title';
  static const createMeditation = '/create-meditation';
  static const addVideo = '/add-video';
  static const addArticle = '/add-article';

  static const doctorDashboard = '/doctor-dashboard';
  static const doctorPatients = '/doctor-patients';
  static const doctorAlerts = '/doctor-alerts';
  static const doctorReports = '/doctor-reports';
  static const doctorMessages = '/doctor-messages';
  static const doctorProfile = '/doctor-profile';
  static const doctorSettings = '/doctor-settings';
  static const doctorPatientProfilePath = '/doctor-patient-profile/:patientId';
  static const doctorAnalysisPath = '/doctor-analysis/:patientId/:nightDate';

  static const nightDetailPath = '/night-detail/:nightId';
  static const exportReport = '/export-report';
  static const help = '/help';
  static const privacy = '/privacy';
  static const logout = '/logout';
  static const accessDenied = '/access-denied';
  static const fixProfile = '/fix-profile';

  static String nightDetail(String nightId) => '/night-detail/$nightId';
  static String doctorPatientProfile(String patientId) =>
      '/doctor-patient-profile/$patientId';
  static String doctorAnalysis(String patientId, String nightDate) =>
      '/doctor-analysis/$patientId/$nightDate';
  static String meditationDetail(String title) =>
      '/meditation-detail/${Uri.encodeComponent(title)}';
  static String videoDetail(String title) =>
      '/video-detail/${Uri.encodeComponent(title)}';
  static String articleDetail(String title) =>
      '/article-detail/${Uri.encodeComponent(title)}';
  static const chatbot = '/chatbot';
  static const patientChatbot = '/patient-chatbot';
  static const doctorChatbot = '/doctor-chatbot';
}

GoRouter createAppRouter(
  AuthProvider authProvider, {
  String initialLocation = RouteNames.splash,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: authProvider,
    routes: [
      GoRoute(
        path: RouteNames.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        name: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RouteNames.patientDashboard,
        name: RouteNames.patientDashboard,
        builder: (context, state) => const DashboardPatientScreen(),
      ),
      GoRoute(
        path: RouteNames.doctorDashboard,
        name: RouteNames.doctorDashboard,
        builder: (context, state) => const DashboardDoctorScreen(),
      ),
      GoRoute(
        path: RouteNames.realtimeMonitoring,
        name: RouteNames.realtimeMonitoring,
        builder: (context, state) => const RealtimeMonitoringScreen(),
      ),
      GoRoute(
        path: RouteNames.patientHistory,
        name: RouteNames.patientHistory,
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: RouteNames.nightDetailPath, // '/night-detail/:nightId'
        builder: (context, state) {
          final nightId = state.pathParameters['nightId'] ?? '';
          return NightDetailScreen(nightId: nightId);
        },
      ),
      GoRoute(
        path: RouteNames.relaxation,
        name: RouteNames.relaxation,
        builder: (context, state) => const RelaxationScreen(),
      ),
      GoRoute(
        path: RouteNames.meditationDetailPath,
        name: RouteNames.meditationDetailPath,
        builder: (context, state) => RelaxationContentScreen(
          title: state.pathParameters['title'] ?? 'Meditation',
          contentType: 'meditation',
        ),
      ),
      GoRoute(
        path: RouteNames.videoDetailPath,
        name: RouteNames.videoDetailPath,
        builder: (context, state) => RelaxationContentScreen(
          title: state.pathParameters['title'] ?? 'Video',
          contentType: 'video',
        ),
      ),
      GoRoute(
        path: RouteNames.articleDetailPath,
        name: RouteNames.articleDetailPath,
        builder: (context, state) => RelaxationContentScreen(
          title: state.pathParameters['title'] ?? 'Article',
          contentType: 'article',
        ),
      ),
      GoRoute(
        path: RouteNames.createMeditation,
        name: RouteNames.createMeditation,
        builder: (context, state) => const RelaxationContentScreen(
          title: 'Creer une meditation personnalisee',
          contentType: 'create-meditation',
        ),
      ),
      GoRoute(
        path: RouteNames.addVideo,
        name: RouteNames.addVideo,
        builder: (context, state) => const RelaxationContentScreen(
          title: 'Ajouter une video relaxante',
          contentType: 'add-video',
        ),
      ),
      GoRoute(
        path: RouteNames.addArticle,
        name: RouteNames.addArticle,
        builder: (context, state) => const RelaxationContentScreen(
          title: 'Ajouter un article bien-etre',
          contentType: 'add-article',
        ),
      ),
      GoRoute(
        path: RouteNames.patientSettings,
        name: RouteNames.patientSettings,
        builder: (context, state) => const PatientSettingsScreen(),
      ),
      GoRoute(
        path: RouteNames.patientDevices,
        name: RouteNames.patientDevices,
        builder: (context, state) => const DevicesScreen(),
      ),
      GoRoute(
        path: RouteNames.patientAlerts,
        name: RouteNames.patientAlerts,
        builder: (context, state) => const PatientAlertsScreen(),
      ),
      GoRoute(
        path: RouteNames.patientProfile,
        name: RouteNames.patientProfile,
        builder: (context, state) => const PatientProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.exportReport,
        name: RouteNames.exportReport,
        builder: (context, state) => const ExportReportScreen(),
      ),
      GoRoute(
        path: RouteNames.doctorPatients,
        name: RouteNames.doctorPatients,
        builder: (context, state) => const DoctorPatientsListScreen(),
      ),
      GoRoute(
        path: RouteNames.doctorPatientProfilePath,
        name: RouteNames.doctorPatientProfilePath,
        builder: (context, state) => DoctorPatientProfileScreen(
          patientId: state.pathParameters['patientId']!,
        ),
      ),
      GoRoute(
        path: RouteNames.doctorAnalysisPath,
        name: RouteNames.doctorAnalysisPath,
        builder: (context, state) => DoctorAnalysisScreen(
          patientId: state.pathParameters['patientId']!,
          nightDate: state.pathParameters['nightDate']!,
        ),
      ),
      GoRoute(
        path: RouteNames.doctorAlerts,
        name: RouteNames.doctorAlerts,
        builder: (context, state) => const DoctorAlertsCenterScreen(),
      ),
      GoRoute(
        path: RouteNames.doctorReports,
        name: RouteNames.doctorReports,
        builder: (context, state) => const DoctorReportsScreen(),
      ),
      GoRoute(
        path: RouteNames.doctorMessages,
        name: RouteNames.doctorMessages,
        builder: (context, state) => const DoctorMessagesScreen(),
      ),
      GoRoute(
        path: RouteNames.doctorProfile,
        name: RouteNames.doctorProfile,
        builder: (context, state) => const DoctorProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.doctorSettings,
        name: RouteNames.doctorSettings,
        builder: (context, state) => const DoctorSettingsScreen(),
      ),
      GoRoute(
        path: RouteNames.help,
        name: RouteNames.help,
        builder: (context, state) => const HelpScreen(),
      ),
      GoRoute(
        path: RouteNames.privacy,
        name: RouteNames.privacy,
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: RouteNames.logout,
        name: RouteNames.logout,
        builder: (context, state) => const LogoutScreen(),
      ),
      GoRoute(
        path: RouteNames.accessDenied,
        name: RouteNames.accessDenied,
        builder: (context, state) => const AccessDeniedScreen(),
      ),
      GoRoute(
        path: RouteNames.fixProfile,
        name: RouteNames.fixProfile,
        builder: (context, state) => const FixProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.chatbot,
        name: RouteNames.chatbot,
        builder: (context, state) => const ChatbotScreen(),
      ),
      GoRoute(
        path: RouteNames.patientChatbot,
        name: RouteNames.patientChatbot,
        builder: (context, state) => const PatientChatbotScreen(),
      ),
      GoRoute(
        path: RouteNames.doctorChatbot,
        name: RouteNames.doctorChatbot,
        builder: (context, state) => const DoctorChatbotScreen(),
      ),
    ],
    redirect: (context, state) {
      final isLoggedIn = authProvider.user != null;
      final role = authProvider.role;
      final isLoadingRole = authProvider.isLoadingRole;
      final location = state.matchedLocation;

      final doctorOnlyPrefixes = <String>[
        RouteNames.doctorDashboard,
        RouteNames.doctorPatients,
        RouteNames.doctorAlerts,
        RouteNames.doctorReports,
        RouteNames.doctorMessages,
        RouteNames.doctorProfile,
        RouteNames.doctorSettings,
        RouteNames.doctorChatbot,
        '/doctor-patient-profile/',
        '/doctor-analysis/',
      ];
      final patientOnlyPrefixes = <String>[
        RouteNames.patientDashboard,
        RouteNames.patientHistory,
        RouteNames.patientSettings,
        RouteNames.patientDevices,
        RouteNames.patientAlerts,
        RouteNames.patientProfile,
        RouteNames.realtimeMonitoring,
        RouteNames.relaxation,
        RouteNames.patientChatbot,
        '/meditation-detail/',
        '/video-detail/',
        '/article-detail/',
        RouteNames.createMeditation,
        RouteNames.addVideo,
        RouteNames.addArticle,
        RouteNames.nightDetailPrefix,
      ];

      final isAuthRoute =
          location == RouteNames.login ||
          location == RouteNames.register ||
          location == RouteNames.forgotPassword;
      final isAccessDeniedRoute = location == RouteNames.accessDenied;
      final isFixProfileRoute = location == RouteNames.fixProfile;
      final isDoctorRoute = doctorOnlyPrefixes.any(location.startsWith);
      final isPatientRoute = patientOnlyPrefixes.any(location.startsWith);

      if (location == RouteNames.splash) {
        return null; // Let SplashScreen handle navigation via its internal timer
      }

      if (!isLoggedIn && !isAuthRoute) {
        return RouteNames.login;
      }

      if (isLoggedIn && isLoadingRole) {
        return location == RouteNames.splash ? null : RouteNames.splash;
      }

      if (isLoggedIn && role != 'doctor' && role != 'patient') {
        return isFixProfileRoute ? null : RouteNames.fixProfile;
      }

      if (isLoggedIn && isAuthRoute) {
        if (role == 'doctor') {
          return RouteNames.doctorDashboard;
        }
        if (role == 'patient') {
          return RouteNames.patientDashboard;
        }
        return RouteNames.fixProfile;
      }

      if (isLoggedIn && role == 'patient' && isDoctorRoute) {
        return isAccessDeniedRoute ? null : RouteNames.accessDenied;
      }

      if (isLoggedIn && role == 'doctor' && isPatientRoute) {
        return isAccessDeniedRoute ? null : RouteNames.accessDenied;
      }

      return null;
    },
  );
}
