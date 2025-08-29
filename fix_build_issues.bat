@echo off
echo 🔧 إصلاح مشاكل البناء - MyBus Project
echo =====================================

echo.
echo 1️⃣ إيقاف Gradle Daemon...
cd android
call gradlew --stop
cd ..

echo.
echo 2️⃣ تنظيف المشروع...
call flutter clean

echo.
echo 3️⃣ تنظيف Gradle cache...
cd android
call gradlew clean
cd ..

echo.
echo 4️⃣ حذف ملفات build القديمة...
if exist "build" rmdir /s /q "build"
if exist "android\build" rmdir /s /q "android\build"
if exist "android\app\build" rmdir /s /q "android\app\build"

echo.
echo 5️⃣ إعادة تحميل dependencies...
call flutter pub get

echo.
echo 6️⃣ بناء التطبيق في وضع release...
call flutter build apk --release --verbose

echo.
echo ✅ انتهى! إذا نجح البناء، يمكنك الآن تشغيل:
echo    flutter run --release
echo.
pause
