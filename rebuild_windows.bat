@echo off
echo ========================================
echo MyBus Windows Build Script
echo ========================================

echo.
echo [1/7] Cleaning Flutter project...
flutter clean

echo.
echo [2/7] Cleaning Windows build cache...
if exist build\windows rmdir /s /q build\windows
if exist windows\flutter\ephemeral rmdir /s /q windows\flutter\ephemeral

echo.
echo [3/7] Getting Flutter dependencies...
flutter pub get

echo.
echo [4/7] Regenerating Windows plugins...
flutter config --enable-windows-desktop
flutter create --platforms=windows .

echo.
echo [5/7] Cleaning CMake cache...
if exist build\windows\CMakeCache.txt del build\windows\CMakeCache.txt
if exist build\windows\CMakeFiles rmdir /s /q build\windows\CMakeFiles

echo.
echo [6/7] Building Windows application...
flutter build windows --release

echo.
echo [7/7] Done!
echo ========================================
echo Build completed. Check for any errors above.
echo ========================================
pause
