/// Interface for login view callbacks
abstract class LoginView {
  void showLoading(bool value);
  void showError(String message);
  void updateButtonEnabled(bool enabled);
}
