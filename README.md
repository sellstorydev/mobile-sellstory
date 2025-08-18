# SellStory Mobile App

A production-ready Flutter application built with MVP architecture using GetX for state management, dependency injection, and routing.

## Features

- **MVP Architecture**: Clean separation of concerns with Model-View-Presenter pattern
- **GetX Integration**: State management, dependency injection, and routing
- **Thai Language Support**: Login screen with Thai text and validation
- **Native Splash Screen**: Custom splash screen with logo
- **Form Validation**: Real-time validation with disabled/enabled button states
- **Unit Testing**: Comprehensive test coverage with Mocktail
- **Dark Mode Support**: Automatic theme switching

## Project Structure

```
lib/
├── app/
│   ├── app.dart                 # GetMaterialApp, theme, DI setup
│   └── routes.dart              # GetX routes configuration
├── core/
│   ├── network/
│   │   └── api_client.dart      # Dio wrapper for HTTP requests
│   └── utils/
│       └── validators.dart      # Form validation utilities
├── data/
│   └── services/
│       └── auth_service.dart    # Authentication service interface & implementation
├── models/
│   ├── user.dart               # User model
│   └── auth_result.dart        # Authentication result model
└── features/
    ├── splash/
    │   └── splash_page.dart     # Splash screen with auto-redirect
    ├── login/
    │   ├── contract/
    │   │   └── login_view.dart  # MVP view interface
    │   ├── presenter/
    │   │   └── login_presenter.dart # MVP presenter with GetX
    │   ├── view/
    │   │   └── login_page.dart  # Login UI implementation
    │   └── widgets/
    │       ├── branded_logo.dart
    │       ├── primary_button.dart
    │       └── text_fields.dart
    └── dashboard/
        └── view/
            └── dashboard_page.dart
```

## Getting Started

### Prerequisites

- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Android Studio / VS Code
- iOS Simulator (for iOS development)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd mobile-sellstory
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate native splash screen**
   ```bash
   # Note: You need to add a splash logo image to assets/splash_logo.png first
   # The image should be a PNG file with transparent background
   dart run flutter_native_splash:create
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## Testing

### Run all tests
```bash
flutter test
```

### Run specific test files
```bash
flutter test test/core/utils/validators_test.dart
flutter test test/features/login/login_presenter_test.dart
flutter test test/data/services/auth_service_test.dart
```

### Test coverage
```bash
flutter test --coverage
```

## Architecture

### MVP Pattern
- **Model**: Data models (`User`, `AuthResult`)
- **View**: UI components that implement view interfaces
- **Presenter**: Business logic controllers that extend `GetxController`

### GetX Integration
- **State Management**: Reactive variables with `.obs`
- **Dependency Injection**: `Get.put()` and `Get.find()`
- **Routing**: Named routes with `GetPage`

### Authentication Flow
1. App starts at `/splash`
2. Splash redirects to `/login` after first frame
3. User enters credentials (email/phone + password)
4. Form validates in real-time
5. On successful login, navigates to `/dashboard`

## Login Screen Features

- **Thai Language**: All text in Thai language
- **Form Validation**: 
  - Identity: minimum 5 characters
  - Password: minimum 6 characters
- **Eye Toggle**: Password visibility toggle
- **Button States**: Disabled until form is valid
- **Loading States**: Loading indicator during authentication
- **Error Handling**: SnackBar for error messages

## Dummy Authentication

For testing purposes, the app uses `DummyAuthService`:
- **Success**: Password = "123456" and identity is not empty
- **Delay**: 600ms artificial delay to simulate network request
- **Error**: Any other combination returns "Invalid credentials"

## Development

### Code Analysis
```bash
flutter analyze
```

### Format Code
```bash
dart format lib/ test/
```

### Build for Production
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## Dependencies

### Production Dependencies
- `get: ^4.6.6` - GetX for state management, DI, and routing
- `dio: ^5.4.0` - HTTP client for API requests

### Development Dependencies
- `flutter_test` - Flutter testing framework
- `mocktail: ^1.0.3` - Mocking library for testing
- `flutter_lints: ^4.0.0` - Code linting rules
- `flutter_native_splash: ^2.4.1` - Native splash screen generation

## Configuration

### Native Splash Screen
The splash screen is configured in `pubspec.yaml`:
```yaml
flutter_native_splash:
  color: "#FFFFFF"
  image: assets/splash_logo.png
  color_dark: "#000000"
  image_dark: assets/splash_logo.png
  android_gravity: center
  ios_content_mode: center
```

### Theme Configuration
- **Primary Color**: `#FF6A00` (Orange)
- **Text Fields**: `OutlineInputBorder` with 12px radius
- **Dark Mode**: Automatic theme switching supported

## Contributing

1. Follow the MVP architecture pattern
2. Write unit tests for new features
3. Ensure `flutter analyze` passes
4. Run tests before submitting changes

## License

This project is licensed under the MIT License.
