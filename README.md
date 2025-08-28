# SellStory Mobile App

A Flutter application for managing sales and customer relationships.

## Bottom Navigation Customization

The app features a bottom navigation bar with 5 tabs that can be easily customized:

### Changing Active Color
To change the active tab color, modify the `selectedItemColor` in `lib/features/shell/shell_page.dart`:
```dart
selectedItemColor: const Color(0xFFFF6A00), // Change this color
```

### Changing Labels
To change tab labels, modify the `label` property in each `BottomNavigationBarItem`:
```dart
BottomNavigationBarItem(
  icon: Icon(Icons.menu),
  label: 'Job Card', // Change this text
),
```

### Changing Icons
To change tab icons, modify the `icon` property in each `BottomNavigationBarItem`:
```dart
BottomNavigationBarItem(
  icon: Icon(Icons.menu), // Change this icon
  label: 'Job Card',
),
```

### Current Tab Configuration
1. **Job Card** - `Icons.menu` (filled when active, outlined when inactive)
2. **รายการคำสั่งซื้อ** - `Icons.description_outlined`
3. **ลูกค้า** - `Icons.person_outline`
4. **สินค้า** - `Icons.shopping_bag_outlined`
5. **อื่น ๆ** - `Icons.grid_view_outlined`

### Adding New Tabs
To add a new tab:
1. Create a new page in `lib/features/[feature_name]/view/[feature_name]_page.dart`
2. Add the page to the `IndexedStack` in `lib/features/shell/shell_page.dart`
3. Add a new `BottomNavigationBarItem` to the items list
4. Update the `ShellController` if needed

## Features

- **Firebase Authentication**
  - Email/Password authentication
  - Google Sign-In
  - Phone number authentication (OTP)
  - Password reset functionality
- **GetX State Management**
  - Reactive state management
  - Dependency injection
  - Route management
- **Multi-language Support**
  - English and Thai localization
- **Theme Support**
  - Light and dark mode
- **Modern UI**
  - Material Design 3
  - Responsive layout

## Project Structure

```
lib/
├── app/
│   ├── app.dart              # Main app configuration
│   └── routes.dart           # Route definitions
├── core/
│   ├── auth/
│   │   └── auth_gate.dart    # Firebase auth state listener
│   ├── i18n/                 # Internationalization
│   ├── network/              # API client
│   ├── theme/                # Theme management
│   └── utils/                # Utilities
├── data/
│   └── services/
│       └── firebase_auth_service.dart  # Firebase auth service
├── features/
│   ├── dashboard/
│   │   └── view/
│   │       └── dashboard_page.dart
│   ├── login/
│   │   ├── controller/
│   │   │   └── login_controller.dart   # GetX controller
│   │   ├── view/
│   │   │   └── login_page.dart         # Login UI
│   │   └── widgets/                    # Reusable widgets
│   └── splash/
│       └── splash_page.dart
├── models/                   # Data models
└── main.dart                 # App entry point
```

## 🚀 iOS Build & Release Scripts

### Quick Commands

```bash
# ตรวจสอบเวอร์ชันปัจจุบัน
./scripts/check_version.sh

# เปลี่ยนเวอร์ชันและ sync ทุกไฟล์
./scripts/sync_version.sh 1.12.0 10

# Build iOS แบบปกติ
./scripts/build_ios.sh

# Build iOS และเปิด Xcode สำหรับ Archive
./scripts/build_ios.sh --archive

# ทำทุกขั้นตอนในคำสั่งเดียว (เปลี่ยนเวอร์ชัน + build + เปิด Xcode)
./scripts/quick_release.sh 1.12.0 10
```

### 📖 รายละเอียดเพิ่มเติม
ดูคู่มือฉบับเต็มได้ที่: [docs/IOS_BUILD_GUIDE.md](docs/IOS_BUILD_GUIDE.md)

---

## 🛠️ Debugging & Logging

### Quick Commands

```bash
# รันแอพใน debug mode พร้อม logging
./scripts/run_debug.sh

# เปิด Dart DevTools
./scripts/open_devtools.sh

# รันแอพแบบปกติ
flutter run --debug
```

### 📊 Logging Features

- **Real-time logging** ใน Dart DevTools Console
- **Structured data logging** สำหรับ debugging
- **Performance profiling** และ memory usage tracking
- **Dependency injection logging** สำหรับ troubleshooting
- **User action tracking** และ state management logging

### 🎯 Log Types

- 🛠️ **DevTools Logs**: สำหรับ debugging ใน DevTools
- 📱 **Console Logs**: สำหรับ general console output
- 🔍 **Debug Logs**: สำหรับ detailed debugging
- ⏱️ **Performance Logs**: สำหรับ performance analysis
- 💾 **Memory Logs**: สำหรับ memory usage tracking

