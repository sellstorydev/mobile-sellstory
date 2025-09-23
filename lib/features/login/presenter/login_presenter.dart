import 'package:get/get.dart';
import '../../../core/utils/validators.dart';
import '../../../data/services/auth_service.dart';
import '../contract/login_view.dart';

class LoginPresenter extends GetxController {
  final AuthService auth;
  late final LoginView view;
  
  var identity = ''.obs;
  var password = ''.obs;
  var canSubmit = false.obs;
  var isLoading = false.obs;

  LoginPresenter(this.auth);

  void bind(LoginView v) {
    view = v;
  }

  void onIdentityChanged(String value) {
    identity.value = value;
    _validateForm();
  }

  void onPasswordChanged(String value) {
    password.value = value;
    _validateForm();
  }

  void _validateForm() {
    final isValid = Validators.isValidIdentity(identity.value) &&
        Validators.isValidPassword(password.value);
    canSubmit.value = isValid;
    view.updateButtonEnabled(isValid);
  }

  Future<void> onSubmit() async {
    if (!canSubmit.value || isLoading.value) return;

    isLoading.value = true;
    view.showLoading(true);

    try {
      final result = await auth.login(
        identity: identity.value,
        password: password.value,
      );

      if (result.success) {
        // Navigate to dashboard on success
        Get.offAllNamed('/dashboard');
      } else {
        view.showError(result.errorMessage ?? 'login_failed'.tr);
      }
    } catch (e) {
      view.showError('an_error_occurred_please_try_again'.tr);
    } finally {
      isLoading.value = false;
      view.showLoading(false);
    }
  }
}
