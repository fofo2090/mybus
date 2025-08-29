import 'package:flutter/material.dart';
import 'lib/services/notification_dialog_service.dart';

/// مثال على كيفية إعداد خدمة dialog الإشعارات في التطبيق
/// يجب إضافة هذا الكود في main.dart

class MyApp extends StatelessWidget {
  // إنشاء مفتاح التنقل الرئيسي
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyBus',
      
      // تعيين مفتاح التنقل للخدمة
      navigatorKey: navigatorKey,
      
      // باقي إعدادات التطبيق...
      home: MyHomePage(),
      
      // تهيئة خدمة dialog الإشعارات
      builder: (context, child) {
        // تعيين مفتاح التنقل لخدمة الإشعارات
        NotificationDialogService.setNavigatorKey(navigatorKey);
        return child!;
      },
    );
  }
}

/// مثال على كيفية الاستخدام في main.dart الفعلي
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة Firebase
  await Firebase.initializeApp();
  
  // تشغيل التطبيق
  runApp(MyApp());
}

/// مثال على كيفية إضافة الكود للـ main.dart الموجود
/*
في ملف lib/main.dart، أضف هذا الكود:

1. في أعلى الملف:
import 'services/notification_dialog_service.dart';

2. في class MyApp:
class MyApp extends StatelessWidget {
  // إضافة مفتاح التنقل
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // إضافة مفتاح التنقل
      navigatorKey: navigatorKey,
      
      // باقي الإعدادات الموجودة...
      title: 'MyBus',
      theme: ThemeData(...),
      home: SplashScreen(),
      routes: {...},
      
      // إضافة builder لتهيئة الخدمة
      builder: (context, child) {
        NotificationDialogService.setNavigatorKey(navigatorKey);
        return child!;
      },
    );
  }
}
*/

/// مثال على اختبار dialog الإشعار
class NotificationDialogTestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('اختبار dialog الإشعارات'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.notifications_active, size: 48, color: Colors.blue),
                    SizedBox(height: 8),
                    Text(
                      'اختبار dialog الإشعارات التفاعلية',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'اختبر أنواع مختلفة من الإشعارات التفاعلية',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // أزرار اختبار أنواع مختلفة من الإشعارات
            _buildTestButton(
              'إشعار طالب',
              Icons.directions_bus,
              Colors.green,
              () => _testStudentNotification(context),
            ),
            
            _buildTestButton(
              'إشعار غياب',
              Icons.event_busy,
              Colors.red,
              () => _testAbsenceNotification(context),
            ),
            
            _buildTestButton(
              'إشعار ترحيبي',
              Icons.celebration,
              Colors.blue,
              () => _testWelcomeNotification(context),
            ),
            
            _buildTestButton(
              'إشعار إداري',
              Icons.admin_panel_settings,
              Colors.orange,
              () => _testAdminNotification(context),
            ),
            
            _buildTestButton(
              'إشعار طوارئ',
              Icons.warning,
              Colors.red[700]!,
              () => _testEmergencyNotification(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(title, style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  void _testStudentNotification(BuildContext context) {
    final fakeMessage = _createFakeMessage(
      title: 'ركب أحمد الباص',
      body: 'ركب الطالب أحمد محمد الباص في الساعة 7:30 صباحاً',
      type: 'student',
      data: {
        'studentName': 'أحمد محمد',
        'busRoute': 'الخط الأول',
        'timestamp': DateTime.now().toString(),
        'action': 'view_student',
      },
    );
    
    NotificationDialogService().showNotificationDialog(fakeMessage);
  }

  void _testAbsenceNotification(BuildContext context) {
    final fakeMessage = _createFakeMessage(
      title: 'طلب غياب جديد',
      body: 'تم تقديم طلب غياب للطالب سارة أحمد ليوم غد',
      type: 'absence',
      data: {
        'studentName': 'سارة أحمد',
        'absenceDate': DateTime.now().add(Duration(days: 1)).toString(),
        'reason': 'موعد طبي',
        'action': 'view_absence',
      },
    );
    
    NotificationDialogService().showNotificationDialog(fakeMessage);
  }

  void _testWelcomeNotification(BuildContext context) {
    final fakeMessage = _createFakeMessage(
      title: '🎉 أهلاً وسهلاً بك في MyBus',
      body: 'مرحباً محمد أحمد! تم إنشاء حسابك بنجاح. استمتع بمتابعة رحلة طفلك بأمان.',
      type: 'welcome',
      data: {
        'parentName': 'محمد أحمد',
        'action': 'show_tutorial',
      },
    );
    
    NotificationDialogService().showNotificationDialog(fakeMessage);
  }

  void _testAdminNotification(BuildContext context) {
    final fakeMessage = _createFakeMessage(
      title: 'تكليف جديد',
      body: 'تم تعيينك كمشرف للباص رقم 123 - الخط الأول',
      type: 'assignment',
      data: {
        'busId': '123',
        'busRoute': 'الخط الأول',
        'action': 'view_assignment',
      },
    );
    
    NotificationDialogService().showNotificationDialog(fakeMessage);
  }

  void _testEmergencyNotification(BuildContext context) {
    final fakeMessage = _createFakeMessage(
      title: '⚠️ تنبيه طوارئ',
      body: 'يرجى التواصل مع الإدارة فوراً بخصوص الباص رقم 456',
      type: 'emergency',
      data: {
        'busId': '456',
        'urgency': 'high',
        'action': 'contact_admin',
      },
    );
    
    NotificationDialogService().showNotificationDialog(fakeMessage);
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
