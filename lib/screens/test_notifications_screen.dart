import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../widgets/responsive_widgets.dart';

/// شاشة اختبار الإشعارات
class TestNotificationsScreen extends StatefulWidget {
  const TestNotificationsScreen({super.key});

  @override
  State<TestNotificationsScreen> createState() => _TestNotificationsScreenState();
}

class _TestNotificationsScreenState extends State<TestNotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const ResponsiveHeading('اختبار الإشعارات'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: ResponsiveContainer(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(),
              const ResponsiveVerticalSpace(),
              _buildTestSection('إشعارات الطلاب', [
                _buildTestButton(
                  'تسكين طالب',
                  'اختبار إشعار تسكين طالب في الباص',
                  Icons.school,
                  Colors.green,
                  _testStudentAssignment,
                ),
                _buildTestButton(
                  'إلغاء تسكين طالب',
                  'اختبار إشعار إلغاء تسكين طالب',
                  Icons.school_outlined,
                  Colors.orange,
                  _testStudentUnassignment,
                ),
              ]),
              const ResponsiveVerticalSpace(),
              _buildTestSection('إشعارات الباص', [
                _buildTestButton(
                  'ركوب الباص',
                  'اختبار إشعار ركوب طالب للباص',
                  Icons.directions_bus,
                  Colors.blue,
                  _testStudentBoarded,
                ),
                _buildTestButton(
                  'نزول من الباص',
                  'اختبار إشعار نزول طالب من الباص',
                  Icons.home,
                  Colors.purple,
                  _testStudentAlighted,
                ),
              ]),
              const ResponsiveVerticalSpace(),
              _buildTestSection('إشعارات الغياب', [
                _buildTestButton(
                  'طلب غياب',
                  'اختبار إشعار طلب غياب جديد',
                  Icons.event_busy,
                  Colors.orange,
                  _testAbsenceRequest,
                ),
                _buildTestButton(
                  'موافقة على الغياب',
                  'اختبار إشعار الموافقة على الغياب',
                  Icons.check_circle,
                  Colors.green,
                  _testAbsenceApproved,
                ),
                _buildTestButton(
                  'رفض الغياب',
                  'اختبار إشعار رفض الغياب',
                  Icons.cancel,
                  Colors.red,
                  _testAbsenceRejected,
                ),
              ]),
              const ResponsiveVerticalSpace(),
              _buildTestSection('إشعارات أخرى', [
                _buildTestButton(
                  'شكوى جديدة',
                  'اختبار إشعار شكوى جديدة',
                  Icons.feedback,
                  Colors.blueGrey,
                  _testNewComplaint,
                ),
                _buildTestButton(
                  'حالة طوارئ',
                  'اختبار إشعار حالة طوارئ',
                  Icons.emergency,
                  Colors.red,
                  _testEmergency,
                ),
                _buildTestButton(
                  'تحديث حالة الرحلة',
                  'اختبار إشعار تحديث حالة الرحلة',
                  Icons.update,
                  Colors.indigo,
                  _testTripStatusUpdate,
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return ResponsiveCard(
      color: Colors.blue.withOpacity(0.1),
      border: Border.all(color: Colors.blue.withOpacity(0.3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ResponsiveIcon(Icons.info, color: Colors.blue),
              const ResponsiveHorizontalSpace(),
              const ResponsiveSubheading('معلومات الاختبار'),
            ],
          ),
          const ResponsiveVerticalSpace(),
          const ResponsiveBodyText(
            'هذه الشاشة لاختبار جميع أنواع الإشعارات في التطبيق. '
            'ستظهر الإشعارات مع الصوت والاهتزاز في قائمة الإشعارات.',
          ),
          const ResponsiveVerticalSpace(),
          ResponsiveWrap(
            children: [
              ResponsiveChip(
                label: const Text('مع صوت'),
                backgroundColor: Colors.green.withOpacity(0.1),
              ),
              ResponsiveChip(
                label: const Text('مع اهتزاز'),
                backgroundColor: Colors.orange.withOpacity(0.1),
              ),
              ResponsiveChip(
                label: const Text('في قائمة الإشعارات'),
                backgroundColor: Colors.blue.withOpacity(0.1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestSection(String title, List<Widget> buttons) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveSubheading(title),
          const ResponsiveVerticalSpace(),
          ResponsiveWrap(
            children: buttons,
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: ResponsiveHelper.isMobile(context) 
          ? double.infinity 
          : (MediaQuery.of(context).size.width - 64) / 2,
      child: ResponsiveCard(
        onTap: _isLoading ? null : onPressed,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: color.withOpacity(0.3)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(ResponsiveHelper.getSpacing(context)),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context)),
                  ),
                  child: ResponsiveIcon(icon, color: color),
                ),
                const Spacer(),
                if (_isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                else
                  ResponsiveIcon(
                    Icons.play_arrow,
                    color: color.withOpacity(0.7),
                    mobileSize: 16,
                    tabletSize: 18,
                    desktopSize: 20,
                  ),
              ],
            ),
            const ResponsiveVerticalSpace(),
            ResponsiveBodyText(
              title,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 4),
            ResponsiveCaption(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testStudentAssignment() async {
    await _runTest(() async {
      await _notificationService.notifyStudentAssignmentWithSound(
        studentId: 'test-student-1',
        studentName: 'أحمد محمد',
        busId: 'bus-001',
        busRoute: 'خط الرياض - الملز',
        parentId: _getCurrentUserId(),
        supervisorId: 'supervisor-1',
        parentName: 'محمد أحمد',
        parentPhone: '01234567890',
      );
    });
  }

  Future<void> _testStudentUnassignment() async {
    await _runTest(() async {
      await _notificationService.notifyStudentUnassignmentWithSound(
        studentId: 'test-student-1',
        studentName: 'أحمد محمد',
        busId: 'bus-001',
        parentId: _getCurrentUserId(),
        supervisorId: 'supervisor-1',
      );
    });
  }

  Future<void> _testStudentBoarded() async {
    await _runTest(() async {
      await _notificationService.notifyStudentBoardedWithSound(
        studentId: 'test-student-1',
        studentName: 'أحمد محمد',
        busId: 'bus-001',
        parentId: _getCurrentUserId(),
        supervisorId: 'supervisor-1',
      );
    });
  }

  Future<void> _testStudentAlighted() async {
    await _runTest(() async {
      await _notificationService.notifyStudentAlightedWithSound(
        studentId: 'test-student-1',
        studentName: 'أحمد محمد',
        busId: 'bus-001',
        parentId: _getCurrentUserId(),
        supervisorId: 'supervisor-1',
      );
    });
  }

  Future<void> _testAbsenceRequest() async {
    await _runTest(() async {
      await _notificationService.notifyAbsenceRequestWithSound(
        studentId: 'test-student-1',
        studentName: 'أحمد محمد',
        parentId: _getCurrentUserId(),
        parentName: 'محمد أحمد',
        supervisorId: 'supervisor-1',
        busId: 'bus-001',
        absenceDate: DateTime.now().add(const Duration(days: 1)),
        reason: 'مرض',
      );
    });
  }

  Future<void> _testAbsenceApproved() async {
    await _runTest(() async {
      await _notificationService.notifyAbsenceApprovedWithSound(
        studentId: 'test-student-1',
        studentName: 'أحمد محمد',
        parentId: _getCurrentUserId(),
        supervisorId: 'supervisor-1',
        absenceDate: DateTime.now().add(const Duration(days: 1)),
        approvedBy: 'المشرف أحمد',
        approvedBySupervisorId: 'supervisor-1', // استبعاد المشرف من الإشعار
      );
    });
  }

  Future<void> _testAbsenceRejected() async {
    await _runTest(() async {
      await _notificationService.notifyAbsenceRejectedWithSound(
        studentId: 'test-student-1',
        studentName: 'أحمد محمد',
        parentId: _getCurrentUserId(),
        supervisorId: 'supervisor-1',
        absenceDate: DateTime.now().add(const Duration(days: 1)),
        rejectedBy: 'المشرف أحمد',
        reason: 'السبب غير مقبول',
        rejectedBySupervisorId: 'supervisor-1', // استبعاد المشرف من الإشعار
      );
    });
  }

  Future<void> _testNewComplaint() async {
    await _runTest(() async {
      await _notificationService.notifyNewComplaintWithSound(
        complaintId: 'complaint-1',
        parentId: _getCurrentUserId(),
        parentName: 'والد الطالب',
        subject: 'شكوى تجريبية',
        category: 'عام',
      );
    });
  }

  Future<void> _testEmergency() async {
    await _runTest(() async {
      await _notificationService.notifyEmergencyWithSound(
        busId: 'bus-001',
        supervisorId: 'supervisor-1',
        supervisorName: 'المشرف أحمد',
        emergencyType: 'عطل في الباص',
        description: 'عطل مفاجئ في المحرك',
        parentIds: [_getCurrentUserId()],
      );
    });
  }

  Future<void> _testTripStatusUpdate() async {
    await _runTest(() async {
      await _notificationService.notifyTripStatusUpdateWithSound(
        busId: 'bus-001',
        busRoute: 'خط الرياض - الملز',
        status: 'started',
        parentIds: [_getCurrentUserId()],
        supervisorId: 'supervisor-1',
      );
    });
  }

  Future<void> _runTest(Future<void> Function() testFunction) async {
    setState(() => _isLoading = true);
    
    try {
      await testFunction();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إرسال الإشعار بنجاح!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في إرسال الإشعار: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getCurrentUserId() {
    return context.read<AuthService>().currentUser?.uid ?? 'test-user';
  }
}
