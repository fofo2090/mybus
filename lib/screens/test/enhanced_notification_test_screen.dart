import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/enhanced_notification_service.dart';
import '../../utils/notification_images.dart';

/// شاشة اختبار الإشعارات المحسنة مع الصور
class EnhancedNotificationTestScreen extends StatefulWidget {
  const EnhancedNotificationTestScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedNotificationTestScreen> createState() => _EnhancedNotificationTestScreenState();
}

class _EnhancedNotificationTestScreenState extends State<EnhancedNotificationTestScreen> {
  final EnhancedNotificationService _notificationService = EnhancedNotificationService();
  bool _isLoading = false;
  String _lastResult = '';

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _notificationService.initialize();
  }

  Future<void> _sendTestNotification(String type, String title, String body) async {
    setState(() {
      _isLoading = true;
      _lastResult = 'جاري إرسال الإشعار...';
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _lastResult = '❌ يجب تسجيل الدخول أولاً';
          _isLoading = false;
        });
        return;
      }

      await _notificationService.sendNotificationToUser(
        userId: currentUser.uid,
        title: title,
        body: body,
        type: type,
        data: {
          'test': 'true',
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      setState(() {
        _lastResult = '✅ تم إرسال إشعار $type بنجاح!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _lastResult = '❌ خطأ في إرسال الإشعار: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildTestButton({
    required String type,
    required String title,
    required String body,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : () => _sendTestNotification(type, title, body),
        icon: Icon(icon, size: 24),
        label: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${NotificationImages.getNotificationEmoji(type)} $title',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              body,
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
          minimumSize: const Size(double.infinity, 80),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار الإشعارات المحسنة'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // معلومات الاختبار
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🧪 اختبار الإشعارات المحسنة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'هذه الشاشة تختبر الإشعارات المحسنة مع:\n'
                      '• صور مميزة لكل نوع إشعار\n'
                      '• أيقونات مخصصة\n'
                      '• ألوان مختلفة\n'
                      '• عناوين محسنة مع رموز تعبيرية\n'
                      '• دعم الخلفية والمقدمة',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    if (_lastResult.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _lastResult.startsWith('✅') 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _lastResult.startsWith('✅') 
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        child: Text(
                          _lastResult,
                          style: TextStyle(
                            color: _lastResult.startsWith('✅') 
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // أزرار الاختبار
            const Text(
              'اختبر أنواع الإشعارات المختلفة:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildTestButton(
              type: 'student',
              title: 'تم تسكين الطالب',
              body: 'تم تسكين أحمد محمد في الباص رقم 101',
              color: Color(NotificationImages.getNotificationColor('student')),
              icon: Icons.school,
            ),

            _buildTestButton(
              type: 'bus',
              title: 'ركب الطالب الباص',
              body: 'أحمد محمد ركب الباص في الساعة 07:30',
              color: Color(NotificationImages.getNotificationColor('bus')),
              icon: Icons.directions_bus,
            ),

            _buildTestButton(
              type: 'absence',
              title: 'طلب غياب جديد',
              body: 'طلب غياب لأحمد محمد بتاريخ اليوم',
              color: Color(NotificationImages.getNotificationColor('absence')),
              icon: Icons.event_busy,
            ),

            _buildTestButton(
              type: 'admin',
              title: 'إشعار إداري',
              body: 'تم تحديث جدول الرحلات للباص رقم 101',
              color: Color(NotificationImages.getNotificationColor('admin')),
              icon: Icons.admin_panel_settings,
            ),

            _buildTestButton(
              type: 'emergency',
              title: 'حالة طوارئ',
              body: 'حالة طوارئ في الباص رقم 101 - يرجى التواصل فوراً',
              color: Color(NotificationImages.getNotificationColor('emergency')),
              icon: Icons.emergency,
            ),

            _buildTestButton(
              type: 'complaint',
              title: 'شكوى جديدة',
              body: 'شكوى جديدة من ولي أمر حول خدمة النقل',
              color: Color(NotificationImages.getNotificationColor('complaint')),
              icon: Icons.feedback,
            ),

            const SizedBox(height: 20),

            // معلومات إضافية
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📋 ملاحظات الاختبار:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• الإشعارات ستظهر مع صور وأيقونات مميزة\n'
                      '• كل نوع له لون وصوت مختلف\n'
                      '• الإشعارات تعمل في الخلفية والمقدمة\n'
                      '• يمكن النقر على الإشعار للتفاعل معه\n'
                      '• الإشعارات محفوظة في قاعدة البيانات',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
