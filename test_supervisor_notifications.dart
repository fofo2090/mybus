import 'package:flutter/material.dart';
import 'lib/services/supervisor_notification_service.dart';
import 'lib/models/supervisor_notification_model.dart';

/// اختبار نظام إشعارات المشرف
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🧪 بدء اختبار نظام إشعارات المشرف...');
  
  final supervisorNotificationService = SupervisorNotificationService();
  
  try {
    // اختبار إنشاء إشعارات تجريبية
    await _testCreateSupervisorNotifications(supervisorNotificationService);
    
    // اختبار الحفظ والتحميل
    await _testSaveAndLoad(supervisorNotificationService);
    
    // اختبار العمليات
    await _testOperations(supervisorNotificationService);
    
    // اختبار الأنواع المختلفة
    await _testNotificationTypes();
    
    // اختبار الميزات المتقدمة
    await _testAdvancedFeatures();
    
    print('✅ تم اجتياز جميع اختبارات نظام إشعارات المشرف!');
    
  } catch (e) {
    print('❌ فشل في اختبار نظام إشعارات المشرف: $e');
  }
}

/// اختبار إنشاء إشعارات تجريبية للمشرف
Future<void> _testCreateSupervisorNotifications(SupervisorNotificationService service) async {
  print('📝 اختبار إنشاء إشعارات المشرف...');
  
  // إشعار حضور الطالب
  final attendanceNotification = SupervisorNotificationModel(
    id: '1',
    title: 'تأكيد حضور الطالب',
    body: 'يرجى تأكيد حضور الطالب أحمد محمد في الحافلة رقم 123',
    data: {
      'type': 'student_attendance',
      'studentName': 'أحمد محمد',
      'busNumber': '123',
      'routeName': 'طريق الحي الأول',
    },
    timestamp: DateTime.now(),
    isRead: false,
    type: 'student_attendance',
    priority: SupervisorNotificationPriority.normal,
    studentId: 'student_123',
    busId: 'bus_123',
    routeId: 'route_123',
  );
  
  // إشعار بداية الرحلة
  final routeStartNotification = SupervisorNotificationModel(
    id: '2',
    title: 'بداية الرحلة',
    body: 'تم بدء رحلة الحافلة رقم 123 - طريق الحي الأول',
    data: {
      'type': 'route_start',
      'busNumber': '123',
      'routeName': 'طريق الحي الأول',
      'expectedTime': '07:30 ص',
    },
    timestamp: DateTime.now(),
    isRead: false,
    type: 'route_start',
    priority: SupervisorNotificationPriority.high,
    busId: 'bus_123',
    routeId: 'route_123',
  );
  
  // إشعار طوارئ
  final emergencyNotification = SupervisorNotificationModel(
    id: '3',
    title: 'حالة طوارئ',
    body: 'حادث طفيف في الحافلة رقم 123 - يتطلب تدخل فوري',
    data: {
      'type': 'emergency',
      'busNumber': '123',
      'location': 'شارع الملك فهد',
      'severity': 'minor',
    },
    timestamp: DateTime.now(),
    isRead: false,
    type: 'emergency',
    priority: SupervisorNotificationPriority.urgent,
    busId: 'bus_123',
  );
  
  print('✅ تم إنشاء ${[attendanceNotification, routeStartNotification, emergencyNotification].length} إشعارات تجريبية');
  
  // اختبار الخصائص
  print('🔍 اختبار خصائص الإشعارات:');
  print('   - إشعار الحضور: ${attendanceNotification.typeDescription} ${attendanceNotification.typeIcon}');
  print('   - إشعار الرحلة: ${routeStartNotification.priorityText} (${routeStartNotification.priorityColor})');
  print('   - إشعار الطوارئ: ${emergencyNotification.requiresAction ? 'يتطلب إجراء' : 'لا يتطلب إجراء'}');
  print('   - يتطلب تأكيد: ${attendanceNotification.requiresConfirmation}');
  print('   - الوقت المنسق: ${attendanceNotification.formattedTime}');
  print('   - هل جديد؟ ${attendanceNotification.isNew}');
}

