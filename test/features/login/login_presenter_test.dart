import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sellstory/data/services/auth_service.dart';
import 'package:sellstory/features/login/contract/login_view.dart';
import 'package:sellstory/features/login/presenter/login_presenter.dart';
import 'package:sellstory/models/auth_result.dart';
import 'package:sellstory/models/user.dart';

class MockAuthService extends Mock implements AuthService {}
class MockLoginView extends Mock implements LoginView {}

void main() {
  late LoginPresenter presenter;
  late MockAuthService mockAuthService;
  late MockLoginView mockView;

  setUp(() {
    mockAuthService = MockAuthService();
    mockView = MockLoginView();
    presenter = LoginPresenter(mockAuthService);
    presenter.bind(mockView);
  });

  tearDown(() {
    Get.reset();
  });

  group('LoginPresenter', () {
    group('Form Validation', () {
      test('should set canSubmit to false when fields are invalid', () {
        // Arrange
        when(() => mockView.updateButtonEnabled(any())).thenReturn(null);

        // Act
        presenter.onIdentityChanged('test'); // less than 5 chars
        presenter.onPasswordChanged('12345'); // less than 6 chars

        // Assert
        expect(presenter.canSubmit.value, false);
        verify(() => mockView.updateButtonEnabled(false)).called(2);
      });

      test('should set canSubmit to true when fields are valid', () {
        // Arrange
        when(() => mockView.updateButtonEnabled(any())).thenReturn(null);

        // Act
        presenter.onIdentityChanged('test@example.com'); // valid identity
        presenter.onPasswordChanged('123456'); // valid password

        // Assert
        expect(presenter.canSubmit.value, true);
        verify(() => mockView.updateButtonEnabled(true)).called(1);
      });

      test('should update identity and password observables', () {
        // Act
        presenter.onIdentityChanged('test@example.com');
        presenter.onPasswordChanged('123456');

        // Assert
        expect(presenter.identity.value, 'test@example.com');
        expect(presenter.password.value, '123456');
      });
    });

    group('onSubmit', () {
      test('should not proceed when canSubmit is false', () async {
        // Arrange
        presenter.canSubmit.value = false;

        // Act
        await presenter.onSubmit();

        // Assert
        verifyNever(() => mockAuthService.login(identity: any(named: 'identity'), password: any(named: 'password')));
        verifyNever(() => mockView.showLoading(true));
      });

      test('should not proceed when already loading', () async {
        // Arrange
        presenter.canSubmit.value = true;
        presenter.isLoading.value = true;

        // Act
        await presenter.onSubmit();

        // Assert
        verifyNever(() => mockAuthService.login(identity: any(named: 'identity'), password: any(named: 'password')));
        verifyNever(() => mockView.showLoading(true));
      });

      test('should handle successful login', () async {
        // Arrange
        const testUser = User(id: '1', name: 'Test User', email: 'test@example.com');
        const authResult = AuthResult.success(testUser);
        
        presenter.canSubmit.value = true;
        presenter.identity.value = 'test@example.com';
        presenter.password.value = '123456';

        when(() => mockAuthService.login(
          identity: any(named: 'identity'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => authResult);

        when(() => mockView.showLoading(any())).thenReturn(null);

        // Act
        await presenter.onSubmit();

        // Assert
        verify(() => mockView.showLoading(true)).called(1);
        verify(() => mockAuthService.login(
          identity: 'test@example.com',
          password: '123456',
        )).called(1);
        verify(() => mockView.showLoading(false)).called(1);
        expect(presenter.isLoading.value, false);
      });

      test('should handle failed login', () async {
        // Arrange
        const authResult = AuthResult.failure('Invalid credentials');
        
        presenter.canSubmit.value = true;
        presenter.identity.value = 'test@example.com';
        presenter.password.value = 'wrongpassword';

        when(() => mockAuthService.login(
          identity: any(named: 'identity'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => authResult);

        when(() => mockView.showLoading(any())).thenReturn(null);
        when(() => mockView.showError(any())).thenReturn(null);

        // Act
        await presenter.onSubmit();

        // Assert
        verify(() => mockView.showLoading(true)).called(1);
        verify(() => mockAuthService.login(
          identity: 'test@example.com',
          password: 'wrongpassword',
        )).called(1);
        verify(() => mockView.showError('Invalid credentials')).called(1);
        verify(() => mockView.showLoading(false)).called(1);
        expect(presenter.isLoading.value, false);
      });

      test('should handle exceptions', () async {
        // Arrange
        presenter.canSubmit.value = true;
        presenter.identity.value = 'test@example.com';
        presenter.password.value = '123456';

        when(() => mockAuthService.login(
          identity: any(named: 'identity'),
          password: any(named: 'password'),
        )).thenThrow(Exception('Network error'));

        when(() => mockView.showLoading(any())).thenReturn(null);
        when(() => mockView.showError(any())).thenReturn(null);

        // Act
        await presenter.onSubmit();

        // Assert
        verify(() => mockView.showLoading(true)).called(1);
        verify(() => mockView.showError('An error occurred. Please try again.')).called(1);
        verify(() => mockView.showLoading(false)).called(1);
        expect(presenter.isLoading.value, false);
      });
    });
  });
}
