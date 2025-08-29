import 'package:flutter/material.dart';
import '../services/welcome_notification_service.dart';
import '../services/notification_service.dart';
import '../services/enhanced_notification_service.dart';

/// مثال على كيفية استخدام الإشعارات الترحيبية
/// يمكن دمج هذا الكود في صفحة التسجيل أو إنشاء الحساب

class WelcomeNotificationUsageExample {
  final WelcomeNotificationService _welcomeService = WelcomeNotificationService();
  final NotificationService _notificationService = NotificationService();
  final EnhancedNotificationService _enhancedService = EnhancedNotificationService();

  /// استخدام في صفحة التسجيل - إشعار ترحيبي شامل
  Future<void> onParentRegistrationComplete({
    required String parentId,
    required String parentName,
    required String parentEmail,
    String? parentPhone,
  }) async {
    try {
      print('🎉 Parent registration completed for: $parentName');

      // إرسال تسلسل الإشعارات الترحيبية الشامل
      await _welcomeService.sendCompleteWelcomeSequence(
        parentId: parentId,
        parentName: parentName,
        parentEmail: parentEmail,
        parentPhone: parentPhone,
      );

      print('✅ Welcome sequence initiated successfully');
    } catch (e) {
      print('❌ Error sending welcome notifications: $e');
    }
  }

  /// استخدام سريع - إشعار ترحيبي بسيط
  Future<void> onQuickParentRegistration({
    required String parentId,
    required String parentName,
  }) async {
    try {
      print('🎉 Quick parent registration for: $parentName');

      // إرسال إشعار ترحيبي سريع
      await _welcomeService.sendQuickWelcome(
        parentId: parentId,
        parentName: parentName,
      );

      print('✅ Quick welcome sent successfully');
    } catch (e) {
      print('❌ Error sending quick welcome: $e');
    }
  }

  /// استخدام الخدمة الرئيسية
  Future<void> onParentRegistrationUsingMainService({
    required String parentId,
    required String parentName,
    required String parentEmail,
    String? parentPhone,
  }) async {
    try {
      print('🎉 Using main notification service for: $parentName');

      // استخدام الخدمة الرئيسية
      await _notificationService.sendWelcomeNotificationToNewParent(
        parentId: parentId,
        parentName: parentName,
        parentEmail: parentEmail,
        parentPhone: parentPhone,
      );

      print('✅ Welcome notification sent via main service');
    } catch (e) {
      print('❌ Error using main service: $e');
    }
  }

  /// استخدام الخدمة المحسنة مباشرة
  Future<void> onParentRegistrationUsingEnhancedService({
    required String parentId,
    required String parentName,
    required String parentEmail,
    String? parentPhone,
  }) async {
    try {
      print('🎉 Using enhanced service for: $parentName');

      // استخدام الخدمة المحسنة مباشرة
      await _enhancedService.sendWelcomeNotificationToNewParent(
        parentId: parentId,
        parentName: parentName,
        parentEmail: parentEmail,
        parentPhone: parentPhone,
      );

      print('✅ Welcome notification sent via enhanced service');
    } catch (e) {
      print('❌ Error using enhanced service: $e');
    }
  }
}

/// شاشة مثال لاختبار الإشعارات الترحيبية
class WelcomeNotificationTestScreen extends StatefulWidget {
  @override
  _WelcomeNotificationTestScreenState createState() => _WelcomeNotificationTestScreenState();
}

