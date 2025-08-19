#!/bin/bash

# Script to build iOS app for release
# Usage: ./scripts/build_ios.sh [--archive]
# Example: ./scripts/build_ios.sh --archive

echo "🚀 Starting iOS build process..."

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: pubspec.yaml not found. Make sure you're in the Flutter project root."
    exit 1
fi

# Check if iOS directory exists
if [ ! -d "ios" ]; then
    echo "❌ Error: ios directory not found."
    exit 1
fi

echo "📋 Current version info:"
./scripts/check_version.sh | grep -E "(📋|🔢)"

echo ""
echo "🧹 Cleaning project..."
flutter clean

echo "📦 Getting dependencies..."
flutter pub get

echo "🔨 Building iOS release..."
flutter build ios --release

if [ $? -ne 0 ]; then
    echo "❌ Flutter build failed!"
    exit 1
fi

echo "✅ Flutter build completed successfully!"

# Check if --archive flag is provided
if [ "$1" = "--archive" ]; then
    echo ""
    echo "📱 Opening Xcode for Archive..."
    echo "📋 Next steps in Xcode:"
    echo "   1. Product → Archive"
    echo "   2. Wait for archive to complete"
    echo "   3. Choose 'Distribute App'"
    echo "   4. Select distribution method"
    
    open ios/Runner.xcworkspace
else
    echo ""
    echo "✅ Build completed!"
    echo "🎯 To archive:"
    echo "   Option 1: ./scripts/build_ios.sh --archive"
    echo "   Option 2: Open Xcode manually and Product → Archive"
    echo ""
    echo "🔧 Manual Xcode steps:"
    echo "   1. Open ios/Runner.xcworkspace"
    echo "   2. Product → Clean Build Folder"
    echo "   3. Product → Archive"
fi

echo ""
echo "📊 Build summary:"
echo "   Flutter build: ✅ Success"
echo "   Ready for Archive: ✅ Yes"
echo "   Xcode workspace: ios/Runner.xcworkspace"
