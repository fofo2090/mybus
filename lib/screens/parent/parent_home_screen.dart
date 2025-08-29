import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../services/persistent_auth_service.dart';
import '../../services/database_service.dart';
import '../../services/theme_service.dart';
import '../../utils/background_utils.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/responsive_widgets.dart';

import '../../models/student_model.dart';
import '../../models/bus_model.dart';
import '../../models/trip_model.dart';
import '../../models/user_model.dart';

import '../../widgets/custom_button.dart';
import '../../widgets/curved_app_bar.dart';
import '../../widgets/student_avatar.dart';
import '../../models/absence_model.dart';
import 'school_info_screen.dart';
import 'report_absence_screen.dart';
import 'update_student_photo_screen.dart';
import 'add_student_screen.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  late PersistentAuthService _authService;
  final DatabaseService _databaseService = DatabaseService();
  List<StudentModel> _students = [];

  // User and school data
  UserModel? _currentUser;
  Map<String, dynamic> _schoolInfo = {};
  List<BusModel> _allBuses = [];

  @override
  void initState() {
    super.initState();
    _authService = Provider.of<PersistentAuthService>(context, listen: false);
    _checkProfileCompletion();
    _loadUserData();
    _loadSchoolData();
  }

  Future<void> _checkProfileCompletion() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    final isComplete = await _databaseService.isParentProfileComplete(currentUser.uid);
    if (!isComplete && mounted) {
      // إجبار المستخدم على إكمال البروفايل
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/parent/complete-profile');
      });
    }
  }

  // Load current user data
  Future<void> _loadUserData() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    try {
      final userData = await _databaseService.getUserData(currentUser.uid);
      if (userData != null && mounted) {
        setState(() {
          _currentUser = UserModel.fromMap(userData);
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // Load school information and buses
  Future<void> _loadSchoolData() async {
    try {
      // Load school info
      final schoolDoc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('school')
          .get();

      if (schoolDoc.exists && mounted) {
        setState(() {
          _schoolInfo = schoolDoc.data() ?? {};
        });
      }

      // Load all buses for emergency contacts
      final buses = await _databaseService.getBusesWithFallback();
      if (mounted) {
        setState(() {
          _allBuses = buses;
        });
      }
    } catch (e) {
      debugPrint('Error loading school data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          body: Stack(
            children: [
              AnimatedBackground(
                showChildren: true, // نريد عناصر الأطفال في صفحة ولي الأمر
                child: Column(
              children: [
                EnhancedCurvedAppBar(
                  title: 'الرئيسية',
                  subtitle: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.home,
                        size: ResponsiveHelper.getIconSize(context,
                          mobileSize: 14,
                          tabletSize: 16,
                          desktopSize: 18,
                        ),
                        color: Colors.white70,
                      ),
                      SizedBox(width: ResponsiveHelper.getSpacing(context) * 0.375),
                      Text(
                        'متابعة شاملة لرحلة أطفالك',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getFontSize(context,
                            mobileFontSize: 12,
                            tabletFontSize: 14,
                            desktopFontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                  height: ResponsiveHelper.isMobile(context) ? 200 :
                         ResponsiveHelper.isTablet(context) ? 220 : 240,
                  leadingIcon: Icons.settings,
                  onLeadingPressed: () {
                    context.push('/parent/settings');
                  },
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, size: 24),
            onPressed: () {
              context.push('/parent/profile');
            },
            tooltip: 'الملف الشخصي',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              foregroundColor: Colors.white,
            ),
          ),
          StreamBuilder<int>(
            stream: _databaseService.getParentNotificationsCount(_authService.currentUser?.uid ?? ''),
            builder: (context, snapshot) {
              final notificationCount = snapshot.data ?? 0;
              final hasNotifications = notificationCount > 0;

              return Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      hasNotifications ? Icons.notifications_active : Icons.notifications,
                      size: 24,
                      color: hasNotifications ? Colors.yellow : Colors.white,
                    ),
                    onPressed: () {
                      context.push('/parent/notifications');
                    },
                    tooltip: hasNotifications ? '$notificationCount إشعار جديد' : 'الإشعارات',
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
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          notificationCount > 99 ? '99+' : notificationCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 24),
            tooltip: 'المزيد',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              foregroundColor: Colors.white,
            ),
            onSelected: (value) {
              if (value == 'help') {
                context.push('/parent/help');
              } else if (value == 'about') {
                _showAboutDialog(context);
              } else if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'help',
                child: Row(
                  children: [
                    Icon(Icons.help_center, color: Color(0xFF1E88E5)),
                    SizedBox(width: 12),
                    Text('المساعدة والدعم'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF1E88E5)),
                    SizedBox(width: 12),
                    Text('حول التطبيق'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 12),
                    Text('تسجيل الخروج'),
                  ],
                ),
              ),
            ],
          ),
                  ],
                ),
                Expanded(
                  child: StreamBuilder<List<StudentModel>>(
        stream: _databaseService.getStudentsByParent(_authService.currentUser?.uid ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('حدث خطأ: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'إعادة المحاولة',
                    onPressed: () => setState(() {}),
                    width: 200,
                  ),
                ],
              ),
            );
          }

          final students = snapshot.data ?? [];
          _students = students; // تحديث قائمة الطلاب

          if (students.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView(
              padding: ResponsiveHelper.getPadding(context,
                mobilePadding: const EdgeInsets.all(12),
                tabletPadding: const EdgeInsets.all(16),
                desktopPadding: const EdgeInsets.all(20),
              ),
              children: [
                // Welcome Card
                _buildWelcomeCard(),
                SizedBox(height: ResponsiveHelper.getSpacing(context) * 1.25),

                // Students List
                ...students.map((student) => _buildStudentCard(student)),

                SizedBox(height: ResponsiveHelper.getSpacing(context) * 1.25),

                // Quick Actions
                _buildQuickActions(),
                ],
              ),
            );
          },
        ),
                ),
                    ],
              ),
            ),
          ],
        ),
      );
      },
    );
  }

  Widget _buildWelcomeCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: ResponsiveHelper.getPadding(context,
        mobilePadding: const EdgeInsets.all(20),
        tabletPadding: const EdgeInsets.all(28),
        desktopPadding: const EdgeInsets.all(32),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? [
            const Color(0xFF2C2C2C),
            const Color(0xFF383838),
            const Color(0xFF1E88E5).withOpacity(0.3),
          ] : [
            const Color(0xFF1E88E5),
            const Color(0xFF1976D2),
            const Color(0xFF1565C0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context) * 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E88E5).withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: ResponsiveHelper.getPadding(context,
                  mobilePadding: const EdgeInsets.all(12),
                  tabletPadding: const EdgeInsets.all(16),
                  desktopPadding: const EdgeInsets.all(20),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.25),
                      Colors.white.withOpacity(0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context) * 1.25),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.waving_hand,
                  color: Colors.white,
                  size: ResponsiveHelper.getIconSize(context,
                    mobileSize: 24,
                    tabletSize: 32,
                    desktopSize: 36,
                  ),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getSpacing(context) * 1.25),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentUser != null ? 'مرحباً بك ${_currentUser!.name}' : 'مرحباً بك',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveHelper.getFontSize(context,
                          mobileFontSize: 20,
                          tabletFontSize: 24,
                          desktopFontSize: 28,
                        ),
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getSpacing(context) * 0.5),
                    Text(
                      'تابع رحلة أطفالك بسهولة وأمان',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: ResponsiveHelper.getFontSize(context,
                          mobileFontSize: 14,
                          tabletFontSize: 16,
                          desktopFontSize: 18,
                        ),
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context) * 1.25),
          Row(
            children: [
              Expanded(
                child: StreamBuilder<int>(
                  stream: _databaseService.getParentNotificationsCount(_authService.currentUser?.uid ?? ''),
                  builder: (context, snapshot) {
                    final notificationCount = snapshot.data ?? 0;
                    final hasNotifications = notificationCount > 0;

                    return GestureDetector(
                      onTap: () {
                        context.push('/parent/notifications');
                      },
                      child: Container(
                        padding: ResponsiveHelper.getPadding(context,
                          mobilePadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          tabletPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                          desktopPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: hasNotifications ? [
                              const Color(0xFFFF6B6B).withOpacity(0.9),
                              const Color(0xFFFF8E53).withOpacity(0.8),
                            ] : [
                              Colors.white.withOpacity(0.25),
                              Colors.white.withOpacity(0.15),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: hasNotifications
                                ? Colors.white.withOpacity(0.6)
                                : Colors.white.withOpacity(0.4),
                            width: 2,
                          ),
                          boxShadow: hasNotifications ? [
                            BoxShadow(
                              color: const Color(0xFFFF6B6B).withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                              spreadRadius: 1,
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, -2),
                            ),
                          ] : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // المحتوى الرئيسي في الوسط
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    hasNotifications ? Icons.notifications_active : Icons.notifications_outlined,
                                    color: hasNotifications ? Colors.white : Colors.white.withOpacity(0.9),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'الإشعارات',
                                    style: TextStyle(
                                      color: hasNotifications ? Colors.white : Colors.white.withOpacity(0.95),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // العداد في الزاوية اليمنى العلوية
                            if (hasNotifications)
                              Positioned(
                                top: 4,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    notificationCount > 99 ? '99+' : notificationCount.toString(),
                                    style: const TextStyle(
                                      color: Color(0xFFFF6B6B),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    context.push('/parent/settings');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.settings, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'الإعدادات',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context) * 0.75),
          ResponsiveWrap(
            spacing: ResponsiveHelper.getSpacing(context) * 0.75,
            runSpacing: ResponsiveHelper.getSpacing(context) * 0.75,
            children: [
              SizedBox(
                width: ResponsiveHelper.isMobile(context)
                    ? double.infinity
                    : ResponsiveHelper.isTablet(context)
                        ? (MediaQuery.of(context).size.width - 48) / 2
                        : (MediaQuery.of(context).size.width - 72) / 3,
                child: _buildQuickActionButton(
                  icon: Icons.feedback_outlined,
                  label: 'الشكاوى والاقتراحات',
                  color: const Color(0xFFFF6B6B),
                  onTap: () {
                    context.push('/parent/complaints');
                  },
                ),
              ),
              SizedBox(
                width: ResponsiveHelper.isMobile(context)
                    ? double.infinity
                    : ResponsiveHelper.isTablet(context)
                        ? (MediaQuery.of(context).size.width - 48) / 2
                        : (MediaQuery.of(context).size.width - 72) / 3,
                child: _buildQuickActionButton(
                  icon: Icons.directions_bus_filled,
                  label: 'معلومات الباص',
                  color: const Color(0xFF20B2AA),
                  onTap: () {
                    _showBusInfoDialog();
                  },
                ),
              ),
              SizedBox(
                width: ResponsiveHelper.isMobile(context)
                    ? double.infinity
                    : ResponsiveHelper.isTablet(context)
                        ? (MediaQuery.of(context).size.width - 48) / 2
                        : (MediaQuery.of(context).size.width - 72) / 3,
                child: _buildQuickActionButton(
                  icon: Icons.supervisor_account_outlined,
                  label: 'معلومات المشرفين',
                  color: const Color(0xFF4A90E2),
                  onTap: () {
                    context.push('/parent/supervisor-info');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(StudentModel student) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveHelper.getSpacing(context) * 1.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context) * 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E88E5).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: const Color(0xFF1E88E5).withOpacity(0.08),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context) * 1.5),
        child: Container(
          padding: ResponsiveHelper.getPadding(context,
            mobilePadding: const EdgeInsets.all(18),
            tabletPadding: const EdgeInsets.all(24),
            desktopPadding: const EdgeInsets.all(28),
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark ? [
                const Color(0xFF2C2C2C),
                const Color(0xFF383838),
              ] : [
                Colors.white,
                const Color(0xFFFAFBFC),
              ],
            ),
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context) * 1.25),
                  border: Border.all(
                    color: const Color(0xFF1E88E5).withOpacity(0.1),
                    width: ResponsiveHelper.isMobile(context) ? 1.5 : 2,
                  ),
                ),
                child: StudentAvatar(
                  photoUrl: student.photoUrl,
                  studentName: student.name,
                  radius: ResponsiveHelper.isMobile(context) ? 28 :
                         ResponsiveHelper.isTablet(context) ? 32 : 36,
                  onTap: () => _showPhotoOptions(student),
                  showCameraIcon: true,
                ),
              ),
              SizedBox(width: ResponsiveHelper.getSpacing(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getFontSize(context,
                          mobileFontSize: 16,
                          tabletFontSize: 20,
                          desktopFontSize: 24,
                        ),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A202C),
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getSpacing(context) * 0.25),
                    Container(
                      padding: ResponsiveHelper.getPadding(context,
                        mobilePadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        tabletPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        desktopPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E88E5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context) * 0.5),
                      ),
                      child: Text(
                        'الصف: ${student.grade}',
                        style: TextStyle(
                          color: const Color(0xFF1E88E5),
                          fontSize: ResponsiveHelper.getFontSize(context,
                            mobileFontSize: 12,
                            tabletFontSize: 14,
                            desktopFontSize: 16,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(student.currentStatus),
            ],
          ),

          SizedBox(height: ResponsiveHelper.getSpacing(context)),

          // معلومات الطالب الخارجية
          _buildStudentInfoSection(student),
          SizedBox(height: ResponsiveHelper.getSpacing(context)),

          // Bus Assignment Info
          _buildBusAssignmentInfo(student),
          SizedBox(height: ResponsiveHelper.getSpacing(context) * 1.25),

          Row(
            children: [
              Expanded(
                child: Container(
                  height: ResponsiveHelper.isMobile(context) ? 44 :
                         ResponsiveHelper.isTablet(context) ? 48 : 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1E88E5),
                        Color(0xFF1976D2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E88E5).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context)),
                      onTap: () {
                        if (student.id.isNotEmpty) {
                          context.push('/parent/student-activity/${student.id}');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('خطأ: معرف الطالب غير صحيح'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: Center(
                        child: Text(
                          'عرض السجل',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: ResponsiveHelper.getFontSize(context,
                              mobileFontSize: 14,
                              tabletFontSize: 16,
                              desktopFontSize: 18,
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getSpacing(context)),
              Expanded(
                child: Container(
                  height: ResponsiveHelper.isMobile(context) ? 44 :
                         ResponsiveHelper.isTablet(context) ? 48 : 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF9800),
                        Color(0xFFF57C00),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF9800).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context)),
                      onTap: () {
                        if (student.id.isNotEmpty) {
                          context.push('/parent/bus-info/${student.id}');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('خطأ: معرف الطالب غير صحيح'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: Center(
                        child: Text(
                          'معلومات السيارة',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: ResponsiveHelper.getFontSize(context,
                              mobileFontSize: 13,
                              tabletFontSize: 15,
                              desktopFontSize: 17,
                            ),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(StudentStatus status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String text;

    switch (status) {
      case StudentStatus.home:
        backgroundColor = const Color(0xFF4CAF50);
        textColor = Colors.white;
        icon = Icons.home;
        text = 'في المنزل';
        break;
      case StudentStatus.onBus:
        backgroundColor = const Color(0xFFFF9800);
        textColor = Colors.white;
        icon = Icons.directions_bus;
        text = 'في الباص';
        break;
      case StudentStatus.atSchool:
        backgroundColor = const Color(0xFF1E88E5);
        textColor = Colors.white;
        icon = Icons.school;
        text = 'في المدرسة';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            backgroundColor,
            backgroundColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusAssignmentInfo(StudentModel student) {
    if (student.busId.isEmpty && student.busRoute.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFF9800).withOpacity(0.1),
              const Color(0xFFFF9800).withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFF9800).withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.info, color: Color(0xFFFF9800), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تسكين الباص',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF9800),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'لم يتم تسكين الطالب في باص بعد',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _getBusDetails(student.busId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E88E5).withOpacity(0.1),
                  const Color(0xFF1E88E5).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF1E88E5).withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('جاري تحميل معلومات الباص...'),
              ],
            ),
          );
        }

        final busData = snapshot.data;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withAlpha(76)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.directions_bus, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'معلومات الباص المُسكن',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (busData != null) ...[
                _buildBusInfoRow('نوع الباص', busData['description'] ?? 'غير محدد'),
                // Show supervisor info based on current time and assignment
                FutureBuilder<Map<String, String>>(
                  future: _databaseService.getSupervisorInfoForParent(student.busId),
                  builder: (context, supervisorSnapshot) {
                    final supervisorInfo = supervisorSnapshot.data ?? {};
                    return Column(
                      children: [
                        _buildBusInfoRow('المشرف', supervisorInfo['name'] ?? 'غير محدد'),
                        _buildBusInfoRow(
                          'هاتف المشرف',
                          supervisorInfo['phone'] ?? 'غير محدد',
                          isPhone: supervisorInfo['phone']?.isNotEmpty == true,
                        ),
                        if (supervisorInfo['direction']?.isNotEmpty == true)
                          _buildBusInfoRow('فترة الإشراف', supervisorInfo['direction']!),
                      ],
                    );
                  },
                ),
              ] else ...[
                const Text(
                  'تفاصيل الباص غير متاحة',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildBusInfoRow(String label, String value, {bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: isPhone
                ? GestureDetector(
                    onTap: () => _makePhoneCall(value),
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2D3748),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // بناء قسم معلومات الطالب الخارجية
  Widget _buildStudentInfoSection(StudentModel student) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withAlpha(76)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              const Text(
                'معلومات الطالب',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildStudentInfoRow('الاسم الكامل', student.name),
          _buildStudentInfoRow('الصف الدراسي', student.grade),
          _buildStudentInfoRow('رقم الهوية', student.qrCode.isNotEmpty ? student.qrCode : 'غير محدد'),
          _buildStudentInfoRow('المدرسة', student.schoolName.isNotEmpty ? student.schoolName : 'غير محدد'),
          _buildStudentInfoRow('العنوان', student.address.isNotEmpty ? student.address : 'غير محدد'),
          // عرض خط السير مع التحديث من قاعدة البيانات
          FutureBuilder<String>(
            future: _getStudentBusRoute(student),
            builder: (context, routeSnapshot) {
              final busRoute = routeSnapshot.data ?? 'جاري التحميل...';
              return _buildStudentInfoRow('خط السير', busRoute);
            },
          ),
          _buildStudentInfoRow('الحالة الحالية', _getStatusDisplayText(student.currentStatus.toString().split('.').last)),
          _buildStudentInfoRow('هاتف ولي الأمر', student.parentPhone, isPhone: true),
          if (student.notes.isNotEmpty)
            _buildStudentInfoRow('ملاحظات', student.notes),
        ],
      ),
    );
  }

  Widget _buildStudentInfoRow(String label, String value, {bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: isPhone
                ? GestureDetector(
                    onTap: () => _makePhoneCall(value),
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2D3748),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _getStatusDisplayText(String status) {
    switch (status) {
      case 'onBus':
        return 'في الباص';
      case 'atSchool':
        return 'في المدرسة';
      case 'home':
        return 'في المنزل';
      case 'leftSchool':
        return 'غادر المدرسة';
      case 'onWayHome':
        return 'في الطريق للمنزل';
      case 'arrivedHome':
        return 'وصل المنزل';
      case 'absent':
        return 'غائب';
      default:
        return 'في المنزل';
    }
  }

  // الحصول على خط السير من قاعدة البيانات
  Future<String> _getStudentBusRoute(StudentModel student) async {
    try {
      // أولاً، التحقق من خط السير في بيانات الطالب
      if (student.busRoute.isNotEmpty && student.busRoute.trim() != '') {
        return student.busRoute;
      }

      // إذا لم يكن موجود، جلب البيانات المحدثة من قاعدة البيانات
      final studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(student.id)
          .get();

      if (studentDoc.exists) {
        final data = studentDoc.data()!;
        final busRoute = data['busRoute'] as String? ?? '';

        if (busRoute.isNotEmpty && busRoute.trim() != '') {
          return busRoute;
        }

        // إذا لم يكن هناك خط سير، التحقق من الباص المُسكن
        final busId = data['busId'] as String? ?? '';
        if (busId.isNotEmpty) {
          final busDoc = await FirebaseFirestore.instance
              .collection('buses')
              .doc(busId)
              .get();

          if (busDoc.exists) {
            final busData = busDoc.data()!;
            final route = busData['route'] as String? ?? '';
            if (route.isNotEmpty) {
              return route;
            }
          }
        }
      }

      return 'لم يتم تحديد خط السير';
    } catch (e) {
      debugPrint('❌ Error getting bus route: $e');
      return 'خطأ في تحميل خط السير';
    }
  }

  // الحصول على خط السير مع التحقق من البيانات (للعرض السريع)
  String _getBusRouteDisplay(StudentModel student) {
    // التحقق من خط السير في بيانات الطالب
    if (student.busRoute.isNotEmpty && student.busRoute.trim() != '') {
      return student.busRoute;
    }

    return 'جاري التحميل...';
  }

  Future<Map<String, dynamic>?> _getBusDetails(String busId) async {
    if (busId.isEmpty) return null;

    try {
      final busDoc = await FirebaseFirestore.instance
          .collection('buses')
          .doc(busId)
          .get();

      if (busDoc.exists) {
        return busDoc.data();
      }
    } catch (e) {
      debugPrint('Error getting bus details: $e');
    }

    return null;
  }

  Widget _buildQuickActions() {
    return Container(
      padding: ResponsiveHelper.getPadding(context,
        mobilePadding: const EdgeInsets.all(12),
        tabletPadding: const EdgeInsets.all(16),
        desktopPadding: const EdgeInsets.all(20),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إجراءات سريعة',
            style: TextStyle(
              fontSize: ResponsiveHelper.getFontSize(context,
                mobileFontSize: 16,
                tabletFontSize: 18,
                desktopFontSize: 20,
              ),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context)),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.person_off_outlined,
                  label: 'إبلاغ غياب',
                  color: const Color(0xFFFF8C00), // برتقالي أكثر إشراقاً
                  onTap: () {
                    _showAbsenceDialog();
                  },
                ),
              ),
              SizedBox(width: ResponsiveHelper.getSpacing(context) * 0.75),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.person_add_alt_1_outlined,
                  label: 'إضافة طالب',
                  color: const Color(0xFF007AFF), // أزرق iOS أكثر إشراقاً
                  onTap: () {
                    _navigateToAddStudent();
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context) * 0.75),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.access_time,
                  label: 'مواعيد الرحلات',
                  color: Colors.green,
                  onTap: () {
                    _showScheduleDialog();
                  },
                ),
              ),
              SizedBox(width: ResponsiveHelper.getSpacing(context) * 0.75),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.phone,
                  label: 'اتصال طارئ',
                  color: Colors.red,
                  onTap: () {
                    _showEmergencyContactDialog();
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context) * 0.75),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.history_outlined,
                  label: 'سجل الرحلات',
                  color: const Color(0xFF9C27B0), // بنفسجي أكثر إشراقاً
                  onTap: () {
                    _showTripHistoryDialog();
                  },
                ),
              ),
              SizedBox(width: ResponsiveHelper.getSpacing(context) * 0.75),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.poll_outlined,
                  label: 'الاستبيانات',
                  color: const Color(0xFF3F51B5), // نيلي أكثر إشراقاً
                  onTap: () {
                    context.push('/parent/surveys');
                  },
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final buttonColor = color ?? const Color(0xFF1E88E5);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context) * 1.25),
      child: Container(
        padding: ResponsiveHelper.getPadding(context,
          mobilePadding: const EdgeInsets.all(16),
          tabletPadding: const EdgeInsets.all(20),
          desktopPadding: const EdgeInsets.all(24),
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              buttonColor.withOpacity(0.25),
              buttonColor.withOpacity(0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context) * 1.25),
          border: Border.all(
            color: buttonColor.withOpacity(0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: buttonColor.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              blurRadius: 8,
              offset: const Offset(0, -2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: ResponsiveHelper.getPadding(context,
                mobilePadding: const EdgeInsets.all(12),
                tabletPadding: const EdgeInsets.all(14),
                desktopPadding: const EdgeInsets.all(16),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    buttonColor.withOpacity(0.9),
                    buttonColor.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context)),
                boxShadow: [
                  BoxShadow(
                    color: buttonColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: ResponsiveHelper.getIconSize(context,
                  mobileSize: 24,
                  tabletSize: 32,
                  desktopSize: 36,
                ),
                color: Colors.white,
              ),
            ),
            SizedBox(height: ResponsiveHelper.getSpacing(context) * 0.875),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ResponsiveHelper.getFontSize(context,
                  mobileFontSize: 12,
                  tabletFontSize: 14,
                  desktopFontSize: 16,
                ),
                fontWeight: FontWeight.bold,
                color: buttonColor.withOpacity(0.9),
                shadows: [
                  Shadow(
                    color: Colors.white.withOpacity(0.8),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: ResponsiveHelper.getPadding(context,
          mobilePadding: const EdgeInsets.all(24),
          tabletPadding: const EdgeInsets.all(32),
          desktopPadding: const EdgeInsets.all(40),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school,
              size: ResponsiveHelper.getIconSize(context,
                mobileSize: 64,
                tabletSize: 80,
                desktopSize: 96,
              ),
              color: Colors.grey[400],
            ),
            SizedBox(height: ResponsiveHelper.getSpacing(context) * 1.25),
            Text(
              'لا توجد بيانات طلاب',
              style: TextStyle(
                fontSize: ResponsiveHelper.getFontSize(context,
                  mobileFontSize: 18,
                  tabletFontSize: 20,
                  desktopFontSize: 24,
                ),
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: ResponsiveHelper.getSpacing(context) * 0.5),
            Text(
              'لم يتم إضافة أي طلاب بعد',
              style: TextStyle(
                fontSize: ResponsiveHelper.getFontSize(context,
                  mobileFontSize: 14,
                  tabletFontSize: 16,
                  desktopFontSize: 18,
                ),
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveHelper.getSpacing(context) * 1.5),
            CustomButton(
              text: 'إضافة طالب جديد',
              onPressed: () {
                context.push('/parent/add-student');
              },
              width: ResponsiveHelper.isMobile(context) ?
                     MediaQuery.of(context).size.width * 0.8 : 200,
            ),
          ],
        ),
      ),
    );
  }



  Future<void> _logout() async {
    try {
      // تسجيل الخروج مع الحفاظ على البيانات للدخول السريع
      await _authService.signOut(clearPersistedData: false);
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

  // دالة لعرض حوار اختيار الطالب لإبلاغ الغياب
  void _showAbsenceDialog() {
    if (_students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يوجد طلاب مسجلين'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_students.length == 1) {
      // إذا كان هناك طالب واحد فقط، انتقل مباشرة لشاشة إبلاغ الغياب
      context.push('/parent/report-absence/${_students.first.id}');
    } else {
      // إذا كان هناك أكثر من طالب، اعرض حوار الاختيار
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person_off, color: Colors.orange),
              SizedBox(width: 8),
              Text('اختر الطالب'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _students.map((student) {
              return ListTile(
                leading: StudentAvatar(
                  photoUrl: student.photoUrl,
                  studentName: student.name,
                  radius: 20,
                  backgroundColor: Colors.blue.withAlpha(25),
                  textColor: Colors.blue,
                ),
                title: Text(student.name),
                subtitle: Text('الصف: ${student.grade} - الخط: ${_getBusRouteDisplay(student)}'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportAbsenceScreen(student: student),
                    ),
                  );
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
          ],
        ),
      );
    }
  }

  // دالة لعرض تاريخ الغيابات
  void _showAbsenceHistory() {
    // عرض جميع طلبات الغياب لولي الأمر
    _showParentAbsenceHistory();
  }

  // دالة لعرض جميع طلبات الغياب لولي الأمر
  void _showParentAbsenceHistory() {
    final parentId = _authService.currentUser?.uid;
    if (parentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ في تحديد هوية ولي الأمر'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.maxFinite,
          height: 500,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.history, color: Colors.indigo),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'تاريخ طلبات الغياب',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<AbsenceModel>>(
                  stream: _databaseService.getAbsencesByParent(parentId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text('خطأ في تحميل البيانات: ${snapshot.error}'),
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, size: 64, color: Colors.green),
                            SizedBox(height: 16),
                            Text(
                              'لا توجد طلبات غياب',
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(
                              'لم ترسل أي طلبات غياب بعد',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    final absences = snapshot.data!;
                    return ListView.builder(
                      itemCount: absences.length,
                      itemBuilder: (context, index) {
                        final absence = absences[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(absence.status).withAlpha(25),
                              child: Icon(
                                _getStatusIcon(absence.status),
                                color: _getStatusColor(absence.status),
                              ),
                            ),
                            title: Text('${absence.studentName} - ${absence.typeDisplayText}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('التاريخ: ${_formatDate(absence.date)}'),
                                if (absence.isMultipleDays)
                                  Text('إلى: ${_formatDate(absence.endDate!)}'),
                                Text('السبب: ${absence.reason}'),
                                if (absence.notes != null)
                                  Text('ملاحظات: ${absence.notes}'),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(absence.status),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                absence.statusDisplayText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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



  // دوال مساعدة لعرض تاريخ الغيابات
  Color _getStatusColor(AbsenceStatus status) {
    switch (status) {
      case AbsenceStatus.pending:
        return Colors.orange;
      case AbsenceStatus.approved:
        return Colors.green;
      case AbsenceStatus.rejected:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(AbsenceStatus status) {
    switch (status) {
      case AbsenceStatus.pending:
        return Icons.schedule;
      case AbsenceStatus.approved:
        return Icons.check_circle;
      case AbsenceStatus.rejected:
        return Icons.cancel;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showPhotoOptions(StudentModel student) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            StudentAvatar(
              photoUrl: student.photoUrl,
              studentName: student.name,
              radius: 40,
            ),
            const SizedBox(height: 16),
            Text(
              student.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'الصف: ${student.grade}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'تحديث صورة الطالب',
              onPressed: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UpdateStudentPhotoScreen(student: student),
                  ),
                );

                // Refresh the page if photo was updated
                if (result == true) {
                  debugPrint('🔄 Photo update confirmed, refreshing UI...');

                  // Force rebuild to refresh the StreamBuilder
                  setState(() {
                    // تحديث الواجهة
                  });

                  // Wait a moment then refresh again to ensure data is loaded
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) {
                      setState(() {
                        // تحديث الواجهة مرة أخرى
                      });
                    }
                  });

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تحديث الصورة بنجاح'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: Icons.camera_alt,
              backgroundColor: const Color(0xFF1E88E5),
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'إلغاء',
              onPressed: () => Navigator.pop(context),
              backgroundColor: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF1E88E5)),
            SizedBox(width: 12),
            Text('حول التطبيق'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'كيدز باص',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E88E5),
              ),
            ),
            SizedBox(height: 8),
            Text('تطبيق متابعة النقل المدرسي الآمن'),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.verified, color: Colors.green, size: 16),
                SizedBox(width: 6),
                Text('الإصدار: 1.0.0'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.security, color: Colors.blue, size: 16),
                SizedBox(width: 6),
                Text('حماية متقدمة للبيانات'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.support_agent, color: Colors.orange, size: 16),
                SizedBox(width: 6),
                Text('دعم فني 24/7'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  // دوال الميزات الجديدة المفيدة


  void _showScheduleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.access_time, color: Colors.green),
            SizedBox(width: 12),
            Text('مواعيد الرحلات'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'رحلة الذهاب:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Text('6:30 ص - وقت الانطلاق'),
              ],
            ),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Text('7:00 ص - الوصول للمدرسة'),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'رحلة العودة:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.orange, size: 16),
                SizedBox(width: 8),
                Text('2:00 م - وقت الانطلاق'),
              ],
            ),
            Row(
              children: [
                Icon(Icons.home, color: Colors.orange, size: 16),
                SizedBox(width: 8),
                Text('2:30 م - الوصول للمنزل'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  String _getCurrentPeriod() {
    final currentTime = DateTime.now();
    final currentHour = currentTime.hour;

    if (currentHour >= 6 && currentHour <= 10) {
      return 'فترة الذهاب';
    } else if (currentHour >= 12 && currentHour <= 18) {
      return 'فترة العودة';
    } else {
      return 'خارج أوقات العمل';
    }
  }

  // Get supervisor info for emergency contact
  Future<Map<String, String>> _getSupervisorInfo() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return {};

      // Get student data to find bus ID
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('parentId', isEqualTo: currentUser.uid)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (studentsSnapshot.docs.isEmpty) return {};

      final studentData = studentsSnapshot.docs.first.data();
      final busId = studentData['busId'] as String?;

      if (busId == null || busId.isEmpty) return {};

      // Get supervisor info using the new system
      return await _databaseService.getSupervisorInfoForParent(busId);
    } catch (e) {
      debugPrint('Error getting supervisor info: $e');
      return {
        'name': 'خطأ في التحميل',
        'phone': '',
        'direction': '',
      };
    }
  }

  void _showEmergencyContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emergency, color: Colors.red),
            SizedBox(width: 8),
            Text('جهات الاتصال الطارئة'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_schoolInfo.isNotEmpty) ...[
                const Text(
                  'المدرسة:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.school, color: Colors.blue),
                  title: Text('${_schoolInfo['name'] ?? 'المدرسة'}: ${_schoolInfo['phone'] ?? 'غير متوفر'}'),
                  onTap: () => _makePhoneCall(_schoolInfo['phone'] ?? ''),
                ),
                if (_schoolInfo['email'] != null) ...[
                  ListTile(
                    leading: const Icon(Icons.email, color: Colors.green),
                    title: const Text('البريد الإلكتروني'),
                    subtitle: Text(_schoolInfo['email']),
                  ),
                ],
                const Divider(),
              ],
              const Text(
                'المشرف:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              FutureBuilder<Map<String, String>>(
                future: _getSupervisorInfo(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final supervisorInfo = snapshot.data ?? {};
                  if (supervisorInfo.isEmpty || supervisorInfo['phone']?.isEmpty == true) {
                    return const ListTile(
                      leading: Icon(Icons.person_off, color: Colors.grey),
                      title: Text('لا يوجد مشرف متاح حالياً'),
                    );
                  }

                  return ListTile(
                    leading: const Icon(Icons.person, color: Colors.orange),
                    title: Text(supervisorInfo['name'] ?? 'مشرف'),
                    subtitle: Text(supervisorInfo['phone'] ?? ''),
                    onTap: () => _makePhoneCall(supervisorInfo['phone'] ?? ''),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  // Show bus info dialog
  void _showBusInfoDialog() {
    if (_students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يوجد طلاب مسجلين'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final student = _students.first;
    if (student.busId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لم يتم تعيين باص للطالب بعد'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    context.push('/parent/bus-info/${student.id}');
  }

  // Make phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('رقم الهاتف غير متوفر'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لا يمكن إجراء المكالمة'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إجراء المكالمة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Navigate to add student screen
  void _navigateToAddStudent() {
    context.push('/parent/add-student').then((_) {
      // Refresh the students list after adding a new student
      setState(() {
        // تحديث قائمة الطلاب
      });
    });
  }

  // Show trip history dialog
  void _showTripHistoryDialog() {
    if (_students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يوجد طلاب مسجلين لعرض سجل الرحلات'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.history, color: Colors.purple),
            SizedBox(width: 12),
            Text('سجل الرحلات'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('trips')
                .where('studentId', whereIn: _students.map((s) => s.id).toList())
                .orderBy('timestamp', descending: true)
                .limit(20)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('خطأ في تحميل البيانات: ${snapshot.error}'),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'لا يوجد سجل رحلات',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              final trips = snapshot.data!.docs;

              return ListView.builder(
                itemCount: trips.length,
                itemBuilder: (context, index) {
                  final tripData = trips[index].data() as Map<String, dynamic>;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Icon(
                          Icons.directions_bus,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(tripData['studentName'] ?? 'طالب'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tripData['action'] ?? 'نشاط'),
                          Text(
                            tripData['timestamp']?.toDate()?.toString() ?? '',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      trailing: Text(
                        tripData['busRoute'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/parent/trip-history');
            },
            child: const Text('عرض التفاصيل'),
          ),
        ],
      ),
    );
  }

}


