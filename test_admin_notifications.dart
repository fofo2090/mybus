import 'package:flutter/material.dart';
import 'lib/services/admin_notification_service.dart';
import 'lib/models/admin_notification_model.dart';

/// اختبار نظام إشعارات الأدمن
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🧪 بدء اختبار نظام إشعارات الأدمن...');
  
  final adminNotificationService = AdminNotificationService();
  
  try {
    // اختبار إنشاء إشعارات تجريبية
    await _testCreateNotifications(adminNotificationService);
    
    // اختبار الحفظ والتحميل
    await _testSaveAndLoad(adminNotificationService);
    
    // اختبار العمليات
    await _testOperations(adminNotificationService);
    
    print('✅ تم اجتياز جميع اختبارات نظام إشعارات الأدمن!');
    
  } catch (e) {
    print('❌ فشل في اختبار نظام إشعارات الأدمن: $e');
  }
}

/// اختبار إنشاء إشعارات تجريبية
Future<void> _testCreateNotifications(AdminNotificationService service) async {
  print('📝 اختبار إنشاء الإشعارات...');
  
  // إشعار عادي
  final normalNotification = AdminNotificationModel(
    id: '1',
    title: 'إشعار تجريبي عادي',
    body: 'هذا إشعار تجريبي للاختبار',
    data: {'type': 'test', 'source': 'unit_test'},
    timestamp: DateTime.now(),
    isRead: false,
    type: 'general',
    priority: NotificationPriority.normal,
  );
  
  // إشعار عاجل
  final urgentNotification = AdminNotificationModel(
    id: '2',
    title: 'إشعار طوارئ',
    body: 'هذا إشعار طوارئ يتطلب انتباه فوري',
    data: {'type': 'emergency', 'source': 'unit_test'},
    timestamp: DateTime.now(),
    isRead: false,
    type: 'emergency',
    priority: NotificationPriority.urgent,
  );
  
  // إشعار طالب
  final studentNotification = AdminNotificationModel(
    id: '3',
    title: 'إشعار طالب جديد',
    body: 'تم تسجيل طالب جديد في النظام',
    data: {'type': 'student', 'studentId': 'student_123'},
    timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
    isRead: false,
    type: 'student',
    priority: NotificationPriority.high,
  );
  
  print('✅ تم إنشاء ${[normalNotification, urgentNotification, studentNotification].length} إشعارات تجريبية');
  
  // اختبار الخصائص
  print('🔍 اختبار خصائص الإشعارات:');
  print('   - الإشعار العادي: ${normalNotification.priorityText} (${normalNotification.priorityColor})');
  print('   - الإشعار العاجل: ${urgentNotification.priorityText} (${urgentNotification.priorityColor})');
  print('   - إشعار الطالب: ${studentNotification.typeDescription} ${studentNotification.typeIcon}');
  print('   - الوقت المنسق: ${studentNotification.formattedTime}');
  print('   - هل جديد؟ ${normalNotification.isNew}');
}

/// اختبار الحفظ والتحميل
Future<void> _testSaveAndLoad(AdminNotificationService service) async {
  print('💾 اختبار الحفظ والتحميل...');
  
  // محاكاة حفظ إشعار
  final testNotification = AdminNotificationModel(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    title: 'اختبار الحفظ',
    body: 'هذا إشعار لاختبار عملية الحفظ والتحميل',
    data: {'test': 'save_load'},
    timestamp: DateTime.now(),
    isRead: false,
    type: 'system',
    priority: NotificationPriority.normal,
  );
  
  print('📤 محاكاة حفظ إشعار: ${testNotification.title}');
  
  // اختبار تحويل JSON
  final json = testNotification.toJson();
  final fromJson = AdminNotificationModel.fromJson(json);
  
  assert(testNotification.id == fromJson.id, 'فشل في تحويل JSON');
  assert(testNotification.title == fromJson.title, 'فشل في تحويل العنوان');
  assert(testNotification.priority == fromJson.priority, 'فشل في تحويل الأولوية');
  
  print('✅ نجح اختبار تحويل JSON');
  
  // اختبار تحويل Map
  final map = testNotification.toMap();
  final fromMap = AdminNotificationModel.fromMap(map);
  
  assert(testNotification.id == fromMap.id, 'فشل في تحويل Map');
  print('✅ نجح اختبار تحويل Map');
}

