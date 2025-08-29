import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// إرسال إيميل إشعار لولي الأمر
  Future<void> sendParentNotification({
    required String parentEmail,
    required String parentName,
    required String title,
    required String message,
    String? studentName,
  }) async {
    try {
      // إضافة الإيميل إلى قائمة الانتظار في Firebase
      await _firestore.collection('email_queue').add({
        'to': parentEmail,
        'subject': title,
        'html': _buildEmailTemplate(
          parentName: parentName,
          title: title,
          message: message,
          studentName: studentName,
        ),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'parent_notification',
      });

      debugPrint('✅ تم إضافة الإيميل إلى قائمة الانتظار: $parentEmail');
    } catch (e) {
      debugPrint('❌ خطأ في إرسال الإيميل: $e');
      throw Exception('فشل في إرسال الإيميل');
    }
  }

  /// إرسال إيميل ترحيب لولي أمر جديد
  Future<void> sendWelcomeEmail({
    required String parentEmail,
    required String parentName,
    required String password,
  }) async {
    try {
      await _firestore.collection('email_queue').add({
        'to': parentEmail,
        'subject': 'مرحباً بك في تطبيق MyBus',
        'html': _buildWelcomeEmailTemplate(
          parentName: parentName,
          email: parentEmail,
          password: password,
        ),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'welcome_email',
      });

      debugPrint('✅ تم إرسال إيميل الترحيب إلى: $parentEmail');
    } catch (e) {
      debugPrint('❌ خطأ في إرسال إيميل الترحيب: $e');
    }
  }

  /// إرسال إيميل تحديث حالة الطالب
  Future<void> sendStudentStatusUpdate({
    required String parentEmail,
    required String parentName,
    required String studentName,
    required String status,
    required String location,
    required DateTime timestamp,
  }) async {
    try {
      await _firestore.collection('email_queue').add({
        'to': parentEmail,
        'subject': 'تحديث حالة $studentName',
        'html': _buildStatusUpdateEmailTemplate(
          parentName: parentName,
          studentName: studentName,
          status: status,
          location: location,
          timestamp: timestamp,
        ),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'status_update',
      });

      debugPrint('✅ تم إرسال تحديث الحالة إلى: $parentEmail');
    } catch (e) {
      debugPrint('❌ خطأ في إرسال تحديث الحالة: $e');
    }
  }

  /// بناء قالب الإيميل العام
  String _buildEmailTemplate({
    required String parentName,
    required String title,
    required String message,
    String? studentName,
  }) {
    return '''
    <!DOCTYPE html>
    <html dir="rtl" lang="ar">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>$title</title>
        <style>
            body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                line-height: 1.6;
                color: #333;
                background-color: #f4f4f4;
                margin: 0;
                padding: 20px;
            }
            .container {
                max-width: 600px;
                margin: 0 auto;
                background: white;
                border-radius: 10px;
                box-shadow: 0 0 20px rgba(0,0,0,0.1);
                overflow: hidden;
            }
            .header {
                background: linear-gradient(135deg, #1E88E5, #42A5F5);
                color: white;
                padding: 30px;
                text-align: center;
            }
            .header h1 {
                margin: 0;
                font-size: 28px;
            }
            .content {
                padding: 30px;
            }
            .greeting {
                font-size: 18px;
                color: #1E88E5;
                margin-bottom: 20px;
            }
            .message {
                background: #f8f9fa;
                padding: 20px;
                border-radius: 8px;
                border-left: 4px solid #1E88E5;
                margin: 20px 0;
            }
            .footer {
                background: #f8f9fa;
                padding: 20px;
                text-align: center;
                color: #666;
                border-top: 1px solid #eee;
            }
            .app-info {
                background: #e3f2fd;
                padding: 15px;
                border-radius: 8px;
                margin: 20px 0;
                text-align: center;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🚌 MyBus</h1>
                <p>نظام إدارة النقل المدرسي</p>
            </div>
            
            <div class="content">
                <div class="greeting">
                    مرحباً $parentName،
                </div>
                
                <div class="message">
                    <h3>$title</h3>
                    <p>$message</p>
                    ${studentName != null ? '<p><strong>الطالب:</strong> $studentName</p>' : ''}
                </div>
                
                <div class="app-info">
                    <p><strong>💡 نصيحة:</strong> يمكنك متابعة جميع التحديثات من خلال تطبيق MyBus</p>
                </div>
            </div>
            
            <div class="footer">
                <p>هذا إيميل تلقائي من تطبيق MyBus</p>
                <p>© 2024 MyBus - جميع الحقوق محفوظة</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  /// بناء قالب إيميل الترحيب
  String _buildWelcomeEmailTemplate({
    required String parentName,
    required String email,
    required String password,
  }) {
    return '''
    <!DOCTYPE html>
    <html dir="rtl" lang="ar">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>مرحباً بك في MyBus</title>
        <style>
            body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                line-height: 1.6;
                color: #333;
                background-color: #f4f4f4;
                margin: 0;
                padding: 20px;
            }
            .container {
                max-width: 600px;
                margin: 0 auto;
                background: white;
                border-radius: 10px;
                box-shadow: 0 0 20px rgba(0,0,0,0.1);
                overflow: hidden;
            }
            .header {
                background: linear-gradient(135deg, #1E88E5, #42A5F5);
                color: white;
                padding: 30px;
                text-align: center;
            }
            .content {
                padding: 30px;
            }
            .credentials {
                background: #e8f5e8;
                padding: 20px;
                border-radius: 8px;
                border: 2px solid #4caf50;
                margin: 20px 0;
            }
            .footer {
                background: #f8f9fa;
                padding: 20px;
                text-align: center;
                color: #666;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🎉 مرحباً بك في MyBus!</h1>
                <p>نظام إدارة النقل المدرسي</p>
            </div>
            
            <div class="content">
                <h2>أهلاً وسهلاً $parentName</h2>
                
                <p>نحن سعداء لانضمامك إلى عائلة MyBus! تم إنشاء حسابك بنجاح.</p>
                
                <div class="credentials">
                    <h3>🔐 بيانات تسجيل الدخول:</h3>
                    <p><strong>البريد الإلكتروني:</strong> $email</p>
                    <p><strong>كلمة المرور:</strong> $password</p>
                    <p><em>⚠️ يرجى تغيير كلمة المرور بعد أول تسجيل دخول</em></p>
                </div>
                
                <h3>✨ ما يمكنك فعله الآن:</h3>
                <ul>
                    <li>📱 تحميل تطبيق MyBus</li>
                    <li>👀 متابعة حالة أطفالك في الوقت الفعلي</li>
                    <li>📍 معرفة موقع الباص المدرسي</li>
                    <li>🔔 استقبال إشعارات فورية</li>
                    <li>📊 مراجعة تقارير الحضور والغياب</li>
                </ul>
            </div>
            
            <div class="footer">
                <p>إذا كان لديك أي استفسار، لا تتردد في التواصل معنا</p>
                <p>© 2024 MyBus - جميع الحقوق محفوظة</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  /// بناء قالب إيميل تحديث الحالة
  String _buildStatusUpdateEmailTemplate({
    required String parentName,
    required String studentName,
    required String status,
    required String location,
    required DateTime timestamp,
  }) {
    String statusIcon = '';
    String statusColor = '';
    
    switch (status) {
      case 'onBus':
        statusIcon = '🚌';
        statusColor = '#ff9800';
        break;
      case 'atSchool':
        statusIcon = '🏫';
        statusColor = '#2196f3';
        break;
      case 'home':
        statusIcon = '🏠';
        statusColor = '#4caf50';
        break;
      default:
        statusIcon = '📍';
        statusColor = '#666';
    }

    return '''
    <!DOCTYPE html>
    <html dir="rtl" lang="ar">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>تحديث حالة $studentName</title>
        <style>
            body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                line-height: 1.6;
                color: #333;
                background-color: #f4f4f4;
                margin: 0;
                padding: 20px;
            }
            .container {
                max-width: 600px;
                margin: 0 auto;
                background: white;
                border-radius: 10px;
                box-shadow: 0 0 20px rgba(0,0,0,0.1);
                overflow: hidden;
            }
            .header {
                background: linear-gradient(135deg, #1E88E5, #42A5F5);
                color: white;
                padding: 30px;
                text-align: center;
            }
            .content {
                padding: 30px;
            }
            .status-update {
                background: #f8f9fa;
                padding: 20px;
                border-radius: 8px;
                border-left: 4px solid $statusColor;
                margin: 20px 0;
                text-align: center;
            }
            .footer {
                background: #f8f9fa;
                padding: 20px;
                text-align: center;
                color: #666;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>📍 تحديث الموقع</h1>
                <p>MyBus - نظام إدارة النقل المدرسي</p>
            </div>
            
            <div class="content">
                <h2>مرحباً $parentName</h2>
                
                <div class="status-update">
                    <h3>$statusIcon تحديث حالة $studentName</h3>
                    <p><strong>الحالة الحالية:</strong> $status</p>
                    <p><strong>الموقع:</strong> $location</p>
                    <p><strong>الوقت:</strong> ${timestamp.toString()}</p>
                </div>
                
                <p>يمكنك متابعة جميع التحديثات من خلال تطبيق MyBus على هاتفك.</p>
            </div>
            
            <div class="footer">
                <p>هذا إيميل تلقائي من تطبيق MyBus</p>
                <p>© 2024 MyBus - جميع الحقوق محفوظة</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }
}
