import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';

class NotificationBadge extends StatelessWidget {
  final Widget child;
  final Color? badgeColor;
  final Color? textColor;
  final double? badgeSize;
  final bool showZero;

  const NotificationBadge({
    super.key,
    required this.child,
    this.badgeColor,
    this.textColor,
    this.badgeSize,
    this.showZero = false,
  });

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();
    final authService = AuthService();

    return StreamBuilder<int>(
      stream: notificationService.getUnreadNotificationsCount(
        authService.currentUser?.uid ?? '',
      ),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        
        if (count == 0 && !showZero) {
          return child;
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: badgeColor ?? Colors.red,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                constraints: BoxConstraints(
                  minWidth: badgeSize ?? 18,
                  minHeight: badgeSize ?? 18,
                ),
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: TextStyle(
                    color: textColor ?? Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class NotificationIcon extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? iconColor;
  final double? iconSize;
  final String? tooltip;

  const NotificationIcon({
    super.key,
    this.onPressed,
    this.iconColor,
    this.iconSize,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();
    final authService = AuthService();

    return StreamBuilder<int>(
      stream: notificationService.getUnreadNotificationsCount(
        authService.currentUser?.uid ?? '',
      ),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        final hasNotifications = count > 0;

        return NotificationBadge(
          child: IconButton(
            icon: Icon(
              hasNotifications ? Icons.notifications_active : Icons.notifications,
              color: iconColor ?? (hasNotifications ? Colors.orange : Colors.grey),
              size: iconSize ?? 24,
            ),
            onPressed: onPressed,
            tooltip: tooltip ?? (hasNotifications ? '$count إشعار جديد' : 'الإشعارات'),
          ),
        );
      },
    );
  }
}

class NotificationCounter extends StatelessWidget {
  final TextStyle? textStyle;
  final String? prefix;
  final String? suffix;

  const NotificationCounter({
    super.key,
    this.textStyle,
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();
    final authService = AuthService();

    return StreamBuilder<int>(
      stream: notificationService.getUnreadNotificationsCount(
        authService.currentUser?.uid ?? '',
      ),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        
        if (count == 0) {
          return const SizedBox.shrink();
        }

        return Text(
          '${prefix ?? ''}$count${suffix ?? ''}',
          style: textStyle ?? const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        );
      },
    );
  }
}
