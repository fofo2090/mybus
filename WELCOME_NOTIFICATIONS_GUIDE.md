# دليل الإشعارات الترحيبية لأولياء الأمور الجدد

## نظرة عامة

تم إضافة نظام شامل للإشعارات الترحيبية لأولياء الأمور الجدد عند تسجيلهم في التطبيق. النظام يوفر تجربة ترحيبية متدرجة ومفيدة للمستخدمين الجدد.

## الملفات الجديدة

### 1. `lib/services/welcome_notification_service.dart`
خدمة متخصصة للإشعارات الترحيبية مع الميزات التالية:
- تسلسل إشعارات ترحيبية متدرج
- إشعارات تعليمية عن استخدام التطبيق
- إشعارات الدعم والمساعدة
- تتبع حالة التسلسل الترحيبي

### 2. `lib/examples/welcome_notification_usage.dart`
أمثلة شاملة على كيفية استخدام الإشعارات الترحيبية مع شاشة اختبار تفاعلية.

## أنواع الإشعارات الترحيبية

### 1. الإشعار الترحيبي الشامل
```dart
await WelcomeNotificationService().sendCompleteWelcomeSequence(
  parentId: parentId,
  parentName: parentName,
  parentEmail: parentEmail,
  parentPhone: parentPhone,
);
```

**التسلسل الزمني:**
- **فوري**: إشعار ترحيبي أساسي
- **بعد 30 ثانية**: تعليمات استخدام التطبيق
- **بعد دقيقتين**: الميزات الرئيسية
- **بعد 5 دقائق**: معلومات الدعم والمساعدة

### 2. الإشعار الترحيبي السريع
```dart
await WelcomeNotificationService().sendQuickWelcome(
  parentId: parentId,
  parentName: parentName,
);
```

### 3. استخدام الخدمة الرئيسية
```dart
await NotificationService().sendWelcomeNotificationToNewParent(
  parentId: parentId,
  parentName: parentName,
  parentEmail: parentEmail,
  parentPhone: parentPhone,
);
```

### 4. استخدام الخدمة المحسنة
```dart
await EnhancedNotificationService().sendWelcomeNotificationToNewParent(
  parentId: parentId,
  parentName: parentName,
  parentEmail: parentEmail,
  parentPhone: parentPhone,
);
```

## محتوى الإشعارات

### الإشعار الترحيبي الأساسي
- **العنوان**: "🎉 أهلاً وسهلاً بك في MyBus"
- **المحتوى**: "مرحباً [اسم ولي الأمر]! تم إنشاء حسابك بنجاح. استمتع بمتابعة رحلة طفلك بأمان."

### إشعار تعليمات التطبيق
- **العنوان**: "📱 كيفية استخدام التطبيق"
- **المحتوى**: دليل سريع للميزات الأساسية

### إشعار الميزات الرئيسية
- **العنوان**: "⭐ الميزات الرئيسية"
- **المحتوى**: عرض للميزات المتاحة في التطبيق

### إشعار الدعم
- **العنوان**: "🆘 الدعم والمساعدة"
- **المحتوى**: معلومات التواصل والدعم

## التكامل مع صفحة التسجيل

### في دالة إنشاء الحساب:
```dart
Future<void> createParentAccount({
  required String name,
  required String email,
  required String password,
  String? phone,
}) async {
  try {
    // إنشاء الحساب
    final userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);
    
    final parentId = userCredential.user!.uid;
    
    // حفظ بيانات المستخدم
    await FirebaseFirestore.instance
        .collection('users')
        .doc(parentId)
        .set({
      'name': name,
      'email': email,
      'phone': phone,
      'userType': 'parent',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    // إرسال الإشعارات الترحيبية
    await WelcomeNotificationService().sendCompleteWelcomeSequence(
      parentId: parentId,
      parentName: name,
      parentEmail: email,
      parentPhone: phone,
    );
    
    print('✅ Parent account created and welcome notifications sent');
  } catch (e) {
    print('❌ Error creating parent account: $e');
  }
}
```

## الميزات المتقدمة

### 1. تتبع حالة التسلسل
```dart
// تحديث خطوة معينة
await WelcomeNotificationService().updateWelcomeStep(parentId, 'app_instructions');

// إكمال التسلسل
await WelcomeNotificationService().completeWelcomeSequence(parentId);
```

### 2. الإحصائيات
```dart
final stats = await WelcomeNotificationService().getWelcomeStats();
print('إجمالي الإشعارات: ${stats['total_welcomes']}');
print('التسلسلات المكتملة: ${stats['completed_sequences']}');
```

### 3. سجلات الترحيب
يتم حفظ سجل لكل ولي أمر جديد في مجموعة `welcome_records`:
```json
{
  "parentId": "user_123",
  "parentName": "أحمد محمد",
  "parentEmail": "ahmed@example.com",
  "welcomeDate": "2024-01-01T10:00:00Z",
  "sequenceCompleted": false,
  "steps": {
    "immediate_welcome": true,
    "app_instructions": false,
    "main_features": false,
    "support_info": false
  }
}
```

## إشعارات الإدمن

عند تسجيل ولي أمر جديد، يتم إرسال إشعار لجميع الإدمن:
- **العنوان**: "👨‍👩‍👧‍👦 تسجيل ولي أمر جديد"
- **المحتوى**: معلومات ولي الأمر الجديد

## الاختبار

### شاشة الاختبار التفاعلية
استخدم `WelcomeNotificationTestScreen` لاختبار جميع أنواع الإشعارات:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => WelcomeNotificationTestScreen(),
  ),
);
```

### اختبار سريع
```dart
final example = WelcomeNotificationUsageExample();

// اختبار الإشعار الشامل
await example.onParentRegistrationComplete(
  parentId: 'test_123',
  parentName: 'أحمد محمد',
  parentEmail: 'ahmed@test.com',
  parentPhone: '0501234567',
);
```

## التخصيص

### تخصيص التوقيت
يمكن تعديل أوقات الإشعارات في `WelcomeNotificationService`:
```dart
// تغيير التوقيت من 30 ثانية إلى دقيقة
Future.delayed(Duration(minutes: 1), () async {
  await _sendAppInstructions(parentId, parentName);
});
```

### تخصيص المحتوى
يمكن تعديل نصوص الإشعارات في الدوال المختلفة:
```dart
await _enhancedService.sendNotificationToUser(
  userId: parentId,
  title: 'عنوان مخصص',
  body: 'محتوى مخصص للإشعار',
  // ...
);
```

## أفضل الممارسات

1. **استخدم الإشعار الشامل** للمستخدمين الجدد تماماً
2. **استخدم الإشعار السريع** للتسجيل السريع أو التحديثات
3. **راقب الإحصائيات** لتحسين تجربة المستخدم
4. **اختبر الإشعارات** قبل النشر في الإنتاج
5. **تأكد من صحة البيانات** قبل إرسال الإشعارات

## الخلاصة

نظام الإشعارات الترحيبية يوفر:
- ✅ تجربة ترحيبية شاملة ومتدرجة
- ✅ تعليم المستخدمين الجدد كيفية استخدام التطبيق
- ✅ إشعارات للإدمن عن التسجيلات الجديدة
- ✅ تتبع وإحصائيات شاملة
- ✅ مرونة في التخصيص والاستخدام
- ✅ سهولة التكامل مع النظام الموجود
