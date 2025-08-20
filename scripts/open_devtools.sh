#!/bin/bash

# Script สำหรับเปิด Dart DevTools สำหรับ SellStory App

echo "🚀 เปิด Dart DevTools สำหรับ SellStory App..."

# ตรวจสอบว่า Flutter ติดตั้งแล้วหรือไม่
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter ไม่ได้ติดตั้ง กรุณาติดตั้ง Flutter ก่อน"
    exit 1
fi

# ตรวจสอบว่า DevTools ติดตั้งแล้วหรือไม่
if ! flutter pub global list | grep -q "devtools"; then
    echo "📦 ติดตั้ง Dart DevTools..."
    flutter pub global activate devtools
fi

# เปิด DevTools
echo "🛠️ เปิด Dart DevTools..."
flutter pub global run devtools

echo "✅ Dart DevTools เปิดแล้ว!"
echo ""
echo "📋 คำแนะนำ:"
echo "1. เปิดแอพ SellStory ใน debug mode: flutter run --debug"
echo "2. เชื่อมต่อกับแอพใน DevTools"
echo "3. ไปที่แท็บ Console เพื่อดู log"
echo "4. ดูคู่มือเพิ่มเติมได้ที่ docs/LOGGING_GUIDE.md"

