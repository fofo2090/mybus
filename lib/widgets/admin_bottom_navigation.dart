import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminBottomNavigation extends StatelessWidget {
  final int currentIndex;

  const AdminBottomNavigation({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1E88E5),
            Color(0xFF1976D2),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: currentIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'الطلاب',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bus),
            label: 'الحافلات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: 'التقارير',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
        onTap: (index) => _onItemTapped(context, index),
      ),
    );
  }

  void _onItemTapped(BuildContext context, int index) {
    // تجنب التنقل إذا كنا بالفعل في نفس الصفحة
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        context.go('/admin');
        break;
      case 1:
        context.push('/admin/students');
        break;
      case 2:
        context.push('/admin/buses-management');
        break;
      case 3:
        context.push('/admin/reports');
        break;
      case 4:
        context.push('/admin/settings');
        break;
    }
  }
}
