@echo off
echo ========================================
echo MyBus Project Rebuild Script
echo ========================================

echo.
echo [1/6] Cleaning Flutter project...
flutter clean

echo.
echo [2/6] Cleaning Android Gradle cache...
cd android
if exist .gradle rmdir /s /q .gradle
if exist app\build rmdir /s /q app\build
if exist build rmdir /s /q build
cd ..

echo.
echo [3/6] Cleaning global Gradle cache...
if exist "%USERPROFILE%\.gradle\caches" rmdir /s /q "%USERPROFILE%\.gradle\caches"

echo.
echo [4/6] Getting Flutter dependencies...
flutter pub get

echo.
echo [5/6] Building APK with verbose output...
flutter build apk --release --verbose

echo.
echo [6/6] Done!
echo ========================================
echo Build completed. Check for any errors above.
echo ========================================
pause
