import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/student_model.dart';
import '../../models/absence_model.dart';
import '../../models/supervisor_assignment_model.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../services/notification_sender_service.dart';
import '../../services/auth_service.dart';

class SupervisorAbsenceManagementScreen extends StatefulWidget {
  const SupervisorAbsenceManagementScreen({super.key});

  @override
  State<SupervisorAbsenceManagementScreen> createState() => _SupervisorAbsenceManagementScreenState();
}

class _SupervisorAbsenceManagementScreenState extends State<SupervisorAbsenceManagementScreen> with TickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  final NotificationSenderService _notificationSender = NotificationSenderService();
  final AuthService _authService = AuthService();
  
  late TabController _tabController;
  List<StudentModel> _students = [];
  List<AbsenceModel> _todayAbsences = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // احصل على خط السير الخاص بالمشرف
      final supervisorId = _authService.currentUser?.uid ?? '';
      final assignments = await _databaseService.getSupervisorAssignments(supervisorId).first;

      if (assignments.isNotEmpty) {
        final supervisorRoute = assignments.first.busRoute;

        // احصل على طلاب خط السير الخاص بالمشرف فقط
        _databaseService.getStudentsByRoute(supervisorRoute).listen((students) {
          if (mounted) {
            setState(() {
              _students = students;
            });
          }
        });
      } else {
        // إذا لم يكن للمشرف تعيينات، اعرض قائمة فارغة
        setState(() {
          _students = [];
        });
      }

      // Load today's absences
      _databaseService.getAllAbsencesStream().listen((absences) {
        if (mounted) {
          final today = DateTime.now();
          final todayAbsences = absences.where((absence) =>
            absence.date.year == today.year &&
            absence.date.month == today.month &&
            absence.date.day == today.day
          ).toList();
          
          setState(() {
            _todayAbsences = todayAbsences;
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('إدارة الغياب'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.person_add_disabled),
              text: 'تسجيل غياب',
            ),
            Tab(
              icon: Icon(Icons.list_alt),
              text: 'غيابات اليوم',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'السجل',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRegisterAbsenceTab(),
          _buildTodayAbsencesTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildRegisterAbsenceTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final activeStudents = _students.where((student) => 
      student.currentStatus == StudentStatus.onBus || 
      student.currentStatus == StudentStatus.atSchool
    ).toList();

    if (activeStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'لا يوجد طلاب نشطون',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'جميع الطلاب في المنزل حالياً',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeStudents.length,
      itemBuilder: (context, index) {
        final student = activeStudents[index];
        final isAbsentToday = _todayAbsences.any((absence) => 
          absence.studentId == student.id
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Student Avatar
                CircleAvatar(
                  radius: 25,
                  backgroundColor: _getStatusColor(student.currentStatus),
                  child: Text(
                    student.name.isNotEmpty ? student.name[0] : 'ط',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Student Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        student.grade,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            _getStatusIcon(student.currentStatus),
                            size: 16,
                            color: _getStatusColor(student.currentStatus),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getStatusText(student.currentStatus),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStatusColor(student.currentStatus),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Action Button
                if (isAbsentToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.withAlpha(76)),
                    ),
                    child: const Text(
                      'غائب اليوم',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => _registerAbsence(student),
                    icon: const Icon(Icons.person_off, size: 18),
                    label: const Text('تسجيل غياب'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodayAbsencesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_todayAbsences.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 80,
              color: Colors.green[400],
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد غيابات اليوم',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'جميع الطلاب حاضرون',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _todayAbsences.length,
      itemBuilder: (context, index) {
        final absence = _todayAbsences[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getAbsenceSourceColor(absence.source),
              child: Icon(
                _getAbsenceSourceIcon(absence.source),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              absence.studentName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('السبب: ${absence.reason}'),
                Text(
                  'الوقت: ${DateFormat('HH:mm').format(absence.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getAbsenceSourceColor(absence.source).withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getAbsenceSourceText(absence.source),
                style: TextStyle(
                  fontSize: 12,
                  color: _getAbsenceSourceColor(absence.source),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return StreamBuilder<List<AbsenceModel>>(
      stream: _databaseService.getAllAbsencesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allAbsences = snapshot.data ?? [];
        final supervisorAbsences = allAbsences
            .where((absence) => absence.source == AbsenceSource.supervisor)
            .toList();

        supervisorAbsences.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (supervisorAbsences.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'لا يوجد سجل غيابات',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'لم تقم بتسجيل أي غيابات بعد',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: supervisorAbsences.length,
          itemBuilder: (context, index) {
            final absence = supervisorAbsences[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red,
                  child: const Icon(
                    Icons.person_off,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(
                  absence.studentName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('السبب: ${absence.reason}'),
                    Text(
                      'التاريخ: ${DateFormat('yyyy/MM/dd - HH:mm').format(absence.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'مقبول',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _registerAbsence(StudentModel student) async {
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmAbsenceRegistration(student);
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

  Future<void> _confirmAbsenceRegistration(StudentModel student) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري تسجيل الغياب...'),
                ],
              ),
            ),
          ),
        ),
      );

      final now = DateTime.now();
      final absenceModel = AbsenceModel(
        id: now.millisecondsSinceEpoch.toString(),
        studentId: student.id,
        studentName: student.name,
        parentId: student.parentId,
        supervisorId: _authService.currentUser?.uid,
        adminId: null,
        type: AbsenceType.other,
        status: AbsenceStatus.approved,
        source: AbsenceSource.supervisor,
        date: now,
        endDate: null,
        reason: 'غياب مسجل من قبل المشرف',
        notes: 'تم تسجيل الغياب من قبل المشرف أثناء الرحلة',
        attachmentUrl: null,
        createdAt: now,
        updatedAt: now,
        approvedBy: 'المشرف',
        approvedAt: now,
        rejectionReason: null,
      );

      await _databaseService.createAbsence(absenceModel);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تسجيل غياب ${student.name} بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Send notification to parent with sound (exclude current supervisor)
      await _notificationService.notifyAbsenceApprovedWithSound(
        studentId: student.id,
        studentName: student.name,
        parentId: student.parentId,
        supervisorId: _authService.currentUser?.uid ?? '',
        absenceDate: now,
        approvedBy: 'المشرف',
        approvedBySupervisorId: _authService.currentUser?.uid, // استبعاد المشرف الحالي
      );

      // إرسال إشعار push لولي الأمر (النظام الجديد)
      await _notificationSender.sendStudentStatusNotificationToParent(
        parentId: student.parentId,
        studentName: student.name,
        status: 'absent',
        busNumber: student.busId, // استخدام busId بدلاً من busNumber
        location: 'تم تسجيل الغياب من قبل المشرف',
      );
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

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

  Color _getStatusColor(StudentStatus status) {
    switch (status) {
      case StudentStatus.home:
        return Colors.grey;
      case StudentStatus.onBus:
        return Colors.orange;
      case StudentStatus.atSchool:
        return Colors.green;
    }
  }

  IconData _getStatusIcon(StudentStatus status) {
    switch (status) {
      case StudentStatus.home:
        return Icons.home;
      case StudentStatus.onBus:
        return Icons.directions_bus;
      case StudentStatus.atSchool:
        return Icons.school;
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

  Color _getAbsenceSourceColor(AbsenceSource source) {
    switch (source) {
      case AbsenceSource.parent:
        return Colors.blue;
      case AbsenceSource.supervisor:
        return Colors.red;
      case AbsenceSource.admin:
        return Colors.purple;
      case AbsenceSource.system:
        return Colors.grey;
    }
  }

  IconData _getAbsenceSourceIcon(AbsenceSource source) {
    switch (source) {
      case AbsenceSource.parent:
        return Icons.family_restroom;
      case AbsenceSource.supervisor:
        return Icons.person_off;
      case AbsenceSource.admin:
        return Icons.admin_panel_settings;
      case AbsenceSource.system:
        return Icons.computer;
    }
  }

  String _getAbsenceSourceText(AbsenceSource source) {
    switch (source) {
      case AbsenceSource.parent:
        return 'ولي الأمر';
      case AbsenceSource.supervisor:
        return 'المشرف';
      case AbsenceSource.admin:
        return 'الإدارة';
      case AbsenceSource.system:
        return 'النظام';
    }
  }
}