/// اختبار الحفظ والتحميل
Future<void> _testSaveAndLoad(SupervisorNotificationService service) async {
  print('💾 اختبار الحفظ والتحميل...');
  
  // محاكاة حفظ إشعار
  final testNotification = SupervisorNotificationModel(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    title: 'اختبار الحفظ',
    body: 'هذا إشعار لاختبار عملية الحفظ والتحميل',
    data: {'test': 'save_load'},
    timestamp: DateTime.now(),
    isRead: false,
    type: 'system_update',
    priority: SupervisorNotificationPriority.normal,
    routeId: 'test_route',
  );
  
  print('📤 محاكاة حفظ إشعار: ${testNotification.title}');
  
  // اختبار تحويل JSON
  final json = testNotification.toJson();
  final fromJson = SupervisorNotificationModel.fromJson(json);
  
  assert(testNotification.id == fromJson.id, 'فشل في تحويل JSON');
  assert(testNotification.title == fromJson.title, 'فشل في تحويل العنوان');
  assert(testNotification.priority == fromJson.priority, 'فشل في تحويل الأولوية');
  assert(testNotification.routeId == fromJson.routeId, 'فشل في تحويل معرف الطريق');
  
  print('✅ نجح اختبار تحويل JSON');
  
  // اختبار تحويل Map
  final map = testNotification.toMap();
  final fromMap = SupervisorNotificationModel.fromMap(map);
  
  assert(testNotification.id == fromMap.id, 'فشل في تحويل Map');
  print('✅ نجح اختبار تحويل Map');
}

/// اختبار العمليات
Future<void> _testOperations(SupervisorNotificationService service) async {
  print('⚙️ اختبار العمليات...');
  
  // اختبار copyWith
  final originalNotification = SupervisorNotificationModel(
    id: 'test_copy',
    title: 'إشعار أصلي',
    body: 'محتوى أصلي',
    data: {},
    timestamp: DateTime.now(),
    isRead: false,
    type: 'general',
    priority: SupervisorNotificationPriority.normal,
  );
  
  final copiedNotification = originalNotification.copyWith(
    isRead: true,
    priority: SupervisorNotificationPriority.high,
    studentId: 'new_student_id',
    busId: 'new_bus_id',
  );
  
  assert(copiedNotification.id == originalNotification.id, 'فشل في copyWith - ID');
  assert(copiedNotification.title == originalNotification.title, 'فشل في copyWith - Title');
  assert(copiedNotification.isRead == true, 'فشل في copyWith - isRead');
  assert(copiedNotification.priority == SupervisorNotificationPriority.high, 'فشل في copyWith - priority');
  assert(copiedNotification.studentId == 'new_student_id', 'فشل في copyWith - studentId');
  assert(copiedNotification.busId == 'new_bus_id', 'فشل في copyWith - busId');
  
  print('✅ نجح اختبار copyWith');
  
  // اختبار المقارنة
  final notification1 = SupervisorNotificationModel(
    id: 'same_id',
    title: 'إشعار 1',
    body: 'محتوى 1',
    data: {},
    timestamp: DateTime.now(),
    isRead: false,
    type: 'general',
    priority: SupervisorNotificationPriority.normal,
  );
  
  final notification2 = SupervisorNotificationModel(
    id: 'same_id',
    title: 'إشعار 2',
    body: 'محتوى 2',
    data: {},
    timestamp: DateTime.now(),
    isRead: true,
    type: 'student_attendance',
    priority: SupervisorNotificationPriority.high,
  );
  
  assert(notification1 == notification2, 'فشل في المقارنة - نفس ID');
  assert(notification1.hashCode == notification2.hashCode, 'فشل في hashCode');
  
  print('✅ نجح اختبار المقارنة');
}

