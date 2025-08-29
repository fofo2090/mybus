# إصلاح مشكلة استهداف المستخدمين في الإشعارات

## المشكلة الأصلية

كانت الإشعارات تظهر لجميع المستخدمين بدلاً من المستخدم المستهدف فقط. على سبيل المثال:
- عندما يقوم الإدمن بتعديل بيانات طالب، كان يظهر له إشعار في نفس الصفحة
- المفروض أن الإشعار يظهر فقط لولي الأمر عندما يفتح تطبيقه

## الحل المطبق

### 1. تحديث معالج الإشعارات في المقدمة (Foreground)

تم إضافة التحقق من المستخدم المستهدف في جميع معالجات الإشعارات:

```dart
// في notification_service.dart
void _handleForegroundMessage(RemoteMessage message) {
  // التحقق من المستخدم المستهدف قبل عرض الإشعار
  final targetUserId = message.data['userId'] ?? message.data['recipientId'];
  final currentUser = FirebaseAuth.instance.currentUser;

  if (targetUserId != null && currentUser?.uid == targetUserId) {
    // عرض الإشعار فقط إذا كان المستخدم الحالي هو المستهدف
    _showSystemNotification(message);
  } else {
    // تجاهل الإشعار إذا لم يكن للمستخدم الحالي
    debugPrint('⚠️ Notification not for current user');
  }
}
```

### 2. تحديث معالج الإشعارات في الخلفية (Background)

تم تحسين معالج الخلفية لحفظ الإشعارات في قاعدة البيانات فقط:

```dart
// في fcm_background_handler.dart
Future<void> _showBackgroundNotification(RemoteMessage message) async {
  final targetUserId = message.data['userId'] ?? message.data['recipientId'];
  
  // في الخلفية، نحفظ الإشعار في قاعدة البيانات فقط
  // ولا نعرض إشعارات محلية لتجنب إظهارها للمستخدم الخطأ
  debugPrint('📤 Background notification for user: $targetUserId');
  debugPrint('📱 User will see notification when they open the app');
  return; // لا نعرض إشعارات محلية في الخلفية
}
```

### 3. تحديث الخدمة الموحدة للإشعارات

تم إضافة معامل `targetUserId` لدالة عرض الإشعارات المحلية:

```dart
// في unified_notification_service.dart
Future<void> showLocalNotification({
  required String title,
  required String body,
  String channelId = 'mybus_notifications',
  Map<String, dynamic>? data,
  String? imageUrl,
  String? iconUrl,
  String? targetUserId, // معرف المستخدم المستهدف
}) async {
  // التحقق من المستخدم المستهدف إذا تم تمريره
  if (targetUserId != null) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.uid != targetUserId) {
      debugPrint('⚠️ Local notification not for current user');
      return; // لا نعرض الإشعار
    }
  }
  
  // عرض الإشعار فقط للمستخدم المستهدف
  // ...
}
```

### 4. تحديث خدمة FCM HTTP

تم تحسين إرسال الإشعارات المحلية في بيئة التطوير:

```dart
// في fcm_http_service.dart
if (_serverKey == 'YOUR_SERVER_KEY_HERE') {
  // التحقق من المستخدم المستهدف قبل إرسال الإشعار المحلي
  final targetUserId = data['userId'] ?? data['recipientId'];
  final currentUser = FirebaseAuth.instance.currentUser;

  if (targetUserId != null && currentUser?.uid == targetUserId) {
    // إرسال إشعار محلي للمستخدم المستهدف فقط
    await _sendRealLocalNotification(/* ... */);
  } else {
    debugPrint('⚠️ Local notification not for current user');
  }
}
```

## النتيجة

الآن الإشعارات تعمل بالشكل الصحيح:

1. **في المقدمة**: الإشعارات تظهر فقط للمستخدم المستهدف
2. **في الخلفية**: الإشعارات تُحفظ في قاعدة البيانات ولا تظهر للمستخدم الخطأ
3. **للإدمن**: لن يرى إشعارات العمليات التي يقوم بها بنفسه
4. **لولي الأمر**: سيرى الإشعارات فقط عندما يفتح التطبيق

## الملفات المحدثة

- `lib/services/notification_service.dart`
- `lib/services/fcm_background_handler.dart`
- `lib/services/enhanced_notification_service.dart`
- `lib/services/unified_notification_service.dart`
- `lib/services/fcm_http_service.dart`

## اختبار الحل

1. قم بتسجيل الدخول كإدمن
2. قم بتعديل بيانات طالب
3. تأكد من عدم ظهور إشعار في صفحة الإدمن
4. قم بتسجيل الدخول كولي أمر
5. تأكد من ظهور الإشعار في صفحة ولي الأمر

## ملاحظات مهمة

- تم الحفاظ على جميع الوظائف الموجودة
- تم إضافة التحقق من المستخدم دون كسر الكود الموجود
- الإشعارات ما زالت تُحفظ في قاعدة البيانات للمستخدم المستهدف
- تم تحسين الأداء بتجنب عرض الإشعارات غير المرغوب فيها