class _WelcomeNotificationTestScreenState extends State<WelcomeNotificationTestScreen> {
  final WelcomeNotificationUsageExample _example = WelcomeNotificationUsageExample();
  final WelcomeNotificationService _welcomeService = WelcomeNotificationService();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('اختبار الإشعارات الترحيبية'),
        backgroundColor: Colors.green,
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
                    Icon(Icons.celebration, size: 48, color: Colors.green),
                    SizedBox(height: 8),
                    Text(
                      'إشعارات ترحيبية لأولياء الأمور الجدد',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'اختبر أنواع مختلفة من الإشعارات الترحيبية',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            
            // حقول الإدخال
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'اسم ولي الأمر',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'البريد الإلكتروني',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'رقم الهاتف (اختياري)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            SizedBox(height: 20),

            // أزرار الاختبار
            _buildTestButton(
              'إشعار ترحيبي شامل',
              Icons.auto_awesome,
              Colors.green,
              () => _testCompleteWelcome(),
            ),
            _buildTestButton(
              'إشعار ترحيبي سريع',
              Icons.flash_on,
              Colors.blue,
              () => _testQuickWelcome(),
            ),
            _buildTestButton(
              'الخدمة الرئيسية',
              Icons.notifications,
              Colors.orange,
              () => _testMainService(),
            ),
            _buildTestButton(
              'الخدمة المحسنة',
              Icons.star,
              Colors.purple,
              () => _testEnhancedService(),
            ),
            
            SizedBox(height: 20),
            
            // إحصائيات
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _showWelcomeStats,
              icon: Icon(Icons.analytics),
              label: Text('عرض الإحصائيات'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
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
        onPressed: _isLoading ? null : onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(title, style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Future<void> _testCompleteWelcome() async {
    if (!_validateInput()) return;
    
    setState(() => _isLoading = true);
    try {
      await _example.onParentRegistrationComplete(
        parentId: 'test_parent_${DateTime.now().millisecondsSinceEpoch}',
        parentName: _nameController.text,
        parentEmail: _emailController.text,
        parentPhone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      );
      _showSuccessMessage('تم إرسال الإشعار الترحيبي الشامل بنجاح!');
    } catch (e) {
      _showErrorMessage('خطأ في إرسال الإشعار: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testQuickWelcome() async {
    if (_nameController.text.isEmpty) {
      _showErrorMessage('يرجى إدخال اسم ولي الأمر');
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      await _example.onQuickParentRegistration(
        parentId: 'test_parent_${DateTime.now().millisecondsSinceEpoch}',
        parentName: _nameController.text,
      );
      _showSuccessMessage('تم إرسال الإشعار الترحيبي السريع بنجاح!');
    } catch (e) {
      _showErrorMessage('خطأ في إرسال الإشعار: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testMainService() async {
    if (!_validateInput()) return;
    
    setState(() => _isLoading = true);
    try {
      await _example.onParentRegistrationUsingMainService(
        parentId: 'test_parent_${DateTime.now().millisecondsSinceEpoch}',
        parentName: _nameController.text,
        parentEmail: _emailController.text,
        parentPhone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      );
      _showSuccessMessage('تم إرسال الإشعار عبر الخدمة الرئيسية بنجاح!');
    } catch (e) {
      _showErrorMessage('خطأ في إرسال الإشعار: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testEnhancedService() async {
    if (!_validateInput()) return;
    
    setState(() => _isLoading = true);
    try {
      await _example.onParentRegistrationUsingEnhancedService(
        parentId: 'test_parent_${DateTime.now().millisecondsSinceEpoch}',
        parentName: _nameController.text,
        parentEmail: _emailController.text,
        parentPhone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      );
      _showSuccessMessage('تم إرسال الإشعار عبر الخدمة المحسنة بنجاح!');
    } catch (e) {
      _showErrorMessage('خطأ في إرسال الإشعار: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showWelcomeStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _welcomeService.getWelcomeStats();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('إحصائيات الإشعارات الترحيبية'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('إجمالي الإشعارات الترحيبية: ${stats['total_welcomes']}'),
              Text('التسلسلات المكتملة: ${stats['completed_sequences']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('موافق'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorMessage('خطأ في جلب الإحصائيات: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _validateInput() {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      _showErrorMessage('يرجى إدخال الاسم والبريد الإلكتروني');
      return false;
    }
    return true;
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
