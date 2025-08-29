import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class AdminBottomNav extends StatefulWidget {
  final String currentRoute;
  
  const AdminBottomNav({
    super.key,
    required this.currentRoute,
  });

  @override
  State<AdminBottomNav> createState() => _AdminBottomNavState();
}

class _AdminBottomNavState extends State<AdminBottomNav> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final List<NavItem> _navItems = [
    NavItem(
      icon: Icons.dashboard,
      activeIcon: Icons.dashboard,
      label: 'الرئيسية',
      route: '/admin',
      color: const Color(0xFF4CAF50),
    ),
    NavItem(
      icon: Icons.school_outlined,
      activeIcon: Icons.school,
      label: 'الطلاب',
      route: '/admin/students',
      color: const Color(0xFF2196F3),
    ),
    NavItem(
      icon: Icons.supervisor_account_outlined,
      activeIcon: Icons.supervisor_account,
      label: 'المشرفين',
      route: '/admin/supervisors',
      color: const Color(0xFF9C27B0),
    ),
    NavItem(
      icon: Icons.family_restroom_outlined,
      activeIcon: Icons.family_restroom,
      label: 'الأولياء',
      route: '/admin/parents',
      color: const Color(0xFFFF9800),
    ),
    NavItem(
      icon: Icons.assessment_outlined,
      activeIcon: Icons.assessment,
      label: 'التقارير',
      route: '/admin/reports',
      color: const Color(0xFFE91E63),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  int get _currentIndex {
    for (int i = 0; i < _navItems.length; i++) {
      if (widget.currentRoute.startsWith(_navItems[i].route)) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            height: 85,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: Colors.grey.withAlpha(13),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _navItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = index == _currentIndex;
                  
                  return _buildNavItem(item, isSelected, index);
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(NavItem item, bool isSelected, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(item, index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? item.color == const Color(0xFF4CAF50) ? Colors.green.shade50 :
                  item.color == const Color(0xFF2196F3) ? Colors.blue.shade50 :
                  item.color == const Color(0xFF9C27B0) ? Colors.purple.shade50 :
                  item.color == const Color(0xFFFF9800) ? Colors.orange.shade50 :
                  Colors.pink.shade50
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.all(isSelected ? 8 : 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? item.color == const Color(0xFF4CAF50) ? Colors.green.shade100 :
                        item.color == const Color(0xFF2196F3) ? Colors.blue.shade100 :
                        item.color == const Color(0xFF9C27B0) ? Colors.purple.shade100 :
                        item.color == const Color(0xFFFF9800) ? Colors.orange.shade100 :
                        Colors.pink.shade100
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: isSelected ? item.color : Colors.grey[600],
                  size: isSelected ? 28 : 26,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  color: isSelected ? item.color : Colors.grey[600],
                  fontSize: isSelected ? 14 : 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
                child: Text(item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onItemTapped(NavItem item, int index) {
    HapticFeedback.lightImpact();
    
    if (widget.currentRoute != item.route) {
      _animationController.reset();
      _animationController.forward();
      context.go(item.route);
    }
  }
}

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final Color color;

  NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    required this.color,
  });
}


