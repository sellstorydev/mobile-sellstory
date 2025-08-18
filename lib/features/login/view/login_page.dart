import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../contract/login_view.dart';
import '../presenter/login_presenter.dart';
import '../widgets/branded_logo.dart';
import '../widgets/primary_button.dart';
import '../widgets/text_fields.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/theme/theme_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> implements LoginView {
  late final LoginPresenter presenter;

  @override
  void initState() {
    super.initState();
    // Dependency injection
    presenter = Get.put(LoginPresenter(Get.find<AuthService>()));
    presenter.bind(this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const BrandedLogo(),
                      const SizedBox(height: 48),
                      
                      // Text fields
                      LoginTextFields(
                        onIdentityChanged: presenter.onIdentityChanged,
                        onPasswordChanged: presenter.onPasswordChanged,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Forgot password link
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // TODO: Navigate to forgot password
                          },
                          child: Text(
                            'forgot_password'.tr,
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Login button
                      Obx(() => PrimaryButton(
                        text: 'login'.tr,
                        onPressed: presenter.canSubmit.value ? presenter.onSubmit : null,
                        isLoading: presenter.isLoading.value,
                      )),
                      
                      const SizedBox(height: 24),
                      
                      // Register link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${'register_q'.tr} ',
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // TODO: Navigate to register
                            },
                            child: Text(
                              'register'.tr,
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // Version text
                      Text(
                        'version'.tr,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Theme toggle button in top-right
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: () {
                  Get.find<ThemeController>().toggle();
                },
                icon: Obx(() {
                  final themeController = Get.find<ThemeController>();
                  return Icon(
                    themeController.mode.value == ThemeMode.dark 
                        ? Icons.light_mode 
                        : Icons.dark_mode,
                    color: Theme.of(context).primaryColor,
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void showLoading(bool value) {
    // Loading state is handled by Obx in the UI
  }

  @override
  void showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red[100],
      colorText: Colors.red[900],
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void updateButtonEnabled(bool enabled) {
    // Button state is handled by Obx in the UI
  }
}
