# Version Management Guide

## Overview
This project manages iOS app versions directly through Xcode instead of pubspec.yaml. This allows for more granular control over versioning and easier management through Xcode's interface.

## Current Version
- **Version**: 1.10.7
- **Build Number**: 6

## How to Update Version

### Method 1: Using the Script (Recommended)
```bash
# Update to version 1.10.8 with build number 7
./scripts/update_version.sh 1.10.8 7

# Update to version 2.0.0 with build number 1
./scripts/update_version.sh 2.0.0 1
```

### Method 2: Manual Update in Xcode
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the "Runner" project in the navigator
3. Select the "Runner" target
4. Go to the "General" tab
5. Update the following fields:
   - **Version**: The public version (e.g., 1.10.8)
   - **Build**: The build number (e.g., 7)

### Method 3: Manual File Editing
You can manually edit these files:

#### Update `ios/Runner.xcodeproj/project.pbxproj`
Find and update these lines:
```
MARKETING_VERSION = "1.10.7";
CURRENT_PROJECT_VERSION = 6;
```

#### Update `ios/Runner/Info.plist`
Find and update these lines:
```xml
<key>CFBundleShortVersionString</key>
<string>1.10.7</string>
<key>CFBundleVersion</key>
<string>6</string>
```

## Version Numbering Convention

### Version Format: `MAJOR.MINOR.PATCH`
- **MAJOR**: Breaking changes, major new features
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, minor improvements

### Build Number
- Increment for each build
- Should always increase (never decrease)
- Can be reset when version changes

## Examples

| Version | Build | Description |
|---------|-------|-------------|
| 1.10.7 | 6 | Current version |
| 1.10.8 | 7 | Bug fix release |
| 1.11.0 | 1 | New feature release |
| 2.0.0 | 1 | Major version update |

## Important Notes

1. **pubspec.yaml**: Version is commented out to prevent conflicts
2. **Xcode Priority**: Xcode settings take precedence over Flutter settings
3. **Build Process**: Use `flutter build ios` or build directly in Xcode
4. **Distribution**: Version and build number are used for App Store distribution

## Troubleshooting

### Version Not Updating
1. Clean the build: `flutter clean`
2. Delete derived data in Xcode
3. Rebuild the project

### Build Number Conflicts
- Ensure build number is always increasing
- Check both project.pbxproj and Info.plist files
- Verify in Xcode project settings

### Script Issues
- Make sure script is executable: `chmod +x scripts/update_version.sh`
- Check file permissions
- Verify script syntax: `bash -n scripts/update_version.sh`
