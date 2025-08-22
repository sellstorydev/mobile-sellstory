import 'package:get/get.dart';
import '../features/splash/splash_page.dart';
import '../features/login/view/login_page.dart';
import '../features/shell/shell_page.dart';
import '../features/board/view/board_page.dart';
import '../features/board/view/user_cards_page.dart';
import '../features/board/view/card_detail_page.dart';
import '../features/board/view/create_card_page.dart';
import '../features/board/view/create_workspace_page.dart';
import '../features/board/view/edit_workspace_page.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String shell = '/shell';
  static const String board = '/board';
  static const String userCards = '/user-cards';
  static const String cardDetail = '/card-detail';
  static const String createCard = '/create-card';
  static const String createWorkspace = '/create-workspace';
  static const String editWorkspace = '/edit-workspace';

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
    GetPage(
      name: cardDetail,
      page: () => CardDetailPage(card: Get.arguments),
    ),
    GetPage(
      name: createCard,
      page: () => CreateCardPage(
        laneId: Get.parameters['laneId'],
        boardId: Get.parameters['boardId'],
        workspaceId: Get.parameters['workspaceId'],
      ),
    ),
    GetPage(
      name: createWorkspace,
      page: () => const CreateWorkspacePage(),
    ),
    GetPage(
      name: editWorkspace,
      page: () => EditWorkspacePage(
        workspaceId: Get.parameters['workspaceId'] ?? '',
        currentName: Get.parameters['currentName'] ?? '',
      ),
    ),
  ];
}
