import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../screens/admin/system_settings_screen.dart';
import 'curved_app_bar.dart';

class AdminShell extends StatefulWidget {
  final Widget child;
  final String location;

  const AdminShell({
    super.key,
    required this.child,
    required this.location,
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  int _currentIndex = 0;

  final List<AdminNavItem> _navItems = [
    AdminNavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'الرئيسية',
      route: '/admin',
      color: const Color(0xFF4CAF50), // أخضر
    ),
    AdminNavItem(
      icon: Icons.school_outlined,
      activeIcon: Icons.school,
      label: 'الطلاب',
      route: '/admin/students',
      color: const Color(0xFF2196F3), // أزرق
    ),
    AdminNavItem(
      icon: Icons.supervisor_account_outlined,
      activeIcon: Icons.supervisor_account,
      label: 'المشرفين',
      route: '/admin/supervisors',
      color: const Color(0xFF9C27B0), // بنفسجي
    ),
    AdminNavItem(
      icon: Icons.directions_bus_outlined,
      activeIcon: Icons.directions_bus,
      label: 'السيارات',
      route: '/admin/buses',
      color: const Color(0xFFFF9800), // برتقالي
    ),
    AdminNavItem(
      icon: Icons.family_restroom_outlined,
      activeIcon: Icons.family_restroom,
      label: 'الأولياء',
      route: '/admin/parents',
      color: const Color(0xFF795548), // بني
    ),
    AdminNavItem(
      icon: Icons.assessment_outlined,
      activeIcon: Icons.assessment,
      label: 'التقارير',
      route: '/admin/reports',
      color: const Color(0xFFE91E63), // وردي
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
    _updateCurrentIndex();
  }

  @override
  void didUpdateWidget(AdminShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      _updateCurrentIndex();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateCurrentIndex() {
    int newIndex = 0;
    String currentLocation = widget.location;

    debugPrint('🔍 AdminShell: Updating index for location: $currentLocation');

    // تحديد الصفحة النشطة بدقة أكبر
    if (currentLocation == '/admin') {
      newIndex = 0;
    } else if (currentLocation.startsWith('/admin/students')) {
      newIndex = 1;
    } else if (currentLocation.startsWith('/admin/supervisors')) {
      newIndex = 2;
    } else if (currentLocation.startsWith('/admin/buses')) {
      newIndex = 3;
    } else if (currentLocation.startsWith('/admin/parents')) {
      newIndex = 4;
    } else if (currentLocation.startsWith('/admin/reports')) {
      newIndex = 5;
    } else if (currentLocation.startsWith('/admin/complaints')) {
      newIndex = 5; // نفس index التقارير لأن الشكاوى جزء من التقارير
    }

    debugPrint('🎯 AdminShell: Current index: $_currentIndex, New index: $newIndex');

    if (_currentIndex != newIndex) {
      setState(() {
        _currentIndex = newIndex;
      });
      debugPrint('✅ AdminShell: Index updated to $newIndex');
    }
  }

  bool _shouldShowBackButton() {
    // عرض زر الرجوع في الصفحات الفرعية فقط (مثل تعديل الطالب، إضافة طالب، إلخ)
    return widget.location != '/admin' &&
           widget.location != '/admin/students' &&
           widget.location != '/admin/supervisors' &&
           widget.location != '/admin/buses' &&
           widget.location != '/admin/parents' &&
           widget.location != '/admin/reports' &&
           widget.location != '/admin/complaints';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: EnhancedCurvedAppBar(
        title: _getPageTitle(),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: _shouldShowBackButton(),
        leading: _shouldShowBackButton() ? IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            context.go('/admin');
          },
        ) : null,
        subtitle: _getPageSubtitle(),
        actions: [
          ..._getPageActions(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              switch (value) {
                case 'logout':
                  await _logout();
                  break;
              }
            },
            itemBuilder: (context) => [

              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  String _getPageTitle() {
    switch (widget.location) {
      case '/admin':
        return 'باصي - الإدارة';
      case '/admin/students':
        return 'إدارة الطلاب';
      case '/admin/supervisors':
        return 'إدارة المشرفين';
      case '/admin/buses':
        return 'إدارة الحافلات';
      case '/admin/parents':
        return 'إدارة أولياء الأمور';
      case '/admin/reports':
        return 'التقارير والإحصائيات';
      case '/admin/complaints':
        return 'إدارة الشكاوى';
      case '/admin/add-student':
        return 'إضافة طالب جديد';
      case '/admin/advanced-analytics':
        return 'التحليلات المتقدمة';
      default:
        if (widget.location.contains('/admin/students/edit/')) {
          return 'تعديل بيانات الطالب';
        }
        return 'باصي - الإدارة';
    }
  }

  Widget? _getPageSubtitle() {
    switch (widget.location) {
      case '/admin':
        return const Text('لوحة التحكم الرئيسية');
      case '/admin/students':
        return const Text('إضافة وتعديل بيانات الطلاب');
      case '/admin/supervisors':
        return const Text('إدارة المشرفين والصلاحيات');
      case '/admin/buses':
        return const Text('إدارة أسطول الحافلات');
      case '/admin/parents':
        return const Text('إدارة حسابات أولياء الأمور');
      case '/admin/reports':
        return const Text('تقارير شاملة وإحصائيات مفصلة');
      case '/admin/complaints':
        return const Text('متابعة وحل الشكاوى');
      case '/admin/add-student':
        return const Text('إضافة طالب جديد للنظام');
      case '/admin/advanced-analytics':
        return const Text('تحليلات متقدمة ورؤى ذكية');
      default:
        if (widget.location.contains('/admin/students/edit/')) {
          return const Text('تحديث بيانات الطالب');
        }
        return null;
    }
  }

  List<Widget> _getPageActions() {
    // إضافة إشعارات الأدمن في جميع الصفحات
    List<Widget> actions = [];

    // إضافة أيقونة الإشعارات للأدمن
    actions.add(
      StreamBuilder<int>(
        stream: DatabaseService().getAdminNotificationsCount(),
        builder: (context, snapshot) {
          final notificationCount = snapshot.data ?? 0;
          final hasNotifications = notificationCount > 0;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: Icon(
                    hasNotifications ? Icons.notifications_active : Icons.notifications,
                    color: hasNotifications ? Colors.yellow : Colors.white,
                  ),
                  onPressed: () => _showAdminNotifications(),
                  tooltip: hasNotifications
                      ? '$notificationCount إشعار جديد'
                      : 'الإشعارات',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    foregroundColor: Colors.white,
                  ),
                ),
                if (hasNotifications)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        notificationCount > 99 ? '99+' : notificationCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );

    switch (widget.location) {
      case '/admin/supervisors':
        actions.addAll([
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              // يمكن إضافة وظيفة إضافة مشرف هنا
            },
            tooltip: 'إضافة مشرف',
          ),
        ]);
        break;
      case '/admin/buses':
        actions.addAll([
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              // يمكن إضافة وظيفة إضافة سيارة هنا
            },
            tooltip: 'إضافة سيارة',
          ),
        ]);
        break;
      case '/admin/parents':
        actions.addAll([
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              // يمكن إضافة وظيفة إضافة ولي أمر هنا
            },
            tooltip: 'إضافة ولي أمر',
          ),
        ]);
        break;
      default:
        break;
    }

