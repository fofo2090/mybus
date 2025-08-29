@echo off
echo ========================================
echo تنظيف وإصلاح مشاكل البناء
echo ========================================

echo.
echo 1. تنظيف Flutter...
call flutter clean

echo.
echo 2. تنظيف Gradle...
cd android
call gradlew clean
cd ..

echo.
echo 3. إيقاف جميع Gradle daemons...
cd android
call gradlew --stop
cd ..

echo.
echo 4. حذف مجلدات البناء المؤقتة...
if exist "build" rmdir /s /q "build"
if exist "android\build" rmdir /s /q "android\build"
if exist "android\app\build" rmdir /s /q "android\app\build"
if exist ".dart_tool" rmdir /s /q ".dart_tool"

echo.
echo 5. تحديث dependencies...
call flutter pub get

echo.
echo 6. إعادة بناء التطبيق...
call flutter build apk --release

echo.
echo ========================================
echo انتهى الإصلاح!
echo ========================================
pause