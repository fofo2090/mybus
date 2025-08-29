# دليل اختبار الإشعارات الشامل 🧪

## نظرة عامة

تم إصلاح وتحسين نظام Firebase Cloud Messaging (FCM) في التطبيق ليدعم:

✅ **الظهور في notification tray** حتى لو الأبلكيشن مقفول أو في الخلفية  
✅ **العمل real-time** عند حدوث أي حدث  
✅ **الدعم الكامل** لـ Android (بما فيه Android 13+) و iOS  

---

## 🔧 التحسينات المطبقة

### 1. Firebase Project Setup
- ✅ تم التأكد من وجود `google-services.json` (Android)
- ✅ تم إنشاء `GoogleService-Info.plist` (iOS)
- ✅ تم ربط الـ app ID مع Firebase project
- ✅ تم تفعيل Cloud Messaging API (HTTP v1)

### 2. Flutter Packages
- ✅ تم تحديث `firebase_core: ^3.15.1`
- ✅ تم تحديث `firebase_messaging: ^15.2.9`
- ✅ تم تحديث `flutter_local_notifications: ^17.2.2`

### 3. Android Configuration
- ✅ تم إضافة `apply plugin: 'com.google.gms.google-services'`
- ✅ تم إضافة صلاحيات Android 13+:
  ```xml
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
  ```
- ✅ تم إنشاء Notification Channels بـ `IMPORTANCE_HIGH`
- ✅ تم تفعيل `FirebaseMessaging.onBackgroundMessage`

### 4. iOS Configuration
- ✅ تم تفعيل Push Notifications + Background Modes
- ✅ تم تحديث `AppDelegate.swift` مع دعم كامل للإشعارات
- ✅ تم إضافة `UIBackgroundModes` في `Info.plist`

### 5. Flutter Code
- ✅ تم إنشاء `firebaseMessagingBackgroundHandler` كـ top-level function
- ✅ تم ربط `flutter_local_notifications` لعرض الإشعارات
- ✅ تم إنشاء خدمات متقدمة للاختبار والإرسال

---

## 🧪 كيفية الاختبار

### الطريقة الأولى: من داخل التطبيق

1. **افتح التطبيق** كمدير (Admin)
2. **اذهب إلى** شاشة "اختبار الإشعارات"
3. **انسخ FCM Token** من الشاشة
4. **جرب الاختبارات السريعة:**
   - إشعار محلي
   - إشعار FCM
   - إشعار تجريبي
5. **شغل الاختبار الشامل** لفحص جميع المكونات

### الطريقة الثانية: باستخدام Firebase Console

