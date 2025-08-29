import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/database_service.dart';
import '../../services/backup_service.dart';
import '../../models/student_model.dart';
import '../../models/absence_model.dart';
import '../../widgets/admin_bottom_navigation.dart';
import '../../widgets/admin_app_bar.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/notification_badge.dart';
import '../../widgets/responsive_widgets.dart';
import '../../utils/background_utils.dart';
import '../../utils/notification_test_helper.dart';
import 'system_settings_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final BackupService _backupService = BackupService();

  @override
  void initState() {
    super.initState();
    _initializeBackupService();
  }

  /// تهيئة خدمة النسخ الاحتياطي
  Future<void> _initializeBackupService() async {
    try {
      await _backupService.initialize();
      debugPrint('✅ تم تهيئة خدمة النسخ الاحتياطي بنجاح');

      // إنشاء نسخة احتياطية تجريبية عند التشغيل الأول (للاختبار)
      if (!_backupService.isAutoBackupEnabled) {
        debugPrint('🔧 إنشاء نسخة احتياطية تجريبية...');
        final result = await _backupService.createSystemBackup();
        if (result['success'] == true) {
          debugPrint('✅ تم إنشاء النسخة التجريبية: ${result['backupId']}');
        }
      }
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة خدمة النسخ الاحتياطي: $e');
    }
  }

  /// عرض نافذة اختبار الإشعارات
  void _showNotificationTestDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.notifications_active, color: Color(0xFFFF6B6B)),
              SizedBox(width: 8),
              Text('اختبار الإشعارات'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('اختر نوع الاختبار الذي تريد تشغيله:'),
              const SizedBox(height: 16),
              _buildTestButton(
                'اختبار سريع',
                'إشعار تجريبي بسيط',
                Icons.flash_on,
                const Color(0xFF4CAF50),
                () => _runQuickTest(),
              ),
              const SizedBox(height: 8),
              _buildTestButton(
                'اختبار شامل',
                'جميع أنواع الإشعارات',
                Icons.playlist_add_check,
                const Color(0xFF2196F3),
                () => _runFullTest(),
              ),
              const SizedBox(height: 8),
              _buildTestButton(
                'اختبار الترحيب',
                'إشعار ترحيب تجريبي',
                Icons.waving_hand,
                const Color(0xFFFF9800),
                () => _runWelcomeTest(),
              ),
              const SizedBox(height: 8),
              _buildTestButton(
                'معلومات النظام',
                'عرض حالة نظام الإشعارات',
                Icons.info,
                const Color(0xFF9C27B0),
                () => _showSystemInfo(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  /// بناء زر اختبار
  Widget _buildTestButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// تشغيل اختبار سريع
  Future<void> _runQuickTest() async {
    try {
      await NotificationTestHelper.quickTest();
      _showSuccessSnackBar('تم إرسال الإشعار التجريبي بنجاح');
    } catch (e) {
      _showErrorSnackBar('خطأ في إرسال الإشعار: $e');
    }
  }

  /// تشغيل اختبار شامل
  Future<void> _runFullTest() async {
    try {
      _showInfoSnackBar('جاري إرسال جميع أنواع الإشعارات...');
      await NotificationTestHelper.runFullNotificationTest();
      _showSuccessSnackBar('تم إرسال جميع الإشعارات التجريبية بنجاح');
    } catch (e) {
      _showErrorSnackBar('خطأ في الاختبار الشامل: $e');
    }
  }

  /// تشغيل اختبار الترحيب
  Future<void> _runWelcomeTest() async {
    try {
      await NotificationTestHelper.testWelcomeNotification();
      _showSuccessSnackBar('تم إرسال إشعار الترحيب التجريبي');
    } catch (e) {
      _showErrorSnackBar('خطأ في إرسال إشعار الترحيب: $e');
    }
  }

  /// عرض معلومات النظام
  void _showSystemInfo() {
    NotificationTestHelper.printSystemInfo();
    _showInfoSnackBar('تم طباعة معلومات النظام في وحدة التحكم');
  }

  /// عرض رسالة نجاح
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// عرض رسالة خطأ
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFF44336),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// عرض رسالة معلومات
  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF2196F3),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _backupService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminAppBar(
        title: 'لوحة تحكم الإدارة',
        actions: [
          // عداد الإشعارات للإدارة
          StreamBuilder<int>(
            stream: _databaseService.getAdminNotificationsCount(),
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
                        hasNotifications ? Icons.notifications_active : Icons.notifications_outlined,
                        color: hasNotifications ? Colors.amber : Colors.white,
                        size: 26,
                      ),
                      onPressed: () => context.push('/admin/notifications'),
                      tooltip: hasNotifications
                          ? '$notificationCount إشعار جديد'
                          : 'الإشعارات',
                      style: IconButton.styleFrom(
                        backgroundColor: hasNotifications
                            ? Colors.white.withOpacity(0.2)
                            : Colors.white.withOpacity(0.1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                    if (hasNotifications)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              notificationCount > 99 ? '99+' : notificationCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: AnimatedBackground(
        showChildren: false, // لا نريد عناصر الأطفال في صفحة الأدمن
        child: Stack(
          children: [
            // خلفية مع عناصر بصرية محسنة للباص المدرسي
            Positioned(
              top: 40,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.directions_bus,
                  size: 80,
                  color: const Color(0xFF1E88E5).withOpacity(0.15),
                ),
              ),
            ),
            Positioned(
              top: 120,
              left: 30,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.school,
                  size: 60,
                  color: const Color(0xFF4CAF50).withOpacity(0.15),
                ),
              ),
            ),
            Positioned(
              bottom: 220,
              right: 40,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.child_care,
                  size: 50,
                  color: const Color(0xFFFF9800).withOpacity(0.15),
                ),
              ),
            ),
            // المحتوى الرئيسي
            SingleChildScrollView(
              padding: EdgeInsets.only(bottom: ResponsiveHelper.getSpacing(context) * 5),
              child: Column(
                children: [
                  SizedBox(height: ResponsiveHelper.getSpacing(context) * 0.5),
                  // Dashboard Cards
                  Container(
                    padding: ResponsiveHelper.getPadding(context,
                      mobilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      tabletPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      desktopPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: _buildDashboardCards(),
                  ),

                  SizedBox(height: ResponsiveHelper.getSpacing(context) * 1.5),

                  // Management Options
                  Container(
                    padding: ResponsiveHelper.getPadding(context,
                      mobilePadding: const EdgeInsets.symmetric(horizontal: 16),
                      tabletPadding: const EdgeInsets.symmetric(horizontal: 20),
                      desktopPadding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    child: _buildManagementOptions(),
                  ),

                  SizedBox(height: ResponsiveHelper.getSpacing(context) * 1.75),

                  // Quick Stats Section
                  Container(
                    padding: ResponsiveHelper.getPadding(context,
                      mobilePadding: const EdgeInsets.symmetric(horizontal: 16),
                      tabletPadding: const EdgeInsets.symmetric(horizontal: 20),
                      desktopPadding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    child: _buildQuickStatsSection(),
                  ),

                  SizedBox(height: ResponsiveHelper.getSpacing(context) * 1.75),

                  // Recent Activity Section
                  Container(
                    padding: ResponsiveHelper.getPadding(context,
                      mobilePadding: const EdgeInsets.symmetric(horizontal: 16),
                      tabletPadding: const EdgeInsets.symmetric(horizontal: 20),
                      desktopPadding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    child: _buildRecentActivitySection(),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AdminBottomNavigation(currentIndex: 0),
    );
  }

  Widget _buildDashboardCards() {
    return StreamBuilder<List<StudentModel>>(
      stream: _databaseService.getAllStudents(),
      builder: (context, snapshot) {
        final students = snapshot.data ?? [];
        final totalStudents = students.length;
        final studentsOnBus = students.where((s) => s.currentStatus == StudentStatus.onBus).length;
        final studentsAtSchool = students.where((s) => s.currentStatus == StudentStatus.atSchool).length;

        return Row(
          children: [
            Expanded(
              child: _buildDashboardCard(
                title: 'إجمالي الطلاب',
                value: '$totalStudents',
                icon: Icons.school,
                color: const Color(0xFF1E88E5),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDashboardCard(
                title: 'في الباص',
                value: '$studentsOnBus',
                icon: Icons.directions_bus,
                color: const Color(0xFFFF9800),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDashboardCard(
                title: 'في المدرسة',
                value: '$studentsAtSchool',
                icon: Icons.location_on,
                color: const Color(0xFF4CAF50),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: ResponsiveHelper.getPadding(context,
        mobilePadding: const EdgeInsets.all(16),
        tabletPadding: const EdgeInsets.all(20),
        desktopPadding: const EdgeInsets.all(24),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildManagementOptions() {
    return _buildManagementSection();
  }

  Widget _buildManagementSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E88E5).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF1E88E5).withOpacity(0.08),
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
                  mobilePadding: const EdgeInsets.all(10),
                  tabletPadding: const EdgeInsets.all(12),
                  desktopPadding: const EdgeInsets.all(14),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1E88E5),
                      const Color(0xFF1976D2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context) * 0.75),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E88E5).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: ResponsiveHelper.getIconSize(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'إدارة النظام',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E88E5),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'لوحة التحكم الرئيسية',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          ResponsiveGridView(
            mobileColumns: 2,
            tabletColumns: 3,
            desktopColumns: 4,
            largeDesktopColumns: 4,
            mobileAspectRatio: 0.85,
            tabletAspectRatio: 0.8,
            desktopAspectRatio: 0.75,
            largeDesktopAspectRatio: 0.7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildManagementCard(
                icon: Icons.backup,
                label: 'نسخ احتياطي',
                description: 'حفظ واستعادة البيانات',
                color: const Color(0xFF2196F3),
                onTap: () => _showBackupDialog(),
              ),
              _buildManagementCard(
                icon: Icons.people_alt,
                label: 'إدارة أولياء الأمور',
                description: 'إدارة حسابات أولياء الأمور',
                color: const Color(0xFFFF9800),
                onTap: () => context.push('/admin/parents'),
              ),
              _buildManagementCard(
                icon: Icons.settings,
                label: 'إعدادات النظام',
                description: 'تكوين التطبيق',
                color: const Color(0xFF9C27B0),
                onTap: () => _showSystemSettings(),
              ),

              _buildManagementCard(
                icon: Icons.feedback,
                label: 'الشكاوى',
                description: 'إدارة شكاوى أولياء الأمور',
                color: const Color(0xFFFF5722),
                onTap: () => context.push('/admin/complaints'),
              ),
              _buildManagementCard(
                icon: Icons.poll,
                label: 'تقارير الاستبيانات',
                description: 'تقييم المشرفين وسلوك الطلاب',
                color: const Color(0xFF4CAF50),
                onTap: () => context.push('/admin/surveys-reports'),
              ),
              _buildManagementCard(
                icon: Icons.person_off,
                label: 'إدارة الغياب',
                description: 'موافقة طلبات الغياب والإحصائيات',
                color: const Color(0xFFE91E63),
                onTap: () => context.push('/admin/absence-management'),
              ),
              _buildManagementCard(
                icon: Icons.directions_bus,
                label: 'إدارة السيارات',
                description: 'إضافة وتعديل السيارات والسائقين',
                color: const Color(0xFF4CAF50),
                onTap: () => context.push('/admin/buses-management'),
              ),
              _buildManagementCard(
                icon: Icons.assignment_ind,
                label: 'تعيينات المشرفين',
                description: 'ربط المشرفين بالسيارات وإدارة الطوارئ',
                color: const Color(0xFF1E88E5),
                onTap: () => context.push('/admin/supervisor-assignments'),
              ),
              _buildManagementCard(
                icon: Icons.notifications_active,
                label: 'اختبار الإشعارات',
                description: 'اختبار نظام الإشعارات والتنبيهات',
                color: const Color(0xFFFF6B6B),
                onTap: () => _showNotificationTestDialog(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManagementCard({
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.1),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.1),
                      color.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A202C),
                        letterSpacing: -0.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.backup,
                color: Color(0xFF2196F3),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'النسخ الاحتياطي',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A202C),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'إدارة النسخ الاحتياطية للبيانات',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _createBackup();
                    },
                    icon: const Icon(Icons.cloud_upload, size: 20),
                    label: const Text(
                      'إنشاء نسخة',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _restoreBackup();
                    },
                    icon: const Icon(Icons.cloud_download, size: 20),
                    label: const Text(
                      'استعادة',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9800),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // إعدادات النسخ التلقائي
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.blue[600], size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'النسخ التلقائي',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<bool>(
                    future: Future.value(_backupService.isAutoBackupEnabled),
                    builder: (context, snapshot) {
                      final isEnabled = snapshot.data ?? false;
                      return SwitchListTile(
                        title: const Text(
                          'تفعيل النسخ التلقائي',
                          style: TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          isEnabled ? 'مفعل - كل 24 ساعة' : 'معطل',
                          style: TextStyle(
                            fontSize: 11,
                            color: isEnabled ? Colors.green : Colors.grey,
                          ),
                        ),
                        value: isEnabled,
                        onChanged: (value) async {
                          await _backupService.setAutoBackupEnabled(value);
                          setState(() {}); // إعادة بناء الواجهة
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showBackupStatistics();
            },
            child: const Text('الإحصائيات'),
          ),
        ],
      ),
    );
  }

  Future<void> _createBackup() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('جاري إنشاء النسخة الاحتياطية...'),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 10),
        ),
      );

      // إنشاء النسخة الاحتياطية
      final backupResult = await _backupService.createSystemBackup();

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (backupResult['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('تم إنشاء النسخة الاحتياطية بنجاح!'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'معرف النسخة: ${backupResult['backupId']}',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  Text(
                    'عدد السجلات: ${backupResult['totalRecords']}',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'عرض التفاصيل',
                textColor: Colors.white,
                onPressed: () => _showBackupDetails(backupResult),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل في إنشاء النسخة الاحتياطية: ${backupResult['error']}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إنشاء النسخة الاحتياطية: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _restoreBackup() async {
    // عرض قائمة النسخ الاحتياطية المتاحة
    _showBackupsList();
  }

  void _showNotificationDialog() {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('إرسال إشعار جماعي'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('إرسال إشعار لجميع أولياء الأمور'),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'نص الإشعار',
                border: OutlineInputBorder(),
                hintText: 'اكتب رسالة الإشعار هنا...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (messageController.text.isNotEmpty) {
                Navigator.pop(context);
                _sendNotification(messageController.text);
              }
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }

  void _sendNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم إرسال الإشعار: $message'),
        backgroundColor: Colors.green,
      ),
    );
    // هنا يمكن إضافة منطق إرسال الإشعارات الفعلي
  }

  void _showSystemSettings() {
    context.push('/admin/settings');
  }





  // دالة لبناء قسم الإحصائيات السريعة
  Widget _buildQuickStatsSection() {
    return StreamBuilder<List<StudentModel>>(
      stream: _databaseService.getAllStudents(),
      builder: (context, snapshot) {
        final students = snapshot.data ?? [];

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(20), // 0.08 * 255 = 20
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.trending_up,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'إحصائيات سريعة',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _buildQuickStatCard(
                      'الطلاب النشطون',
                      '${students.where((s) => s.isActive).length}',
                      Icons.people_alt,
                      Colors.blue,
                      '${students.isNotEmpty ? (students.where((s) => s.isActive).length / students.length * 100).toStringAsFixed(1) : 0}% من الإجمالي',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickStatCard(
                      'في الطريق',
                      '${students.where((s) => s.currentStatus == StudentStatus.onBus).length}',
                      Icons.directions_bus,
                      Colors.orange,
                      'طلاب في الحافلات',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildQuickStatCard(
                      'وصلوا المدرسة',
                      '${students.where((s) => s.currentStatus == StudentStatus.atSchool).length}',
                      Icons.school,
                      Colors.green,
                      'طلاب في المدرسة',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickStatCard(
                      'غير نشطين',
                      '${students.where((s) => !s.isActive).length}',
                      Icons.person_off,
                      Colors.purple,
                      'طلاب غير نشطين',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // دالة لبناء بطاقة إحصائية سريعة
  Widget _buildQuickStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // دالة لبناء قسم النشاط الأخير
  Widget _buildRecentActivitySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.history,
                  color: Colors.indigo,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'النشاط الأخير',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/admin/reports'),
                child: const Text('عرض الكل'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // قائمة النشاطات الأخيرة من قاعدة البيانات
          StreamBuilder<List<AbsenceModel>>(
            stream: _databaseService.getRecentAbsenceNotifications(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildActivityItem(
                  'لا توجد أنشطة حديثة',
                  'اليوم',
                  Icons.info,
                  Colors.grey,
                );
              }

              final recentActivities = snapshot.data!.take(4).toList();
              return Column(
                children: recentActivities.map((absence) {
                  return Column(
                    children: [
                      _buildActivityItem(
                        'طلب غياب من ${absence.studentName}',
                        _getTimeAgo(absence.createdAt),
                        Icons.person_off,
                        _getAbsenceStatusColor(absence.status),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 16),

          // أزرار الإجراءات السريعة
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/admin/reports'),
                  icon: const Icon(Icons.assessment, size: 18),
                  label: const Text('التقارير'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

            ],
          ),
        ],
      ),
    );
  }

  // دالة لبناء عنصر نشاط
  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // دالة لحساب الوقت المنقضي
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return 'منذ ${difference.inDays} يوم';
    }
  }

  // دالة لتحديد لون حالة الغياب
  Color _getAbsenceStatusColor(AbsenceStatus status) {
    switch (status) {
      case AbsenceStatus.pending:
        return Colors.orange;
      case AbsenceStatus.approved:
        return Colors.green;
      case AbsenceStatus.rejected:
        return Colors.red;
    }
  }

  // ==================== دوال النسخ الاحتياطي ====================



  /// عرض تفاصيل النسخة الاحتياطية
  void _showBackupDetails(Map<String, dynamic> backupResult) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            SizedBox(width: 8),
            Text('تفاصيل النسخة الاحتياطية'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('معرف النسخة', backupResult['backupId'] ?? 'غير محدد'),
            _buildDetailRow('إجمالي السجلات', '${backupResult['totalRecords'] ?? 0}'),
            _buildDetailRow('عدد المجموعات', '${backupResult['collections'] ?? 0}'),
            _buildDetailRow('الحجم', '${((backupResult['size'] ?? 0) / 1024).toStringAsFixed(1)} KB'),
            _buildDetailRow('التاريخ', DateTime.now().toString().substring(0, 19)),
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

  /// عرض قائمة النسخ الاحتياطية المتاحة
  void _showBackupsList() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.restore, color: Colors.orange),
            SizedBox(width: 8),
            Text('استعادة النسخة الاحتياطية'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _getBackupsList(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('خطأ في تحميل النسخ: ${snapshot.error}'),
                );
              }

              final backups = snapshot.data ?? [];

              if (backups.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.backup, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('لا توجد نسخ احتياطية متاحة'),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: backups.length,
                itemBuilder: (context, index) {
                  final backup = backups[index];
                  return _buildBackupListItem(backup);
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
        ],
      ),
    );
  }

  /// بناء عنصر في قائمة النسخ الاحتياطية
  Widget _buildBackupListItem(Map<String, dynamic> backup) {
    final createdAt = backup['createdAt'] as String?;
    final totalRecords = backup['totalRecords'] as int? ?? 0;
    final size = backup['size'] as int? ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.backup, color: Colors.blue),
        ),
        title: Text(
          backup['id'] ?? 'نسخة احتياطية',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('التاريخ: ${createdAt?.substring(0, 19) ?? 'غير محدد'}'),
            Text('السجلات: $totalRecords | الحجم: ${(size / 1024).toStringAsFixed(1)} KB'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.info, color: Colors.blue),
              onPressed: () => _showBackupInfo(backup),
              tooltip: 'عرض التفاصيل',
            ),
            IconButton(
              icon: const Icon(Icons.restore, color: Colors.orange),
              onPressed: () => _confirmRestoreBackup(backup),
              tooltip: 'استعادة',
            ),
          ],
        ),
      ),
    );
  }

  /// الحصول على قائمة النسخ الاحتياطية
  Stream<List<Map<String, dynamic>>> _getBackupsList() {
    return _backupService.getBackupsList();
  }

  /// عرض معلومات النسخة الاحتياطية
  void _showBackupInfo(Map<String, dynamic> backup) {
    Navigator.pop(context); // إغلاق الحوار الحالي

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            SizedBox(width: 8),
            Text('معلومات النسخة الاحتياطية'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('المعرف', backup['id'] ?? 'غير محدد'),
              _buildDetailRow('التاريخ', backup['createdAt']?.toString().substring(0, 19) ?? 'غير محدد'),
              _buildDetailRow('المنشئ', backup['createdBy'] ?? 'غير محدد'),
              _buildDetailRow('الإصدار', backup['version'] ?? 'غير محدد'),
              _buildDetailRow('إجمالي السجلات', '${backup['totalRecords'] ?? 0}'),
              _buildDetailRow('الحجم', '${((backup['size'] ?? 0) / 1024).toStringAsFixed(1)} KB'),
              _buildDetailRow('الحالة', backup['status'] ?? 'غير محدد'),

              const SizedBox(height: 16),
              const Text(
                'المجموعات المشمولة:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              if (backup['collections'] != null)
                ...((backup['collections'] as List).map((collection) =>
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.folder, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(collection.toString()),
                      ],
                    ),
                  ),
                )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmRestoreBackup(backup);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('استعادة هذه النسخة'),
          ),
        ],
      ),
    );
  }

  /// تأكيد استعادة النسخة الاحتياطية
  void _confirmRestoreBackup(Map<String, dynamic> backup) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('تأكيد الاستعادة'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '⚠️ تحذير مهم',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'استعادة النسخة الاحتياطية ستؤدي إلى:\n'
              '• حذف جميع البيانات الحالية\n'
              '• استبدالها ببيانات النسخة المحددة\n'
              '• فقدان أي تغييرات حدثت بعد تاريخ النسخة\n\n'
              'هذه العملية لا يمكن التراجع عنها!',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('النسخة المحددة: ${backup['id']}'),
                  Text('التاريخ: ${backup['createdAt']?.toString().substring(0, 19)}'),
                  Text('السجلات: ${backup['totalRecords']}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performRestore(backup);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد الاستعادة'),
          ),
        ],
      ),
    );
  }

  /// تنفيذ عملية الاستعادة
  Future<void> _performRestore(Map<String, dynamic> backup) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('جاري استعادة النسخة الاحتياطية...'),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(minutes: 5),
        ),
      );

      // تنفيذ الاستعادة
      final result = await _restoreFromBackup(backup);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('تم استعادة النسخة الاحتياطية بنجاح!'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'تم استعادة ${result['restoredRecords']} سجل',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل في استعادة النسخة: ${result['error']}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في استعادة النسخة: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// استعادة البيانات من النسخة الاحتياطية
  Future<Map<String, dynamic>> _restoreFromBackup(Map<String, dynamic> backup) async {
    try {
      final backupData = backup['data'] as Map<String, dynamic>?;
      if (backupData == null) {
        throw Exception('بيانات النسخة الاحتياطية غير صالحة');
      }

      int restoredRecords = 0;
      final firestore = _databaseService.firestore;

      // استعادة كل مجموعة
      for (final entry in backupData.entries) {
        final collectionName = entry.key;
        final collectionData = entry.value as List<dynamic>;

        debugPrint('🔄 استعادة مجموعة $collectionName: ${collectionData.length} سجل');

        // حذف البيانات الحالية
        final currentDocs = await firestore.collection(collectionName).get();
        final batch = firestore.batch();

        for (final doc in currentDocs.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        // إضافة البيانات المستعادة
        final restoreBatch = firestore.batch();
        for (final record in collectionData) {
          final recordMap = record as Map<String, dynamic>;
          final docId = recordMap['id'] as String;
          recordMap.remove('id'); // إزالة المعرف من البيانات

          restoreBatch.set(
            firestore.collection(collectionName).doc(docId),
            recordMap,
          );
        }
        await restoreBatch.commit();

        restoredRecords += collectionData.length;
        debugPrint('✅ تم استعادة مجموعة $collectionName');
      }

      debugPrint('✅ تم استعادة النسخة الاحتياطية بنجاح: $restoredRecords سجل');

      return {
        'success': true,
        'restoredRecords': restoredRecords,
      };

    } catch (e) {
      debugPrint('❌ خطأ في استعادة النسخة الاحتياطية: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// عرض إحصائيات النسخ الاحتياطي
  void _showBackupStatistics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.analytics, color: Colors.blue),
            SizedBox(width: 8),
            Text('إحصائيات النسخ الاحتياطي'),
          ],
        ),
        content: FutureBuilder<Map<String, dynamic>>(
          future: _backupService.getBackupStatistics(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Text('خطأ في تحميل الإحصائيات: ${snapshot.error}');
            }

            final stats = snapshot.data ?? {};
            final totalBackups = stats['totalBackups'] ?? 0;
            final lastBackup = stats['lastBackup'] as DateTime?;
            final totalSize = stats['totalSize'] ?? 0;
            final isAutoEnabled = stats['isAutoEnabled'] ?? false;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow('إجمالي النسخ', '$totalBackups نسخة'),
                _buildStatRow(
                  'آخر نسخة احتياطية',
                  lastBackup != null
                    ? '${lastBackup.toString().substring(0, 19)}'
                    : 'لا توجد نسخ',
                ),
                _buildStatRow(
                  'إجمالي الحجم',
                  '${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB',
                ),
                _buildStatRow(
                  'النسخ التلقائي',
                  isAutoEnabled ? 'مفعل' : 'معطل',
                ),

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue[600], size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            'معلومات مهمة',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• يتم الاحتفاظ بآخر 10 نسخ احتياطية فقط\n'
                        '• النسخ التلقائي يعمل كل 24 ساعة\n'
                        '• يمكن تغيير إعدادات النسخ من الإعدادات',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createBackup();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('إنشاء نسخة الآن'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}


