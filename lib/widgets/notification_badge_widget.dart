import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_badge_service.dart';

/// Widget لعرض عداد الإشعارات غير المقروءة
class NotificationBadgeWidget extends StatelessWidget {
  final Widget child;
  final bool showZero;
  final Color? badgeColor;
  final Color? textColor;
  final double? badgeSize;

  const NotificationBadgeWidget({
    super.key,
    required this.child,
    this.showZero = false,
    this.badgeColor,
    this.textColor,
    this.badgeSize,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationBadgeService>(
      builder: (context, badgeService, _) {
        final count = badgeService.unreadCount;
        final shouldShow = count > 0 || (showZero && count == 0);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            if (shouldShow)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  constraints: BoxConstraints(
                    minWidth: badgeSize ?? 20,
                    minHeight: badgeSize ?? 20,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor ?? Colors.red,
                    borderRadius: BorderRadius.circular((badgeSize ?? 20) / 2),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Center(
                    child: Text(
                      count > 99 ? '99+' : count.toString(),
                      style: TextStyle(
                        color: textColor ?? Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Widget بسيط لأيقونة الإشعارات مع عداد
class NotificationIconWithBadge extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final double iconSize;
  final Color? iconColor;

  const NotificationIconWithBadge({
    super.key,
    this.onTap,
    this.icon = Icons.notifications,
    this.iconSize = 24,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: NotificationBadgeWidget(
          child: Icon(
            icon,
            size: iconSize,
            color: iconColor ?? Theme.of(context).iconTheme.color,
          ),
        ),
      ),
    );
  }
}

/// Widget لعرض عدد الإشعارات غير المقروءة كنص
class UnreadNotificationCounter extends StatelessWidget {
  final TextStyle? textStyle;
  final String prefix;
  final String suffix;

  const UnreadNotificationCounter({
    super.key,
    this.textStyle,
    this.prefix = '',
    this.suffix = ' إشعار غير مقروء',
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationBadgeService>(
      builder: (context, badgeService, _) {
        final count = badgeService.unreadCount;
        
        if (count == 0) {
          return const SizedBox.shrink();
        }

        return Text(
          '$prefix$count$suffix',
          style: textStyle ?? TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w600,
          ),
        );
      },
    );
  }
}

/// Widget لنقطة الإشعار البسيطة (بدون رقم)
class NotificationDotWidget extends StatelessWidget {
  final Widget child;
  final Color? dotColor;
  final double dotSize;

  const NotificationDotWidget({
    super.key,
    required this.child,
    this.dotColor,
    this.dotSize = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationBadgeService>(
      builder: (context, badgeService, _) {
        final hasNotifications = badgeService.hasUnreadNotifications;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            if (hasNotifications)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: dotColor ?? Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// مثال على كيفية الاستخدام في AppBar
class ExampleAppBarWithNotifications extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const ExampleAppBarWithNotifications({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        NotificationIconWithBadge(
          onTap: () {
            // الانتقال إلى صفحة الإشعارات
            Navigator.pushNamed(context, '/notifications');
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
