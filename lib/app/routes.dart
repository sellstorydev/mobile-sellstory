import 'package:get/get.dart';
import '../features/splash/splash_page.dart';
import '../features/login/view/login_page.dart';
import '../features/shell/shell_page.dart';
import '../features/board/view/board_page.dart';
import '../features/board/view/user_cards_page.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String shell = '/shell';
  static const String board = '/board';
  static const String userCards = '/user-cards';

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
      name: shell,
      page: () => const ShellPage(),
    ),
    GetPage(
      name: board,
      page: () => const BoardPage(),
    ),
    GetPage(
      name: userCards,
      page: () => const UserCardsPage(),
    ),
  ];
}