    return actions;
  }

  Widget _buildBottomNavigationBar() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            height: 75,
            margin: const EdgeInsets.fromLTRB(10, 6, 10, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.grey.shade100,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
          ),
        );
      },
    );
  }

  Widget _buildNavItem(AdminNavItem item, bool isSelected, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(item, index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          margin: const EdgeInsets.symmetric(horizontal: 0.5),
          decoration: BoxDecoration(
            color: isSelected
                ? item.color == const Color(0xFF4CAF50) ? Colors.green.shade50 :
                  item.color == const Color(0xFF2196F3) ? Colors.blue.shade50 :
                  item.color == const Color(0xFF9C27B0) ? Colors.purple.shade50 :
                  item.color == const Color(0xFFFF9800) ? Colors.orange.shade50 :
                  Colors.pink.shade50
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? item.activeIcon : item.icon,
                color: isSelected ? item.color : Colors.grey[600],
                size: isSelected ? 24 : 22,
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  color: isSelected ? item.color : Colors.grey[600],
                  fontSize: isSelected ? 12 : 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onItemTapped(AdminNavItem item, int index) {
    debugPrint('🔥 AdminShell: Item tapped - ${item.label} (index: $index, route: ${item.route})');
    debugPrint('🔥 AdminShell: Current location: ${widget.location}');

    HapticFeedback.lightImpact();

    // تحديث الحالة فوراً
    setState(() {
      _currentIndex = index;
    });

    _animationController.reset();
    _animationController.forward();

    if (widget.location != item.route) {
      debugPrint('🚀 AdminShell: Navigating to ${item.route}');
      context.go(item.route);
    } else {
      debugPrint('⚠️ AdminShell: Already at ${item.route}');
    }
  }

  Future<void> _logout() async {
    try {
      await AuthService().signOut();
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تسجيل الخروج: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }









  // دالة لعرض إشعارات الأدمن
  void _showAdminNotifications() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.admin_panel_settings, color: Color(0xFF1E88E5)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'إشعارات الأدمن',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E88E5),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: DatabaseService().getRecentGeneralNotifications(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('لا توجد إشعارات حديثة'),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final notification = snapshot.data![index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: const Icon(Icons.admin_panel_settings, color: Colors.blue),
                            title: Text(notification['title'] ?? 'إشعار إداري'),
                            subtitle: Text(notification['body'] ?? ''),
                            trailing: Text(
                              '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final Color color;

  AdminNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    required this.color,
  });
}
