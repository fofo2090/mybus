#!/bin/bash

# MyBus Admin Dashboard Server Startup Script
# سكريبت تشغيل خادم لوحة تحكم MyBus

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_colored() {
    echo -e "${1}${2}${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Clear screen and show header
clear
print_colored $CYAN "========================================"
print_colored $CYAN "🚀 MyBus Admin Dashboard Server"
print_colored $CYAN "========================================"
echo

# Check if we're in the right directory
print_colored $BLUE "📁 التحقق من الملفات المطلوبة..."

if [ ! -f "index.html" ]; then
    print_colored $RED "❌ خطأ: ملف index.html غير موجود"
    exit 1
fi

if [ ! -f "app.js" ]; then
    print_colored $RED "❌ خطأ: ملف app.js غير موجود"
    exit 1
fi

if [ ! -f "firebase-config.js" ]; then
    print_colored $RED "❌ خطأ: ملف firebase-config.js غير موجود"
    exit 1
fi

print_colored $GREEN "✅ جميع الملفات موجودة"
echo

# Check for Python
print_colored $BLUE "🔍 البحث عن Python..."

if command_exists python3; then
    PYTHON_CMD="python3"
    print_colored $GREEN "✅ Python3 موجود"
elif command_exists python; then
    PYTHON_CMD="python"
    print_colored $GREEN "✅ Python موجود"
else
    print_colored $RED "❌ Python غير مثبت أو غير موجود في PATH"
    print_colored $YELLOW "💡 يرجى تثبيت Python من: https://python.org"
    exit 1
fi

echo

# Start server
print_colored $BLUE "🌐 بدء تشغيل الخادم..."
print_colored $PURPLE "📱 لوحة التحكم ستفتح تلقائياً في المتصفح"
echo
print_colored $YELLOW "🔑 بيانات تسجيل الدخول:"
print_colored $YELLOW "   📧 البريد الإلكتروني: admin@mybus.com"
print_colored $YELLOW "   🔒 كلمة المرور: admin123456"
echo
print_colored $RED "⚠️  للإيقاف: اضغط Ctrl+C"
print_colored $CYAN "========================================"
echo

# Make server.py executable if it isn't
chmod +x server.py 2>/dev/null

# Start the server
$PYTHON_CMD server.py

echo
print_colored $GREEN "👋 تم إيقاف الخادم"
