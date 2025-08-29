import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../services/notification_dialog_service.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';

/// شاشة اختبار الإشعارات لأولياء الأمور
class ParentNotificationTestScreen extends StatefulWidget {
  @override
  _ParentNotificationTestScreenState createState() => _ParentNotificationTestScreenState();
}

class _ParentNotificationTestScreenState extends State<ParentNotificationTestScreen> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    final user = _authService.currentUser;
    setState(() {
      _currentUserId = user?.uid ?? 'غير محدد';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('اختبار إشعارات ولي الأمر'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // معلومات المستخدم الحالي
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'معلومات المستخدم الحالي',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('معرف المستخدم: $_currentUserId'),
                    Text('نوع المستخدم: ولي أمر'),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            Text(
              'اختبار أنواع مختلفة من الإشعارات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 16),

            // اختبار إشعار ركوب الطالب
            _buildTestButton(
              'إشعار ركوب الطالب',
              'طفلك أحمد ركب الباص الآن',
              Icons.directions_bus,
              Colors.green,
              () => _testStudentBoardingNotification(),
            ),

            // اختبار إشعار وصول الطالب
            _buildTestButton(
              'إشعار وصول الطالب',
              'طفلك أحمد وصل إلى المدرسة بأمان',
              Icons.school,
              Colors.blue,
              () => _testStudentArrivalNotification(),
            ),

            // اختبار إشعار عام
            _buildTestButton(
              'إشعار عام',
              'إشعار عام لجميع أولياء الأمور',
              Icons.notifications,
              Colors.orange,
              () => _testGeneralNotification(),
            ),

            // اختبار إشعار بدون targetUserId
            _buildTestButton(
              'إشعار بدون مستخدم محدد',
              'إشعار يجب أن يظهر لجميع المستخدمين',
              Icons.campaign,
              Colors.purple,
              () => _testNotificationWithoutTarget(),
            ),

            // اختبار إشعار لمستخدم آخر
            _buildTestButton(
              'إشعار لمستخدم آخر',
              'إشعار لمستخدم آخر (لا يجب أن يظهر)',
              Icons.person_off,
              Colors.red,
              () => _testNotificationForOtherUser(),
            ),

            SizedBox(height: 20),

            // معلومات إضافية
            Card(
              color: Colors.amber[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📝 ملاحظات الاختبار:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('• الإشعارات الخضراء والزرقاء يجب أن تظهر'),
                    Text('• الإشعار البنفسجي يجب أن يظهر (بدون مستخدم محدد)'),
                    Text('• الإشعار الأحمر لا يجب أن يظهر (لمستخدم آخر)'),
                    Text('• تحقق من console للرسائل التشخيصية'),
                  ],
                ),
              ),
            ),
          ],
        ),
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
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.all(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _testStudentBoardingNotification() {
    final fakeMessage = _createFakeMessage(
      title: '🚌 ركب طفلك الباص',
      body: 'ركب طفلك أحمد الباص في الساعة ${_getCurrentTime()}',
      type: 'student',
      data: {
        'userId': _currentUserId, // للمستخدم الحالي
        'studentName': 'أحمد',
        'busRoute': 'الخط الأول',
        'timestamp': DateTime.now().toString(),
        'action': 'view_student',
      },
    );

    NotificationDialogService().showNotificationDialog(fakeMessage);
  }

  void _testStudentArrivalNotification() {
    final fakeMessage = _createFakeMessage(
      title: '🏫 وصل طفلك إلى المدرسة',
      body: 'وصل طفلك أحمد إلى المدرسة بأمان في الساعة ${_getCurrentTime()}',
      type: 'arrival',
      data: {
        'recipientId': _currentUserId, // للمستخدم الحالي
        'studentName': 'أحمد',
        'schoolName': 'مدرسة النور',
        'timestamp': DateTime.now().toString(),
        'action': 'view_arrival',
      },
    );

    NotificationDialogService().showNotificationDialog(fakeMessage);
  }

  void _testGeneralNotification() {
    final fakeMessage = _createFakeMessage(
      title: '📢 إشعار عام',
      body: 'تذكير: غداً إجازة رسمية، لن تعمل الباصات',
      type: 'general',
      data: {
        'userId': _currentUserId, // للمستخدم الحالي
        'source': 'admin',
        'priority': 'normal',
      },
    );

    NotificationDialogService().showNotificationDialog(fakeMessage);
  }

  void _testNotificationWithoutTarget() {
    final fakeMessage = _createFakeMessage(
      title: '🌟 إشعار للجميع',
      body: 'هذا إشعار يجب أن يظهر لجميع المستخدمين المتصلين',
      type: 'broadcast',
      data: {
        // بدون userId أو recipientId
        'source': 'system',
        'priority': 'high',
      },
    );

    NotificationDialogService().showNotificationDialog(fakeMessage);
  }

  void _testNotificationForOtherUser() {
    final fakeMessage = _createFakeMessage(
      title: '❌ إشعار لمستخدم آخر',
      body: 'هذا الإشعار لا يجب أن يظهر لأنه لمستخدم آخر',
      type: 'student',
      data: {
        'userId': 'other_user_id_12345', // لمستخدم آخر
        'studentName': 'سارة',
        'busRoute': 'الخط الثاني',
      },
    );

    NotificationDialogService().showNotificationDialog(fakeMessage);
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  // دالة مساعدة لإنشاء رسالة وهمية للاختبار
  dynamic _createFakeMessage({
    required String title,
    required String body,
    required String type,
    required Map<String, dynamic> data,
  }) {
    return FakeRemoteMessage(
      notification: FakeNotification(title: title, body: body),
      data: {'type': type, ...data},
    );
  }
}

// فئات وهمية للاختبار
class FakeRemoteMessage {
  final FakeNotification? notification;
  final Map<String, dynamic> data;

  FakeRemoteMessage({this.notification, required this.data});
}

class FakeNotification {
  final String? title;
  final String? body;

  FakeNotification({this.title, this.body});
}