/// اختبار العمليات
Future<void> _testOperations(AdminNotificationService service) async {
  print('⚙️ اختبار العمليات...');
  
  // اختبار copyWith
  final originalNotification = AdminNotificationModel(
    id: 'test_copy',
    title: 'إشعار أصلي',
    body: 'محتوى أصلي',
    data: {},
    timestamp: DateTime.now(),
    isRead: false,
    type: 'general',
    priority: NotificationPriority.normal,
  );
  
  final copiedNotification = originalNotification.copyWith(
    isRead: true,
    priority: NotificationPriority.high,
  );
  
  assert(copiedNotification.id == originalNotification.id, 'فشل في copyWith - ID');
  assert(copiedNotification.title == originalNotification.title, 'فشل في copyWith - Title');
  assert(copiedNotification.isRead == true, 'فشل في copyWith - isRead');
  assert(copiedNotification.priority == NotificationPriority.high, 'فشل في copyWith - priority');
  
  print('✅ نجح اختبار copyWith');
  
  // اختبار المقارنة
  final notification1 = AdminNotificationModel(
    id: 'same_id',
    title: 'إشعار 1',
    body: 'محتوى 1',
    data: {},
    timestamp: DateTime.now(),
    isRead: false,
    type: 'general',
    priority: NotificationPriority.normal,
  );
  
  final notification2 = AdminNotificationModel(
    id: 'same_id',
    title: 'إشعار 2',
    body: 'محتوى 2',
    data: {},
    timestamp: DateTime.now(),
    isRead: true,
    type: 'student',
    priority: NotificationPriority.high,
  );
  
  assert(notification1 == notification2, 'فشل في المقارنة - نفس ID');
  assert(notification1.hashCode == notification2.hashCode, 'فشل في hashCode');
  
  print('✅ نجح اختبار المقارنة');
  
  // اختبار الأولويات
  final priorities = [
    NotificationPriority.low,
    NotificationPriority.normal,
    NotificationPriority.high,
    NotificationPriority.urgent,
  ];
  
  for (final priority in priorities) {
    final notification = AdminNotificationModel(
      id: 'priority_test',
      title: 'اختبار الأولوية',
      body: 'اختبار',
      data: {},
      timestamp: DateTime.now(),
      isRead: false,
      type: 'general',
      priority: priority,
    );
    
    print('   - ${notification.priorityText}: ${notification.priorityColor}');
  }
  
  print('✅ نجح اختبار الأولويات');
  
  // اختبار الأنواع
  final types = ['student', 'bus', 'complaint', 'emergency', 'system', 'backup', 'general'];
  
  for (final type in types) {
    final notification = AdminNotificationModel(
      id: 'type_test',
      title: 'اختبار النوع',
      body: 'اختبار',
      data: {},
      timestamp: DateTime.now(),
      isRead: false,
      type: type,
      priority: NotificationPriority.normal,
    );
    
    print('   - ${notification.typeDescription}: ${notification.typeIcon}');
  }
  
  print('✅ نجح اختبار الأنواع');
}

/// اختبار الأداء
Future<void> _testPerformance() async {
  print('🚀 اختبار الأداء...');
  
  final stopwatch = Stopwatch()..start();
  
  // إنشاء 1000 إشعار
  final notifications = <AdminNotificationModel>[];
  for (int i = 0; i < 1000; i++) {
    notifications.add(AdminNotificationModel(
      id: 'perf_test_$i',
      title: 'إشعار رقم $i',
      body: 'محتوى الإشعار رقم $i',
      data: {'index': i.toString()},
      timestamp: DateTime.now().subtract(Duration(minutes: i)),
      isRead: i % 2 == 0,
      type: ['general', 'student', 'bus', 'emergency'][i % 4],
      priority: NotificationPriority.values[i % 4],
    ));
  }
  
  stopwatch.stop();
  print('⏱️ إنشاء 1000 إشعار: ${stopwatch.elapsedMilliseconds}ms');
  
  // اختبار تحويل JSON
  stopwatch.reset();
  stopwatch.start();
  
  final jsonList = notifications.map((n) => n.toJson()).toList();
  
  stopwatch.stop();
  print('⏱️ تحويل 1000 إشعار إلى JSON: ${stopwatch.elapsedMilliseconds}ms');
  
  // اختبار استرجاع من JSON
  stopwatch.reset();
  stopwatch.start();
  
  final fromJsonList = jsonList.map((json) => AdminNotificationModel.fromJson(json)).toList();
  
  stopwatch.stop();
  print('⏱️ استرجاع 1000 إشعار من JSON: ${stopwatch.elapsedMilliseconds}ms');
  
  assert(fromJsonList.length == notifications.length, 'فشل في اختبار الأداء');
  print('✅ نجح اختبار الأداء');
}
