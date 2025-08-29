import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'lib/services/enhanced_notification_service.dart';
import 'lib/services/global_notification_monitor.dart';

/// اختبار النظام العالمي للإشعارات
class GlobalNotificationTest {
  final EnhancedNotificationService _enhancedService = EnhancedNotificationService();
  final GlobalNotificationMonitor _globalMonitor = GlobalNotificationMonitor();

  /// اختبار شامل للنظام العالمي
  Future<void> runGlobalNotificationTests() async {
    print('🌍 بدء اختبار النظام العالمي للإشعارات...\n');

    await _testGlobalDelivery();
    await Future.delayed(Duration(seconds: 2));
    
    await _testQueueMonitoring();
    await Future.delayed(Duration(seconds: 2));
    
    await _testRetryMechanism();
    await Future.delayed(Duration(seconds: 2));
    
    await _testQueueStats();

    print('\n✅ انتهت جميع اختبارات النظام العالمي!');
  }

  /// اختبار التسليم العالمي
  Future<void> _testGlobalDelivery() async {
    try {
      print('🌍 اختبار التسليم العالمي...');

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ لا يوجد مستخدم مسجل دخول');
        return;
      }

      // إرسال إشعار للمستخدم الحالي
      await _enhancedService.sendNotificationToUser(
        userId: currentUser.uid,
        title: 'اختبار التسليم العالمي',
        body: 'هذا إشعار يجب أن يصل من أي مكان في العالم',
        type: 'global_test',
        data: {
          'test_type': 'global_delivery',
          'timestamp': DateTime.now().toIso8601String(),
          'location': 'worldwide',
        },
      );

      print('✅ تم إرسال إشعار للتسليم العالمي');
      print('📱 الإشعار سيصل حتى لو كنت في أي مكان في العالم');

    } catch (e) {
      print('❌ خطأ في اختبار التسليم العالمي: $e');
    }
  }

  /// اختبار مراقبة الطابور
  Future<void> _testQueueMonitoring() async {
    try {
      print('\n📊 اختبار مراقبة الطابور العالمي...');

      // بدء المراقبة إذا لم تكن بدأت
      if (!_globalMonitor.isMonitoring) {
        await _globalMonitor.startMonitoring();
        print('✅ تم بدء مراقبة الطابور العالمي');
      } else {
        print('ℹ️ مراقبة الطابور تعمل بالفعل');
      }

      // إضافة إشعار للطابور مباشرة
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await _globalMonitor.queueGlobalNotification(
          targetToken: 'test_token_${DateTime.now().millisecondsSinceEpoch}',
          title: 'اختبار الطابور العالمي',
          body: 'إشعار تجريبي للطابور العالمي',
          userId: currentUser.uid,
          data: {
            'test_type': 'queue_monitoring',
            'queue_test': 'true',
          },
        );

        print('✅ تم إضافة إشعار للطابور العالمي');
        print('🔄 المراقب سيعالج الإشعار تلقائياً');
      }

    } catch (e) {
      print('❌ خطأ في اختبار مراقبة الطابور: $e');
    }
  }

  /// اختبار آلية إعادة المحاولة
  Future<void> _testRetryMechanism() async {
    try {
      print('\n🔄 اختبار آلية إعادة المحاولة...');

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // إضافة إشعار بـ token خاطئ لاختبار إعادة المحاولة
        await _globalMonitor.queueGlobalNotification(
          targetToken: 'invalid_token_for_retry_test',
          title: 'اختبار إعادة المحاولة',
          body: 'هذا الإشعار سيفشل ويعيد المحاولة',
          userId: currentUser.uid,
          data: {
            'test_type': 'retry_mechanism',
            'expected_to_fail': 'true',
          },
        );

        print('✅ تم إضافة إشعار لاختبار إعادة المحاولة');
        print('🔄 النظام سيعيد المحاولة حتى 3 مرات');
        print('⏱️ انتظر قليلاً لرؤية إعادة المحاولات...');
      }

    } catch (e) {
      print('❌ خطأ في اختبار إعادة المحاولة: $e');
    }
  }

  /// اختبار إحصائيات الطابور
  Future<void> _testQueueStats() async {
    try {
      print('\n📈 اختبار إحصائيات الطابور...');

      // انتظار قليل للسماح للمعالجة
      await Future.delayed(Duration(seconds: 3));

      final stats = await _globalMonitor.getQueueStats();
      
      print('📊 إحصائيات الطابور العالمي:');
      print('   📋 معلق: ${stats['pending']} إشعار');
      print('   ✅ مكتمل: ${stats['completed']} إشعار');
      print('   ❌ فاشل: ${stats['failed']} إشعار');

      if (stats['pending']! > 0) {
        print('🔄 يوجد ${stats['pending']} إشعار معلق في الطابور');
        print('⏱️ سيتم معالجتها تلقائياً');
      }

      if (stats['failed']! > 0) {
        print('⚠️ يوجد ${stats['failed']} إشعار فاشل');
        print('🔄 تم استنفاد محاولات إعادة الإرسال');
      }

    } catch (e) {
      print('❌ خطأ في اختبار الإحصائيات: $e');
    }
  }

  /// اختبار تنظيف الطابور
  Future<void> testQueueCleanup() async {
    try {
      print('\n🧹 اختبار تنظيف الطابور...');

      await _globalMonitor.cleanupOldQueueItems();
      print('✅ تم تنظيف العناصر القديمة من الطابور');

    } catch (e) {
      print('❌ خطأ في تنظيف الطابور: $e');
    }
  }

  /// محاكاة سيناريو المشرف وولي الأمر عالمياً
  Future<void> testSupervisorParentGlobalScenario() async {
    try {
      print('\n🌍 اختبار سيناريو المشرف وولي الأمر عالمياً...');

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ لا يوجد مستخدم مسجل دخول');
        return;
      }

      // محاكاة: مشرف في السعودية يسجل ركوب طالب
      print('🚌 محاكاة: مشرف في الرياض يسجل ركوب طالب...');
      
      await _enhancedService.notifyStudentBoardedWithSound(
        studentId: 'student_global_test',
        studentName: 'سارة أحمد',
        busId: 'bus_riyadh_01',
        parentId: 'parent_in_london', // ولي أمر في لندن
        supervisorId: currentUser.uid,
      );

      print('✅ تم إرسال إشعار عالمي لولي الأمر');
      print('🌍 ولي الأمر في لندن سيحصل على الإشعار فوراً');
      print('📱 الإشعار سيصل حتى لو كان في منطقة زمنية مختلفة');

      // محاكاة: ولي أمر في أمريكا يطلب غياب
      print('\n📝 محاكاة: ولي أمر في نيويورك يطلب غياب...');
      
      await _enhancedService.notifyAbsenceRequestWithSound(
        studentId: 'student_global_test',
        studentName: 'سارة أحمد',
        parentId: currentUser.uid,
        parentName: 'أحمد محمد',
        supervisorId: 'supervisor_in_riyadh', // مشرف في الرياض
        busId: 'bus_riyadh_01',
        absenceDate: DateTime.now().add(Duration(days: 1)),
        reason: 'موعد طبي',
      );

      print('✅ تم إرسال طلب غياب عالمي للمشرف');
      print('🌍 المشرف في الرياض سيحصل على الطلب فوراً');
      print('⏰ بغض النظر عن فارق التوقيت');

    } catch (e) {
      print('❌ خطأ في السيناريو العالمي: $e');
    }
  }
}

