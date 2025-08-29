@echo off
chcp 65001 >nul
title MyBus Admin Dashboard Server

echo.
echo ========================================
echo 🚀 MyBus Admin Dashboard Server
echo ========================================
echo.

echo 📁 التحقق من الملفات المطلوبة...

if not exist "index.html" (
    echo ❌ خطأ: ملف index.html غير موجود
    pause
    exit /b 1
)

if not exist "app.js" (
    echo ❌ خطأ: ملف app.js غير موجود
    pause
    exit /b 1
)

if not exist "firebase-config.js" (
    echo ❌ خطأ: ملف firebase-config.js غير موجود
    pause
    exit /b 1
)

echo ✅ جميع الملفات موجودة

echo.
echo 🔍 البحث عن Python...

python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python غير مثبت أو غير موجود في PATH
    echo 💡 يرجى تثبيت Python من: https://python.org
    pause
    exit /b 1
)

echo ✅ Python موجود

echo.
echo 🌐 بدء تشغيل الخادم...
echo 📱 لوحة التحكم ستفتح تلقائياً في المتصفح
echo.
echo 🔑 بيانات تسجيل الدخول:
echo    📧 البريد الإلكتروني: admin@mybus.com
echo    🔒 كلمة المرور: admin123456
echo.
echo ⚠️  للإيقاف: اضغط Ctrl+C
echo ========================================
echo.

python server.py

echo.
echo 👋 تم إيقاف الخادم
pause