### 📖 รายละเอียดเพิ่มเติม
ดูคู่มือฉบับเต็มได้ที่: [docs/LOGGING_GUIDE.md](docs/LOGGING_GUIDE.md)

---

## Setup Instructions

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Firebase Setup

#### Install FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
```

#### Configure Firebase
```bash
flutterfire configure
```

This will:
- Create a Firebase project (if needed)
- Add your Flutter app to the project
- Generate `lib/firebase_options.dart`
- Update platform-specific configuration files

#### Manual Firebase Console Setup

1. **Create Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project or select existing one

2. **Add Android App**
   - In Firebase Console, go to Project Settings > General
   - Add Android app with package name: `com.example.sellstory`
   - Download `google-services.json` and place in `android/app/`
   - Add SHA-1 and SHA-256 fingerprints to Firebase Console

3. **Add iOS App**
   - In Firebase Console, add iOS app with bundle ID: `com.example.sellstory`
   - Download `GoogleService-Info.plist` and place in `ios/Runner/`
   - Add to Xcode project

4. **Enable Authentication Methods**
   - Go to Authentication > Sign-in method
   - Enable Email/Password
   - Enable Phone
   - Enable Google Sign-In

### 3. Platform-Specific Configuration

#### Android
1. **Add SHA fingerprints to Firebase Console**
   ```bash
   # Debug SHA-1
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   
   # Release SHA-1 (if you have a release keystore)
   keytool -list -v -keystore your-release-key.keystore -alias your-key-alias
   ```

2. **Update android/app/build.gradle.kts**
   ```kotlin
   android {
       defaultConfig {
           applicationId "com.example.sellstory"
           minSdkVersion 21  // Required for Firebase
       }
   }
   ```

#### iOS
1. **Update ios/Runner/Info.plist**
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleURLName</key>
           <string>REVERSED_CLIENT_ID</string>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>YOUR_REVERSED_CLIENT_ID</string>
           </array>
       </dict>
   </array>
   <key>GIDClientID</key>
   <string>YOUR_CLIENT_ID</string>
   ```

2. **Add Google Sign-In capability**
   - Open Xcode
   - Select Runner target
   - Go to Signing & Capabilities
   - Add "Sign in with Apple" capability

### 4. Google Sign-In Assets

Download the official Google Sign-In button assets from:
https://developers.google.com/identity/branding-guidelines

Place `google_icon.png` in the `assets/` directory.

### 5. Run the App

```bash
flutter run
```

## Testing

Run unit tests:
```bash
flutter test
```

Run widget tests:
```bash
flutter test test/features/login/login_page_test.dart
```

## Authentication Flow

1. **Splash Screen**: Checks Firebase auth state
2. **Login Screen**: 
   - Email/Password authentication
   - Google Sign-In
   - Phone OTP authentication
3. **Dashboard**: Shows user info and sign-out option

## Dependencies

- `firebase_core`: ^3.4.0
- `firebase_auth`: ^5.3.0
- `google_sign_in`: ^6.2.1
- `get`: ^4.6.6
- `dio`: ^5.4.0
- `intl`: ^0.20.2
- `get_storage`: ^2.1.1

## Troubleshooting

### Common Issues

1. **Firebase not initialized**
   - Ensure `flutterfire configure` was run
   - Check `lib/firebase_options.dart` exists
   - Verify Firebase.initializeApp() in main.dart

2. **Google Sign-In not working**
   - Verify SHA fingerprints in Firebase Console
   - Check GoogleService-Info.plist configuration
   - Ensure Google Sign-In is enabled in Firebase Console

3. **Phone authentication issues**
   - Enable Phone authentication in Firebase Console
   - Add test phone numbers for development
   - Check Firebase project billing (Phone auth requires billing)

4. **Build errors**
   - Clean and rebuild: `flutter clean && flutter pub get`
   - Check platform-specific configuration files
   - Verify all dependencies are compatible

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the MIT License.


**User Permission Notice**:
{roleId: owner, roleName: Owner, permissions: [*]}

{roleId: admin, roleName: Admin, permissions: [jobcard:view:all, jobcard:create, jobcard:edit:all, jobcard:delete:all, jobcard:move, customer:view:all, customer:create, customer:edit:all, customer:delete, customer:import, company:view, company:create, company:edit:all, company:delete, company:import, product:view, product:create, product:edit:all, product:delete, product:import, user:manage, settings:board:manage, settings:company:manage, settings:id:manage, settings:catalog:manage, settings:roles:manage]}


