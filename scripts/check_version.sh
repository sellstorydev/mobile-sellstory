#!/bin/bash

# Script to check current iOS version in Xcode project
# Usage: ./scripts/check_version.sh

PROJECT_FILE="ios/Runner.xcodeproj/project.pbxproj"
INFO_PLIST="ios/Runner/Info.plist"
PUBSPEC_FILE="pubspec.yaml"

echo "🔍 Checking current iOS version..."
echo ""

echo "📱 Project.pbxproj versions:"
grep "MARKETING_VERSION" "$PROJECT_FILE" | head -3
echo ""

echo "🔢 Project.pbxproj build numbers:"
grep "CURRENT_PROJECT_VERSION" "$PROJECT_FILE" | head -3
echo ""

echo "📋 Info.plist version:"
grep -A 1 "CFBundleShortVersionString" "$INFO_PLIST"
echo ""

echo "📋 Info.plist build:"
grep -A 1 "CFBundleVersion" "$INFO_PLIST"
echo ""

echo "📦 Pubspec.yaml version:"
grep "version:" "$PUBSPEC_FILE" | head -1
echo ""

echo "💡 To update version:"
echo "   1. Use script: ./scripts/sync_version.sh <version> <build>"
echo "   2. Or manually in Xcode:"
echo "      - Open ios/Runner.xcworkspace"
echo "      - Select Runner project → Runner target"
echo "      - Go to General tab"
echo "      - Update Version and Build fields"
echo "      - Save (Cmd + S)"
echo "      - Clean Build Folder (Product → Clean Build Folder)"
