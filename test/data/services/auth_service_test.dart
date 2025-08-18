import 'package:flutter_test/flutter_test.dart';
import 'package:sellstory/data/services/auth_service.dart';

void main() {
  group('DummyAuthService', () {
    late DummyAuthService authService;

    setUp(() {
      authService = DummyAuthService();
    });

    group('login', () {
      test('should return success when password is "123456" and identity is not empty', () async {
        // Arrange
        const identity = 'test@example.com';
        const password = '123456';

        // Act
        final result = await authService.login(
          identity: identity,
          password: password,
        );

        // Assert
        expect(result.success, true);
        expect(result.user, isNotNull);
        expect(result.user!.email, identity);
        expect(result.user!.name, 'Test User');
        expect(result.errorMessage, isNull);
      });

      test('should return success when password is "123456" and identity is phone number', () async {
        // Arrange
        const identity = '0812345678';
        const password = '123456';

        // Act
        final result = await authService.login(
          identity: identity,
          password: password,
        );

        // Assert
        expect(result.success, true);
        expect(result.user, isNotNull);
        expect(result.user!.phone, identity);
        expect(result.user!.email, 'test@example.com');
        expect(result.errorMessage, isNull);
      });

      test('should return failure when password is not "123456"', () async {
        // Arrange
        const identity = 'test@example.com';
        const password = 'wrongpassword';

        // Act
        final result = await authService.login(
          identity: identity,
          password: password,
        );

        // Assert
        expect(result.success, false);
        expect(result.user, isNull);
        expect(result.errorMessage, 'invalid_credentials');
      });

      test('should return failure when identity is empty', () async {
        // Arrange
        const identity = '';
        const password = '123456';

        // Act
        final result = await authService.login(
          identity: identity,
          password: password,
        );

        // Assert
        expect(result.success, false);
        expect(result.user, isNull);
        expect(result.errorMessage, 'invalid_credentials');
      });

      test('should return failure when identity is only whitespace', () async {
        // Arrange
        const identity = '   ';
        const password = '123456';

        // Act
        final result = await authService.login(
          identity: identity,
          password: password,
        );

        // Assert
        expect(result.success, false);
        expect(result.user, isNull);
        expect(result.errorMessage, 'invalid_credentials');
      });

      test('should have artificial delay of approximately 600ms', () async {
        // Arrange
        const identity = 'test@example.com';
        const password = '123456';

        // Act & Assert
        final stopwatch = Stopwatch()..start();
        await authService.login(
          identity: identity,
          password: password,
        );
        stopwatch.stop();

        // Should be at least 600ms (allowing for some variance)
        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(590));
      });
    });
  });
}
