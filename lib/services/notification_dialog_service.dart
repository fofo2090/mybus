import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';

/// خدمة عرض dialog الإشعارات التفاعلية
class NotificationDialogService {
  static final NotificationDialogService _instance = NotificationDialogService._internal();
  factory NotificationDialogService() => _instance;
  NotificationDialogService._internal();

  static GlobalKey<NavigatorState>? _navigatorKey;
  
  /// تعيين مفتاح التنقل الرئيسي
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// عرض dialog الإشعار التفاعلي
  void showNotificationDialog(RemoteMessage message) {
    try {
      final context = _navigatorKey?.currentContext;
      if (context == null) {
        debugPrint('⚠️ No context available for notification dialog');
        debugPrint('🔍 Navigator key: $_navigatorKey');
        debugPrint('🔍 Navigator key current context: ${_navigatorKey?.currentContext}');

        // محاولة أخرى للحصول على context
        _tryShowDialogWithDelay(message);
        return;
      }

      debugPrint('✅ Context available, showing dialog immediately');
      _showDialogWithContext(context, message);
    } catch (e) {
      debugPrint('❌ Error showing notification dialog: $e');
    }
  }

  /// بناء dialog الإشعار المحسن
  Widget _buildNotificationDialog({
    required BuildContext context,
    required String title,
    required String body,
    required String type,
    required Map<String, dynamic> data,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 15,
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 350,
            maxHeight: 400,
          ),
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getNotificationColor(type),
                _getNotificationColor(type).withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _getNotificationColor(type).withOpacity(0.4),
                blurRadius: 25,
                offset: Offset(0, 15),
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // أيقونة الإشعار مع تأثير نبضة
              TweenAnimationBuilder(
                duration: Duration(seconds: 1),
                tween: Tween<double>(begin: 0.8, end: 1.2),
                builder: (context, double scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _getNotificationIcon(type),
                        size: 45,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              
              SizedBox(height: 20),
              
              // عنوان الإشعار
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: 15),
              
              // محتوى الإشعار
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    body.isNotEmpty ? body : 'لا يوجد محتوى للإشعار',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.95),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              
              SizedBox(height: 25),
              
              // أزرار الإجراءات
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // زر الإغلاق
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        'إغلاق',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 12),
                  
