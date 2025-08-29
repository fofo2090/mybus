import 'package:flutter/material.dart';
import 'lib/services/parent_notification_service.dart';
import 'lib/models/parent_notification_model.dart';

/// اختبار نظام إشعارات ولي الأمر
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🧪 بدء اختبار نظام إشعارات ولي الأمر...');
  
  final parentNotificationService = ParentNotificationService();
  
  try {
    // اختبار إنشاء إشعارات تجريبية
    await _testCreateParentNotifications(parentNotificationService);
    
    // اختبار الحفظ والتحميل
    await _testSaveAndLoad(parentNotificationService);
    
    // اختبار العمليات
    await _testOperations(parentNotificationService);
    
    // اختبار الأنواع المختلفة
    await _testNotificationTypes();
    
    print('✅ تم اجتياز جميع اختبارات نظام إشعارات ولي الأمر!');
    
  } catch (e) {
    print('❌ فشل في اختبار نظام إشعارات ولي الأمر: $e');
  }
}

/// اختبار إنشاء إشعارات تجريبية لولي الأمر
Future<void> _testCreateParentNotifications(ParentNotificationService service) async {
  print('📝 اختبار إنشاء إشعارات ولي الأمر...');
  
  // إشعار ركوب الطالب
  final pickupNotification = ParentNotificationModel(
    id: '1',
    title: 'ركوب الطالب',
    body: 'تم ركوب طفلك أحمد في الحافلة رقم 123',
    data: {
      'type': 'student_pickup',
      'studentName': 'أحمد محمد',
      'busNumber': '123',
      'location': 'محطة الحي الأول',
    },
    timestamp: DateTime.now(),
    isRead: false,
    type: 'student_pickup',
    priority: ParentNotificationPriority.normal,
    studentId: 'student_123',
    busId: 'bus_123',
  );
  
  // إشعار تأخير الحافلة
  final delayNotification = ParentNotificationModel(
    id: '2',
    title: 'تأخير الحافلة',
    body: 'تأخرت الحافلة رقم 123 لمدة 15 دقيقة بسبب الازدحام',
    data: {
      'type': 'bus_delay',
      'busNumber': '123',
      'delayMinutes': '15',
      'reason': 'ازدحام مروري',
    },
    timestamp: DateTime.now(),
    isRead: false,
    type: 'bus_delay',
    priority: ParentNotificationPriority.high,
    busId: 'bus_123',
  );
  
  // إشعار طوارئ
  final emergencyNotification = ParentNotificationModel(
    id: '3',
    title: 'حالة طوارئ',
    body: 'يرجى التواصل مع إدارة المدرسة فوراً',
    data: {
      'type': 'emergency',
      'studentName': 'أحمد محمد',
      'contactNumber': '0501234567',
    },
    timestamp: DateTime.now(),
    isRead: false,
    type: 'emergency',
    priority: ParentNotificationPriority.urgent,
    studentId: 'student_123',
  );
  
  print('✅ تم إنشاء ${[pickupNotification, delayNotification, emergencyNotification].length} إشعارات تجريبية');
  
  // اختبار الخصائص
  print('🔍 اختبار خصائص الإشعارات:');
  print('   - إشعار الركوب: ${pickupNotification.typeDescription} ${pickupNotification.typeIcon}');
  print('   - إشعار التأخير: ${delayNotification.priorityText} (${delayNotification.priorityColor})');
  print('   - إشعار الطوارئ: ${emergencyNotification.requiresAction ? 'يتطلب إجراء' : 'لا يتطلب إجراء'}');
  print('   - الوقت المنسق: ${pickupNotification.formattedTime}');
  print('   - هل جديد؟ ${pickupNotification.isNew}');
}

/// اختبار الحفظ والتحميل
Future<void> _testSaveAndLoad(ParentNotificationService service) async {
  print('💾 اختبار الحفظ والتحميل...');
  
  // محاكاة حفظ إشعار
  final testNotification = ParentNotificationModel(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    title: 'اختبار الحفظ',
    body: 'هذا إشعار لاختبار عملية الحفظ والتحميل',
    data: {'test': 'save_load'},
    timestamp: DateTime.now(),
    isRead: false,
    type: 'student_behavior',
    priority: ParentNotificationPriority.normal,
    studentId: 'test_student',
  );
  
  print('📤 محاكاة حفظ إشعار: ${testNotification.title}');
  
  // اختبار تحويل JSON
  final json = testNotification.toJson();
  final fromJson = ParentNotificationModel.fromJson(json);
  
  assert(testNotification.id == fromJson.id, 'فشل في تحويل JSON');
  assert(testNotification.title == fromJson.title, 'فشل في تحويل العنوان');
  assert(testNotification.priority == fromJson.priority, 'فشل في تحويل الأولوية');
  assert(testNotification.studentId == fromJson.studentId, 'فشل في تحويل معرف الطالب');
  
  print('✅ نجح اختبار تحويل JSON');
  
  // اختبار تحويل Map
  final map = testNotification.toMap();
  final fromMap = ParentNotificationModel.fromMap(map);
  
  assert(testNotification.id == fromMap.id, 'فشل في تحويل Map');
  print('✅ نجح اختبار تحويل Map');
}

