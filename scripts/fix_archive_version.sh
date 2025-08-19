#!/bin/bash

# Script to fix Xcode archive version issues
# Usage: ./scripts/fix_archive_version.sh <version> <build_number>
# Example: ./scripts/fix_archive_version.sh 1.10.7 7

if [ $# -ne 2 ]; then
    echo "Usage: $0 <version> <build_number>"
    echo "Example: $0 1.10.7 7"
    exit 1
fi

VERSION=$1
BUILD_NUMBER=$2

echo "🔧 Fixing Xcode Archive Version Issues..."
echo "📱 Target Version: $VERSION"
echo "🔢 Target Build: $BUILD_NUMBER"
echo ""

# Step 1: Force sync all version files
echo "⚡ Step 1: Force syncing all version files..."
./scripts/sync_version.sh $VERSION $BUILD_NUMBER

# Step 2: Clean everything
echo ""
echo "⚡ Step 2: Cleaning everything..."
flutter clean
rm -rf ios/build/
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/Developer/Xcode/Archives/*

# Step 3: Rebuild
echo ""
echo "⚡ Step 3: Rebuilding..."
flutter pub get
flutter build ios --release --no-codesign

# Step 4: Verify
echo ""
echo "⚡ Step 4: Verifying versions..."
./scripts/check_version.sh

echo ""
echo "🎯 Next steps:"
echo "   1. Close Xcode completely"
echo "   2. Open ios/Runner.xcworkspace"
echo "   3. In Xcode: Product → Clean Build Folder"
echo "   4. In Xcode: Product → Archive"
echo "   5. Check that Archive shows version $VERSION ($BUILD_NUMBER)"
echo ""
echo "💡 If Archive still shows wrong version:"
echo "   - Delete all Archives in Xcode Organizer"
echo "   - Clean Build Folder again"
echo "   - Archive again"
