import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/providers/user_profile_provider.dart';
import 'package:apnea_project/providers/theme_provider.dart';
import 'package:apnea_project/l10n/app_localizations.dart';
import 'package:apnea_project/theme/app_colors.dart';
import 'package:apnea_project/theme/app_dimensions.dart';
import 'package:apnea_project/widgets/chatbot_fab.dart';
import 'package:apnea_project/widgets/doctor_bottom_navigation_bar.dart';

class DashboardDoctorScreen extends StatefulWidget {
  const DashboardDoctorScreen({super.key});

  @override
  State<DashboardDoctorScreen> createState() => _DashboardDoctorScreenState();
}

class _DashboardDoctorScreenState extends State<DashboardDoctorScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ecgController;

  @override
  void initState() {
    super.initState();
    _ecgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _ecgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final doctorProfile = useDoctorProfile(context);
    final doctorName = doctorProfile?.fullName ?? 'Médecin';
    final photoUrl = doctorProfile?.profileImageUrl;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom Header
            _buildCustomHeader(
              name: doctorName,
              clinic: 'Centre Médical',
              photoUrl: photoUrl,
              context: context,
              isDark: isDark,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildSectionTitle(
                    l10n.sectionOverview,
                    Icons.dashboard_rounded,
                    isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildStatsGrid(l10n, isDark),
                  const SizedBox(height: 30),
                  _buildSectionTitle(
                    l10n.sectionAIAnalysis,
                    Icons.psychology,
                    isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildAIAnalysisSection(l10n, isDark),
                  const SizedBox(height: 30),
                  _buildSectionTitle(
                    l10n.sectionECGSignal,
                    Icons.monitor_heart,
                    isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildECGSection(l10n, isDark),
                  const SizedBox(height: 30),
                  _buildSectionTitle(
                    l10n.sectionCriticalPatients,
                    Icons.warning_amber_rounded,
                    isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildCriticalAlerts(context, isDark),
                  const SizedBox(height: 30),
                  _buildSectionTitle(
                    l10n.sectionQuickActions,
                    Icons.flash_on_rounded,
                    isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildQuickActions(context, l10n, isDark),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: const DoctorChatbotFAB(),
      bottomNavigationBar: const DoctorBottomNavigationBar(currentIndex: 0),
    );
  }

  Widget _buildCustomHeader({
    required String name,
    required String clinic,
    String? photoUrl,
    required BuildContext context,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 24,
        right: 24,
        bottom: 30,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dr. $name',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                  semanticsLabel: 'Docteur $name',
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.business_center,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        clinic,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        semanticsLabel: 'Clinique: $clinic',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            enabled: true,
            label: 'Profil médecin',
            child: InkWell(
              onTap: () => context.push(RouteNames.doctorProfile),
              customBorder: CircleBorder(),
              child: Hero(
                tag: 'profilePic',
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.surfaceLight,
                    backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                        ? NetworkImage(photoUrl)
                        : null,
                    child: (photoUrl == null || photoUrl.isEmpty)
                        ? Icon(
                            Icons.person,
                            color: AppColors.textMedium,
                            size: 30,
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(AppLocalizations l10n, bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(
          l10n.statPatients,
          '24',
          Icons.people_alt,
          AppColors.primaryLight,
          isDark,
        ),
        _buildStatCard(
          l10n.statCritical,
          '2',
          Icons.notification_important,
          AppColors.error,
          isDark,
        ),
        _buildStatCard(
          l10n.statAIAnalyzed,
          '15',
          Icons.biotech,
          AppColors.aiPrimary,
          isDark,
        ),
        _buildStatCard(
          l10n.statPDFReports,
          '8',
          Icons.picture_as_pdf,
          AppColors.success,
          isDark,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Icon(
                  Icons.trending_up,
                  color: AppColors.textLight,
                  size: 16,
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textDark,
              ),
              semanticsLabel: '$title: $value',
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIAnalysisSection(AppLocalizations l10n, bool isDark) {
    return Semantics(
      container: true,
      enabled: true,
      label: 'Section analyse IA',
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.aiDark,
              AppColors.aiPrimary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.aiPrimary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.aiRiskPrediction,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    semanticsLabel: 'Prédiction de risque IA',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Patient: Ahmed Ben',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              semanticsLabel: 'Nom du patient: Ahmed Ben',
            ),
            const SizedBox(height: 8),
            Text(
              '85% de risque de crise d\'apnée',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              semanticsLabel: 'Risque de crise apnée: 85 pourcent',
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const LinearProgressIndicator(
                value: 0.85,
                minHeight: 8,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.rosePink),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildECGSection(AppLocalizations l10n, bool isDark) {
    return Semantics(
      container: true,
      label: 'Signal ECG en direct',
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: GridPainter(isDark: isDark)),
              ),
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _ecgController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: EcgPainter(_ecgController.value),
                    );
                  },
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Semantics(
                  live: true,
                  label: 'Signal ECG en direct',
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.ecgLiveLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Semantics(
                  label: 'Battements par minute: 72',
                  child: const Text(
                    'BPM 72',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCriticalAlerts(BuildContext context, bool isDark) {
    return Column(
      children: [
        _buildAlertCard(
          context: context,
          patientName: 'Karim Dupont',
          alert: '5 apnées sévères (>30s) détectées',
          time: 'Il y a 10 min',
          isCritical: true,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildAlertCard(
          context: context,
          patientName: 'Marie Curie',
          alert: 'Chute SpO2 relative (84%)',
          time: 'Il y a 1 heure',
          isCritical: false,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildAlertCard({
    required BuildContext context,
    required String patientName,
    required String alert,
    required String time,
    required bool isCritical,
    required bool isDark,
  }) {
    final statusColor = isCritical ? AppColors.error : AppColors.warning;

    return Semantics(
      container: true,
      label: 'Alerte patient: $patientName',
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: statusColor, width: 5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: CircleAvatar(
            backgroundColor: statusColor.withOpacity(0.15),
            child: Icon(
              isCritical ? Icons.warning_rounded : Icons.notifications_active,
              color: statusColor,
              size: 22,
            ),
          ),
          title: Text(
            patientName,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: isDark ? Colors.white : AppColors.textDark,
            ),
            semanticsLabel: 'Patient: $patientName',
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text(
                alert,
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textBody,
                  fontSize: 13,
                ),
                semanticsLabel: 'Alerte: $alert',
              ),
              const SizedBox(height: 6),
              Text(
                time,
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          trailing: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: AppColors.textMedium,
          ),
          onTap: () {
            final encodedPatientId = Uri.encodeComponent('sample-patient-id');
            context.push(RouteNames.doctorPatientProfile(encodedPatientId));
          },
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AppLocalizations l10n, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionButton(
          context,
          l10n.quickActionPDF,
          Icons.picture_as_pdf_rounded,
          AppColors.primaryLight,
          () => context.go(RouteNames.doctorReports),
          isDark,
        ),
        _buildActionButton(
          context,
          l10n.patientsLabel,
          Icons.people_alt_rounded,
          AppColors.success,
          () => context.go(RouteNames.doctorPatients),
          isDark,
        ),
        _buildActionButton(
          context,
          l10n.quickActionStats,
          Icons.analytics_rounded,
          AppColors.aiPrimary,
          () => context.go(RouteNames.doctorMessages),
          isDark,
        ),
        _buildActionButton(
          context,
          l10n.settingsTitle,
          Icons.settings_rounded,
          AppColors.textMedium,
          () => context.go(RouteNames.doctorSettings),
          isDark,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isDark,
  ) {
    return Semantics(
      button: true,
      enabled: true,
      label: label,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textBody,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Semantics(
      header: true,
      label: title,
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final bool isDark;
  
  GridPainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.05)
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class EcgPainter extends CustomPainter {
  final double progress;
  EcgPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.success
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    double width = size.width;
    double midY = size.height / 2;

    int cycles = 5;
    double cycleWidth = width / cycles;

    path.moveTo(0, midY);
    for (int i = 0; i < cycles; i++) {
      double startX = i * cycleWidth;
      path.lineTo(startX + cycleWidth * 0.2, midY);
      path.lineTo(startX + cycleWidth * 0.3, midY - 20); // P
      path.lineTo(startX + cycleWidth * 0.4, midY + 10); // Q
      path.lineTo(startX + cycleWidth * 0.5, midY - 60); // R
      path.lineTo(startX + cycleWidth * 0.6, midY + 30); // S
      path.lineTo(startX + cycleWidth * 0.7, midY);
      path.lineTo(startX + cycleWidth * 0.8, midY - 15); // T
      path.lineTo(startX + cycleWidth * 0.9, midY);
      path.lineTo(startX + cycleWidth, midY);
    }

    final fadedPaint = Paint()
      ..color = AppColors.success.withOpacity(0.2)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, fadedPaint);

    double revealWidth = width * progress;
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, revealWidth, size.height));
    canvas.drawPath(path, paint);
    canvas.restore();

    final headPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(revealWidth, midY), 4, headPaint);
  }

  @override
  bool shouldRepaint(covariant EcgPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
