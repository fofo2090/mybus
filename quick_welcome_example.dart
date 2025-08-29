import 'package:flutter/material.dart';
import 'lib/services/welcome_notification_service.dart';
import 'lib/services/notification_service.dart';

/// مثال سريع لاستخدام الإشعارات الترحيبية
/// يمكن نسخ هذا الكود واستخدامه مباشرة في صفحة التسجيل

class QuickWelcomeExample {
  
  /// استخدام في صفحة تسجيل ولي الأمر
  static Future<void> sendWelcomeToNewParent({
    required String parentId,
    required String parentName,
    required String parentEmail,
    String? parentPhone,
  }) async {
    try {
      print('🎉 Sending welcome notification to: $parentName');

      // الطريقة الأولى: استخدام خدمة الإشعارات الترحيبية (الأفضل)
      await WelcomeNotificationService().sendCompleteWelcomeSequence(
        parentId: parentId,
        parentName: parentName,
        parentEmail: parentEmail,
        parentPhone: parentPhone,
      );

      print('✅ Complete welcome sequence sent successfully');
    } catch (e) {
      print('❌ Error sending welcome notification: $e');
    }
  }

  /// إشعار ترحيبي سريع
  static Future<void> sendQuickWelcome({
    required String parentId,
    required String parentName,
  }) async {
    try {
      print('🎉 Sending quick welcome to: $parentName');

      // الطريقة الثانية: إشعار سريع
      await WelcomeNotificationService().sendQuickWelcome(
        parentId: parentId,
        parentName: parentName,
      );

      print('✅ Quick welcome sent successfully');
    } catch (e) {
      print('❌ Error sending quick welcome: $e');
    }
  }

  /// استخدام الخدمة الرئيسية
  static Future<void> sendWelcomeUsingMainService({
    required String parentId,
    required String parentName,
    required String parentEmail,
    String? parentPhone,
  }) async {
    try {
      print('🎉 Using main notification service for: $parentName');

      // الطريقة الثالثة: استخدام الخدمة الرئيسية
      await NotificationService().sendWelcomeNotificationToNewParent(
        parentId: parentId,
        parentName: parentName,
        parentEmail: parentEmail,
        parentPhone: parentPhone,
      );

      print('✅ Welcome sent via main service successfully');
    } catch (e) {
      print('❌ Error using main service: $e');
    }
  }
}

/// مثال على التكامل مع صفحة التسجيل
class ParentRegistrationPage extends StatefulWidget {
  @override
  _ParentRegistrationPageState createState() => _ParentRegistrationPageState();
}

class _ParentRegistrationPageState extends State<ParentRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تسجيل ولي أمر جديد'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'الاسم الكامل',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال الاسم';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال البريد الإلكتروني';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'رقم الهاتف (اختياري)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _registerParent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'تسجيل الحساب',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _registerParent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // محاكاة إنشاء الحساب
      final parentId = 'parent_${DateTime.now().millisecondsSinceEpoch}';
      
      print('📝 Creating parent account...');
      
      // هنا يتم إنشاء الحساب الفعلي في Firebase
      // await FirebaseAuth.instance.createUserWithEmailAndPassword(...)
      
      // إرسال الإشعار الترحيبي
      await QuickWelcomeExample.sendWelcomeToNewParent(
        parentId: parentId,
        parentName: _nameController.text,
        parentEmail: _emailController.text,
        parentPhone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      );

      // إظهار رسالة نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تسجيل الحساب بنجاح! تم إرسال إشعار ترحيبي.'),
          backgroundColor: Colors.green,
        ),
      );

      // الانتقال للصفحة التالية
      Navigator.pushReplacementNamed(context, '/parent_dashboard');

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تسجيل الحساب: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

/// مثال على استخدام الإشعارات في أماكن مختلفة
class WelcomeNotificationExamples {
  
  /// في صفحة تسجيل الدخول الأولى
  static Future<void> onFirstLogin(String parentId, String parentName) async {
    await QuickWelcomeExample.sendQuickWelcome(
      parentId: parentId,
      parentName: parentName,
    );
  }

  /// عند إكمال الملف الشخصي
  static Future<void> onProfileComplete({
    required String parentId,
    required String parentName,
    required String parentEmail,
    String? parentPhone,
  }) async {
    await QuickWelcomeExample.sendWelcomeToNewParent(
      parentId: parentId,
      parentName: parentName,
      parentEmail: parentEmail,
      parentPhone: parentPhone,
    );
  }

  /// عند تفعيل الحساب
  static Future<void> onAccountActivation(String parentId, String parentName) async {
    await WelcomeNotificationService().sendNotificationToUser(
      userId: parentId,
      title: '✅ تم تفعيل حسابك',
      body: 'مرحباً $parentName! تم تفعيل حسابك بنجاح. يمكنك الآن الاستفادة من جميع ميزات التطبيق.',
      type: 'activation',
      data: {
        'type': 'account_activated',
        'parentId': parentId,
        'parentName': parentName,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// إشعار تذكيري للمستخدمين الجدد
  static Future<void> sendReminderToNewUsers() async {
    // يمكن استخدامها في مهمة مجدولة
    print('🔔 Sending reminder notifications to new users...');
    
    // هنا يمكن جلب المستخدمين الجدد من قاعدة البيانات
    // وإرسال تذكيرات لهم
  }
}

/// دالة مساعدة للاستخدام السريع
Future<void> sendWelcomeNotification({
  required String parentId,
  required String parentName,
  required String parentEmail,
  String? parentPhone,
}) async {
  await QuickWelcomeExample.sendWelcomeToNewParent(
    parentId: parentId,
    parentName: parentName,
    parentEmail: parentEmail,
    parentPhone: parentPhone,
  );
}
