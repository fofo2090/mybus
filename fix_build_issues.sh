#!/bin/bash

echo "🔧 إصلاح مشاكل البناء - MyBus Project"
echo "====================================="

echo ""
echo "1️⃣ إيقاف Gradle Daemon..."
cd android
./gradlew --stop
cd ..

echo ""
echo "2️⃣ تنظيف المشروع..."
flutter clean

echo ""
echo "3️⃣ تنظيف Gradle cache..."
cd android
./gradlew clean
cd ..

echo ""
echo "4️⃣ حذف ملفات build القديمة..."
rm -rf build
rm -rf android/build
rm -rf android/app/build

echo ""
echo "5️⃣ إعادة تحميل dependencies..."
flutter pub get

echo ""
echo "6️⃣ بناء التطبيق في وضع release..."
flutter build apk --release --verbose

echo ""
echo "✅ انتهى! إذا نجح البناء، يمكنك الآن تشغيل:"
echo "   flutter run --release"
echo ""
