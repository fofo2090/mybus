import 'package:flutter/material.dart';
import '../../services/fcm_service.dart';
import '../../services/notification_sender_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/admin_bottom_navigation.dart';

/// صفحة اختبار الإشعارات
class TestNotificationsScreen extends StatefulWidget {
  const TestNotificationsScreen({super.key});

  @override
  State<TestNotificationsScreen> createState() => _TestNotificationsScreenState();
}

class _TestNotificationsScreenState extends State<TestNotificationsScreen> {
  final FCMService _fcmService = FCMService();
  final NotificationSenderService _notificationSender = NotificationSenderService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('اختبار الإشعارات'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بطاقة معلومات
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.science, color: Colors.purple[600]),
                        const SizedBox(width: 8),
                        Text(
                          'اختبار نظام الإشعارات',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'اختبر الإشعارات المحلية التي تظهر خارج التطبيق. هذه الإشعارات ستظهر في شريط الإشعارات حتى لو كان التطبيق مغلق.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // أزرار الاختبار
            _buildTestButton(
              title: 'اختبار إشعار بسيط',
              description: 'إشعار عادي مع عنوان ونص',
              icon: Icons.notifications,
              color: Colors.blue,
              onPressed: _testSimpleNotification,
            ),
            
            const SizedBox(height: 12),
            
            _buildTestButton(
              title: 'اختبار إشعار شكوى',
              description: 'محاكاة وصول شكوى جديدة للأدمن',
              icon: Icons.report_problem,
              color: Colors.orange,
              onPressed: _testComplaintNotification,
            ),
            
            const SizedBox(height: 12),
            
            _buildTestButton(
              title: 'اختبار إشعار حالة طالب',
              description: 'محاكاة تحديث حالة طالب لولي الأمر',
              icon: Icons.school,
              color: Colors.green,
              onPressed: _testStudentStatusNotification,
            ),
            
            const SizedBox(height: 12),
            
            _buildTestButton(
              title: 'اختبار إشعار طوارئ',
              description: 'إشعار طوارئ عالي الأولوية',
              icon: Icons.warning,
              color: Colors.red,
              onPressed: _testEmergencyNotification,
            ),
            
            const SizedBox(height: 12),
            
            _buildTestButton(
              title: 'اختبار إشعار مع صوت',
              description: 'إشعار مع صوت واهتزاز',
              icon: Icons.volume_up,
              color: Colors.purple,
              onPressed: _testSoundNotification,
            ),
            
            const SizedBox(height: 20),
            
            // معلومات إضافية
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        Text(
                          'ملاحظات مهمة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• الإشعارات ستظهر في شريط الإشعارات\n'
                      '• يمكن النقر عليها لفتح التطبيق\n'
                      '• تعمل حتى لو كان التطبيق مغلق\n'
                      '• للحصول على إشعارات FCM حقيقية، أضف Server Key',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AdminBottomNavigation(currentIndex: 0),
    );
  }

  /// بناء زر اختبار
  Widget _buildTestButton({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: _isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// اختبار إشعار بسيط
  Future<void> _testSimpleNotification() async {
    setState(() => _isLoading = true);
    
    try {
      await _fcmService.sendNotificationToUserType(
        userType: 'admin',
        title: 'اختبار إشعار بسيط',
        body: 'هذا إشعار تجريبي يجب أن يظهر في شريط الإشعارات',
        data: {
          'type': 'test',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      _showSuccessMessage('تم إرسال الإشعار البسيط');
    } catch (e) {
      _showErrorMessage('خطأ في إرسال الإشعار: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// اختبار إشعار شكوى
  Future<void> _testComplaintNotification() async {
    setState(() => _isLoading = true);
    
    try {
      await _notificationSender.sendComplaintNotificationToAdmin(
        complaintId: 'test_complaint_${DateTime.now().millisecondsSinceEpoch}',
        studentName: 'أحمد محمد (اختبار)',
        complaintType: 'شكوى تجريبية',
      );
      
      _showSuccessMessage('تم إرسال إشعار الشكوى');
    } catch (e) {
      _showErrorMessage('خطأ في إرسال إشعار الشكوى: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// اختبار إشعار حالة طالب
  Future<void> _testStudentStatusNotification() async {
    setState(() => _isLoading = true);
    
    try {
      await _notificationSender.sendStudentStatusNotificationToParent(
        parentId: 'test_parent',
        studentName: 'سارة أحمد (اختبار)',
        status: 'onBus',
        busNumber: '123',
        location: 'المدرسة الابتدائية',
      );
      
      _showSuccessMessage('تم إرسال إشعار حالة الطالب');
    } catch (e) {
      _showErrorMessage('خطأ في إرسال إشعار حالة الطالب: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// اختبار إشعار طوارئ
  Future<void> _testEmergencyNotification() async {
    setState(() => _isLoading = true);
    
    try {
      await _notificationSender.sendEmergencyNotification(
        title: '🚨 تنبيه طوارئ - اختبار',
        message: 'هذا إشعار طوارئ تجريبي عالي الأولوية',
        busNumber: '456',
        location: 'شارع الملك فهد',
      );
      
      _showSuccessMessage('تم إرسال إشعار الطوارئ');
    } catch (e) {
      _showErrorMessage('خطأ في إرسال إشعار الطوارئ: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// اختبار إشعار مع صوت
  Future<void> _testSoundNotification() async {
    setState(() => _isLoading = true);
    
    try {
      await _fcmService.sendNotificationToUserType(
        userType: 'admin',
        title: '🔔 إشعار مع صوت',
        body: 'هذا إشعار مع صوت واهتزاز - يجب أن تسمع صوت الإشعار',
        data: {
          'type': 'sound_test',
          'priority': 'high',
        },
        channelId: 'emergency_notifications',
      );
      
      _showSuccessMessage('تم إرسال الإشعار مع الصوت');
    } catch (e) {
      _showErrorMessage('خطأ في إرسال الإشعار: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// عرض رسالة نجاح
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// عرض رسالة خطأ
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
