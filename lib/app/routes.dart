import 'package:get/get.dart';
import '../features/splash/splash_page.dart';
import '../features/login/view/login_page.dart';
import '../features/dashboard/view/dashboard_page.dart';
import '../features/shell/shell_page.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String shell = '/shell';

  static final routes = [
    GetPage(
      name: splash,
      page: () => const SplashPage(),
    ),
    GetPage(
      name: login,
      page: () => const LoginPage(),
    ),
    GetPage(
      name: dashboard,
      page: () => const DashboardPage(),
    ),
    GetPage(
      name: shell,
      page: () => const ShellPage(),
    ),
  ];
}
