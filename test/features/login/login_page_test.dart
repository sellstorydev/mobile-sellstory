import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sellstory/features/login/view/login_page.dart';
import 'package:sellstory/features/login/controller/login_controller.dart';
import 'package:sellstory/data/services/firebase_auth_service.dart';

class MockFirebaseAuthService extends Mock implements FirebaseAuthService {}
class MockLoginController extends Mock implements LoginController {}

void main() {
  late MockFirebaseAuthService mockAuthService;
  late MockLoginController mockController;

  setUp(() {
    mockAuthService = MockFirebaseAuthService();
    mockController = MockLoginController();
    
    // Setup GetX
    Get.put<FirebaseAuthService>(mockAuthService);
    Get.put<LoginController>(mockController);
  });

  tearDown(() {
    Get.reset();
  });

  group('LoginPage', () {
    testWidgets('should render login page with all elements', (WidgetTester tester) async {
      // Arrange
      when(() => mockController.obscurePassword).thenReturn(true.obs);
      when(() => mockController.canSubmit).thenReturn(false);
      when(() => mockController.isLoading).thenReturn(false.obs);
      when(() => mockController.togglePasswordVisibility()).thenReturn(null);
      when(() => mockController.onIdentityChanged(any())).thenReturn(null);
      when(() => mockController.onPasswordChanged(any())).thenReturn(null);
      when(() => mockController.signInWithEmail()).thenAnswer((_) async {});
      when(() => mockController.signInWithGoogle()).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(
        GetMaterialApp(
          home: const LoginPage(),
        ),
      );

      // Assert
      expect(find.text('อีเมล'), findsOneWidget);
      expect(find.text('รหัสผ่าน'), findsOneWidget);
      expect(find.text('ลืมรหัสผ่าน'), findsOneWidget);
      expect(find.text('เข้าสู่ระบบ'), findsOneWidget);
      expect(find.text('เข้าสู่ระบบด้วย Google'), findsOneWidget);
    });

    testWidgets('should call Google sign-in when Google button is tapped', (WidgetTester tester) async {
      // Arrange
      when(() => mockController.obscurePassword).thenReturn(true.obs);
      when(() => mockController.canSubmit).thenReturn(false);
      when(() => mockController.isLoading).thenReturn(false.obs);
      when(() => mockController.togglePasswordVisibility()).thenReturn(null);
      when(() => mockController.onIdentityChanged(any())).thenReturn(null);
      when(() => mockController.onPasswordChanged(any())).thenReturn(null);
      when(() => mockController.signInWithEmail()).thenAnswer((_) async {});
      when(() => mockController.signInWithGoogle()).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(
        GetMaterialApp(
          home: const LoginPage(),
        ),
      );

      await tester.tap(find.text('เข้าสู่ระบบด้วย Google'));
      await tester.pump();

      // Assert
      verify(() => mockController.signInWithGoogle()).called(1);
    });

    testWidgets('should call email sign-in when login button is tapped', (WidgetTester tester) async {
      // Arrange
      when(() => mockController.obscurePassword).thenReturn(true.obs);
      when(() => mockController.canSubmit).thenReturn(true);
      when(() => mockController.isLoading).thenReturn(false.obs);
      when(() => mockController.togglePasswordVisibility()).thenReturn(null);
      when(() => mockController.onIdentityChanged(any())).thenReturn(null);
      when(() => mockController.onPasswordChanged(any())).thenReturn(null);
      when(() => mockController.signInWithEmail()).thenAnswer((_) async {});
      when(() => mockController.signInWithGoogle()).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(
        GetMaterialApp(
          home: const LoginPage(),
        ),
      );

      await tester.tap(find.text('เข้าสู่ระบบ'));
      await tester.pump();

      // Assert
      verify(() => mockController.signInWithEmail()).called(1);
    });
  });
}

