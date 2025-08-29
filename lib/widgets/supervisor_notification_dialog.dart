import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/supervisor_notification_model.dart';

/// Dialog جميل لعرض إشعارات المشرف
class SupervisorNotificationDialog extends StatefulWidget {
  final SupervisorNotificationModel notification;
  final VoidCallback onDismiss;
  final VoidCallback onMarkAsRead;

  const SupervisorNotificationDialog({
    super.key,
    required this.notification,
    required this.onDismiss,
    required this.onMarkAsRead,
  });

  @override
  State<SupervisorNotificationDialog> createState() => _SupervisorNotificationDialogState();
}

class _SupervisorNotificationDialogState extends State<SupervisorNotificationDialog>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    
    // إعداد الأنيميشن
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.bounceOut,
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
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotateController,
      curve: Curves.linear,
    ));

    // بدء الأنيميشن
    _slideController.forward();
    _fadeController.forward();
    
    // نبضة للإشعارات العاجلة
    if (widget.notification.priority == SupervisorNotificationPriority.urgent) {
      _pulseController.repeat(reverse: true);
    }

    // دوران للإشعارات المتعلقة بالنظام
    if (widget.notification.type.toLowerCase() == 'system_update') {
      _rotateController.repeat();
    }

    // إخفاء تلقائي بعد 7 ثوان
    Timer(const Duration(seconds: 7), () {
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
    _rotateController.dispose();
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
                    animation: Listenable.merge([_pulseAnimation, _rotateAnimation]),
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 420),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: _getPriorityColor().withOpacity(0.4),
                                blurRadius: 25,
                                offset: const Offset(0, 12),
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // الهيدر مع الأولوية
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _getPriorityColor(),
                                      _getPriorityColor().withOpacity(0.7),
                                      _getPriorityColor().withOpacity(0.9),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(24),
                                    topRight: Radius.circular(24),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // أيقونة النوع مع أنيميشن
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.25),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.3),
                                              width: 2,
                                            ),
                                          ),
                                          child: Transform.rotate(
                                            angle: _rotateAnimation.value * 2 * 3.14159,
                                            child: Text(
                                              widget.notification.typeIcon,
                                              style: const TextStyle(fontSize: 32),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        
                                        // معلومات الإشعار
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                widget.notification.typeDescription,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withOpacity(0.25),
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(
                                                        color: Colors.white.withOpacity(0.3),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      widget.notification.priorityText,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  if (widget.notification.isNew) ...[
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.yellow.withOpacity(0.9),
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: const Text(
                                                        'جديد',
                                                        style: TextStyle(
                                                          color: Colors.black87,
                                                          fontSize: 10,
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
                                            size: 24,
                                          ),
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.white.withOpacity(0.2),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              // المحتوى
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // العنوان
                                    Text(
                                      widget.notification.title,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    // المحتوى
                                    Text(
                                      widget.notification.body,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.black54,
                                        height: 1.6,
                                      ),
                                    ),
                                    
                                    // معلومات إضافية
                                    if (widget.notification.isStudentRelated || 
                                        widget.notification.isBusRelated ||
                                        widget.notification.isRouteRelated) ...[
                                      const SizedBox(height: 20),
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: _getPriorityColor().withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _getPriorityColor().withOpacity(0.2),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (widget.notification.studentName != null) ...[
                                              _buildInfoRow(
                                                Icons.person,
                                                'الطالب',
                                                widget.notification.studentName!,
                                              ),
                                            ],
                                            if (widget.notification.busNumber != null) ...[
                                              const SizedBox(height: 8),
                                              _buildInfoRow(
                                                Icons.directions_bus,
                                                'الحافلة',
                                                widget.notification.busNumber!,
                                              ),
                                            ],
                                            if (widget.notification.routeName != null) ...[
                                              const SizedBox(height: 8),
                                              _buildInfoRow(
                                                Icons.route,
                                                'الطريق',
                                                widget.notification.routeName!,
                                              ),
                                            ],
                                            if (widget.notification.location != null) ...[
                                              const SizedBox(height: 8),
                                              _buildInfoRow(
                                                Icons.location_on,
                                                'الموقع',
                                                widget.notification.location!,
                                              ),
                                            ],
                                            if (widget.notification.expectedTime != null) ...[
                                              const SizedBox(height: 8),
                                              _buildInfoRow(
                                                Icons.schedule,
                                                'الوقت المتوقع',
                                                widget.notification.expectedTime!,
                                              ),
                                            ],
                                            if (widget.notification.delayReason != null) ...[
                                              const SizedBox(height: 8),
                                              _buildInfoRow(
                                                Icons.warning,
                                                'سبب التأخير',
                                                widget.notification.delayReason!,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                    
                                    const SizedBox(height: 20),
                                    
                                    // الوقت
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 18,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          widget.notification.formattedTime,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              // الأزرار
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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
                                            size: 18,
                                          ),
                                          label: const Text('تحديد كمقروء'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: _getPriorityColor(),
                                            side: BorderSide(color: _getPriorityColor(), width: 2),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
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
                                            size: 18,
                                          ),
                                          label: Text(widget.notification.actionText ?? 'إجراء'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _getPriorityColor(),
                                            foregroundColor: Colors.white,
                                            elevation: 2,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                        ),
                                      ),
                                    
                                    if (widget.notification.requiresAction)
                                      const SizedBox(width: 12),
                                    
                                    // زر التأكيد (إذا كان مطلوب)
                                    if (widget.notification.requiresConfirmation)
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            // يمكن إضافة منطق التأكيد هنا
                                            HapticFeedback.mediumImpact();
                                          },
                                          icon: const Icon(
                                            Icons.check_circle,
                                            size: 18,
                                          ),
                                          label: const Text('تأكيد'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            elevation: 2,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                        ),
                                      ),
                                    
                                    if (widget.notification.requiresConfirmation)
                                      const SizedBox(width: 12),
                                    
                                    // زر الإغلاق
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _dismissDialog,
                                        icon: const Icon(
                                          Icons.check,
                                          size: 18,
                                        ),
                                        label: const Text('حسناً'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: widget.notification.requiresAction || 
                                                          widget.notification.requiresConfirmation
                                              ? Colors.grey[600] 
                                              : _getPriorityColor(),
                                          foregroundColor: Colors.white,
                                          elevation: 2,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
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

  /// بناء صف معلومات
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _getPriorityColor()),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _getPriorityColor(),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

/// Timer للإخفاء التلقائي
class Timer {
  Timer(Duration duration, VoidCallback callback) {
    Future.delayed(duration, callback);
  }
}
