import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sellstory/features/login/controller/login_controller.dart';
import 'package:sellstory/data/services/firebase_auth_service.dart';

class MockFirebaseAuthService extends Mock implements FirebaseAuthService {}
class MockUserCredential extends Mock implements UserCredential {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late LoginController controller;
  late MockFirebaseAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockFirebaseAuthService();
    Get.put<FirebaseAuthService>(mockAuthService);
    Get.testMode = true; // Enable test mode to avoid navigation issues
    controller = LoginController();
  });

  tearDown(() {
    Get.reset();
  });

  group('LoginController', () {
    test('should initialize with correct default values', () {
      expect(controller.identity.value, '');
      expect(controller.password.value, '');
      expect(controller.isLoading.value, false);
      expect(controller.obscurePassword.value, true);
    });

    test('canSubmit should return false when fields are empty', () {
      expect(controller.canSubmit, false);
    });

    test('canSubmit should return true when email and password are filled', () {
      controller.identity.value = 'test@example.com';
      controller.password.value = 'password123';
      expect(controller.canSubmit, true);
    });

    test('togglePasswordVisibility should toggle password visibility', () {
      expect(controller.obscurePassword.value, true);
      
      controller.togglePasswordVisibility();
      expect(controller.obscurePassword.value, false);
      
      controller.togglePasswordVisibility();
      expect(controller.obscurePassword.value, true);
    });

    test('onIdentityChanged should update identity value', () {
      controller.onIdentityChanged('test@example.com');
      expect(controller.identity.value, 'test@example.com');
    });

    test('onPasswordChanged should update password value', () {
      controller.onPasswordChanged('password123');
      expect(controller.password.value, 'password123');
    });

    test('signInWithEmail should call auth service when form is valid', () async {
      // Arrange
      controller.identity.value = 'test@example.com';
      controller.password.value = 'password123';
      
      when(() => mockAuthService.signInWithEmail(any(), any()))
          .thenAnswer((_) async => MockUserCredential());
      
      // Act & Assert
      expect(() => controller.signInWithEmail(), returnsNormally);
      verify(() => mockAuthService.signInWithEmail('test@example.com', 'password123')).called(1);
    });

    test('signInWithGoogle should call auth service', () async {
      // Arrange
      when(() => mockAuthService.signInWithGoogle())
          .thenAnswer((_) async => MockUserCredential());
      
      // Act
      await controller.signInWithGoogle();
      
      // Assert
      verify(() => mockAuthService.signInWithGoogle()).called(1);
    });
  });
}
