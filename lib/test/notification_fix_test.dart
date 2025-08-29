import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/enhanced_notification_service.dart';

/// شاشة اختبار إصلاح مشكلة الإشعارات للإدمن
/// هذه الشاشة لاختبار أن الإشعارات تذهب فقط للمستخدمين المناسبين
class NotificationFixTestScreen extends StatefulWidget {
  const NotificationFixTestScreen({super.key});

  @override
  State<NotificationFixTestScreen> createState() => _NotificationFixTestScreenState();
}

class _NotificationFixTestScreenState extends State<NotificationFixTestScreen> {
  final EnhancedNotificationService _notificationService = EnhancedNotificationService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار إصلاح الإشعارات'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'اختبار إصلاح مشكلة الإشعارات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'هذا الاختبار يتحقق من أن الإشعارات تذهب للمستخدمين المناسبين فقط:\n'
                      '• ولي الأمر: يحصل على إشعار (إذا لم يكن هو الإدمن)\n'
                      '• المشرف: يحصل على إشعار (إذا لم يكن هو الإدمن)\n'
                      '• الإدارة الأخرى: تحصل على إشعار (باستثناء الإدمن الحالي)\n'
                      '• الإدمن الحالي: لا يحصل على إشعار أبداً\n'
                      '• فحص إضافي: منع الإشعارات للإدمن حتى لو كان ولي أمر',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testStudentDataUpdateNotification,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.notification_important),
              label: Text(_isLoading ? 'جاري الاختبار...' : 'اختبار تحديث بيانات الطالب'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testAdminAsParentCase,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.warning),
              label: Text(_isLoading ? 'جاري الاختبار...' : 'اختبار حالة الإدمن كولي أمر'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'ملاحظات مهمة',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• تأكد من وجود طلاب في قاعدة البيانات\n'
                      '• تأكد من وجود مشرفين وإدارة أخرى\n'
                      '• راقب سجلات التشخيص (Debug Console)\n'
                      '• تحقق من قاعدة البيانات للإشعارات المحفوظة',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// اختبار إشعار تحديث بيانات الطالب
  Future<void> _testStudentDataUpdateNotification() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showMessage('يجب تسجيل الدخول أولاً', isError: true);
        return;
      }

      // بيانات اختبار وهمية
      final testStudentId = 'test_student_123';
      final testStudentName = 'أحمد محمد (اختبار)';
      final testParentId = 'test_parent_123';
      final testBusId = 'test_bus_123';
      final testAdminName = 'إدمن الاختبار';

      // تحديثات وهمية
      final updatedFields = {
        'name': {
          'old': 'أحمد محمد',
          'new': 'أحمد محمد المحدث',
        },
        'grade': {
          'old': 'الصف الأول',
          'new': 'الصف الثاني',
        },
        'parentPhone': {
          'old': '0501234567',
          'new': '0507654321',
        },
      };

      debugPrint('🧪 Starting notification fix test...');
      debugPrint('🧪 Current admin ID: ${currentUser.uid}');
      debugPrint('🧪 Test data: Student=$testStudentName, Parent=$testParentId, Bus=$testBusId');

      // إرسال الإشعار باستخدام الدالة المحدثة
      await _notificationService.notifyStudentDataUpdate(
        studentId: testStudentId,
        studentName: testStudentName,
        parentId: testParentId,
        busId: testBusId,
        updatedFields: updatedFields,
        adminName: testAdminName,
        adminId: currentUser.uid, // استبعاد الإدمن الحالي
      );

      _showMessage('تم إرسال إشعار الاختبار بنجاح!\nتحقق من سجلات التشخيص وقاعدة البيانات');

    } catch (e) {
      debugPrint('❌ Error in notification test: $e');
      _showMessage('خطأ في اختبار الإشعار: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// اختبار حالة الإدمن الذي هو ولي أمر (يجب ألا يحصل على إشعار)
  Future<void> _testAdminAsParentCase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showMessage('يجب تسجيل الدخول أولاً', isError: true);
        return;
      }

      // بيانات اختبار حيث الإدمن هو ولي الأمر
      final testStudentId = 'test_student_admin_parent';
      final testStudentName = 'طالب الإدمن (اختبار)';
      final testParentId = currentUser.uid; // الإدمن الحالي هو ولي الأمر
      final testBusId = 'test_bus_456';
      final testAdminName = 'إدمن الاختبار';

      // تحديثات وهمية
      final updatedFields = {
        'address': {
          'old': 'العنوان القديم',
          'new': 'العنوان الجديد',
        },
        'notes': {
          'old': 'ملاحظات قديمة',
          'new': 'ملاحظات جديدة',
        },
      };

      debugPrint('🧪 Starting admin-as-parent test...');
      debugPrint('🧪 Current admin ID: ${currentUser.uid}');
      debugPrint('🧪 Parent ID (same as admin): $testParentId');
      debugPrint('🧪 This should NOT send notification to admin');

      // إرسال الإشعار - يجب ألا يحصل الإدمن على إشعار
      await _notificationService.notifyStudentDataUpdate(
        studentId: testStudentId,
        studentName: testStudentName,
        parentId: testParentId, // نفس معرف الإدمن
        busId: testBusId,
        updatedFields: updatedFields,
        adminName: testAdminName,
        adminId: currentUser.uid,
      );

      _showMessage('تم اختبار حالة الإدمن كولي أمر!\nيجب ألا تحصل على إشعار محلي\nتحقق من سجلات التشخيص');

    } catch (e) {
      debugPrint('❌ Error in admin-as-parent test: $e');
      _showMessage('خطأ في اختبار الإدمن كولي أمر: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
