import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:apnea_project/router/app_router.dart';
import 'package:apnea_project/providers/user_profile_provider.dart';

class DashboardDoctorScreen extends StatefulWidget {
  const DashboardDoctorScreen({super.key});

  @override
  State<DashboardDoctorScreen> createState() => _DashboardDoctorScreenState();
}

class _DashboardDoctorScreenState extends State<DashboardDoctorScreen> with SingleTickerProviderStateMixin {
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
    final doctorProfile = useDoctorProfile(context);
    final doctorName = doctorProfile?.fullName ?? 'Médecin';
    final clinicName = doctorProfile?.clinicName ?? 'Centre de Pneumologie et Sommeil';
    final photoUrl = doctorProfile?.profileImageUrl;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCustomHeader(doctorName, clinicName, photoUrl, context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildSectionTitle('Aperçu Global', Icons.dashboard_rounded),
                  const SizedBox(height: 16),
                  _buildStatsGrid(),
                  const SizedBox(height: 30),
                  _buildSectionTitle('IA & Analyse de Risque', Icons.psychology),
                  const SizedBox(height: 16),
                  _buildAIAnalysisSection(),
                  const SizedBox(height: 30),
                  _buildSectionTitle('Signal ECG en Temps Réel', Icons.monitor_heart),
                  const SizedBox(height: 16),
                  _buildECGSection(),
                  const SizedBox(height: 30),
                  _buildSectionTitle('Patients Critiques', Icons.warning_amber_rounded),
                  const SizedBox(height: 16),
                  _buildCriticalAlerts(context),
                  const SizedBox(height: 30),
                  _buildSectionTitle('Actions Rapides', Icons.flash_on_rounded),
                  const SizedBox(height: 16),
                  _buildQuickActions(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildCustomHeader(String name, String clinic, String? photoUrl, BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 24,
        right: 24,
        bottom: 30,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 8)),
        ],
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
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
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.business_center, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        clinic,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => context.push(RouteNames.doctorProfile),
            child: Hero(
              tag: 'profilePic',
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFE2E8F0),
                  backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                  child: (photoUrl == null || photoUrl.isEmpty)
                      ? const Icon(Icons.person, color: Color(0xFF64748B), size: 30)
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      children: [
        _buildStatCard('Patients', '24', Icons.people_alt, const Color(0xFF3B82F6)),
        _buildStatCard('Critiques', '2', Icons.notification_important, const Color(0xFFEF4444)),
        _buildStatCard('IA Analysés', '15', Icons.biotech, const Color(0xFF8B5CF6)),
        _buildStatCard('Rapports PDF', '8', Icons.picture_as_pdf, const Color(0xFF10B981)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 22),
              ),
              Icon(Icons.arrow_outward, color: Colors.grey.shade400, size: 16),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildAIAnalysisSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E1065), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6D28D9).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Prédiction IA des Risques',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Patient: Ahmed Ben',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          const Text(
            '85% de risque de crise d\'apnée (IA basée sur chute SpO2 combinée)',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 0.85,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF43F5E)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildECGSection() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: GridPainter(),
              ),
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
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  const Text('Direct - SpO2 96%', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Positioned(
              top: 16,
              right: 16,
              child: Text('BPM 72', style: TextStyle(color: Color(0xFF10B981), fontSize: 20, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCriticalAlerts(BuildContext context) {
    return Column(
      children: [
        _buildAlertCard(
          context: context,
          patientName: 'Karim Dupont',
          alert: '5 apnées sévères (>30s) détectées',
          time: 'Il y a 10 min',
          isCritical: true,
        ),
        const SizedBox(height: 12),
        _buildAlertCard(
          context: context,
          patientName: 'Marie Curie',
          alert: 'Chute SpO2 relative (84%)',
          time: 'Il y a 1 heure',
          isCritical: false,
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
  }) {
    Color statusColor = isCritical ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: statusColor, width: 6)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Icon(isCritical ? Icons.warning_rounded : Icons.notifications_active, color: statusColor),
        ),
        title: Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(alert, style: const TextStyle(color: Color(0xFF475569))),
            const SizedBox(height: 6),
            Text(time, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        onTap: () {
          final encodedPatientId = Uri.encodeComponent('sample-patient-id');
          context.push(RouteNames.doctorPatientProfile(encodedPatientId));
        },
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionButton(context, 'PDF', Icons.picture_as_pdf_rounded, const Color(0xFF3B82F6), () => context.go(RouteNames.doctorReports)),
        _buildActionButton(context, 'Patients', Icons.people_alt_rounded, const Color(0xFF10B981), () => context.go(RouteNames.doctorPatients)),
        _buildActionButton(context, 'Stats', Icons.analytics_rounded, const Color(0xFF8B5CF6), () => context.go(RouteNames.doctorMessages)),
        _buildActionButton(context, 'Paramètres', Icons.settings_rounded, const Color(0xFF64748B), () => context.go(RouteNames.doctorSettings)),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 22, color: const Color(0xFF1E3A8A)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A8A),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: const Color(0xFF1E3A8A).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, Icons.home_rounded, 'Accueil', true, () {}),
            _buildNavItem(context, Icons.people_rounded, 'Patients', false, () => context.go(RouteNames.doctorPatients)),
            _buildNavItem(context, Icons.notifications_rounded, 'Alertes', false, () => context.go(RouteNames.doctorAlerts)),
            _buildNavItem(context, Icons.insert_chart_rounded, 'Rapport', false, () => context.go(RouteNames.doctorReports)),
            _buildNavItem(context, Icons.settings_rounded, 'Profil', false, () => context.go(RouteNames.doctorSettings)),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: isSelected
            ? BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white70,
          size: 26,
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class EcgPainter extends CustomPainter {
  final double progress;
  EcgPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF10B981)
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
      ..color = const Color(0xFF10B981).withValues(alpha: 0.2)
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
  bool shouldRepaint(covariant EcgPainter oldDelegate) => oldDelegate.progress != progress;
}
