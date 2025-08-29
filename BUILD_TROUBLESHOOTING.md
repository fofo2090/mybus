# دليل استكشاف أخطاء البناء 🔧

## المشكلة الحالية: Gradle Daemon Crash

### الأعراض:
- `Gradle build daemon disappeared unexpectedly`
- `JVM crash log found`
- فشل في بناء التطبيق في وضع release

### الأسباب المحتملة:
1. **إعدادات ذاكرة عالية جداً** - تم إصلاحها ✅
2. **تضارب في إصدارات Java/Gradle**
3. **مشاكل في Firebase dependencies**
4. **ملفات build قديمة أو تالفة**

---

## 🚀 الحلول المطبقة

### 1. تقليل إعدادات الذاكرة
```properties
# قبل الإصلاح
org.gradle.jvmargs=-Xmx6G -XX:MaxMetaspaceSize=1G
kotlin.daemon.jvm.options=-Xmx3G

# بعد الإصلاح
org.gradle.jvmargs=-Xmx2G -XX:MaxMetaspaceSize=512m
kotlin.daemon.jvm.options=-Xmx1G
```

### 2. تعطيل Parallel Processing
```properties
# قبل الإصلاح
org.gradle.parallel=true
org.gradle.workers.max=4

# بعد الإصلاح
org.gradle.parallel=false
org.gradle.workers.max=2
```

### 3. إضافة HeapDump للتشخيص
```properties
org.gradle.jvmargs=-XX:+HeapDumpOnOutOfMemoryError
```

---

## 📋 خطوات الإصلاح

### الطريقة الأولى: استخدام Script التلقائي

**Windows:**
```bash
fix_build_issues.bat
```

**Linux/Mac:**
```bash
chmod +x fix_build_issues.sh
./fix_build_issues.sh
```

### الطريقة الثانية: خطوات يدوية

```bash
# 1. إيقاف Gradle Daemon
cd android
./gradlew --stop
cd ..

# 2. تنظيف شامل
flutter clean
cd android
./gradlew clean
cd ..

# 3. حذف ملفات build
rm -rf build
rm -rf android/build
rm -rf android/app/build

# 4. إعادة تحميل dependencies
flutter pub get

# 5. بناء التطبيق
flutter build apk --release
```

---

## 🔍 تشخيص إضافي

### فحص إصدارات Java
```bash
java -version
javac -version
```

### فحص إصدار Gradle
```bash
cd android
./gradlew --version
```

### فحص Flutter Doctor
```bash
flutter doctor -v
```

---

## ⚠️ مشاكل شائعة أخرى

### 1. مشكلة Firebase BOM
إذا استمرت المشكلة، جرب تقليل إصدار Firebase BOM:
```gradle
implementation platform('com.google.firebase:firebase-bom:32.8.0')
```

### 2. مشكلة Kotlin Version
تأكد من توافق إصدار Kotlin:
```gradle
ext.kotlin_version = '1.9.10'
```

### 3. مشكلة Android Gradle Plugin
في `android/build.gradle`:
```gradle
id 'com.android.application' version '8.1.4' apply false
```

---

## 🎯 نصائح للوقاية

### 1. مراقبة استخدام الذاكرة
- استخدم Task Manager لمراقبة استهلاك الذاكرة
- أغلق التطبيقات غير الضرورية أثناء البناء

### 2. تحديث منتظم
```bash
flutter upgrade
flutter pub upgrade
```

### 3. تنظيف دوري
```bash
flutter clean
cd android && ./gradlew clean
```

---

## 📞 إذا استمرت المشكلة

### 1. تحقق من crash log
```
C:\Users\[username]\.gradle\daemon\8.9\daemon-[pid].out.log
```

### 2. جرب بناء debug أولاً
```bash
flutter run --debug
```

### 3. استخدم verbose logging
```bash
flutter build apk --release --verbose
```

### 4. تحقق من مساحة القرص
تأكد من وجود مساحة كافية (على الأقل 5GB)

---

## ✅ علامات النجاح

عند نجاح الإصلاح، ستحصل على:
```
✓ Built build/app/outputs/flutter-apk/app-release.apk (XX.XMB)
```

يمكنك بعدها تشغيل:
```bash
flutter install --release
# أو
flutter run --release
```
