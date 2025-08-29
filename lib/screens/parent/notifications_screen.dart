import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/notification_service.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../services/parent_notification_service.dart';
import '../../models/notification_model.dart';
import '../../models/parent_notification_model.dart';
import '../../widgets/parent_notification_dialog.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  final ParentNotificationService _parentNotificationService = ParentNotificationService();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeParentNotifications();
  }

  /// تهيئة خدمة إشعارات ولي الأمر
  Future<void> _initializeParentNotifications() async {
    try {
      await _parentNotificationService.initialize(context);
      debugPrint('✅ تم تهيئة خدمة إشعارات ولي الأمر');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة خدمة إشعارات ولي الأمر: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _parentNotificationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('الإشعارات'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          // زر إصلاح الإشعارات (للتطوير فقط)
          IconButton(
            icon: const Icon(Icons.build),
            onPressed: _fixNotifications,
            tooltip: 'إصلاح الإشعارات',
          ),
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: _markAllAsRead,
            tooltip: 'تحديد الكل كمقروء',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            const Tab(
              icon: Icon(Icons.notifications, size: 18),
              text: 'الإشعارات العامة',
            ),
            Tab(
              icon: Stack(
                children: [
                  const Icon(Icons.notifications_active, size: 18),
                  StreamBuilder<int>(
                    stream: _parentNotificationService.unreadCountStream,
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      if (count == 0) return const SizedBox.shrink();
                      return Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            count > 99 ? '99+' : count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              text: 'إشعاراتي',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // التاب الأول: الإشعارات العامة (النظام القديم)
          Column(
            children: [
              // Unread Count Header
              _buildUnreadCountHeader(),

              // Notifications List
              Expanded(
                child: _buildNotificationsList(),
              ),
            ],
          ),

          // التاب الثاني: الإشعارات المحلية الجديدة
          _buildParentNotifications(),
        ],
      ),
    );
  }

  Widget _buildUnreadCountHeader() {
    return StreamBuilder<int>(
      stream: _databaseService.getParentNotificationsCount(
        _authService.currentUser?.uid ?? '',
      ),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        
        if (unreadCount == 0) return const SizedBox.shrink();
        
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.blue[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'لديك $unreadCount إشعار غير مقروء',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: _markAllAsRead,
                child: const Text('تحديد الكل كمقروء'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationsList() {
    return StreamBuilder<List<NotificationModel>>(
      stream: _databaseService.getParentNotifications(
        _authService.currentUser?.uid ?? '',
      ),
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
                Text('خطأ: ${snapshot.error}'),
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 20),
                Text(
                  'لا توجد إشعارات',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ستظهر هنا الإشعارات المتعلقة بأطفالك',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return _buildNotificationCard(notification);
          },
        );
      },
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead ? Colors.grey[200]! : Colors.blue[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _markAsRead(notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildNotificationIcon(notification.type),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: notification.isRead 
                                ? FontWeight.w600 
                                : FontWeight.bold,
                            color: notification.isRead 
                                ? Colors.grey[800] 
                                : Colors.blue[800],
                          ),
                        ),
                        if (notification.studentName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'الطالب: ${notification.studentName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        notification.formattedTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.timeAgo,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                      if (!notification.isRead) ...[
                        const SizedBox(height: 4),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildNotificationBody(notification),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    notification.formattedDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
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

  Widget _buildNotificationIcon(NotificationType type) {
    IconData icon;
    Color color;

    switch (type) {
      case NotificationType.studentBoarded:
        icon = Icons.directions_bus;
        color = Colors.green;
        break;
      case NotificationType.studentLeft:
        icon = Icons.home;
        color = Colors.orange;
        break;
      case NotificationType.tripStarted:
        icon = Icons.play_arrow;
        color = Colors.blue;
        break;
      case NotificationType.tripEnded:
        icon = Icons.stop;
        color = Colors.red;
        break;
      case NotificationType.studentAssigned:
        icon = Icons.person_add;
        color = Colors.green;
        break;
      case NotificationType.studentUnassigned:
        icon = Icons.person_remove;
        color = Colors.orange;
        break;
      case NotificationType.absenceRequested:
        icon = Icons.event_busy;
        color = Colors.orange;
        break;
      case NotificationType.absenceApproved:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case NotificationType.absenceRejected:
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case NotificationType.complaintSubmitted:
        icon = Icons.feedback;
        color = Colors.purple;
        break;
      case NotificationType.complaintResponded:
        icon = Icons.reply;
        color = Colors.blue;
        break;
      case NotificationType.emergency:
        icon = Icons.emergency;
        color = Colors.red;
        break;
      case NotificationType.systemUpdate:
        icon = Icons.system_update;
        color = Colors.grey;
        break;
      case NotificationType.tripDelayed:
        icon = Icons.schedule;
        color = Colors.orange;
        break;
      case NotificationType.general:
      default:
        icon = Icons.info;
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 20,
        color: color,
      ),
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
    if (!notification.isRead) {
      try {
        await _databaseService.markNotificationAsRead(notification.id);
        debugPrint('✅ Notification marked as read: ${notification.id}');
      } catch (e) {
        debugPrint('❌ Error marking notification as read: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في تحديث الإشعار: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _databaseService.markAllNotificationsAsRead(
        _authService.currentUser?.uid ?? '',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديد جميع الإشعارات كمقروءة'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث الإشعارات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// بناء تاب الإشعارات المحلية لولي الأمر
  Widget _buildParentNotifications() {
    return Column(
      children: [
        // شريط الأدوات
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border(
              bottom: BorderSide(color: Colors.blue[200]!),
            ),
          ),
          child: Row(
            children: [
              // عداد الإشعارات
              StreamBuilder<int>(
                stream: _parentNotificationService.unreadCountStream,
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: unreadCount > 0 ? const Color(0xFF1E88E5) : Colors.grey,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$unreadCount غير مقروء',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
              const Spacer(),

              // زر تحديد الكل كمقروء
              TextButton.icon(
                onPressed: () async {
                  await _parentNotificationService.markAllAsRead();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تحديد جميع الإشعارات كمقروءة'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Icons.mark_email_read, size: 16),
                label: const Text('تحديد الكل كمقروء'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1E88E5),
                ),
              ),

              // زر مسح الكل
              TextButton.icon(
                onPressed: () => _showClearAllDialog(),
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('مسح الكل'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ),
        ),

        // قائمة الإشعارات
        Expanded(
          child: StreamBuilder<List<ParentNotificationModel>>(
            stream: _parentNotificationService.notificationsStream,
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
                      Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'لا توجد إشعارات',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'ستظهر الإشعارات الجديدة هنا',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
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
                  return _buildParentNotificationCard(notification);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// بناء بطاقة إشعار ولي الأمر
  Widget _buildParentNotificationCard(ParentNotificationModel notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: notification.isRead ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: notification.isRead ? Colors.grey[300]! : _getParentNotificationColor(notification),
          width: notification.isRead ? 1 : 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showParentNotificationDetails(notification),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الهيدر
              Row(
                children: [
                  // أيقونة النوع
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getParentNotificationColor(notification).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      notification.typeIcon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // معلومات الإشعار
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              notification.typeDescription,
                              style: TextStyle(
                                fontSize: 12,
                                color: _getParentNotificationColor(notification),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getParentNotificationColor(notification),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                notification.priorityText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                            color: notification.isRead ? Colors.grey[700] : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // مؤشرات
                  Column(
                    children: [
                      if (notification.isNew)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'جديد',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getParentNotificationColor(notification),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // المحتوى
              Text(
                notification.body,
                style: TextStyle(
                  fontSize: 14,
                  color: notification.isRead ? Colors.grey[600] : Colors.black54,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // معلومات إضافية
              if (notification.isStudentRelated || notification.isBusRelated) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      if (notification.studentName != null) ...[
                        const Icon(Icons.person, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          notification.studentName!,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                      if (notification.studentName != null && notification.busNumber != null)
                        const SizedBox(width: 12),
                      if (notification.busNumber != null) ...[
                        const Icon(Icons.directions_bus, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          notification.busNumber!,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // الفوتر
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    notification.formattedTime,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const Spacer(),

                  // أزرار الإجراءات
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!notification.isRead)
                        IconButton(
                          onPressed: () => _parentNotificationService.markAsRead(notification.id),
                          icon: const Icon(Icons.mark_email_read, size: 16),
                          tooltip: 'تحديد كمقروء',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      if (notification.requiresAction)
                        IconButton(
                          onPressed: () {
                            // يمكن إضافة منطق الإجراء هنا
                          },
                          icon: const Icon(Icons.touch_app, size: 16),
                          tooltip: notification.actionText,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      IconButton(
                        onPressed: () => _deleteParentNotification(notification),
                        icon: const Icon(Icons.delete, size: 16),
                        tooltip: 'حذف',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// الحصول على لون الإشعار حسب الأولوية
  Color _getParentNotificationColor(ParentNotificationModel notification) {
    switch (notification.priority) {
      case ParentNotificationPriority.low:
        return Colors.green;
      case ParentNotificationPriority.normal:
        return const Color(0xFF1E88E5);
      case ParentNotificationPriority.high:
        return Colors.orange;
      case ParentNotificationPriority.urgent:
        return Colors.red;
    }
  }

  /// عرض تفاصيل الإشعار
  void _showParentNotificationDetails(ParentNotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => ParentNotificationDialog(
        notification: notification,
        onDismiss: () => Navigator.of(context).pop(),
        onMarkAsRead: () => _parentNotificationService.markAsRead(notification.id),
      ),
    );
  }

  /// حذف إشعار ولي الأمر
  void _deleteParentNotification(ParentNotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف الإشعار "${notification.title}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _parentNotificationService.deleteNotification(notification.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم حذف الإشعار'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  /// عرض حوار مسح جميع الإشعارات
  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد المسح'),
        content: const Text('هل تريد مسح جميع الإشعارات؟ هذا الإجراء لا يمكن التراجع عنه.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _parentNotificationService.clearAllNotifications();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم مسح جميع الإشعارات'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('مسح الكل'),
          ),
        ],
      ),
    );
  }
}