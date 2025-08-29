import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../models/absence_model.dart';
import '../../models/bus_model.dart';
import '../../models/student_model.dart';
import '../../models/supervisor_assignment_model.dart';
import 'package:location/location.dart';
import '../../widgets/curved_app_bar.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/responsive_widgets.dart';
import 'school_info_screen.dart';
import 'absence_management_screen.dart';
import 'monthly_behavior_survey_screen.dart';

class SupervisorHomeScreen extends StatefulWidget {
  const SupervisorHomeScreen({super.key});

  @override
  State<SupervisorHomeScreen> createState() => _SupervisorHomeScreenState();
}

class _SupervisorHomeScreenState extends State<SupervisorHomeScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  final Location _locationService = Location();

  final bool _isLoading = false;
  late Stream<List<StudentModel>> _studentsOnBusStream;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeStreams();
    _listenToSystemUpdates();

    // تهيئة animation للنبضة
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // تكرار النبضة
    _pulseController.repeat(reverse: true);

    _initLocationTracking();
  }

  Future<void> _initLocationTracking() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) {
        return; // Services are not enabled, handle this case.
      }
    }

    permissionGranted = await _locationService.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationService.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return; // Permissions are not granted, handle this case.
      }
    }

    _locationService.onLocationChanged.listen((LocationData currentLocation) {
      _updateStudentsLocation(currentLocation);
    });
  }

  Future<void> _updateStudentsLocation(LocationData locationData) async {
    final supervisorId = _authService.currentUser?.uid ?? '';
    if (supervisorId.isEmpty) return;

    final students = await _loadSupervisorStudents(supervisorId);
    final batch = FirebaseFirestore.instance.batch();

    for (final student in students) {
      if (student.currentStatus == StudentStatus.onBus) {
        final studentRef = FirebaseFirestore.instance.collection('students').doc(student.id);
        batch.update(studentRef, {
          'location': GeoPoint(locationData.latitude!, locationData.longitude!),
        });
      }
    }

    if (students.any((s) => s.currentStatus == StudentStatus.onBus)) {
      await batch.commit();
      debugPrint('Updated location for students on the bus.');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _initializeStreams() {
    final supervisorId = _authService.currentUser?.uid ?? '';
    debugPrint('🔄 Initializing streams for supervisor: $supervisorId');

    // استخدام الطريقة المحسنة لجلب الطلاب
    _studentsOnBusStream = Stream.periodic(const Duration(seconds: 3))
        .asyncMap((_) => _loadSupervisorStudents(supervisorId))
        .distinct((previous, next) =>
            previous.length == next.length &&
            previous.map((s) => s.id).join(',') == next.map((s) => s.id).join(','))
        .asBroadcastStream();

    _checkSupervisorAssignments();
  }

  Future<List<StudentModel>> _loadSupervisorStudents(String supervisorId) async {
    try {
      debugPrint('🔄 Loading supervisor students for: $supervisorId');

      // استخدام الطريقة البسيطة
      final assignments = await _databaseService.getSupervisorAssignmentsSimple(supervisorId);
      debugPrint('📋 Found ${assignments.length} assignments for supervisor');

      if (assignments.isEmpty) {
        debugPrint('⚠️ No assignments found for supervisor $supervisorId');
        return <StudentModel>[];
      }

      final assignment = assignments.first;
      var busRoute = assignment.busRoute;
      var busId = assignment.busId;
      debugPrint('🚌 Assignment busRoute: "$busRoute"');
      debugPrint('🚌 Assignment busId: "$busId"');

      // إذا كان busRoute فارغ، احصل عليه من بيانات الباص
      if (busRoute.isEmpty && busId.isNotEmpty) {
        debugPrint('⚠️ busRoute is empty, fetching from bus data...');
        try {
          final bus = await _databaseService.getBusById(busId);
          if (bus != null) {
            busRoute = bus.route;
            debugPrint('✅ Got busRoute from bus: "$busRoute"');
          } else {
            debugPrint('❌ Bus not found for ID: $busId');
          }
        } catch (e) {
          debugPrint('❌ Error getting bus data: $e');
        }
      }

      // جلب الطلاب بطرق متعددة للتأكد من الحصول على البيانات
      List<StudentModel> students = [];

      // الطريقة الأولى: البحث بـ busRoute
      if (busRoute.isNotEmpty) {
        students = await _databaseService.getStudentsByRouteSimple(busRoute);
        debugPrint('👥 Found ${students.length} students by route "$busRoute"');
      }

      // الطريقة الثانية: البحث بـ busId إذا لم نجد طلاب بـ busRoute
      if (students.isEmpty && busId.isNotEmpty) {
        debugPrint('🔍 No students found by route, trying busId: $busId');
        students = await _databaseService.getStudentsByBusIdSimple(busId);
        debugPrint('👥 Found ${students.length} students by busId "$busId"');
      }

      // الطريقة الثالثة: البحث في الطلاب المسكنين فقط إذا لم نجد أي طلاب
      if (students.isEmpty) {
        debugPrint('🔍 No students found by route or busId, checking assigned students...');
        final assignedStudents = await _databaseService.getAssignedStudents();
        debugPrint('👥 Total assigned students in database: ${assignedStudents.length}');

        // فلترة الطلاب حسب busRoute أو busId
        students = assignedStudents.where((student) {
          final matchesRoute = busRoute.isNotEmpty && student.busRoute == busRoute;
          final matchesBusId = busId.isNotEmpty && student.busId == busId;
          debugPrint('🔍 Checking assigned student ${student.name}: route="${student.busRoute}", busId="${student.busId}"');
          return matchesRoute || matchesBusId;
        }).toList();

        debugPrint('👥 Found ${students.length} matching assigned students');
      }

      // طباعة تفاصيل الطلاب الموجودين
      for (final student in students) {
        debugPrint('   - ${student.name} (Route: "${student.busRoute}", BusId: "${student.busId}", Active: ${student.isActive})');
      }

      return students;
    } catch (e) {
      debugPrint('❌ Error loading supervisor students: $e');
      return <StudentModel>[];
    }
  }

  void _checkSupervisorAssignments() async {
    final supervisorId = _authService.currentUser?.uid ?? '';
    final hasAssignments = await _databaseService.hasSupervisorAssignments(supervisorId);

    if (!hasAssignments && mounted) {
      debugPrint('⚠️ Supervisor has no active assignments');
      // Could show a message or handle this case
    }
  }

  /// Debug function to check all students in database
  Future<void> _debugAllStudents() async {
    try {
      debugPrint('🔍 DEBUG: Checking all students in database...');

      final snapshot = await FirebaseFirestore.instance
          .collection('students')
          .get();

      debugPrint('📊 Total students in database: ${snapshot.docs.length}');

      for (final doc in snapshot.docs) {
        final data = doc.data();
        debugPrint('👤 Student: ${data['name']} - busRoute: "${data['busRoute']}" - busId: "${data['busId']}" - isActive: ${data['isActive']}');
      }

      // فحص الطلاب النشطين فقط
      final activeSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('isActive', isEqualTo: true)
          .get();

      debugPrint('📊 Active students: ${activeSnapshot.docs.length}');

    } catch (e) {
      debugPrint('❌ Error debugging students: $e');
    }
  }

  void _listenToSystemUpdates() {
    // Listen to system updates to refresh data when needed
    FirebaseFirestore.instance
        .collection('system_updates')
        .doc('last_student_update')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        debugPrint('🔄 System update detected, refreshing streams...');
        setState(() {
          _initializeStreams();
        });
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: EnhancedCurvedAppBar(
        title: 'كيدز باص - المشرف',
        automaticallyImplyLeading: false, // إزالة سهم الرجوع
        subtitle: FutureBuilder<List<SupervisorAssignmentModel>>(
          future: _databaseService.getSupervisorAssignmentsSimple(_authService.currentUser?.uid ?? ''),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final assignment = snapshot.data!.first;
              // الحصول على اسم المنطقة من الباص
              return FutureBuilder<BusModel?>(
                future: _databaseService.getBusById(assignment.busId),
                builder: (context, busSnapshot) {
                  if (busSnapshot.hasData && busSnapshot.data != null) {
                    final bus = busSnapshot.data!;
                    return Text('خط السير: ${bus.route}');
                  }
                  // في حالة عدم توفر بيانات الباص، عرض رقم الخط كما هو
                  return Text('خط السير: ${assignment.busRoute}');
                },
              );
            }
            return const Text('إدارة رحلات الطلاب');
          },
        ),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        height: 240,
        actions: [
          // إشعار طلبات الغياب والإشعارات العامة
          StreamBuilder<int>(
            stream: _databaseService.getSupervisorNotificationsCount(_authService.currentUser?.uid ?? ''),
            builder: (context, snapshot) {
              // Add debug information
              debugPrint('🔔 Supervisor Notification StreamBuilder - Connection: ${snapshot.connectionState}, Data: ${snapshot.data}, Error: ${snapshot.error}');

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
                      onPressed: () => _showAllNotifications(),
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
                        right: 4,
                        top: 4,
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.4),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.2),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                child: Text(
                                  notificationCount > 99 ? '99+' : notificationCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),



          IconButton(
            icon: const Icon(Icons.school),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SupervisorSchoolInfoScreen(),
                ),
              );
            },
            tooltip: 'معلومات المدرسة',
          ),

          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                context.push('/supervisor/profile');
              } else if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('الملف الشخصي'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('تسجيل الخروج'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: AnimatedBackground(
        showChildren: false, // لا نريد عناصر الأطفال في صفحة المشرف
        child: SingleChildScrollView(
          padding: ResponsiveHelper.getPadding(context,
            mobilePadding: const EdgeInsets.all(12),
            tabletPadding: const EdgeInsets.all(16),
            desktopPadding: const EdgeInsets.all(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Welcome Section
            _buildWelcomeSection(),
            SizedBox(height: ResponsiveHelper.getSpacing(context) * 1.25),

            // Quick Stats
            _buildQuickStats(),
            SizedBox(height: ResponsiveHelper.getSpacing(context) * 1.5),

            // Main Action Buttons
            _buildMainActions(),
            SizedBox(height: ResponsiveHelper.getSpacing(context) * 1.25),

            // Secondary Actions
            _buildSecondaryActions(),
            SizedBox(height: ResponsiveHelper.getSpacing(context) * 1.25),

            // Students List Section
            _buildStudentsListSection(),
            SizedBox(height: ResponsiveHelper.getSpacing(context) * 1.25),

            // تنبيه إشعارات الغياب الجديدة
            StreamBuilder<List<AbsenceModel>>(
              stream: _databaseService.getRecentAbsenceNotifications(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const SizedBox.shrink();
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }

                final notificationCount = snapshot.data?.length ?? 0;

                if (notificationCount == 0) return const SizedBox.shrink();

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withAlpha(25),
                        Colors.indigo.withAlpha(25),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withAlpha(76)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.notifications_active,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ًں“¢ إشعار: $notificationCount إبلاغ غياب جديد',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const Text(
                              'تم إبلاغ المدرسة عن غيابات جديدة',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _showTodayAbsences,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'عرض',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),


          ],
        ),
      ),
    ),
    );
  }



  Widget _buildQRScannerButton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(20),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.qr_code_scanner,
            size: 40,
            color: Color(0xFF1E88E5),
          ),
          const SizedBox(height: 8),
          const Text(
            'مسح الباركود',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'مسح باركود الطالب',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _scanQRCode,
              icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 16),
              label: const Text(
                'بدء المسح',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsListButton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(20),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.people_outline,
            size: 40,
            color: Color(0xFFFF9800),
          ),
          const SizedBox(height: 8),
          const Text(
            'قائمة الطلاب',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'عرض الطلاب وأكواد QR',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/supervisor/students-list'),
              icon: const Icon(Icons.people, color: Colors.white, size: 16),
              label: const Text(
                'عرض القائمة',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactButton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.emergency,
              color: Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'اتصال الطوارئ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/supervisor/emergency-contact'),
              icon: const Icon(Icons.phone, color: Colors.white, size: 16),
              label: const Text(
                'أرقام الطوارئ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveysButton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.assignment,
              color: Color(0xFF7C3AED),
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'الاستبيانات الشهرية',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/supervisor/surveys'),
              icon: const Icon(Icons.poll, color: Colors.white, size: 16),
              label: const Text(
                'عرض الاستبيانات',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                padding: ResponsiveHelper.getPadding(context,
                  mobilePadding: const EdgeInsets.symmetric(vertical: 8),
                  tabletPadding: const EdgeInsets.symmetric(vertical: 10),
                  desktopPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context) * 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbsenceManagementButton() {
    return StreamBuilder<List<AbsenceModel>>(
      stream: _databaseService.getPendingAbsences(),
      builder: (context, snapshot) {
        final pendingCount = snapshot.data?.length ?? 0;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: pendingCount > 0
                ? Border.all(color: Colors.orange.withAlpha(127), width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: pendingCount > 0
                    ? Colors.orange.withAlpha(51)
                    : Colors.grey.withAlpha(20),
                blurRadius: pendingCount > 0 ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  const Icon(
                    Icons.person_off,
                    size: 40,
                    color: Color(0xFFE91E63),
                  ),
                  if (pendingCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          pendingCount.toString(),
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
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'إدارة الغياب',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (pendingCount > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'جديد',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                pendingCount > 0
                    ? '$pendingCount طلب غياب في الانتظار'
                    : 'تسجيل غياب الطلاب ومتابعة الحالات',
                style: TextStyle(
                  color: pendingCount > 0 ? Colors.orange : Colors.grey[600],
                  fontSize: 12,
                  fontWeight: pendingCount > 0 ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // زر تسجيل غياب
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showAbsenceRegistration,
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
                  label: const Text(
                    'تسجيل غياب جديد',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // زر عرض الطلبات/الغيابات
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showTodayAbsences,
                  icon: Icon(
                    pendingCount > 0 ? Icons.notification_important : Icons.list_alt,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    pendingCount > 0
                        ? 'عرض الطلبات المعلقة ($pendingCount)'
                        : 'عرض غيابات اليوم',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pendingCount > 0 ? Colors.orange : const Color(0xFF9C27B0),
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
        );
      },
    );
  }







  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E88E5),
            Color(0xFF1976D2),
            Color(0xFF1565C0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.25),
                      Colors.white.withOpacity(0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.supervisor_account,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'مرحباً بك أيها المشرف',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'جاهز لبدء رحلة آمنة اليوم؟',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, color: Colors.white.withOpacity(0.8), size: 18),
                const SizedBox(width: 10),
                Text(
                  'آخر تحديث: ${DateFormat('HH:mm').format(DateTime.now())}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF4CAF50),
                        Color(0xFF388E3C),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'متصل',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Column(
      children: [
        // الصف الأول - الإحصائيات الحالية
        Row(
          children: [
            Expanded(
              child: StreamBuilder<List<StudentModel>>(
            stream: _studentsOnBusStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildStatCard(
                  'طلاب الخط',
                  '...',
                  Icons.people,
                  Colors.grey,
                );
              }

              if (snapshot.hasError) {
                debugPrint('❌ Error in students stream: ${snapshot.error}');
                return _buildStatCard(
                  'طلاب الخط',
                  'خطأ',
                  Icons.error,
                  Colors.red,
                );
              }

              final students = snapshot.data ?? [];
              final activeStudents = students.where((s) => s.isActive).toList();
              final count = activeStudents.length;

              debugPrint('📊 Main stats - Total students: ${students.length}, Active: $count');

              return GestureDetector(
                onTap: () => _showRouteStudentsDialog(activeStudents),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (count > 0 ? Colors.green : Colors.blue).withAlpha(25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildStatCard(
                    'طلاب الخط',
                    count.toString(),
                    Icons.people,
                    count > 0 ? Colors.green : Colors.blue,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StreamBuilder<List<AbsenceModel>>(
            stream: _databaseService.getPendingAbsencesForSupervisor(_authService.currentUser?.uid ?? ''),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildStatCard(
                  'طلبات الغياب',
                  '...',
                  Icons.notification_important,
                  Colors.grey,
                );
              }

              final count = snapshot.data?.length ?? 0;
              return _buildStatCard(
                'طلبات الغياب',
                count.toString(),
                Icons.notification_important,
                count > 0 ? Colors.orange : Colors.green,
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StreamBuilder<List<AbsenceModel>>(
            stream: _databaseService.getTodayAbsencesForSupervisor(_authService.currentUser?.uid ?? ''),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildStatCard(
                  'غيابات اليوم',
                  '...',
                  Icons.person_off,
                  Colors.grey,
                );
              }

              final count = snapshot.data?.length ?? 0;
              return _buildStatCard(
                'غيابات اليوم',
                count.toString(),
                Icons.person_off,
                count > 0 ? Colors.red : Colors.green,
              );
            },
          ),
        ),
          ],
        ),

        const SizedBox(height: 16),

        // الصف الثاني - إحصائيات خط السير
        FutureBuilder<List<SupervisorAssignmentModel>>(
          future: _databaseService.getSupervisorAssignmentsSimple(_authService.currentUser?.uid ?? ''),
          builder: (context, assignmentSnapshot) {
            if (assignmentSnapshot.hasData && assignmentSnapshot.data!.isNotEmpty) {
              final assignment = assignmentSnapshot.data!.first;
              var busRoute = assignment.busRoute;

              // إذا كان busRoute فارغ، احصل عليه من بيانات الباص
              if (busRoute.isEmpty) {
                return FutureBuilder<BusModel?>(
                  future: _databaseService.getBusById(assignment.busId),
                  builder: (context, busSnapshot) {
                    if (busSnapshot.connectionState == ConnectionState.waiting) {
                      return _buildRouteStatsCard('...', '...', 'جاري التحميل...');
                    }

                    if (busSnapshot.hasData && busSnapshot.data != null) {
                      busRoute = busSnapshot.data!.route;
                    }

                    return _buildRouteStatsWithData(busRoute);
                  },
                );
              }

              return _buildRouteStatsWithData(busRoute);
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildRouteStatsWithData(String busRoute) {
    final supervisorId = _authService.currentUser?.uid ?? '';

    return FutureBuilder<List<StudentModel>>(
      future: _loadSupervisorStudents(supervisorId),
      builder: (context, studentsSnapshot) {
        if (studentsSnapshot.connectionState == ConnectionState.waiting) {
          return _buildRouteStatsCard('...', '...', busRoute.isEmpty ? 'جاري التحميل...' : busRoute);
        }

        if (studentsSnapshot.hasError) {
          debugPrint('❌ Error loading route stats: ${studentsSnapshot.error}');
          return _buildRouteStatsCard('خطأ', 'خطأ', busRoute.isEmpty ? 'خطأ في التحميل' : busRoute);
        }

        final allStudents = studentsSnapshot.data ?? [];
        final activeStudents = allStudents.where((s) => s.isActive).length;
        final routeDisplayName = busRoute.isEmpty ? 'خط السير' : busRoute;

        debugPrint('📊 Route stats - Total: ${allStudents.length}, Active: $activeStudents, Route: $routeDisplayName');

        return GestureDetector(
          onTap: () => context.push('/supervisor/route-statistics'),
          child: _buildRouteStatsCard(
            allStudents.length.toString(),
            activeStudents.toString(),
            routeDisplayName,
          ),
        );
      },
    );
  }

  Widget _buildRouteStatsCard(String totalStudents, String activeStudents, String routeName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E88E5).withAlpha(25),
            const Color(0xFF1976D2).withAlpha(25),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E88E5).withAlpha(76)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.route,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إحصائيات خط السير',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      routeName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: ResponsiveHelper.getPadding(context,
                  mobilePadding: const EdgeInsets.all(6),
                  tabletPadding: const EdgeInsets.all(8),
                  desktopPadding: const EdgeInsets.all(10),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5).withAlpha(25),
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context) * 0.5),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: const Color(0xFF1E88E5),
                  size: ResponsiveHelper.getIconSize(context) * 0.67,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMiniStatCard(
                  'إجمالي الطلاب',
                  totalStudents,
                  Icons.group,
                  const Color(0xFF1E88E5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStatCard(
                  'الطلاب النشطين',
                  activeStudents,
                  Icons.person_add_alt_1,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(icon, color: color, size: 28),
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
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMainActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1E88E5),
                    Color(0xFF1976D2),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.dashboard,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'الإجراءات الرئيسية',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A202C),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'مسح QR',
                'مسح رمز الطالب',
                Icons.qr_code_scanner,
                const Color(0xFF10B981),
                () => context.push('/supervisor/qr-scanner'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                'قائمة الطلاب',
                'عرض جميع الطلاب',
                Icons.people,
                const Color(0xFF3B82F6),
                () => context.push('/supervisor/students-list'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecondaryActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF4CAF50),
                    Color(0xFF388E3C),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.more_horiz,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'إجراءات إضافية',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A202C),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ResponsiveRow(
          children: [
            Expanded(
              child: _buildActionCard(
                'إدارة الغياب',
                'متابعة طلبات الغياب',
                Icons.event_busy,
                const Color(0xFFEF4444),
                () => _showAbsenceManagement(),
              ),
            ),
            SizedBox(width: ResponsiveHelper.getSpacing(context)),
            Expanded(
              child: _buildActionCard(
                'الاتصال الطارئ',
                'معلومات الاتصال',
                Icons.emergency,
                const Color(0xFFF59E0B),
                () => context.push('/supervisor/emergency-contact'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          'الاستبيانات الشهرية',
          'تقييم سلوك الطلاب الشهري',
          Icons.assignment,
          const Color(0xFF8B5CF6),
          () => _navigateToMonthlySurveys(),
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isFullWidth = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: ResponsiveHelper.getPadding(context,
            mobilePadding: const EdgeInsets.all(18),
            tabletPadding: const EdgeInsets.all(24),
            desktopPadding: const EdgeInsets.all(28),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context) * 1.25),
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
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.1),
                        color.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: color.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: color, size: 28),
                  ),
                  if (isFullWidth) ...[
                    const SizedBox(width: 16),
                    Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: color,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
                ],
                ],
              ),
              if (!isFullWidth) ...[
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _scanQRCode() {
    context.push('/supervisor/qr-scanner');
  }



  Future<void> _logout() async {
    try {
      await _authService.signOut();
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

  // دالة لعرض تسجيل الغياب
  void _showAbsenceRegistration() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.maxFinite,
          height: 500,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.person_add_disabled, color: Colors.red),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'تسجيل غياب طالب',
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
                child: FutureBuilder<List<SupervisorAssignmentModel>>(
                  future: _databaseService.getSupervisorAssignments(_authService.currentUser?.uid ?? '').first,
                  builder: (context, assignmentSnapshot) {
                    if (assignmentSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!assignmentSnapshot.hasData || assignmentSnapshot.data!.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_outlined, size: 64, color: Colors.orange),
                            SizedBox(height: 16),
                            Text(
                              'لم يتم تعيينك لأي باص',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }

                    final assignment = assignmentSnapshot.data!.first;
                    debugPrint('🚌 Dialog assignment route: "${assignment.busRoute}"');
                    debugPrint('🚌 Dialog assignment busId: "${assignment.busId}"');

                    // إذا كان busRoute فارغ، استخدم _studentsOnBusStream بدلاً من ذلك
                    final useMainStream = assignment.busRoute.isEmpty;
                    debugPrint('📱 Using main stream: $useMainStream');

                    return StreamBuilder<List<StudentModel>>(
                      stream: useMainStream
                          ? _studentsOnBusStream
                          : Stream.periodic(const Duration(seconds: 3))
                              .asyncMap((_) => _databaseService.getStudentsByRouteSimple(assignment.busRoute)),
                      builder: (context, snapshot) {
                        debugPrint('📱 Students StreamBuilder state: ${snapshot.connectionState}');
                        debugPrint('📱 Students has data: ${snapshot.hasData}');
                        debugPrint('📱 Students data length: ${snapshot.data?.length ?? 0}');

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          debugPrint('❌ Students StreamBuilder error: ${snapshot.error}');
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, size: 64, color: Colors.red),
                                SizedBox(height: 16),
                                Text(
                                  'خطأ في تحميل البيانات: ${snapshot.error}',
                                  style: TextStyle(fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.school_outlined, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'لا يوجد طلاب في هذا الخط',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          );
                        }

                        final students = snapshot.data!;
                        debugPrint('📱 Displaying ${students.length} students in ListView');

                        return ListView.builder(
                          itemCount: students.length,
                          itemBuilder: (context, index) {
                            final student = students[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.withAlpha(51)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                // صورة الطالب - أصغر
                                Container(
                                  width: 35,
                                  height: 35,
                                  decoration: BoxDecoration(
                                    color: Colors.red.withAlpha(25),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: Colors.red.withAlpha(76)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      student.name.substring(0, 1),
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // معلومات الطالب - مضغوطة
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        student.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2C3E50),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${student.grade} • ${student.busRoute}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),

                                // زر تسجيل الغياب - أصغر
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(6),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _registerStudentAbsence(student);
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.person_off,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'غياب',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                            );
                          },
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

  // دالة لعرض غيابات اليوم وطلبات الغياب
  void _showTodayAbsences() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Container(
          width: double.maxFinite,
          height: 500,
          padding: const EdgeInsets.all(16),
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_off, color: Colors.purple),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'إدارة الغياب',
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

                // Tab Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const TabBar(
                    labelColor: Colors.purple,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.purple,
                    tabs: [
                      Tab(
                        icon: Icon(Icons.notifications, size: 20),
                        text: 'إشعارات الغياب',
                      ),
                      Tab(
                        icon: Icon(Icons.check_circle, size: 20),
                        text: 'غيابات اليوم',
                      ),
                      Tab(
                        icon: Icon(Icons.list_alt, size: 20),
                        text: 'جميع الإشعارات',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // إحصائيات سريعة مضغوطة
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withAlpha(13),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.purple.withAlpha(51)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: StreamBuilder<List<AbsenceModel>>(
                          stream: _databaseService.getRecentAbsenceNotifications(),
                          builder: (context, snapshot) {
                            final count = snapshot.data?.length ?? 0;
                            return _buildCompactStat('إشعارات جديدة', count.toString(), Icons.notifications, Colors.blue);
                          },
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.grey.withAlpha(76),
                      ),
                      Expanded(
                        child: StreamBuilder<List<AbsenceModel>>(
                          stream: _databaseService.getTodayAbsencesForSupervisor(_authService.currentUser?.uid ?? ''),
                          builder: (context, snapshot) {
                            final count = snapshot.data?.length ?? 0;
                            return _buildCompactStat('غيابات اليوم', count.toString(), Icons.person_off, count > 0 ? Colors.red : Colors.green);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // إشعارات الغياب الجديدة
                      StreamBuilder<List<AbsenceModel>>(
                        stream: _databaseService.getRecentAbsenceNotifications(),
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
                                  Text(
                                    'لا توجد إشعارات جديدة',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    'لم يتم إرسال إشعارات غياب في آخر 24 ساعة',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          }

                          final recentNotifications = snapshot.data!;
                          return ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            cacheExtent: 1000,
                            itemCount: recentNotifications.length,
                            itemBuilder: (context, index) {
                              final absence = recentNotifications[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange.withAlpha(76)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header مضغوط
                                      Row(
                                        children: [
                                          Container(
                                            width: 30,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withAlpha(25),
                                              borderRadius: BorderRadius.circular(15),
                                            ),
                                            child: const Icon(
                                              Icons.schedule,
                                              color: Colors.orange,
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  absence.studentName,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF2C3E50),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  absence.typeDisplayText,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.orange,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'معلق',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // السبب مضغوط
                                      Text(
                                        'السبب: ${absence.reason}',
                                        style: const TextStyle(fontSize: 12),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                      if (absence.notes != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'ملاحظات: ${absence.notes}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],

                                      const SizedBox(height: 8),

                                      // معلومات إضافية
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withAlpha(25),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              size: 16,
                                              color: Colors.blue[700],
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'تم إبلاغ المدرسة عن هذا الغياب',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.blue[700],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              _formatTime(absence.createdAt),
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.blue[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),

                      // غيابات اليوم
                      StreamBuilder<List<AbsenceModel>>(
                        stream: _databaseService.getTodayAbsences(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, size: 64, color: Colors.green),
                                  SizedBox(height: 16),
                                  Text(
                                    'لا توجد غيابات اليوم',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    'جميع الطلاب حاضرون',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          }

                          final absences = snapshot.data!;
                          return ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            cacheExtent: 1000,
                            itemCount: absences.length,
                            itemBuilder: (context, index) {
                              final absence = absences[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _getAbsenceStatusColor(absence.status).withAlpha(76),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header مضغوط
                                      Row(
                                        children: [
                                          Container(
                                            width: 30,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              color: _getAbsenceStatusColor(absence.status).withAlpha(25),
                                              borderRadius: BorderRadius.circular(15),
                                            ),
                                            child: Icon(
                                              _getAbsenceStatusIcon(absence.status),
                                              color: _getAbsenceStatusColor(absence.status),
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  absence.studentName,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF2C3E50),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  '${absence.typeDisplayText} • ${absence.sourceDisplayText}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: _getAbsenceStatusColor(absence.status),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  absence.statusDisplayText,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                _formatTime(absence.createdAt),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),

                                      // السبب مضغوط
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'السبب: ${absence.reason}',
                                              style: const TextStyle(fontSize: 12),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (absence.notes != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                'ملاحظات: ${absence.notes}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[600],
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),

                      // جميع الطلبات (للتشخيص)
                      StreamBuilder<List<AbsenceModel>>(
                        stream: _databaseService.getAllAbsencesStream(),
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
                                  Text('خطأ: ${snapshot.error}'),
                                ],
                              ),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'لا توجد طلبات غياب',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    'لم يتم إرسال أي طلبات بعد',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          }

                          final allAbsences = snapshot.data!;
                          return Column(
                            children: [
                              // إحصائيات سريعة
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            '${allAbsences.length}',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          const Text(
                                            'إجمالي الطلبات',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            '${allAbsences.where((a) => a.status == AbsenceStatus.pending).length}',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange,
                                            ),
                                          ),
                                          const Text(
                                            'معلقة',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            '${allAbsences.where((a) => a.status == AbsenceStatus.approved).length}',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                          const Text(
                                            'مقبولة',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            '${allAbsences.where((a) => a.status == AbsenceStatus.rejected).length}',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                            ),
                                          ),
                                          const Text(
                                            'مرفوضة',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // قائمة جميع الطلبات
                              Expanded(
                                child: ListView.builder(
                                  itemCount: allAbsences.length,
                                  itemBuilder: (context, index) {
                                    final absence = allAbsences[index];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _getAbsenceStatusColor(absence.status).withAlpha(76),
                                        ),
                                      ),
                                      child: ListTile(
                                        leading: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: _getAbsenceStatusColor(absence.status).withAlpha(25),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Icon(
                                            _getAbsenceStatusIcon(absence.status),
                                            color: _getAbsenceStatusColor(absence.status),
                                            size: 20,
                                          ),
                                        ),
                                        title: Text(
                                          absence.studentName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${absence.typeDisplayText} • ${absence.sourceDisplayText}',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                            Text(
                                              'السبب: ${absence.reason}',
                                              style: const TextStyle(fontSize: 11),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              'تاريخ الإنشاء: ${_formatTime(absence.createdAt)}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getAbsenceStatusColor(absence.status),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            absence.statusDisplayText,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // دالة لتسجيل غياب طالب
  void _registerStudentAbsence(StudentModel student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.person_off, color: Colors.red),
            const SizedBox(width: 8),
            Text('تسجيل غياب ${student.name}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('هل تريد تسجيل غياب الطالب ${student.name}؟'),
            const SizedBox(height: 16),
            const Text(
              'سيتم إرسال إشعار لولي الأمر',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
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
            onPressed: () async {
              Navigator.pop(context);
              await _confirmAbsenceRegistration(student);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد الغياب'),
          ),
        ],
      ),
    );
  }

  // دالة لتأكيد تسجيل الغياب
  Future<void> _confirmAbsenceRegistration(StudentModel student) async {
    try {
      final absenceData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'studentId': student.id,
        'studentName': student.name,
        'parentId': student.parentId,
        'type': 'other',
        'reason': 'غياب مسجل من قبل المشرف',
        'date': DateTime.now().toIso8601String(),
        'endDate': null,
        'isMultipleDays': false,
        'status': 'approved', // مقبول مباشرة من المشرف
        'notes': 'تم تسجيل الغياب من قبل المشرف أثناء الرحلة',
        'createdAt': DateTime.now().toIso8601String(),
        'approvedAt': DateTime.now().toIso8601String(),
        'approvedBy': 'المشرف',
        'rejectionReason': null,
      };

      // إنشاء نموذج الغياب
      final now = DateTime.now();
      final absenceModel = AbsenceModel(
        id: absenceData['id'] as String,
        studentId: absenceData['studentId'] as String,
        studentName: absenceData['studentName'] as String,
        parentId: absenceData['parentId'] as String,
        supervisorId: null, // يمكن إضافة ID المشرف هنا
        adminId: null,
        type: AbsenceType.other,
        status: AbsenceStatus.approved,
        source: AbsenceSource.supervisor, // مصدر الغياب: المشرف
        date: DateTime.parse(absenceData['date'] as String),
        endDate: null,
        reason: absenceData['reason'] as String,
        notes: absenceData['notes'] as String?,
        attachmentUrl: null,
        createdAt: DateTime.parse(absenceData['createdAt'] as String),
        updatedAt: now, // وقت التحديث
        approvedBy: absenceData['approvedBy'] as String,
        approvedAt: DateTime.parse(absenceData['approvedAt'] as String),
        rejectionReason: null,
      );

      await _databaseService.createAbsence(absenceModel);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تسجيل غياب ${student.name} بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // إرسال إشعار لولي الأمر مع الصوت (بدون إشعار للمشرف الحالي)
      final currentUser = FirebaseAuth.instance.currentUser;
      await _notificationService.notifyAbsenceApprovedWithSound(
        studentId: student.id,
        studentName: student.name,
        parentId: student.parentId,
        supervisorId: currentUser?.uid ?? '',
        absenceDate: DateTime.now(),
        approvedBy: 'المشرف',
        approvedBySupervisorId: currentUser?.uid, // استبعاد المشرف الحالي
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تسجيل الغياب: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // دوال مساعدة لحالة الغياب
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

  IconData _getAbsenceStatusIcon(AbsenceStatus status) {
    switch (status) {
      case AbsenceStatus.pending:
        return Icons.schedule;
      case AbsenceStatus.approved:
        return Icons.check_circle;
      case AbsenceStatus.rejected:
        return Icons.cancel;
    }
  }



  // دالة لتنسيق الوقت
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // دالة لبناء إحصائية مضغوطة
  Widget _buildCompactStat(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // دالة لعرض جميع الإشعارات الحديثة
  void _showAllNotifications() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.notifications, color: Color(0xFF1E88E5)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'الإشعارات الحديثة',
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
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: Color(0xFF1E88E5),
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Color(0xFF1E88E5),
                        tabs: [
                          Tab(text: 'إشعارات الغياب'),
                          Tab(text: 'الإشعارات العامة'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            // إشعارات الغياب
                            StreamBuilder<List<AbsenceModel>>(
                              stream: _databaseService.getRecentAbsenceNotifications(),
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
                                        Text('لا توجد إشعارات غياب حديثة'),
                                      ],
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  cacheExtent: 1000,
                                  itemCount: snapshot.data!.length,
                                  itemBuilder: (context, index) {
                                    final absence = snapshot.data![index];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                      child: ListTile(
                                        leading: const Icon(Icons.person_off, color: Colors.orange),
                                        title: Text('غياب ${absence.studentName}'),
                                        subtitle: Text(
                                          'السبب: ${absence.reason}\n'
                                          'التاريخ: ${absence.date.day}/${absence.date.month}/${absence.date.year}',
                                        ),
                                        trailing: Text(
                                          '${absence.createdAt.hour}:${absence.createdAt.minute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            // الإشعارات العامة
                            StreamBuilder<List<Map<String, dynamic>>>(
                              stream: _databaseService.getRecentGeneralNotifications(),
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
                                        Text('لا توجد إشعارات عامة حديثة'),
                                      ],
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  cacheExtent: 1000,
                                  itemCount: snapshot.data!.length,
                                  itemBuilder: (context, index) {
                                    final notification = snapshot.data![index];
                                    final timestamp = notification['timestamp'] != null
                                        ? (notification['timestamp'] as Timestamp).toDate()
                                        : DateTime.now();

                                    return Card(
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                      child: ListTile(
                                        leading: const Icon(Icons.notifications, color: Colors.blue),
                                        title: Text(notification['title'] ?? 'إشعار'),
                                        subtitle: Text(notification['body'] ?? ''),
                                        trailing: Text(
                                          '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAbsenceManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SupervisorAbsenceManagementScreen(),
      ),
    );
  }

  void _navigateToMonthlySurveys() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MonthlyBehaviorSurveyScreen(),
      ),
    );
  }

  // Show students in route dialog
  void _showRouteStudentsDialog(List<StudentModel> students) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[400]!, Colors.green[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.people,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'طلاب خط المسار',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        Text(
                          '${students.length} ${students.length == 1 ? 'طالب' : 'طلاب'} في خط المسار المعين لك',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.grey[600]),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Students List
              if (students.isEmpty)
                Expanded(
                  child: FutureBuilder<bool>(
                    future: _databaseService.hasSupervisorAssignments(_authService.currentUser?.uid ?? ''),
                    builder: (context, snapshot) {
                      final hasAssignments = snapshot.data ?? true;

                      if (!hasAssignments) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 64,
                                color: Colors.orange[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'لم يتم تعيينك لأي باص',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.orange[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'يرجى التواصل مع الإدارة لتعيينك لباص',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.directions_bus_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا يوجد طلاب في الباص',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'ابدأ بمسح QR للطلاب المعينين لباصك',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16), // إضافة مساحة في الأسفل
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withAlpha(76)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF2D3748),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'الصف: ${student.grade} • ${student.schoolName}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  FutureBuilder<String>(
                                    future: _getBusPlateNumber(student.busId),
                                    builder: (context, snapshot) {
                                      final busPlate = snapshot.data ?? student.busId;
                                      return Text(
                                        'الباص: $busPlate',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.blue[600],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.directions_bus,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'في الباص',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/supervisor/qr-scanner');
                      },
                      icon: const Icon(Icons.qr_code_scanner, size: 16),
                      label: const Text('مسح QR'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                        backgroundColor: Colors.green.withAlpha(25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        backgroundColor: Colors.grey.withAlpha(25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('إغلاق'),
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

  // Get bus plate number from bus ID
  Future<String> _getBusPlateNumber(String busId) async {
    try {
      final bus = await _databaseService.getBus(busId);
      return bus?.plateNumber ?? busId;
    } catch (e) {
      debugPrint('Error getting bus plate number: $e');
      return busId;
    }
  }

  // Build Students List Section
  Widget _buildStudentsListSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1976D2),
                  const Color(0xFF1565C0),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.people,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'طلاب الخط',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Students List
          Container(
            height: 300, // Fixed height for the list
            child: StreamBuilder<List<StudentModel>>(
              stream: _studentsOnBusStream,
              builder: (context, snapshot) {
                debugPrint('🎯 Students List Section - Connection: ${snapshot.connectionState}');
                debugPrint('🎯 Students List Section - Has Data: ${snapshot.hasData}');
                debugPrint('🎯 Students List Section - Data Length: ${snapshot.data?.length ?? 0}');

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  debugPrint('❌ Students List Section Error: ${snapshot.error}');
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'خطأ في تحميل الطلاب: ${snapshot.error}',
                            style: const TextStyle(fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.school_outlined, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'لا يوجد طلاب في هذا الخط',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final students = snapshot.data!;
                debugPrint('🎯 Displaying ${students.length} students in main list');

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return _buildStudentListItem(student);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Build Student List Item (similar to admin style)
  Widget _buildStudentListItem(StudentModel student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withAlpha(51)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF1976D2).withAlpha(25),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.person,
            color: Color(0xFF1976D2),
            size: 20,
          ),
        ),
        title: Text(
          student.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${student.schoolName} - ${student.grade}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'ولي الأمر: ${student.parentName}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(student.currentStatus).withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getStatusText(student.currentStatus),
            style: TextStyle(
              color: _getStatusColor(student.currentStatus),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // Helper methods for student status
  Color _getStatusColor(StudentStatus status) {
    switch (status) {
      case StudentStatus.home:
        return Colors.green;
      case StudentStatus.onBus:
        return Colors.orange;
      case StudentStatus.atSchool:
        return Colors.blue;
    }
  }

  String _getStatusText(StudentStatus status) {
    switch (status) {
      case StudentStatus.home:
        return 'في المنزل';
      case StudentStatus.onBus:
        return 'في الباص';
      case StudentStatus.atSchool:
        return 'في المدرسة';
    }
  }
}

