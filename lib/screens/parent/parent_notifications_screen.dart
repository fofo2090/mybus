import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/notification_model.dart';
import '../../utils/notification_test_helper.dart';

class ParentNotificationsScreen extends StatefulWidget {
  const ParentNotificationsScreen({super.key});

  @override
  State<ParentNotificationsScreen> createState() => _ParentNotificationsScreenState();
}

class _ParentNotificationsScreenState extends State<ParentNotificationsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  late Stream<List<NotificationModel>> _notificationsStream;

  @override
  void initState() {
    super.initState();
    _initializeStream();
    // Mark all notifications as read when opening the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAllAsRead();
    });
  }

  void _initializeStream() {
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      _notificationsStream = _databaseService.getParentNotifications(userId);
    } else {
      _notificationsStream = Stream.value([]);
    }
  }

  Future<void> _markAllAsRead() async {
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      await _databaseService.markAllNotificationsAsRead(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'الإشعارات',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // زر إصلاح الإشعارات (للتطوير فقط)
          IconButton(
            icon: const Icon(Icons.build),
            onPressed: _fixNotifications,
            tooltip: 'إصلاح الإشعارات',
          ),
          // زر اختبار الإشعارات (للتطوير فقط)
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => NotificationTestHelper.showQuickTestMenu(context),
            tooltip: 'اختبار الإشعارات',
          ),
          StreamBuilder<int>(
            stream: _databaseService.getParentNotificationsCount(_authService.currentUser?.uid ?? ''),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              if (count > 0) {
                return IconButton(
                  icon: const Icon(Icons.mark_email_read),
                  onPressed: _markAllAsRead,
                  tooltip: 'تحديد الكل كمقروء',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('خطأ في تحميل الإشعارات: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'لا توجد إشعارات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'ستظهر الإشعارات الجديدة هنا',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    // تسجيل تشخيصي لفهم محتوى الإشعار
    debugPrint('🔍 Notification Debug:');
    debugPrint('  - ID: ${notification.id}');
    debugPrint('  - Title: "${notification.title}"');
    debugPrint('  - Body: "${notification.body}"');
    debugPrint('  - Body length: ${notification.body.length}');
    debugPrint('  - Type: ${notification.type}');
    debugPrint('  - IsRead: ${notification.isRead}');
    debugPrint('  - Data: ${notification.data}');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: notification.isRead ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: notification.isRead 
            ? BorderSide.none 
            : BorderSide(color: Colors.blue.withAlpha(76), width: 1),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: notification.isRead ? Colors.white : Colors.blue.withAlpha(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getNotificationColor(notification.type).withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getNotificationIcon(notification.type),
                      color: _getNotificationColor(notification.type),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                            color: const Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTimestamp(notification.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!notification.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Body - عرض النص الكامل مع إمكانية التوسع
              _buildNotificationBody(notification),
              
              // Student info if available
              if (notification.studentName != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'الطالب: ${notification.studentName}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBody(NotificationModel notification) {
    // الحصول على النص الكامل من body أو message أو data
    String fullText = '';

    if (notification.body.isNotEmpty) {
      fullText = notification.body;
    } else if (notification.data != null && notification.data!['message'] != null) {
      fullText = notification.data!['message'].toString();
    } else if (notification.data != null && notification.data!['body'] != null) {
      fullText = notification.data!['body'].toString();
    } else {
      fullText = 'لا يوجد محتوى للإشعار';
    }

    // إذا كان النص قصير، عرضه مباشرة
    if (fullText.length <= 100) {
      return Text(
        fullText,
        style: TextStyle(
          fontSize: 14,
          color: fullText != 'لا يوجد محتوى للإشعار' ? Colors.grey[700] : Colors.red[400],
          height: 1.4,
          fontStyle: fullText != 'لا يوجد محتوى للإشعار' ? FontStyle.normal : FontStyle.italic,
        ),
      );
    }

    // إذا كان النص طويل، عرضه مع إمكانية التوسع
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fullText.length > 100 ? '${fullText.substring(0, 100)}...' : fullText,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            height: 1.4,
          ),
        ),
        if (fullText.length > 100) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showFullNotificationDialog(notification, fullText),
            child: Text(
              'اضغط لعرض النص الكامل',
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF1E88E5),
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showFullNotificationDialog(NotificationModel notification, String fullText) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.notifications_active,
                  color: const Color(0xFF1E88E5),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  notification.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // النص الكامل
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    fullText,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF2D3748),
                      height: 1.6,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // معلومات إضافية
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      notification.relativeTime,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),

                if (notification.studentName != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'الطالب: ${notification.studentName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'إغلاق',
                style: TextStyle(
                  color: Color(0xFF1E88E5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (!notification.isRead)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _markAsRead(notification);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('تحديد كمقروء'),
              ),
          ],
        );
      },
    );
  }

  Future<void> _fixNotifications() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('جاري إصلاح الإشعارات...'),
          backgroundColor: Colors.orange,
        ),
      );

      await _databaseService.fixExistingNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إصلاح الإشعارات بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error fixing notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إصلاح الإشعارات'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    try {
      await _databaseService.markNotificationAsRead(notification.id);
      debugPrint('✅ Notification marked as read: ${notification.id}');
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث حالة الإشعار'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final parentId = _authService.currentUser?.uid ?? '';
      if (parentId.isEmpty) return;

      await _databaseService.markAllParentNotificationsAsRead(parentId);
      debugPrint('✅ All notifications marked as read for parent: $parentId');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحديد جميع الإشعارات كمقروءة'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error marking all notifications as read: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث الإشعارات'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.studentBoarded:
        return Colors.green;
      case NotificationType.studentLeft:
        return Colors.orange;
      case NotificationType.tripStarted:
        return Colors.blue;
      case NotificationType.tripEnded:
        return Colors.purple;
      case NotificationType.general:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.studentBoarded:
        return Icons.directions_bus;
      case NotificationType.studentLeft:
        return Icons.home;
      case NotificationType.tripStarted:
        return Icons.play_arrow;
      case NotificationType.tripEnded:
        return Icons.stop;
      case NotificationType.general:
        return Icons.info;
      default:
        return Icons.info;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} دقيقة';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} يوم';
    } else {
      return DateFormat('yyyy/MM/dd').format(timestamp);
    }
  }
}
