import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'enhanced_notification_service.dart';
import 'notification_service.dart';

/// خدمة الإشعارات الترحيبية للمستخدمين الجدد
class WelcomeNotificationService {
  static final WelcomeNotificationService _instance = WelcomeNotificationService._internal();
  factory WelcomeNotificationService() => _instance;
  WelcomeNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EnhancedNotificationService _enhancedService = EnhancedNotificationService();
  final NotificationService _notificationService = NotificationService();

  /// إرسال إشعار ترحيبي شامل لولي الأمر الجديد
  Future<void> sendCompleteWelcomeSequence({
    required String parentId,
    required String parentName,
    required String parentEmail,
    String? parentPhone,
  }) async {
    try {
      debugPrint('🎉 Starting complete welcome sequence for: $parentName');

      // 1. إشعار ترحيبي فوري
      await _sendImmediateWelcome(parentId, parentName);

      // 2. إشعار تعليمات التطبيق (بعد 30 ثانية)
      Future.delayed(Duration(seconds: 30), () async {
        await _sendAppInstructions(parentId, parentName);
      });

      // 3. إشعار الميزات الرئيسية (بعد دقيقتين)
      Future.delayed(Duration(minutes: 2), () async {
        await _sendMainFeatures(parentId, parentName);
      });

      // 4. إشعار الدعم والمساعدة (بعد 5 دقائق)
      Future.delayed(Duration(minutes: 5), () async {
        await _sendSupportInfo(parentId, parentName);
      });

      // 5. إشعار للإدمن عن التسجيل الجديد
      await _notifyAdminOfNewRegistration(parentId, parentName, parentEmail, parentPhone);

      // 6. حفظ سجل الترحيب
      await _saveWelcomeRecord(parentId, parentName, parentEmail);

      debugPrint('✅ Complete welcome sequence initiated for: $parentName');
    } catch (e) {
      debugPrint('❌ Error in complete welcome sequence: $e');
    }
  }

