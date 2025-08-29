import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/fcm_service.dart';
import '../../widgets/admin_app_bar.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  Map<String, dynamic>? _notificationStatus;
  String? _fcmToken;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    setState(() => _isLoading = true);
    
    try {
      final fcmService = Provider.of<FCMService>(context, listen: false);
      
      final status = await fcmService.checkNotificationStatus();
      final token = await fcmService.getToken();
      
      setState(() {
        _notificationStatus = status;
        _fcmToken = token;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في فحص الإشعارات: $e')),
      );
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      final fcmService = Provider.of<FCMService>(context, listen: false);
      
      await fcmService.sendTestNotification(
        title: 'إشعار تجريبي',
        body: 'هذا إشعار تجريبي للتأكد من عمل النظام',
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال الإشعار التجريبي'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في إرسال الإشعار: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AdminAppBar(title: 'اختبار الإشعارات'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildTokenCard(),
                  const SizedBox(height: 16),
                  _buildActionsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    if (_notificationStatus == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('لا توجد معلومات متاحة'),
        ),
      );
    }

    final isEnabled = _notificationStatus!['isFullyEnabled'] ?? false;
    final fcmAuthorized = _notificationStatus!['fcmAuthorized'] ?? false;
    final androidPermission = _notificationStatus!['androidPermissionGranted'] ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isEnabled ? Icons.check_circle : Icons.error,
                  color: isEnabled ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'حالة الإشعارات',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatusRow('الحالة العامة', isEnabled ? 'مفعلة' : 'معطلة', isEnabled),
            _buildStatusRow('أذونات FCM', fcmAuthorized ? 'مفعلة' : 'معطلة', fcmAuthorized),
            _buildStatusRow('أذونات Android', androidPermission ? 'مفعلة' : 'معطلة', androidPermission),
            _buildStatusRow('حالة FCM', _notificationStatus!['fcmStatus'] ?? 'غير معروف', fcmAuthorized),
            _buildStatusRow('التنبيهات', _notificationStatus!['alertSetting'] ?? 'غير معروف', true),
            _buildStatusRow('الأصوات', _notificationStatus!['soundSetting'] ?? 'غير معروف', true),
            _buildStatusRow('الشارات', _notificationStatus!['badgeSetting'] ?? 'غير معروف', true),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, bool isGood) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Row(
            children: [
              Icon(
                isGood ? Icons.check : Icons.close,
                size: 16,
                color: isGood ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  color: isGood ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTokenCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FCM Token',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _fcmToken ?? 'لا يوجد توكن',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إجراءات الاختبار',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sendTestNotification,
                icon: const Icon(Icons.send),
                label: const Text('إرسال إشعار تجريبي'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _checkNotificationStatus,
                icon: const Icon(Icons.refresh),
                label: const Text('تحديث الحالة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
