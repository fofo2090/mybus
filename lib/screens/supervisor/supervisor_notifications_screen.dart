import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/supervisor_notification_service.dart';
import '../../models/notification_model.dart';
import '../../models/absence_model.dart';
import '../../models/supervisor_notification_model.dart';
import '../../widgets/supervisor_notification_dialog.dart';

class SupervisorNotificationsScreen extends StatefulWidget {
  const SupervisorNotificationsScreen({super.key});

  @override
  State<SupervisorNotificationsScreen> createState() => _SupervisorNotificationsScreenState();
}

class _SupervisorNotificationsScreenState extends State<SupervisorNotificationsScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  final SupervisorNotificationService _supervisorNotificationService = SupervisorNotificationService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // زيادة عدد التابات
    _initializeSupervisorNotifications();
    // Mark all notifications as read when opening the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAllAsRead();
    });
  }

  /// تهيئة خدمة إشعارات المشرف
  Future<void> _initializeSupervisorNotifications() async {
    try {
      await _supervisorNotificationService.initialize(context);
      debugPrint('✅ تم تهيئة خدمة إشعارات المشرف');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة خدمة إشعارات المشرف: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId != null) {
        await _databaseService.markAllNotificationsAsRead(userId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تحديد جميع الإشعارات كمقروءة'),
              backgroundColor: Colors.green,
            ),
          );
        }
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

  @override
  void dispose() {
    _tabController.dispose();
    _supervisorNotificationService.dispose();
    super.dispose();
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
              icon: Icon(Icons.notifications_active, size: 20),
              text: 'الإشعارات العامة',
            ),
            Tab(
              icon: Stack(
                children: [
                  const Icon(Icons.supervisor_account, size: 20),
                  StreamBuilder<int>(
                    stream: _supervisorNotificationService.unreadCountStream,
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
              text: 'إشعارات المشرف',
            ),
            const Tab(
              icon: Icon(Icons.person_off, size: 20),
              text: 'إشعارات الغياب',
            ),
            const Tab(
              icon: Icon(Icons.directions_bus, size: 20),
              text: 'إشعارات الرحلات',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneralNotifications(),
          _buildSupervisorNotifications(),
          _buildAbsenceNotifications(),
          _buildTripNotifications(),
        ],
      ),
    );
  }

  Widget _buildGeneralNotifications() {
    return StreamBuilder<List<NotificationModel>>(
      stream: _notificationService.getNotificationsForUser(
        _authService.currentUser?.uid ?? '',
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState('خطأ في تحميل الإشعارات');
        }

        final notifications = snapshot.data ?? [];
        final generalNotifications = notifications
            .where((n) => n.type == NotificationType.general)
            .toList();

        if (generalNotifications.isEmpty) {
          return _buildEmptyState(
            'لا توجد إشعارات عامة',
            'لم يتم استلام أي إشعارات عامة',
            Icons.notifications_off,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: generalNotifications.length,
          itemBuilder: (context, index) {
            final notification = generalNotifications[index];
            return _buildNotificationCard(notification);
          },
        );
      },
    );
  }

  Widget _buildAbsenceNotifications() {
    return StreamBuilder<List<AbsenceModel>>(
      stream: _databaseService.getRecentAbsenceNotifications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState('خطأ في تحميل إشعارات الغياب');
        }

        final absences = snapshot.data ?? [];

        if (absences.isEmpty) {
          return _buildEmptyState(
            'لا توجد إشعارات غياب',
            'لم يتم استلام أي إشعارات غياب حديثة',
            Icons.person_off,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: absences.length,
          itemBuilder: (context, index) {
            final absence = absences[index];
            return _buildAbsenceCard(absence);
          },
        );
      },
    );
  }

  Widget _buildTripNotifications() {
    return StreamBuilder<List<NotificationModel>>(
      stream: _notificationService.getNotificationsForUser(
        _authService.currentUser?.uid ?? '',
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState('خطأ في تحميل إشعارات الرحلات');
        }

        final notifications = snapshot.data ?? [];
        final tripNotifications = notifications
            .where((n) => n.type == NotificationType.tripStarted || 
                         n.type == NotificationType.tripEnded ||
                         n.type == NotificationType.studentBoarded ||
                         n.type == NotificationType.studentLeft)
            .toList();

        if (tripNotifications.isEmpty) {
          return _buildEmptyState(
            'لا توجد إشعارات رحلات',
            'لم يتم استلام أي إشعارات متعلقة بالرحلات',
            Icons.directions_bus,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tripNotifications.length,
          itemBuilder: (context, index) {
            final notification = tripNotifications[index];
            return _buildNotificationCard(notification);
          },
        );
      },
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : Colors.blue.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead ? Colors.grey.withAlpha(76) : Colors.blue.withAlpha(76),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getNotificationTypeColor(notification.type).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getNotificationTypeIcon(notification.type),
                  color: _getNotificationTypeColor(notification.type),
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
                        fontWeight: FontWeight.bold,
                        color: notification.isRead ? Colors.grey[700] : const Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('yyyy/MM/dd - HH:mm').format(notification.timestamp),
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
          Text(
            notification.body,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          if (notification.studentName != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'الطالب: ${notification.studentName}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAbsenceCard(AbsenceModel absence) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getAbsenceStatusColor(absence.status).withAlpha(76)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getAbsenceStatusColor(absence.status).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getAbsenceTypeIcon(absence.type),
                  color: _getAbsenceStatusColor(absence.status),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'طلب غياب - ${absence.studentName}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('yyyy/MM/dd').format(absence.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getAbsenceStatusColor(absence.status).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getAbsenceStatusText(absence.status),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getAbsenceStatusColor(absence.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'نوع الغياب: ${_getAbsenceTypeText(absence.type)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (absence.reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'السبب: ${absence.reason}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Color _getNotificationTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.general:
        return Colors.blue;
      case NotificationType.studentBoarded:
        return Colors.green;
      case NotificationType.studentLeft:
        return Colors.orange;
      case NotificationType.tripStarted:
        return Colors.purple;
      case NotificationType.tripEnded:
        return Colors.indigo;
    }
  }

  IconData _getNotificationTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.general:
        return Icons.notifications;
      case NotificationType.studentBoarded:
        return Icons.directions_bus;
      case NotificationType.studentLeft:
        return Icons.school;
      case NotificationType.tripStarted:
        return Icons.play_arrow;
      case NotificationType.tripEnded:
        return Icons.stop;
      default:
        return Icons.notifications;
    }
  }

  Color _getAbsenceStatusColor(AbsenceStatus status) {
    switch (status) {
      case AbsenceStatus.pending:
        return Colors.orange;
      case AbsenceStatus.approved:
        return Colors.green;
      case AbsenceStatus.rejected:
        return Colors.red;
    }
  }

  IconData _getAbsenceTypeIcon(AbsenceType type) {
    switch (type) {
      case AbsenceType.sick:
        return Icons.local_hospital;
      case AbsenceType.family:
        return Icons.family_restroom;
      case AbsenceType.travel:
        return Icons.flight;
      case AbsenceType.emergency:
        return Icons.emergency;
      case AbsenceType.other:
        return Icons.help;
    }
  }

  String _getAbsenceStatusText(AbsenceStatus status) {
    switch (status) {
      case AbsenceStatus.pending:
        return 'معلق';
      case AbsenceStatus.approved:
        return 'مقبول';
      case AbsenceStatus.rejected:
        return 'مرفوض';
    }
  }

  String _getAbsenceTypeText(AbsenceType type) {
    switch (type) {
      case AbsenceType.sick:
        return 'مرض';
      case AbsenceType.family:
        return 'ظروف عائلية';
      case AbsenceType.travel:
        return 'سفر';
      case AbsenceType.emergency:
        return 'طوارئ';
      case AbsenceType.other:
        return 'أخرى';
    }
  }

  /// بناء تاب الإشعارات المحلية للمشرف
  Widget _buildSupervisorNotifications() {
    return Column(
      children: [
        // شريط الأدوات
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            border: Border(
              bottom: BorderSide(color: Colors.orange[200]!),
            ),
          ),
          child: Row(
            children: [
              // عداد الإشعارات
              StreamBuilder<int>(
                stream: _supervisorNotificationService.unreadCountStream,
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: unreadCount > 0 ? const Color(0xFFFF9800) : Colors.grey,
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
                  await _supervisorNotificationService.markAllAsRead();
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
                  foregroundColor: const Color(0xFFFF9800),
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
          child: StreamBuilder<List<SupervisorNotificationModel>>(
            stream: _supervisorNotificationService.notificationsStream,
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
                  return _buildSupervisorNotificationCard(notification);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// بناء بطاقة إشعار المشرف
  Widget _buildSupervisorNotificationCard(SupervisorNotificationModel notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: notification.isRead ? 1 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: notification.isRead ? Colors.grey[300]! : _getSupervisorNotificationColor(notification),
          width: notification.isRead ? 1 : 3,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showSupervisorNotificationDetails(notification),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الهيدر
              Row(
                children: [
                  // أيقونة النوع
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getSupervisorNotificationColor(notification).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getSupervisorNotificationColor(notification).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      notification.typeIcon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 16),

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
                                fontSize: 13,
                                color: _getSupervisorNotificationColor(notification),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _getSupervisorNotificationColor(notification),
                                borderRadius: BorderRadius.circular(12),
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
                        const SizedBox(height: 6),
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
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
                      const SizedBox(height: 6),
                      if (!notification.isRead)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _getSupervisorNotificationColor(notification),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // المحتوى
              Text(
                notification.body,
                style: TextStyle(
                  fontSize: 15,
                  color: notification.isRead ? Colors.grey[600] : Colors.black54,
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // معلومات إضافية
              if (notification.isStudentRelated ||
                  notification.isBusRelated ||
                  notification.isRouteRelated) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      if (notification.studentName != null) ...[
                        const Icon(Icons.person, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          notification.studentName!,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                      if (notification.studentName != null &&
                          (notification.busNumber != null || notification.routeName != null))
                        const SizedBox(width: 16),
                      if (notification.busNumber != null) ...[
                        const Icon(Icons.directions_bus, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          notification.busNumber!,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                      if (notification.busNumber != null && notification.routeName != null)
                        const SizedBox(width: 16),
                      if (notification.routeName != null) ...[
                        const Icon(Icons.route, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            notification.routeName!,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // الفوتر
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    notification.formattedTime,
                    style: TextStyle(
                      fontSize: 13,
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
                          onPressed: () => _supervisorNotificationService.markAsRead(notification.id),
                          icon: const Icon(Icons.mark_email_read, size: 18),
                          tooltip: 'تحديد كمقروء',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        ),
                      if (notification.requiresAction)
                        IconButton(
                          onPressed: () {
                            // يمكن إضافة منطق الإجراء هنا
                          },
                          icon: const Icon(Icons.touch_app, size: 18),
                          tooltip: notification.actionText,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        ),
                      if (notification.requiresConfirmation)
                        IconButton(
                          onPressed: () {
                            // يمكن إضافة منطق التأكيد هنا
                          },
                          icon: const Icon(Icons.check_circle, size: 18),
                          tooltip: 'تأكيد',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        ),
                      IconButton(
                        onPressed: () => _deleteSupervisorNotification(notification),
                        icon: const Icon(Icons.delete, size: 18),
                        tooltip: 'حذف',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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
  Color _getSupervisorNotificationColor(SupervisorNotificationModel notification) {
    switch (notification.priority) {
      case SupervisorNotificationPriority.low:
        return Colors.green;
      case SupervisorNotificationPriority.normal:
        return const Color(0xFFFF9800); // برتقالي (لون المشرف)
      case SupervisorNotificationPriority.high:
        return Colors.red;
      case SupervisorNotificationPriority.urgent:
        return const Color(0xFF9C27B0); // بنفسجي
    }
  }

  /// عرض تفاصيل الإشعار
  void _showSupervisorNotificationDetails(SupervisorNotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => SupervisorNotificationDialog(
        notification: notification,
        onDismiss: () => Navigator.of(context).pop(),
        onMarkAsRead: () => _supervisorNotificationService.markAsRead(notification.id),
      ),
    );
  }

  /// حذف إشعار المشرف
  void _deleteSupervisorNotification(SupervisorNotificationModel notification) {
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
              await _supervisorNotificationService.deleteNotification(notification.id);
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
              await _supervisorNotificationService.clearAllNotifications();
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