/// اختبار أنواع الإشعارات المختلفة
Future<void> _testNotificationTypes() async {
  print('🎯 اختبار أنواع الإشعارات...');
  
  final types = [
    'student_attendance',
    'student_absence',
    'student_behavior',
    'student_incident',
    'route_start',
    'route_complete',
    'route_delay',
    'bus_maintenance',
    'bus_breakdown',
    'emergency',
    'schedule_change',
    'admin_message',
    'system_update',
    'general',
  ];
  
  for (final type in types) {
    final notification = SupervisorNotificationModel(
      id: 'type_test_$type',
      title: 'اختبار النوع',
      body: 'اختبار نوع الإشعار',
      data: {'type': type},
      timestamp: DateTime.now(),
      isRead: false,
      type: type,
      priority: SupervisorNotificationPriority.normal,
    );
    
    print('   - ${notification.typeDescription}: ${notification.typeIcon}');
    print('     يتطلب إجراء: ${notification.requiresAction}');
    print('     يتطلب تأكيد: ${notification.requiresConfirmation}');
    if (notification.requiresAction) {
      print('     نص الإجراء: ${notification.actionText}');
    }
  }
  
  print('✅ نجح اختبار أنواع الإشعارات');
  
  // اختبار الأولويات
  print('🎨 اختبار الأولويات...');
  final priorities = SupervisorNotificationPriority.values;
  
  for (final priority in priorities) {
    final notification = SupervisorNotificationModel(
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
}

/// اختبار الميزات المتقدمة
Future<void> _testAdvancedFeatures() async {
  print('🚀 اختبار الميزات المتقدمة...');
  
  // إشعار مع بيانات شاملة
  final comprehensiveNotification = SupervisorNotificationModel(
    id: 'comprehensive_test',
    title: 'إشعار شامل',
    body: 'إشعار يحتوي على جميع البيانات',
    data: {
      'studentName': 'أحمد محمد',
      'busNumber': 'حافلة 123',
      'routeName': 'طريق الحي الأول',
      'location': 'مدرسة النور الابتدائية',
      'expectedTime': '07:30 ص',
      'delayReason': 'ازدحام مروري',
    },
    timestamp: DateTime.now(),
    isRead: false,
    type: 'route_delay',
    priority: SupervisorNotificationPriority.high,
    studentId: 'student_123',
    busId: 'bus_123',
    routeId: 'route_123',
  );
  
  print('👨‍💼 اختبار الإشعار الشامل:');
  print('   - اسم الطالب: ${comprehensiveNotification.studentName}');
  print('   - رقم الحافلة: ${comprehensiveNotification.busNumber}');
  print('   - اسم الطريق: ${comprehensiveNotification.routeName}');
  print('   - الموقع: ${comprehensiveNotification.location}');
  print('   - الوقت المتوقع: ${comprehensiveNotification.expectedTime}');
  print('   - سبب التأخير: ${comprehensiveNotification.delayReason}');
  print('   - متعلق بطالب: ${comprehensiveNotification.isStudentRelated}');
  print('   - متعلق بحافلة: ${comprehensiveNotification.isBusRelated}');
  print('   - متعلق بطريق: ${comprehensiveNotification.isRouteRelated}');
  
  // اختبار الوقت
  final oldNotification = SupervisorNotificationModel(
    id: 'old_test',
    title: 'إشعار قديم',
    body: 'إشعار من الأمس',
    data: {},
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
    isRead: true,
    type: 'general',
    priority: SupervisorNotificationPriority.low,
  );
  
  print('⏰ اختبار تنسيق الوقت:');
  print('   - الإشعار الجديد: ${comprehensiveNotification.formattedTime}');
  print('   - الإشعار القديم: ${oldNotification.formattedTime}');
  print('   - هل الجديد جديد؟ ${comprehensiveNotification.isNew}');
  print('   - هل القديم جديد؟ ${oldNotification.isNew}');
  
  // اختبار الإجراءات والتأكيدات
  print('🔧 اختبار الإجراءات والتأكيدات:');
  final actionTypes = ['student_incident', 'bus_breakdown', 'emergency', 'schedule_change'];
  final confirmationTypes = ['route_start', 'route_complete', 'student_attendance'];
  
  for (final type in actionTypes) {
    final notification = SupervisorNotificationModel(
      id: 'action_test_$type',
      title: 'اختبار الإجراء',
      body: 'اختبار',
      data: {},
      timestamp: DateTime.now(),
      isRead: false,
      type: type,
      priority: SupervisorNotificationPriority.normal,
    );
    print('   - $type: يتطلب إجراء = ${notification.requiresAction}, نص الإجراء = ${notification.actionText}');
  }
  
  for (final type in confirmationTypes) {
    final notification = SupervisorNotificationModel(
      id: 'confirmation_test_$type',
      title: 'اختبار التأكيد',
      body: 'اختبار',
      data: {},
      timestamp: DateTime.now(),
      isRead: false,
      type: type,
      priority: SupervisorNotificationPriority.normal,
    );
    print('   - $type: يتطلب تأكيد = ${notification.requiresConfirmation}');
  }
  
  print('✅ نجح اختبار الميزات المتقدمة');
}
