#!/bin/bash

# Force sync version script - แก้ไขเวอร์ชันในทุกไฟล์ให้ตรงกันแน่นอน
# Usage: ./scripts/force_sync_version.sh <version> <build_number>
# Example: ./scripts/force_sync_version.sh 1.10.7 7

if [ $# -ne 2 ]; then
    echo "Usage: $0 <version> <build_number>"
    echo "Example: $0 1.10.7 7"
    exit 1
fi

VERSION=$1
BUILD_NUMBER=$2
PROJECT_FILE="ios/Runner.xcodeproj/project.pbxproj"
INFO_PLIST="ios/Runner/Info.plist"
PUBSPEC_FILE="pubspec.yaml"

echo "🔧 Force syncing version to $VERSION ($BUILD_NUMBER)..."

# Step 1: Update project.pbxproj
echo "📱 Updating project.pbxproj..."
sed -i '' "s/MARKETING_VERSION = \"[^\"]*\"/MARKETING_VERSION = \"$VERSION\"/g" "$PROJECT_FILE"
sed -i '' "s/MARKETING_VERSION = [^;]*;/MARKETING_VERSION = $VERSION;/g" "$PROJECT_FILE"
sed -i '' "s/CURRENT_PROJECT_VERSION = [^;]*;/CURRENT_PROJECT_VERSION = $BUILD_NUMBER;/g" "$PROJECT_FILE"

# Step 2: Update Info.plist - แก้ไขแบบตรงๆ
echo "📋 Updating Info.plist..."
# Backup original file
cp "$INFO_PLIST" "${INFO_PLIST}.backup"

# Create new Info.plist with correct version
cat > "$INFO_PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>\$(DEVELOPMENT_LANGUAGE)</string>
	<key>CFBundleDisplayName</key>
	<string>Sellstory</string>
	<key>CFBundleExecutable</key>
	<string>\$(EXECUTABLE_NAME)</string>
	<key>CFBundleIdentifier</key>
	<string>\$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>sellstory</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>$VERSION</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleVersion</key>
	<string>$BUILD_NUMBER</string>
	<key>LSRequiresIPhoneOS</key>
	<true/>
	<key>UILaunchStoryboardName</key>
	<string>LaunchScreen</string>
	<key>UIMainStoryboardFile</key>
	<string>Main</string>
	<key>UISupportedInterfaceOrientations</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
	</array>
	<key>UISupportedInterfaceOrientations~ipad</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationPortraitUpsideDown</string>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
	</array>
	<key>CADisableMinimumFrameDurationOnPhone</key>
	<true/>
	<key>UIApplicationSupportsIndirectInputEvents</key>
	<true/>
	
	<!-- Google Sign-In Configuration -->
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleURLName</key>
			<string>REVERSED_CLIENT_ID</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>com.googleusercontent.apps.489911602258-0pt2sm59lvef95pnkmge98bjkkfmg8v6</string>
			</array>
		</dict>
	</array>
	<key>GIDClientID</key>
	<string>489911602258-0pt2sm59lvef95pnkmge98bjkkfmg8v6.apps.googleusercontent.com</string>
	

</dict>
</plist>
EOF

# Step 3: Update pubspec.yaml
echo "📦 Updating pubspec.yaml..."
# Backup original file
cp "$PUBSPEC_FILE" "${PUBSPEC_FILE}.backup"

# Read pubspec.yaml and replace version line
awk -v version="$VERSION+$BUILD_NUMBER" '
/^version:/ { print "version: " version; next }
{ print }
' "$PUBSPEC_FILE.backup" > "$PUBSPEC_FILE"

# Step 4: Clean everything
echo "🧹 Cleaning everything..."
flutter clean
rm -rf ios/build/
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Step 5: Verify
echo "✅ Verifying changes..."
echo ""
echo "📱 Project.pbxproj:"
grep "MARKETING_VERSION" "$PROJECT_FILE" | head -1
grep "CURRENT_PROJECT_VERSION" "$PROJECT_FILE" | head -1

echo ""
echo "📋 Info.plist:"
grep -A 1 "CFBundleShortVersionString" "$INFO_PLIST"
grep -A 1 "CFBundleVersion" "$INFO_PLIST"

echo ""
echo "📦 Pubspec.yaml:"
grep "version:" "$PUBSPEC_FILE" | head -1

echo ""
echo "🎯 Force sync completed!"
echo "📱 Version: $VERSION"
echo "🔢 Build Number: $BUILD_NUMBER"
echo ""
echo "🔄 Next steps:"
echo "   1. Close Xcode completely"
echo "   2. Open ios/Runner.xcworkspace"
echo "   3. Product → Clean Build Folder"
echo "   4. Product → Archive"
echo ""
echo "💡 If still not working:"
echo "   - Delete all Archives in Organizer"
echo "   - Clean Build Folder again"
echo "   - Archive again"