/// شاشة اختبار النظام العالمي
class GlobalNotificationTestScreen extends StatefulWidget {
  @override
  _GlobalNotificationTestScreenState createState() => _GlobalNotificationTestScreenState();
}

class _GlobalNotificationTestScreenState extends State<GlobalNotificationTestScreen> {
  final GlobalNotificationTest _tester = GlobalNotificationTest();
  bool _isRunning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('اختبار النظام العالمي للإشعارات'),
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
                    Icon(Icons.public, size: 48, color: Colors.blue),
                    SizedBox(height: 8),
                    Text(
                      'النظام العالمي للإشعارات',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'يضمن وصول الإشعارات من أي مكان في العالم',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            _buildTestButton(
              'اختبار التسليم العالمي',
              Icons.send,
              () => _tester._testGlobalDelivery(),
            ),
            _buildTestButton(
              'اختبار مراقبة الطابور',
              Icons.monitor,
              () => _tester._testQueueMonitoring(),
            ),
            _buildTestButton(
              'اختبار إعادة المحاولة',
              Icons.refresh,
              () => _tester._testRetryMechanism(),
            ),
            _buildTestButton(
              'عرض الإحصائيات',
              Icons.analytics,
              () => _tester._testQueueStats(),
            ),
            _buildTestButton(
              'السيناريو العالمي',
              Icons.language,
              () => _tester.testSupervisorParentGlobalScenario(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isRunning ? null : _runAllTests,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isRunning
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'تشغيل جميع الاختبارات',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(String title, IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton.icon(
        onPressed: _isRunning ? null : onPressed,
        icon: Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Future<void> _runAllTests() async {
    setState(() => _isRunning = true);
    try {
      await _tester.runGlobalNotificationTests();
    } finally {
      setState(() => _isRunning = false);
    }
  }
}
