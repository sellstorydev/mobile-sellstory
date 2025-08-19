#!/bin/bash

# Script to sync iOS version across all Xcode project files
# Usage: ./scripts/sync_version.sh <version> <build_number>
# Example: ./scripts/sync_version.sh 1.11.0 9

if [ $# -ne 2 ]; then
    echo "Usage: $0 <version> <build_number>"
    echo "Example: $0 1.11.0 9"
    exit 1
fi

VERSION=$1
BUILD_NUMBER=$2
PROJECT_FILE="ios/Runner.xcodeproj/project.pbxproj"
INFO_PLIST="ios/Runner/Info.plist"

echo "🔄 Syncing iOS version to $VERSION ($BUILD_NUMBER) across all files..."

# Step 1: Update project.pbxproj - replace ALL instances
echo "📱 Updating project.pbxproj..."
sed -i '' "s/MARKETING_VERSION = \"[^\"]*\"/MARKETING_VERSION = \"$VERSION\"/g" "$PROJECT_FILE"
sed -i '' "s/MARKETING_VERSION = [^;]*;/MARKETING_VERSION = $VERSION;/g" "$PROJECT_FILE"
sed -i '' "s/CURRENT_PROJECT_VERSION = [^;]*;/CURRENT_PROJECT_VERSION = $BUILD_NUMBER;/g" "$PROJECT_FILE"

# Step 2: Update Info.plist
echo "📋 Updating Info.plist..."
PUBSPEC_FILE="pubspec.yaml"

# Update Info.plist - more robust approach
sed -i '' "s/<string>1\.[0-9]\+\.[0-9]\+<\/string>/<string>$VERSION<\/string>/g" "$INFO_PLIST"
sed -i '' "s/<string>[0-9]\+<\/string>/<string>$BUILD_NUMBER<\/string>/g" "$INFO_PLIST"

# Step 3: Update pubspec.yaml
echo "📦 Updating pubspec.yaml..."
sed -i '' "s/version: [0-9]\+\.[0-9]\+\.[0-9]\+[+][0-9]\+/version: $VERSION+$BUILD_NUMBER/g" "$PUBSPEC_FILE"

# Step 3: Clean Xcode cache
echo "🧹 Cleaning Xcode cache..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ios/build/

echo "✅ Version sync completed!"
echo "📱 Version: $VERSION"
echo "🔢 Build Number: $BUILD_NUMBER"
echo ""
echo "🔄 Next steps:"
echo "   1. Close Xcode completely"
echo "   2. Open ios/Runner.xcworkspace again"
echo "   3. Check that Version and Build match in Xcode UI"
echo "   4. Clean Build Folder (Product → Clean Build Folder)"
echo "   5. Build and Archive again"
