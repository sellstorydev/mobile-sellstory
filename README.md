# SellStory Mobile App

A Flutter mobile application with Firebase Authentication using GetX for state management.

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