1. **اذهب إلى** [Firebase Console](https://console.firebase.google.com)
2. **اختر مشروع** `mybus-5a992`
3. **اذهب إلى** Cloud Messaging
4. **اضغط** "Send your first message"
5. **أدخل:**
   - Title: `اختبار من Firebase Console 🔥`
   - Body: `هذا إشعار تجريبي من Firebase Console`
6. **في Target:** اختر "Single device" وألصق FCM Token
7. **اضغط** "Send"

### الطريقة الثالثة: باستخدام cURL

```bash
# Alert Notification (يظهر في notification tray)
curl -X POST https://fcm.googleapis.com/v1/projects/mybus-5a992/messages:send \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "token": "DEVICE_TOKEN_HERE",
      "notification": {
        "title": "اختبار cURL 🧪",
        "body": "هذا إشعار من cURL يجب أن يظهر في notification tray"
      },
      "android": {
        "priority": "HIGH"
      },
      "apns": {
        "headers": {
          "apns-priority": "10"
        },
        "payload": {
          "aps": {
            "sound": "default"
          }
        }
      }
    }
  }'
```

```bash
# Data-only Notification (للتحديثات الصامتة)
curl -X POST https://fcm.googleapis.com/v1/projects/mybus-5a992/messages:send \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "token": "DEVICE_TOKEN_HERE",
      "data": {
        "type": "silentUpdate",
        "refresh": "true"
      },
      "android": {
        "priority": "HIGH"
      },
      "apns": {
        "headers": {
          "apns-priority": "5"
        },
        "payload": {
          "aps": {
            "content-available": 1
          }
        }
      }
    }
  }'
```

---

## 📱 سيناريوهات الاختبار

### 1. Foreground Testing
- **افتح التطبيق** وابقه في المقدمة
- **أرسل إشعار** باستخدام أي من الطرق أعلاه
- **يجب أن يظهر** الإشعار فوراً داخل التطبيق

### 2. Background Testing
- **افتح التطبيق** ثم اضغط Home button
- **أرسل إشعار** 
- **يجب أن يظهر** في notification tray
- **اضغط على الإشعار** يجب أن يفتح التطبيق

### 3. Killed State Testing
- **أغلق التطبيق** تماماً من recent apps
- **أرسل إشعار**
- **يجب أن يظهر** في notification tray
- **اضغط على الإشعار** يجب أن يفتح التطبيق

### 4. Android 13+ Testing
- **تأكد** أن الجهاز Android 13 أو أحدث
- **افحص** أن صلاحيات الإشعارات مفعلة
- **جرب** جميع السيناريوهات أعلاه

### 5. iOS Testing
- **تأكد** أن صلاحيات الإشعارات مفعلة
- **جرب** في Development و Production environments
- **اختبر** مع Wi-Fi و Cellular data

---

## 🔍 استكشاف الأخطاء

### مشكلة: الإشعارات لا تظهر في Android

**الحلول:**
1. تأكد من تفعيل صلاحيات الإشعارات
2. تحقق من إعدادات Battery Optimization
3. تأكد من أن التطبيق غير مقيد في Background App Refresh

### مشكلة: الإشعارات لا تظهر في iOS

**الحلول:**
1. تأكد من تفعيل Push Notifications في Settings
2. تحقق من ربط APNs key في Firebase Console
3. تأكد من أن Bundle ID صحيح

### مشكلة: FCM Token فارغ

**الحلول:**
1. تحقق من اتصال الإنترنت
2. تأكد من تهيئة Firebase بشكل صحيح
3. أعد تشغيل التطبيق

---

## 📊 مراقبة الأداء

### في Firebase Console:
1. اذهب إلى **Cloud Messaging**
2. راجع **Reports** لمعرفة معدل التسليم
3. تحقق من **Errors** لأي مشاكل

### في التطبيق:
1. استخدم **شاشة اختبار الإشعارات**
2. راجع **Console logs** للتشخيص
3. تحقق من **Firestore** لسجل الإشعارات المرسلة

---

## 🚀 نشر Cloud Functions

لاستخدام خدمة الإرسال من الخادم:

```bash
# تثبيت Firebase CLI
npm install -g firebase-tools

# تسجيل الدخول
firebase login

# نشر Cloud Functions
cd cloud_functions
npm install
firebase deploy --only functions
```

---

## ✅ قائمة التحقق النهائية

- [ ] تم اختبار الإشعارات في Foreground
- [ ] تم اختبار الإشعارات في Background  
- [ ] تم اختبار الإشعارات في Killed state
- [ ] تم اختبار على Android 13+
- [ ] تم اختبار على iOS
- [ ] تم اختبار مع Wi-Fi و Data
- [ ] تم اختبار إعادة تثبيت التطبيق
- [ ] تم التحقق من ظهور الإشعارات في notification tray
- [ ] تم التحقق من الصوت والاهتزاز
- [ ] تم التحقق من فتح التطبيق عند الضغط على الإشعار

---

## 📞 الدعم

إذا واجهت أي مشاكل:
1. راجع Console logs في التطبيق
2. تحقق من Firebase Console للأخطاء
3. استخدم شاشة اختبار الإشعارات للتشخيص
4. راجع هذا الدليل للحلول الشائعة
