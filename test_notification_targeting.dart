import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'lib/services/notification_service.dart';
import 'lib/services/enhanced_notification_service.dart';

/// ملف اختبار لتجربة استهداف الإشعارات
/// يمكن استخدامه للتأكد من أن الإشعارات تظهر للمستخدم المستهدف فقط

class NotificationTargetingTest {
  final NotificationService _notificationService = NotificationService();
  final EnhancedNotificationService _enhancedService = EnhancedNotificationService();

  /// اختبار إرسال إشعار لمستخدم محدد
  Future<void> testTargetedNotification() async {
    try {
      print('🧪 بدء اختبار استهداف الإشعارات...');

      // الحصول على المستخدم الحالي
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ لا يوجد مستخدم مسجل دخول');
        return;
      }

      print('👤 المستخدم الحالي: ${currentUser.uid}');

      // اختبار 1: إرسال إشعار للمستخدم الحالي (يجب أن يظهر)
      print('\n📱 اختبار 1: إرسال إشعار للمستخدم الحالي...');
      await _enhancedService.sendNotificationToUser(
        userId: currentUser.uid,
        title: 'اختبار إشعار للمستخدم الحالي',
        body: 'هذا الإشعار يجب أن يظهر لك',
        type: 'test',
        data: {
          'test_type': 'current_user',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      print('✅ تم إرسال إشعار للمستخدم الحالي');

      // انتظار قليل
      await Future.delayed(Duration(seconds: 2));

      // اختبار 2: إرسال إشعار لمستخدم آخر (يجب ألا يظهر)
      print('\n🚫 اختبار 2: إرسال إشعار لمستخدم آخر...');
      await _enhancedService.sendNotificationToUser(
        userId: 'fake_user_id_12345',
        title: 'اختبار إشعار لمستخدم آخر',
        body: 'هذا الإشعار يجب ألا يظهر لك',
        type: 'test',
        data: {
          'test_type': 'other_user',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      print('✅ تم إرسال إشعار لمستخدم آخر (يجب ألا يظهر)');

      // انتظار قليل
      await Future.delayed(Duration(seconds: 2));

      // اختبار 3: إرسال إشعار عام (يجب أن يظهر)
      print('\n📢 اختبار 3: إرسال إشعار عام...');
      await _notificationService.sendGeneralNotification(
        title: 'إشعار عام للاختبار',
        body: 'هذا إشعار عام يجب أن يظهر',
        recipientId: currentUser.uid,
        data: {
          'test_type': 'general',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      print('✅ تم إرسال إشعار عام');

      print('\n🎉 انتهى الاختبار! تحقق من الإشعارات في التطبيق');

    } catch (e) {
      print('❌ خطأ في الاختبار: $e');
    }
  }

  /// اختبار محاكاة سيناريو الإدمن وولي الأمر
  Future<void> testAdminParentScenario() async {
    try {
      print('🧪 بدء اختبار سيناريو الإدمن وولي الأمر...');

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ لا يوجد مستخدم مسجل دخول');
        return;
      }

      // محاكاة: الإدمن يعدل بيانات طالب
      print('\n👨‍💼 محاكاة: الإدمن يعدل بيانات طالب...');
      
      // إشعار لولي الأمر (مستخدم آخر)
      await _enhancedService.notifyStudentAssignmentWithSound(
        studentId: 'student_123',
        studentName: 'أحمد محمد',
        busId: 'bus_456',
        busRoute: 'الخط الأول',
        parentId: 'parent_789', // مستخدم آخر (ولي الأمر)
        supervisorId: 'supervisor_101',
        parentName: 'محمد أحمد',
        parentPhone: '0501234567',
        excludeAdminId: currentUser.uid, // استبعاد الإدمن الحالي
      );

      print('✅ تم إرسال إشعار لولي الأمر (يجب ألا يظهر للإدمن الحالي)');
      print('📱 ولي الأمر سيرى الإشعار عندما يفتح التطبيق');

      print('\n🎯 النتيجة المتوقعة:');
      print('- الإدمن الحالي: لا يرى إشعار');
      print('- ولي الأمر: سيرى إشعار عند فتح التطبيق');

    } catch (e) {
      print('❌ خطأ في اختبار السيناريو: $e');
    }
  }

  /// تشغيل جميع الاختبارات
  Future<void> runAllTests() async {
    print('🚀 بدء تشغيل جميع اختبارات استهداف الإشعارات...\n');

    await testTargetedNotification();
    
    await Future.delayed(Duration(seconds: 3));
    
    await testAdminParentScenario();

    print('\n✅ انتهت جميع الاختبارات!');
    print('📋 تحقق من النتائج في التطبيق والـ console logs');
  }
}

/// دالة مساعدة لتشغيل الاختبارات
Future<void> runNotificationTargetingTests() async {
  final tester = NotificationTargetingTest();
  await tester.runAllTests();
}

/// مثال على كيفية الاستخدام في التطبيق
class NotificationTestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('اختبار استهداف الإشعارات'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                final tester = NotificationTargetingTest();
                await tester.testTargetedNotification();
              },
              child: Text('اختبار الإشعارات المستهدفة'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final tester = NotificationTargetingTest();
                await tester.testAdminParentScenario();
              },
              child: Text('اختبار سيناريو الإدمن وولي الأمر'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final tester = NotificationTargetingTest();
                await tester.runAllTests();
              },
              child: Text('تشغيل جميع الاختبارات'),
            ),
          ],
        ),
      ),
    );
  }
}
