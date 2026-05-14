import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:apnea_project/router/app_router.dart';

class DoctorBottomNavigationBar extends StatelessWidget {
  final int currentIndex;

  const DoctorBottomNavigationBar({required this.currentIndex, super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Patients'),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_active),
          label: 'Alertes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.description),
          label: 'Rapport',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Param.'),
      ],
      currentIndex: currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go(RouteNames.doctorDashboard);
            break;
          case 1:
            context.go(RouteNames.doctorPatients);
            break;
          case 2:
            context.go(RouteNames.doctorAlerts);
            break;
          case 3:
            context.go(RouteNames.doctorReports);
            break;
          case 4:
            context.go(RouteNames.doctorSettings);
            break;
        }
      },
    );
  }
}
