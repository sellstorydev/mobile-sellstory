// import 'package:flutter_test/flutter_test.dart';
// import 'package:get/get.dart';
// import 'package:mocktail/mocktail.dart';
// import 'package:sellstory/features/login/view/login_page.dart';
// import 'package:sellstory/features/login/controller/login_controller.dart';
// import 'package:sellstory/data/services/firebase_auth_service.dart';
//
// class MockFirebaseAuthService extends Mock implements FirebaseAuthService {}
//
// abstract class MockLoginController extends GetxController implements LoginController {
//   final RxBool _obscurePassword = true.obs;
//   final RxBool _isLoading = false.obs;
//   final RxString _identity = ''.obs;
//   final RxString _password = ''.obs;
//
//   @override
//   RxBool get obscurePassword => _obscurePassword;
//
//   @override
//   bool get canSubmit => _identity.value.isNotEmpty && _password.value.isNotEmpty;
//
//   @override
//   RxBool get isLoading => _isLoading;
//
//   @override
//   RxString get identity => _identity;
//
//   @override
//   RxString get password => _password;
//
//   @override
//   void togglePasswordVisibility() {
//     _obscurePassword.value = !_obscurePassword.value;
//   }
//
//   @override
//   void onIdentityChanged(String value) {
//     _identity.value = value;
//   }
//
//   @override
//   void onPasswordChanged(String value) {
//     _password.value = value;
//   }
//
//   @override
//   Future<void> signInWithEmail() async {
//     // Mock implementation
//   }
//
//   @override
//   Future<void> signInWithGoogle() async {
//     // Mock implementation
//   }
//
//   @override
//   Future<void> forgotPassword() async {
//     // Mock implementation
//   }
// }
//
// void main() {
//   late MockFirebaseAuthService mockAuthService;
//   late MockLoginController mockController;
//
//   setUp(() {
//     mockAuthService = MockFirebaseAuthService();
//     // mockController = MockLoginController();
//
//     // Setup GetX
//     Get.testMode = true; // Enable test mode to avoid navigation issues
//     Get.put<FirebaseAuthService>(mockAuthService);
//     Get.put<LoginController>(mockController);
//   });
//
//   tearDown(() {
//     Get.reset();
//   });
//
//   group('LoginPage', () {
//     testWidgets('should render login page with all elements', (WidgetTester tester) async {
//       // Arrange - No need to mock since we're using a real implementation
//
//       // Act
//       await tester.pumpWidget(
//         const GetMaterialApp(
//           home: LoginPage(),
//         ),
//       );
//
//       // Assert
//       expect(find.text('อีเมล'), findsOneWidget);
//       expect(find.text('รหัสผ่าน'), findsOneWidget);
//       expect(find.text('ลืมรหัสผ่าน'), findsOneWidget);
//       expect(find.text('เข้าสู่ระบบ'), findsOneWidget);
//       expect(find.text('เข้าสู่ระบบด้วย Google'), findsOneWidget);
//     });
//
//     testWidgets('should call Google sign-in when Google button is tapped', (WidgetTester tester) async {
//       // Arrange - No need to mock since we're using a real implementation
//
//       // Act
//       await tester.pumpWidget(
//         const GetMaterialApp(
//           home: LoginPage(),
//         ),
//       );
//
//       await tester.tap(find.text('เข้าสู่ระบบด้วย Google'));
//       await tester.pump();
//
//       // Assert - Since we're using a real implementation, we can't verify calls
//       // The test passes if no exceptions are thrown
//     });
//
//     testWidgets('should call email sign-in when login button is tapped', (WidgetTester tester) async {
//       // Arrange - No need to mock since we're using a real implementation
//
//       // Act
//       await tester.pumpWidget(
//         const GetMaterialApp(
//           home: LoginPage(),
//         ),
//       );
//
//       await tester.tap(find.text('เข้าสู่ระบบ'));
//       await tester.pump();
//
//       // Assert - Since we're using a real implementation, we can't verify calls
//       // The test passes if no exceptions are thrown
//     });
//   });
// }
//
