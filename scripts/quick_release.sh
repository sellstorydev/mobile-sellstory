#!/bin/bash

# Quick release script - ทำทุกขั้นตอนในคำสั่งเดียว
# Usage: ./scripts/quick_release.sh <version> <build_number>
# Example: ./scripts/quick_release.sh 1.12.0 10

if [ $# -ne 2 ]; then
    echo "Usage: $0 <version> <build_number>"
    echo "Example: $0 1.12.0 10"
    echo ""
    echo "📋 Current version:"
    ./scripts/check_version.sh | grep -E "(📋|🔢)" | head -4
    exit 1
fi

VERSION=$1
BUILD_NUMBER=$2

echo "🚀 Quick Release Process Starting..."
echo "📱 Target Version: $VERSION"
echo "🔢 Target Build: $BUILD_NUMBER"
echo ""

# Step 1: Update version
echo "⚡ Step 1: Updating version..."
./scripts/sync_version.sh $VERSION $BUILD_NUMBER

if [ $? -ne 0 ]; then
    echo "❌ Version update failed!"
    exit 1
fi

echo ""

# Step 2: Build
echo "⚡ Step 2: Building iOS..."
./scripts/build_ios.sh

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo ""
echo "🎉 Quick Release Completed!"
echo "📱 Version: $VERSION ($BUILD_NUMBER)"
echo ""
echo "🎯 Next steps:"
echo "   1. Xcode should be opening automatically"
echo "   2. In Xcode: Product → Archive"
echo "   3. Wait for archive to complete"
echo "   4. Distribute to App Store or TestFlight"
echo ""
echo "📋 Files updated:"
echo "   ✅ ios/Runner.xcodeproj/project.pbxproj"
echo "   ✅ ios/Runner/Info.plist"
echo "   ✅ Flutter build completed"

# Open Xcode for archive
echo "📱 Opening Xcode for Archive..."
open ios/Runner.xcworkspace
