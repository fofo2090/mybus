@echo off
echo ========================================
echo     MyBus - No Cache Build Script
echo     بناء بدون كاش نهائياً
echo ========================================
echo.

echo [1/8] إيقاف جميع عمليات Gradle...
taskkill /f /im java.exe 2>nul
taskkill /f /im gradle.exe 2>nul
taskkill /f /im gradlew.exe 2>nul

echo [2/8] حذف ذاكرة Gradle التخزينية...
if exist "%USERPROFILE%\.gradle" (
    rmdir /s /q "%USERPROFILE%\.gradle" 2>nul
    echo ✅ تم حذف .gradle
)

if exist "%USERPROFILE%\.android\build-cache" (
    rmdir /s /q "%USERPROFILE%\.android\build-cache" 2>nul
    echo ✅ تم حذف build-cache
)

echo [3/8] حذف مجلدات البناء المحلية...
if exist "build" (
    rmdir /s /q "build" 2>nul
    echo ✅ تم حذف build
)

if exist "android\build" (
    rmdir /s /q "android\build" 2>nul
    echo ✅ تم حذف android\build
)

if exist "android\app\build" (
    rmdir /s /q "android\app\build" 2>nul
    echo ✅ تم حذف android\app\build
)

if exist "android\.gradle" (
    rmdir /s /q "android\.gradle" 2>nul
    echo ✅ تم حذف android\.gradle
)

echo [4/8] إنشاء gradle.properties عام...
if not exist "%USERPROFILE%\.gradle" mkdir "%USERPROFILE%\.gradle"

echo org.gradle.daemon=false > "%USERPROFILE%\.gradle\gradle.properties"
echo org.gradle.parallel=false >> "%USERPROFILE%\.gradle\gradle.properties"
echo org.gradle.caching=false >> "%USERPROFILE%\.gradle\gradle.properties"
echo org.gradle.configureondemand=false >> "%USERPROFILE%\.gradle\gradle.properties"
echo org.gradle.build-cache.local.enabled=false >> "%USERPROFILE%\.gradle\gradle.properties"
echo org.gradle.build-cache.remote.enabled=false >> "%USERPROFILE%\.gradle\gradle.properties"
echo org.gradle.unsafe.configuration-cache=false >> "%USERPROFILE%\.gradle\gradle.properties"
echo org.gradle.vfs.watch=false >> "%USERPROFILE%\.gradle\gradle.properties"
echo org.gradle.jvmargs=-Xmx3G -XX:MaxMetaspaceSize=512m -XX:+UseG1GC >> "%USERPROFILE%\.gradle\gradle.properties"

echo ✅ تم إنشاء gradle.properties عام

echo [5/8] تنظيف Flutter...
flutter clean
if %errorlevel% neq 0 (
    echo ❌ خطأ في flutter clean
    pause
    exit /b 1
)

echo [6/8] تحديث التبعيات...
flutter pub get
if %errorlevel% neq 0 (
    echo ❌ خطأ في flutter pub get
    pause
    exit /b 1
)

echo [7/8] إيقاف Gradle daemon...
cd android
gradlew --stop 2>nul
cd ..

echo [8/8] بناء APK بدون كاش...
echo تعيين متغيرات البيئة...
set GRADLE_OPTS=-Xmx3G -XX:MaxMetaspaceSize=512m -XX:+UseG1GC
set GRADLE_USER_HOME=%USERPROFILE%\.gradle_temp

echo بدء البناء...
flutter build apk --debug --verbose --no-tree-shake-icons

if %errorlevel% neq 0 (
    echo ❌ فشل البناء!
    echo.
    echo 🔧 جرب الحل اليدوي:
    echo cd android
    echo gradlew --no-daemon --no-build-cache --no-parallel clean
    echo gradlew --no-daemon --no-build-cache --no-parallel assembleDebug
    echo cd ..
    pause
    exit /b 1
)

echo.
echo ✅ نجح البناء!
if exist "build\app\outputs\flutter-apk\app-debug.apk" (
    for %%A in ("build\app\outputs\flutter-apk\app-debug.apk") do (
        set size=%%~zA
        set /a sizeMB=!size!/1024/1024
        echo 📱 حجم APK: !sizeMB! MB
    )
    echo 📍 مكان الملف: build\app\outputs\flutter-apk\app-debug.apk
) else (
    echo ⚠️ لم يتم العثور على ملف APK
)

echo.
echo ========================================
echo        اكتمل البناء بدون كاش
echo ========================================
pause
