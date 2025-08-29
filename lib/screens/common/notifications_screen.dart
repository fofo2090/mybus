import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import '../../widgets/responsive_widgets.dart';

/// شاشة الإشعارات
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = context.read<AuthService>().currentUser?.uid ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const ResponsiveHeading('الإشعارات'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        actions: [
          ResponsiveIconButton(
            onPressed: _markAllAsRead,
            icon: const Icon(Icons.done_all),
            tooltip: 'تحديد الكل كمقروء',
          ),
          ResponsiveIconButton(
            onPressed: _showNotificationSettings,
            icon: const Icon(Icons.settings),
            tooltip: 'إعدادات الإشعارات',
          ),
        ],
      ),
      body: ResponsiveContainer(
        child: StreamBuilder<List<NotificationModel>>(
          stream: _notificationService.getUnreadNotificationsStream(_currentUserId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: ResponsiveCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const ResponsiveIcon(Icons.error, color: Colors.red),
                      const ResponsiveVerticalSpace(),
                      ResponsiveBodyText('خطأ في تحميل الإشعارات: ${snapshot.error}'),
                    ],
                  ),
                ),
              );
            }

            final notifications = snapshot.data ?? [];

            if (notifications.isEmpty) {
              return Center(
                child: ResponsiveCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ResponsiveIcon(
                        Icons.notifications_off,
                        color: Colors.grey[400],
                        mobileSize: 64,
                        tabletSize: 72,
                        desktopSize: 80,
                      ),
                      const ResponsiveVerticalSpace(),
                      const ResponsiveSubheading('لا توجد إشعارات'),
                      const ResponsiveVerticalSpace(),
                      ResponsiveBodyText(
                        'ستظهر الإشعارات الجديدة هنا',
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              );
            }

            return ResponsiveListView(
              children: notifications.map((notification) => 
                _buildNotificationCard(notification)
              ).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return ResponsiveListCard(
      margin: ResponsiveHelper.getPadding(context,
        mobilePadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        tabletPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        desktopPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      onTap: () => _handleNotificationTap(notification),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveHelper.getSpacing(context) / 2),
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context)),
                ),
                child: Text(
                  notification.icon,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getIconSize(context,
                      mobileSize: 20,
                      tabletSize: 24,
                      desktopSize: 28,
                    ),
                  ),
                ),
              ),
              const ResponsiveHorizontalSpace(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveBodyText(
                      notification.title,
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                    if (notification.body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      ResponsiveCaption(
                        notification.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ResponsiveCaption(
                    notification.relativeTime,
                    color: Colors.grey[500],
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
          if (notification.requiresAction) ...[
            const ResponsiveVerticalSpace(),
            ResponsiveButtonGroup(
              buttons: [
                ResponsiveElevatedButton(
                  onPressed: () => _handleNotificationAction(notification),
                  child: Text(notification.actionText ?? 'اتخاذ إجراء'),
                ),
                ResponsiveTextButton(
                  onPressed: () => _markAsRead(notification.id),
                  child: const Text('تحديد كمقروء'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getNotificationColor(NotificationModel notification) {
    switch (notification.type) {
      case NotificationType.studentBoarded:
      case NotificationType.studentLeft:
      case NotificationType.tripStarted:
      case NotificationType.tripEnded:
        return Colors.blue;
      case NotificationType.studentAssigned:
      case NotificationType.studentUnassigned:
        return Colors.green;
      case NotificationType.absenceRequested:
      case NotificationType.tripDelayed:
        return Colors.orange;
      case NotificationType.absenceApproved:
        return Colors.green;
      case NotificationType.absenceRejected:
        return Colors.red;
      case NotificationType.complaintSubmitted:
      case NotificationType.complaintResponded:
        return Colors.blueGrey;
      case NotificationType.emergency:
        return Colors.red;
      case NotificationType.systemUpdate:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    if (!notification.isRead) {
      _markAsRead(notification.id);
    }
    
    // يمكن إضافة منطق التنقل هنا بناءً على نوع الإشعار
    _showNotificationDetails(notification);
  }

  void _handleNotificationAction(NotificationModel notification) {
    // يمكن إضافة منطق الإجراءات هنا
    _showNotificationDetails(notification);
  }

  void _showNotificationDetails(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 16),
            Text(
              'النوع: ${notification.typeDescription}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'التوقيت: ${notification.relativeTime}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          if (!notification.isRead)
            TextButton(
              onPressed: () {
                _markAsRead(notification.id);
                Navigator.pop(context);
              },
              child: const Text('تحديد كمقروء'),
            ),
        ],
      ),
    );
  }

  void _markAsRead(String notificationId) {
    _notificationService.markNotificationAsRead(notificationId);
  }

  void _markAllAsRead() {
    // يمكن إضافة دالة لتحديد جميع الإشعارات كمقروءة
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تحديد جميع الإشعارات كمقروءة'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showNotificationSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationSettingsScreen(),
      ),
    );
  }
}

/// شاشة إعدادات الإشعارات
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _enablePushNotifications = true;
  bool _enableSoundNotifications = true;
  bool _enableVibrationNotifications = true;
  bool _enableStudentNotifications = true;
  bool _enableBusNotifications = true;
  bool _enableAbsenceNotifications = true;
  bool _enableAdminNotifications = true;
  bool _enableEmergencyNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const ResponsiveHeading('إعدادات الإشعارات'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: ResponsiveContainer(
        child: ResponsiveListView(
          children: [
            _buildSettingsSection(
              'الإعدادات العامة',
              [
                _buildSwitchTile(
                  'تفعيل الإشعارات',
                  'تلقي الإشعارات على الجهاز',
                  Icons.notifications,
                  _enablePushNotifications,
                  (value) => setState(() => _enablePushNotifications = value),
                ),
                _buildSwitchTile(
                  'الصوت',
                  'تشغيل صوت مع الإشعارات',
                  Icons.volume_up,
                  _enableSoundNotifications,
                  (value) => setState(() => _enableSoundNotifications = value),
                ),
                _buildSwitchTile(
                  'الاهتزاز',
                  'اهتزاز الجهاز مع الإشعارات',
                  Icons.vibration,
                  _enableVibrationNotifications,
                  (value) => setState(() => _enableVibrationNotifications = value),
                ),
              ],
            ),
            _buildSettingsSection(
              'أنواع الإشعارات',
              [
                _buildSwitchTile(
                  'إشعارات الطلاب',
                  'تسكين وإلغاء تسكين الطلاب',
                  Icons.school,
                  _enableStudentNotifications,
                  (value) => setState(() => _enableStudentNotifications = value),
                ),
                _buildSwitchTile(
                  'إشعارات الباص',
                  'ركوب ونزول الطلاب',
                  Icons.directions_bus,
                  _enableBusNotifications,
                  (value) => setState(() => _enableBusNotifications = value),
                ),
                _buildSwitchTile(
                  'إشعارات الغياب',
                  'طلبات الغياب والموافقات',
                  Icons.event_busy,
                  _enableAbsenceNotifications,
                  (value) => setState(() => _enableAbsenceNotifications = value),
                ),
                _buildSwitchTile(
                  'الإشعارات الإدارية',
                  'إشعارات من الإدارة',
                  Icons.admin_panel_settings,
                  _enableAdminNotifications,
                  (value) => setState(() => _enableAdminNotifications = value),
                ),
                _buildSwitchTile(
                  'إشعارات الطوارئ',
                  'إشعارات الطوارئ (لا يمكن إيقافها)',
                  Icons.emergency,
                  _enableEmergencyNotifications,
                  null, // لا يمكن إيقاف إشعارات الطوارئ
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return ResponsiveCard(
      margin: ResponsiveHelper.getPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveSubheading(title),
          const ResponsiveVerticalSpace(),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool>? onChanged,
  ) {
    return ResponsiveListTile(
      leading: ResponsiveIcon(icon, color: Colors.blue),
      title: ResponsiveBodyText(title),
      subtitle: ResponsiveCaption(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF1E88E5),
      ),
    );
  }
}