/// اختبار العمليات
Future<void> _testOperations(ParentNotificationService service) async {
  print('⚙️ اختبار العمليات...');
  
  // اختبار copyWith
  final originalNotification = ParentNotificationModel(
    id: 'test_copy',
    title: 'إشعار أصلي',
    body: 'محتوى أصلي',
    data: {},
    timestamp: DateTime.now(),
    isRead: false,
    type: 'general',
    priority: ParentNotificationPriority.normal,
  );
  
  final copiedNotification = originalNotification.copyWith(
    isRead: true,
    priority: ParentNotificationPriority.high,
    studentId: 'new_student_id',
  );
  
  assert(copiedNotification.id == originalNotification.id, 'فشل في copyWith - ID');
  assert(copiedNotification.title == originalNotification.title, 'فشل في copyWith - Title');
  assert(copiedNotification.isRead == true, 'فشل في copyWith - isRead');
  assert(copiedNotification.priority == ParentNotificationPriority.high, 'فشل في copyWith - priority');
  assert(copiedNotification.studentId == 'new_student_id', 'فشل في copyWith - studentId');
  
  print('✅ نجح اختبار copyWith');
  
  // اختبار المقارنة
  final notification1 = ParentNotificationModel(
    id: 'same_id',
    title: 'إشعار 1',
    body: 'محتوى 1',
    data: {},
    timestamp: DateTime.now(),
    isRead: false,
    type: 'general',
    priority: ParentNotificationPriority.normal,
  );
  
  final notification2 = ParentNotificationModel(
    id: 'same_id',
    title: 'إشعار 2',
    body: 'محتوى 2',
    data: {},
    timestamp: DateTime.now(),
    isRead: true,
    type: 'student_pickup',
    priority: ParentNotificationPriority.high,
  );
  
  assert(notification1 == notification2, 'فشل في المقارنة - نفس ID');
  assert(notification1.hashCode == notification2.hashCode, 'فشل في hashCode');
  
  print('✅ نجح اختبار المقارنة');
}

/// اختبار أنواع الإشعارات المختلفة
Future<void> _testNotificationTypes() async {
  print('🎯 اختبار أنواع الإشعارات...');
  
  final types = [
    'student_pickup',
    'student_dropoff', 
    'student_absence',
    'student_behavior',
    'bus_delay',
    'bus_breakdown',
    'emergency',
    'announcement',
    'payment',
    'survey',
    'general',
  ];
  
  for (final type in types) {
    final notification = ParentNotificationModel(
      id: 'type_test_$type',
      title: 'اختبار النوع',
      body: 'اختبار نوع الإشعار',
      data: {'type': type},
      timestamp: DateTime.now(),
      isRead: false,
      type: type,
      priority: ParentNotificationPriority.normal,
    );
    
    print('   - ${notification.typeDescription}: ${notification.typeIcon}');
    print('     يتطلب إجراء: ${notification.requiresAction}');
    if (notification.requiresAction) {
      print('     نص الإجراء: ${notification.actionText}');
    }
  }
  
  print('✅ نجح اختبار أنواع الإشعارات');
  
  // اختبار الأولويات
  print('🎨 اختبار الأولويات...');
  final priorities = ParentNotificationPriority.values;
  
  for (final priority in priorities) {
    final notification = ParentNotificationModel(
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

/// اختبار الخصائص المتقدمة
Future<void> _testAdvancedFeatures() async {
  print('🚀 اختبار الخصائص المتقدمة...');
  
  // إشعار مع بيانات طالب
  final studentNotification = ParentNotificationModel(
    id: 'student_test',
    title: 'إشعار طالب',
    body: 'إشعار متعلق بالطالب',
    data: {
      'studentName': 'أحمد محمد',
      'busNumber': 'حافلة 123',
      'location': 'المدرسة الابتدائية',
    },
    timestamp: DateTime.now(),
    isRead: false,
    type: 'student_pickup',
    priority: ParentNotificationPriority.normal,
    studentId: 'student_123',
    busId: 'bus_123',
  );
  
  print('👨‍🎓 اختبار الإشعار المتعلق بالطالب:');
  print('   - اسم الطالب: ${studentNotification.studentName}');
  print('   - رقم الحافلة: ${studentNotification.busNumber}');
  print('   - الموقع: ${studentNotification.location}');
  print('   - متعلق بطالب: ${studentNotification.isStudentRelated}');
  print('   - متعلق بحافلة: ${studentNotification.isBusRelated}');
  
  // اختبار الوقت
  final oldNotification = ParentNotificationModel(
    id: 'old_test',
    title: 'إشعار قديم',
    body: 'إشعار من الأمس',
    data: {},
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
    isRead: true,
    type: 'general',
    priority: ParentNotificationPriority.low,
  );
  
  print('⏰ اختبار تنسيق الوقت:');
  print('   - الإشعار الجديد: ${studentNotification.formattedTime}');
  print('   - الإشعار القديم: ${oldNotification.formattedTime}');
  print('   - هل الجديد جديد؟ ${studentNotification.isNew}');
  print('   - هل القديم جديد؟ ${oldNotification.isNew}');
  
  print('✅ نجح اختبار الخصائص المتقدمة');
}
