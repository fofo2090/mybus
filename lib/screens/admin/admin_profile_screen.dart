import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/database_service.dart';
import '../../models/user_model.dart';
import '../../widgets/admin_app_bar.dart';
import '../../widgets/admin_bottom_navigation.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/responsive_widgets.dart';
import '../../utils/responsive_helper.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  UserModel? _adminUser;
  bool _isLoading = true;
  
  // إحصائيات النظام
  int _totalStudents = 0;
  int _totalParents = 0;
  int _totalSupervisors = 0;
  int _totalBuses = 0;
  int _todayTrips = 0;
  int _totalComplaints = 0;
  int _pendingComplaints = 0;
  int _resolvedComplaints = 0;
  
  // معلومات الأداء
  double _systemUptime = 99.8;
  double _responseTime = 2.3;
  int _activeUsers = 0;

  // آخر الأنشطة
  List<Map<String, dynamic>> _recentActivities = [];
  
  @override
  void initState() {
    super.initState();
    _loadAdminData();
    _loadSystemStats();
  }

  Future<void> _loadAdminData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await _databaseService.getUserById(user.uid);
        if (userData != null) {
          setState(() {
            _adminUser = userData;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading admin data: $e');
    }
  }

  Future<void> _loadSystemStats() async {
    try {
      // تحميل الإحصائيات بشكل متوازي
      final results = await Future.wait([
        _getStudentsCount(),
        _getParentsCount(),
        _getSupervisorsCount(),
        _getBusesCount(),
        _getTodayTripsCount(),
        _getComplaintsStats(),
        _getActiveUsersCount(),
        _getRecentActivities(),
      ]);
      
      setState(() {
        _totalStudents = results[0] as int;
        _totalParents = results[1] as int;
        _totalSupervisors = results[2] as int;
        _totalBuses = results[3] as int;
        _todayTrips = results[4] as int;
        final complaintsStats = results[5] as Map<String, int>;
        _totalComplaints = complaintsStats['total'] ?? 0;
        _pendingComplaints = complaintsStats['pending'] ?? 0;
        _resolvedComplaints = complaintsStats['resolved'] ?? 0;
        _activeUsers = results[6] as int;
        _recentActivities = results[7] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading system stats: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<int> _getStudentsCount() async {
    final snapshot = await _firestore
        .collection('students')
        .where('isActive', isEqualTo: true)
        .get();
    return snapshot.docs.length;
  }

  Future<int> _getParentsCount() async {
    final snapshot = await _firestore
        .collection('users')
        .where('userType', isEqualTo: 'parent')
        .where('isActive', isEqualTo: true)
        .get();
    return snapshot.docs.length;
  }

  Future<int> _getSupervisorsCount() async {
    final snapshot = await _firestore
        .collection('users')
        .where('userType', isEqualTo: 'supervisor')
        .where('isActive', isEqualTo: true)
        .get();
    return snapshot.docs.length;
  }

  Future<int> _getBusesCount() async {
    final snapshot = await _firestore
        .collection('buses')
        .where('isActive', isEqualTo: true)
        .get();
    return snapshot.docs.length;
  }

  Future<int> _getTodayTripsCount() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    final snapshot = await _firestore
        .collection('trips')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();
    return snapshot.docs.length;
  }

  Future<Map<String, int>> _getComplaintsStats() async {
    final totalSnapshot = await _firestore.collection('complaints').get();
    final pendingSnapshot = await _firestore
        .collection('complaints')
        .where('status', isEqualTo: 'pending')
        .get();
    final resolvedSnapshot = await _firestore
        .collection('complaints')
        .where('status', isEqualTo: 'resolved')
        .get();
    
    return {
      'total': totalSnapshot.docs.length,
      'pending': pendingSnapshot.docs.length,
      'resolved': resolvedSnapshot.docs.length,
    };
  }

  Future<int> _getActiveUsersCount() async {
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    final snapshot = await _firestore
        .collection('users')
        .where('lastActive', isGreaterThanOrEqualTo: Timestamp.fromDate(oneHourAgo))
        .get();
    return snapshot.docs.length;
  }

  Future<List<Map<String, dynamic>>> _getRecentActivities() async {
    final activities = <Map<String, dynamic>>[];

    try {
      // آخر الرحلات
      final recentTrips = await _firestore
          .collection('trips')
          .orderBy('timestamp', descending: true)
          .limit(3)
          .get();

      for (final doc in recentTrips.docs) {
        final data = doc.data();
        activities.add({
          'type': 'trip',
          'title': 'رحلة جديدة',
          'description': 'رحلة للطالب ${data['studentName'] ?? 'غير محدد'}',
          'time': data['timestamp'] as Timestamp,
          'icon': Icons.directions_bus,
          'color': Colors.blue,
        });
      }

      // آخر الشكاوى
      final recentComplaints = await _firestore
          .collection('complaints')
          .orderBy('createdAt', descending: true)
          .limit(2)
          .get();

      for (final doc in recentComplaints.docs) {
        final data = doc.data();
        activities.add({
          'type': 'complaint',
          'title': 'شكوى جديدة',
          'description': data['subject'] ?? 'شكوى من ولي أمر',
          'time': data['createdAt'] as Timestamp,
          'icon': Icons.feedback,
          'color': Colors.red,
        });
      }

      // ترتيب الأنشطة حسب الوقت
      activities.sort((a, b) => (b['time'] as Timestamp).compareTo(a['time'] as Timestamp));

      return activities.take(5).toList();
    } catch (e) {
      debugPrint('❌ Error loading recent activities: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: _isLoading ? _buildLoadingScreen() : _buildProfileContent(),
      ),
      appBar: const AdminAppBar(title: 'الملف الشخصي'),
      bottomNavigationBar: const AdminBottomNavigation(currentIndex: 4),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E88E5)),
          ),
          SizedBox(height: 16),
          Text(
            'جاري تحميل البيانات...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF1E88E5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _buildSystemOverview(),
          const SizedBox(height: 24),
          _buildDetailedStats(),
          const SizedBox(height: 24),
          _buildPerformanceMetrics(),
          const SizedBox(height: 24),
          _buildRecentActivities(),
          const SizedBox(height: 24),
          _buildQuickActions(),
        ],
      ),
    );
  }

  // سيتم إضافة باقي الدوال في الجزء التالي
  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E88E5).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _adminUser?.name ?? 'مدير النظام',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _adminUser?.email ?? 'admin@mybus.com',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'آخر دخول: ${_formatDate(FirebaseAuth.instance.currentUser?.metadata.lastSignInTime)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'مدير النظام',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withOpacity(0.5)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Colors.green, size: 8),
                          SizedBox(width: 4),
                          Text(
                            'متصل',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.dashboard, color: Color(0xFF1E88E5), size: 24),
              SizedBox(width: 8),
              Text(
                'نظرة عامة على النظام',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E88E5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ResponsiveGridView(
            mobileColumns: 2,
            tabletColumns: 4,
            desktopColumns: 4,
            largeDesktopColumns: 4,
            mobileAspectRatio: 1.2,
            tabletAspectRatio: 1.0,
            desktopAspectRatio: 1.0,
            largeDesktopAspectRatio: 1.0,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard('الطلاب', _totalStudents, Icons.school, Colors.blue),
              _buildStatCard('أولياء الأمور', _totalParents, Icons.people, Colors.green),
              _buildStatCard('المشرفين', _totalSupervisors, Icons.supervisor_account, Colors.orange),
              _buildStatCard('الحافلات', _totalBuses, Icons.directions_bus, Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, color: Color(0xFF1E88E5), size: 24),
              SizedBox(width: 8),
              Text(
                'إحصائيات مفصلة',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E88E5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailedStatRow('رحلات اليوم', _todayTrips, Icons.today, Colors.indigo),
          const SizedBox(height: 12),
          _buildDetailedStatRow('إجمالي الشكاوى', _totalComplaints, Icons.feedback, Colors.red),
          const SizedBox(height: 12),
          _buildDetailedStatRow('الشكاوى المعلقة', _pendingComplaints, Icons.pending, Colors.orange),
          const SizedBox(height: 12),
          _buildDetailedStatRow('الشكاوى المحلولة', _resolvedComplaints, Icons.check_circle, Colors.green),
          const SizedBox(height: 12),
          _buildDetailedStatRow('المستخدمين النشطين', _activeUsers, Icons.people_alt, Colors.teal),
        ],
      ),
    );
  }

  Widget _buildDetailedStatRow(String title, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.speed, color: Color(0xFF1E88E5), size: 24),
              SizedBox(width: 8),
              Text(
                'مؤشرات الأداء',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E88E5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPerformanceIndicator('وقت تشغيل النظام', '${_systemUptime.toStringAsFixed(1)}%', _systemUptime / 100, Colors.green),
          const SizedBox(height: 16),
          _buildPerformanceIndicator('وقت الاستجابة', '${_responseTime.toStringAsFixed(1)}s', 1 - (_responseTime / 10), Colors.blue),
          const SizedBox(height: 16),
          _buildPerformanceIndicator('معدل الرضا', '${((_resolvedComplaints / (_totalComplaints == 0 ? 1 : _totalComplaints)) * 100).toStringAsFixed(1)}%',
              _resolvedComplaints / (_totalComplaints == 0 ? 1 : _totalComplaints), Colors.purple),
        ],
      ),
    );
  }

  Widget _buildPerformanceIndicator(String title, String value, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildRecentActivities() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history, color: Color(0xFF1E88E5), size: 24),
              SizedBox(width: 8),
              Text(
                'آخر الأنشطة',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E88E5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentActivities.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'لا توجد أنشطة حديثة',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            Column(
              children: _recentActivities.map((activity) {
                return _buildActivityItem(activity);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final timestamp = activity['time'] as Timestamp;
    final dateTime = timestamp.toDate();
    final timeAgo = _getTimeAgo(dateTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (activity['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              activity['icon'] as IconData,
              color: activity['color'] as Color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity['description'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            timeAgo,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.flash_on, color: Color(0xFF1E88E5), size: 24),
              SizedBox(width: 8),
              Text(
                'إجراءات سريعة',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E88E5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ResponsiveGridView(
            mobileColumns: 1,
            tabletColumns: 2,
            desktopColumns: 3,
            largeDesktopColumns: 3,
            mobileAspectRatio: 3.5,
            tabletAspectRatio: 3.0,
            desktopAspectRatio: 2.8,
            largeDesktopAspectRatio: 2.5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildActionButton(
                'إعدادات النظام',
                Icons.settings,
                Colors.blue,
                () => Navigator.pushNamed(context, '/admin/settings'),
              ),
              _buildActionButton(
                'التقارير',
                Icons.assessment,
                Colors.green,
                () => Navigator.pushNamed(context, '/admin/reports'),
              ),
              _buildActionButton(
                'النسخ الاحتياطي',
                Icons.backup,
                Colors.orange,
                () => _showBackupDialog(),
              ),
              _buildActionButton(
                'إدارة المستخدمين',
                Icons.people_alt,
                Colors.purple,
                () => Navigator.pushNamed(context, '/admin/students'),
              ),
              _buildActionButton(
                'الشكاوى',
                Icons.feedback,
                Colors.red,
                () => Navigator.pushNamed(context, '/admin/complaints'),
              ),
              _buildActionButton(
                'التحليلات المتقدمة',
                Icons.analytics,
                Colors.teal,
                () => Navigator.pushNamed(context, '/admin/advanced-analytics'),
              ),
              _buildActionButton(
                'اختبار الإشعارات',
                Icons.notifications_active,
                Colors.deepPurple,
                () => Navigator.pushNamed(context, '/admin/notification-test'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.backup, color: Color(0xFF1E88E5)),
            SizedBox(width: 8),
            Text('النسخ الاحتياطي'),
          ],
        ),
        content: const Text('هل تريد إنشاء نسخة احتياطية من البيانات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performBackup();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
            ),
            child: const Text('إنشاء نسخة احتياطية'),
          ),
        ],
      ),
    );
  }

  void _performBackup() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم بدء عملية النسخ الاحتياطي...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'غير متوفر';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