                  // زر عرض التفاصيل (إذا كان هناك إجراء)
                  if (_hasNotificationAction(type, data))
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true).pop();
                          _handleNotificationAction(type, data, context);
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          'عرض التفاصيل',
                          style: TextStyle(
                            color: _getNotificationColor(type),
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              
              SizedBox(height: 10),
              
              // مؤشر الإغلاق التلقائي
              Text(
                'سيتم الإغلاق تلقائياً خلال 8 ثوان',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// الحصول على لون الإشعار حسب النوع
  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'student':
      case 'boarding':
      case 'arrival':
        return Color(0xFF10B981); // أخضر
      case 'absence':
      case 'emergency':
        return Color(0xFFEF4444); // أحمر
      case 'welcome':
      case 'tutorial':
        return Color(0xFF3B82F6); // أزرق
      case 'admin':
      case 'assignment':
        return Color(0xFFF59E0B); // برتقالي
      case 'support':
        return Color(0xFF8B5CF6); // بنفسجي
      default:
        return Color(0xFF6366F1); // نيلي
    }
  }

  /// الحصول على أيقونة الإشعار حسب النوع
  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'student':
      case 'boarding':
        return Icons.directions_bus;
      case 'arrival':
        return Icons.home_rounded;
      case 'absence':
        return Icons.event_busy;
      case 'emergency':
        return Icons.warning_rounded;
      case 'welcome':
        return Icons.celebration;
      case 'tutorial':
        return Icons.school;
      case 'admin':
        return Icons.admin_panel_settings;
      case 'assignment':
        return Icons.assignment_turned_in;
      case 'support':
        return Icons.support_agent;
      default:
        return Icons.notifications_active;
    }
  }

  /// محاولة عرض Dialog مع تأخير
  void _tryShowDialogWithDelay(RemoteMessage message) {
    debugPrint('🔄 Trying to show dialog with delay...');

    // محاولة بعد ثانية واحدة
    Future.delayed(Duration(seconds: 1), () {
      final context = _navigatorKey?.currentContext;
      if (context != null) {
        debugPrint('✅ Context found after delay, showing dialog');
        _showDialogWithContext(context, message);
      } else {
        debugPrint('❌ Still no context after delay');

        // محاولة أخيرة بعد 3 ثوان
        Future.delayed(Duration(seconds: 3), () {
          final context = _navigatorKey?.currentContext;
          if (context != null) {
            debugPrint('✅ Context found after 3 seconds, showing dialog');
            _showDialogWithContext(context, message);
          } else {
            debugPrint('❌ No context available after multiple attempts');
          }
        });
      }
    });
  }

  /// عرض Dialog مع context محدد
  void _showDialogWithContext(BuildContext context, RemoteMessage message) {
    try {
      final title = message.notification?.title ?? 'إشعار جديد';
      // محاولة الحصول على النص من مصادر مختلفة
      String body = message.notification?.body ?? '';
      if (body.isEmpty) {
        body = message.data['body'] ?? message.data['message'] ?? '';
      }
      final notificationType = message.data['type'] ?? 'general';

      // تشغيل اهتزاز للفت الانتباه
      HapticFeedback.vibrate();

      // عرض dialog مع تأثير بصري جذاب
      showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.5),
        builder: (BuildContext dialogContext) => _buildNotificationDialog(
          context: dialogContext,
          title: title,
          body: body,
          type: notificationType,
          data: message.data,
        ),
      );

      // إخفاء Dialog تلقائياً بعد 8 ثوان
      Future.delayed(Duration(seconds: 8), () {
        try {
          if (Navigator.canPop(context)) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        } catch (e) {
          debugPrint('❌ Error auto-closing dialog: $e');
        }
      });

      debugPrint('✅ Notification dialog shown for: $title');
    } catch (e) {
      debugPrint('❌ Error showing dialog with context: $e');
    }
  }

  /// التحقق من وجود إجراء للإشعار
  bool _hasNotificationAction(String type, Map<String, dynamic> data) {
    return data.containsKey('action') ||
           type.toLowerCase() == 'student' ||
           type.toLowerCase() == 'absence' ||
           type.toLowerCase() == 'assignment' ||
           type.toLowerCase() == 'boarding' ||
           type.toLowerCase() == 'arrival';
  }

  /// معالجة إجراء الإشعار
  void _handleNotificationAction(String type, Map<String, dynamic> data, BuildContext context) {
    try {
      final action = data['action'] as String?;
      debugPrint('🎯 Handling notification action: $action for type: $type');
      
      // يمكن إضافة المزيد من الإجراءات هنا حسب الحاجة
      switch (type.toLowerCase()) {
        case 'student':
        case 'boarding':
        case 'arrival':
          _showStudentDetails(data, context);
          break;
        case 'absence':
          _showAbsenceDetails(data, context);
          break;
        case 'assignment':
          _showAssignmentDetails(data, context);
          break;
        default:
          _showGeneralDetails(data, context);
      }
      
    } catch (e) {
      debugPrint('❌ Error handling notification action: $e');
    }
  }

  /// عرض تفاصيل الطالب
  void _showStudentDetails(Map<String, dynamic> data, BuildContext context) {
    final studentName = data['studentName'] ?? 'غير محدد';
    final busRoute = data['busRoute'] ?? 'غير محدد';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تفاصيل الطالب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الطالب: $studentName'),
            Text('خط السير: $busRoute'),
            if (data['timestamp'] != null)
              Text('الوقت: ${data['timestamp']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('موافق'),
          ),
        ],
      ),
    );
  }

  /// عرض تفاصيل الغياب
  void _showAbsenceDetails(Map<String, dynamic> data, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تفاصيل طلب الغياب'),
        content: Text('تفاصيل الغياب: ${data.toString()}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('موافق'),
          ),
        ],
      ),
    );
  }

  /// عرض تفاصيل التكليف
  void _showAssignmentDetails(Map<String, dynamic> data, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تفاصيل التكليف'),
        content: Text('تفاصيل التكليف: ${data.toString()}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('موافق'),
          ),
        ],
      ),
    );
  }

  /// عرض التفاصيل العامة
  void _showGeneralDetails(Map<String, dynamic> data, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تفاصيل الإشعار'),
        content: Text('البيانات: ${data.toString()}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('موافق'),
          ),
        ],
      ),
    );
  }
}