  /// إشعار ترحيبي فوري
  Future<void> _sendImmediateWelcome(String parentId, String parentName) async {
    await _enhancedService.sendNotificationToUser(
      userId: parentId,
      title: '🎉 أهلاً وسهلاً بك في MyBus',
      body: 'مرحباً $parentName! تم إنشاء حسابك بنجاح. نحن سعداء لانضمامك إلى عائلة MyBus.',
      type: 'welcome',
      data: {
        'type': 'immediate_welcome',
        'parentId': parentId,
        'parentName': parentName,
        'action': 'welcome',
        'step': '1',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// إشعار تعليمات التطبيق
  Future<void> _sendAppInstructions(String parentId, String parentName) async {
    await _enhancedService.sendNotificationToUser(
      userId: parentId,
      title: '📱 كيفية استخدام التطبيق',
      body: 'مرحباً $parentName! إليك دليل سريع لاستخدام التطبيق:\n• متابعة رحلة طفلك\n• طلب الغياب\n• التواصل مع المشرف',
      type: 'tutorial',
      data: {
        'type': 'app_instructions',
        'parentId': parentId,
        'action': 'show_tutorial',
        'step': '2',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// إشعار الميزات الرئيسية
  Future<void> _sendMainFeatures(String parentId, String parentName) async {
    await _enhancedService.sendNotificationToUser(
      userId: parentId,
      title: '⭐ الميزات الرئيسية',
      body: 'اكتشف ميزات MyBus:\n🚌 تتبع الباص مباشرة\n📍 معرفة موقع طفلك\n📱 إشعارات فورية\n💬 تواصل سهل مع المشرف',
      type: 'features',
      data: {
        'type': 'main_features',
        'parentId': parentId,
        'action': 'show_features',
        'step': '3',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// إشعار الدعم والمساعدة
  Future<void> _sendSupportInfo(String parentId, String parentName) async {
    await _enhancedService.sendNotificationToUser(
      userId: parentId,
      title: '🆘 الدعم والمساعدة',
      body: 'نحن هنا لمساعدتك! إذا كان لديك أي استفسار:\n📞 اتصل بنا\n💬 راسلنا\n❓ اطلع على الأسئلة الشائعة',
      type: 'support',
      data: {
        'type': 'support_info',
        'parentId': parentId,
        'action': 'show_support',
        'step': '4',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// إشعار الإدمن عن التسجيل الجديد
  Future<void> _notifyAdminOfNewRegistration(
    String parentId,
    String parentName,
    String parentEmail,
    String? parentPhone,
  ) async {
    // الحصول على جميع الإدمن
    final admins = await _getAllAdmins();
    
    for (var admin in admins) {
      await _enhancedService.sendNotificationToUser(
        userId: admin['id'],
        title: '👨‍👩‍👧‍👦 تسجيل ولي أمر جديد',
        body: 'تم تسجيل ولي أمر جديد:\n👤 الاسم: $parentName\n📧 البريد: $parentEmail${parentPhone != null ? '\n📱 الهاتف: $parentPhone' : ''}',
        type: 'admin',
        data: {
          'type': 'new_parent_registration',
          'parentId': parentId,
          'parentName': parentName,
          'parentEmail': parentEmail,
          'parentPhone': parentPhone ?? '',
          'registrationDate': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  /// حفظ سجل الترحيب
  Future<void> _saveWelcomeRecord(String parentId, String parentName, String parentEmail) async {
    await _firestore.collection('welcome_records').doc(parentId).set({
      'parentId': parentId,
      'parentName': parentName,
      'parentEmail': parentEmail,
      'welcomeDate': FieldValue.serverTimestamp(),
      'sequenceCompleted': false,
      'steps': {
        'immediate_welcome': true,
        'app_instructions': false,
        'main_features': false,
        'support_info': false,
      },
    });
  }

  /// الحصول على جميع الإدمن
  Future<List<Map<String, dynamic>>> _getAllAdmins() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'admin')
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting admins: $e');
      return [];
    }
  }

  /// إشعار ترحيبي سريع (للاستخدام السريع)
  Future<void> sendQuickWelcome({
    required String parentId,
    required String parentName,
  }) async {
    try {
      debugPrint('🎉 Sending quick welcome to: $parentName');

      await _enhancedService.sendNotificationToUser(
        userId: parentId,
        title: '🎉 مرحباً بك في MyBus',
        body: 'أهلاً وسهلاً $parentName! تم تسجيل حسابك بنجاح. نحن سعداء لانضمامك إلينا.',
        type: 'welcome',
        data: {
          'type': 'quick_welcome',
          'parentId': parentId,
          'parentName': parentName,
          'action': 'welcome',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      debugPrint('✅ Quick welcome sent to: $parentName');
    } catch (e) {
      debugPrint('❌ Error sending quick welcome: $e');
    }
  }

  /// تحديث حالة خطوة الترحيب
  Future<void> updateWelcomeStep(String parentId, String step) async {
    try {
      await _firestore.collection('welcome_records').doc(parentId).update({
        'steps.$step': true,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ Error updating welcome step: $e');
    }
  }

  /// إكمال تسلسل الترحيب
  Future<void> completeWelcomeSequence(String parentId) async {
    try {
      await _firestore.collection('welcome_records').doc(parentId).update({
        'sequenceCompleted': true,
        'completedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Welcome sequence completed for: $parentId');
    } catch (e) {
      debugPrint('❌ Error completing welcome sequence: $e');
    }
  }

  /// الحصول على إحصائيات الترحيب
  Future<Map<String, int>> getWelcomeStats() async {
    try {
      final totalWelcomes = await _firestore
          .collection('welcome_records')
          .count()
          .get();

      final completedSequences = await _firestore
          .collection('welcome_records')
          .where('sequenceCompleted', isEqualTo: true)
          .count()
          .get();

      return {
        'total_welcomes': totalWelcomes.count ?? 0,
        'completed_sequences': completedSequences.count ?? 0,
      };
    } catch (e) {
      debugPrint('❌ Error getting welcome stats: $e');
      return {'total_welcomes': 0, 'completed_sequences': 0};
    }
  }
}
