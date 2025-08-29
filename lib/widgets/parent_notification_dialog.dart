import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/parent_notification_model.dart';

/// Dialog جميل لعرض إشعارات ولي الأمر
class ParentNotificationDialog extends StatefulWidget {
  final ParentNotificationModel notification;
  final VoidCallback onDismiss;
  final VoidCallback onMarkAsRead;

  const ParentNotificationDialog({
    super.key,
    required this.notification,
    required this.onDismiss,
    required this.onMarkAsRead,
  });

  @override
  State<ParentNotificationDialog> createState() => _ParentNotificationDialogState();
}

class _ParentNotificationDialogState extends State<ParentNotificationDialog>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // إعداد الأنيميشن
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // بدء الأنيميشن
    _slideController.forward();
    _fadeController.forward();
    
    // نبضة للإشعارات العاجلة
    if (widget.notification.priority == ParentNotificationPriority.urgent) {
      _pulseController.repeat(reverse: true);
    }

    // إخفاء تلقائي بعد 6 ثوان
    Timer(const Duration(seconds: 6), () {
      if (mounted) {
        _dismissDialog();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
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
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 400),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _getPriorityColor().withOpacity(0.3),
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
                                  gradient: LinearGradient(
                                    colors: [
                                      _getPriorityColor(),
                                      _getPriorityColor().withOpacity(0.8),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
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
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            widget.notification.typeIcon,
                                            style: const TextStyle(fontSize: 28),
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
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: Text(
                                                      widget.notification.priorityText,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  if (widget.notification.isNew) ...[
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.yellow.withOpacity(0.9),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: const Text(
                                                        'جديد',
                                                        style: TextStyle(
                                                          color: Colors.black87,
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
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
                                            size: 22,
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
                                    
                                    // معلومات إضافية
                                    if (widget.notification.isStudentRelated || 
                                        widget.notification.isBusRelated) ...[
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey[200]!),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (widget.notification.studentName != null) ...[
                                              Row(
                                                children: [
                                                  const Icon(Icons.person, size: 16, color: Colors.grey),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'الطالب: ${widget.notification.studentName}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                            if (widget.notification.busNumber != null) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(Icons.directions_bus, size: 16, color: Colors.grey),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'الحافلة: ${widget.notification.busNumber}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                            if (widget.notification.location != null) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      'الموقع: ${widget.notification.location}',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                    
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
                                    
                                    // زر الإجراء (إذا كان مطلوب)
                                    if (widget.notification.requiresAction)
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            // يمكن إضافة منطق الإجراء هنا
                                            HapticFeedback.mediumImpact();
                                          },
                                          icon: const Icon(
                                            Icons.touch_app,
                                            size: 16,
                                          ),
                                          label: Text(widget.notification.actionText ?? 'إجراء'),
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
                                    
                                    if (widget.notification.requiresAction)
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
                                          backgroundColor: widget.notification.requiresAction 
                                              ? Colors.grey[600] 
                                              : _getPriorityColor(),
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
                      );
                    },
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
