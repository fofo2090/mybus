import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/admin_notification_model.dart';

/// Dialog جميل لعرض إشعارات الأدمن
class AdminNotificationDialog extends StatefulWidget {
  final AdminNotificationModel notification;
  final VoidCallback onDismiss;
  final VoidCallback onMarkAsRead;

  const AdminNotificationDialog({
    super.key,
    required this.notification,
    required this.onDismiss,
    required this.onMarkAsRead,
  });

  @override
  State<AdminNotificationDialog> createState() => _AdminNotificationDialogState();
}

class _AdminNotificationDialogState extends State<AdminNotificationDialog>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // إعداد الأنيميشن
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    // بدء الأنيميشن
    _slideController.forward();
    _fadeController.forward();

    // إخفاء تلقائي بعد 5 ثوان
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        _dismissDialog();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  /// إخفاء الـ Dialog مع أنيميشن
  Future<void> _dismissDialog() async {
    await _slideController.reverse();
    await _fadeController.reverse();
    if (mounted) {
      widget.onDismiss();
    }
  }

  /// الحصول على لون الأولوية
  Color _getPriorityColor() {
    switch (widget.notification.priority) {
      case NotificationPriority.low:
        return Colors.green;
      case NotificationPriority.normal:
        return Colors.blue;
      case NotificationPriority.high:
        return Colors.orange;
      case NotificationPriority.urgent:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // المساحة العلوية
              const Spacer(flex: 1),
              
              // الـ Dialog
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // الهيدر مع الأولوية
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // أيقونة النوع
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      widget.notification.typeIcon,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  
                                  // معلومات الإشعار
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.notification.typeDescription,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          widget.notification.priorityText,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // زر الإغلاق
                                  IconButton(
                                    onPressed: _dismissDialog,
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // المحتوى
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // العنوان
                              Text(
                                widget.notification.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // المحتوى
                              Text(
                                widget.notification.body,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // الوقت
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.notification.formattedTime,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const Spacer(),
                                  
                                  // مؤشر جديد
                                  if (widget.notification.isNew)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
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
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // الأزرار
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Row(
                            children: [
                              // زر تحديد كمقروء
                              if (!widget.notification.isRead)
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      widget.onMarkAsRead();
                                      HapticFeedback.lightImpact();
                                    },
                                    icon: const Icon(
                                      Icons.mark_email_read,
                                      size: 16,
                                    ),
                                    label: const Text('تحديد كمقروء'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _getPriorityColor(),
                                      side: BorderSide(color: _getPriorityColor()),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              
                              if (!widget.notification.isRead)
                                const SizedBox(width: 12),
                              
                              // زر الإغلاق
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _dismissDialog,
                                  icon: const Icon(
                                    Icons.check,
                                    size: 16,
                                  ),
                                  label: const Text('حسناً'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _getPriorityColor(),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // المساحة السفلية
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

/// Timer للإخفاء التلقائي
class Timer {
  Timer(Duration duration, VoidCallback callback) {
    Future.delayed(duration, callback);
  }
}
