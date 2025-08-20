#!/bin/bash

# Script สำหรับรัน SellStory App ใน debug mode พร้อม logging

echo "🚀 รัน SellStory App ใน debug mode..."

# ตรวจสอบว่า Flutter ติดตั้งแล้วหรือไม่
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter ไม่ได้ติดตั้ง กรุณาติดตั้ง Flutter ก่อน"
    exit 1
fi

# Clean และ get dependencies
echo "🧹 Clean project..."
flutter clean

echo "📦 Get dependencies..."
flutter pub get

# Run ใน debug mode
echo "🔧 รันแอพใน debug mode..."
echo "📱 Log จะปรากฏใน console และ Dart DevTools"
echo "🛠️ เปิด DevTools ในอีก terminal: ./scripts/open_devtools.sh"
echo ""

flutter run --debug

echo ""
echo "✅ แอพปิดแล้ว!"

