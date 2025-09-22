import 'package:get/get.dart';
import '../features/splash/splash_page.dart';
import '../features/login/view/login_page.dart';
import '../features/shell/shell_page.dart';
import '../features/board/view/board_page.dart';
import '../features/board/view/user_cards_page.dart';
import '../features/board/view/card_view_page.dart';
import '../features/board/view/create_card_page.dart';
import '../features/board/view/create_workspace_page.dart';
import '../features/board/view/edit_workspace_page.dart';
import '../features/board/view/edit_card_page.dart';
import '../features/board/view/create_board_page.dart';
import '../features/board/view/edit_board_page.dart';
import '../features/board/view/board_management_page.dart';
import '../features/more/view/edit_profile_page.dart';
import '../features/webview/view/webview_page.dart';
import '../features/more/view/fcm_logs_page.dart';
import '../features/calendar/view/calendar_page.dart';
import '../features/board/view/card_view_setting_page.dart';
import '../features/archive/view/archive_page.dart';
import '../features/customers/view/customers_page.dart';
import '../features/companies/view/company_center_page.dart';
import '../features/login/view/forgot_password_email_page.dart' as fpe;
import '../features/login/view/forgot_password_otp_page.dart' as fpo;
import '../features/login/view/forgot_password_reset_page.dart' as fpr;

class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String shell = '/shell';
  static const String board = '/board';
  static const String userCards = '/user-cards';
  static const String cardView = '/card-view';
  static const String createCard = '/create-card';
  static const String editCard = '/edit-card';
  static const String createBoard = '/create-board';
  static const String editBoard = '/edit-board';
  static const String boardManagement = '/board-management';
  static const String createWorkspace = '/create-workspace';
  static const String editWorkspace = '/edit-workspace';
  static const String editProfile = '/edit-profile';
  static const String webview = '/webview';
  static const String fcmLogs = '/fcm-logs';
  static const String calendar = '/calendar';
  static const String cardViewSettings = '/card-view-settings';
  static const String archive = '/archive';
  static const String customers = '/customers';
  static const String companies = '/companies';

  // Forgot password flow
  static const String forgotPasswordEmail = '/forgot-password-email';
  static const String forgotPasswordOtp = '/forgot-password-otp';
  static const String forgotPasswordReset = '/forgot-password-reset';

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
      name: cardView,
      page: () => CardViewPage(card: Get.arguments),
    ),
    GetPage(
      name: createCard,
      page: () => CreateCardPage(
        laneId: Get.parameters['laneId'],
        boardId: Get.parameters['boardId'],
        workspaceId: Get.parameters['workspaceId'],
        initialCustomerId: Get.parameters['customerId'] ?? Get.parameters['cid'],
      ),
    ),
    GetPage(
      name: editCard,
      page: () => EditCardPage(card: Get.arguments),
    ),
    GetPage(
      name: createBoard,
      page: () => const CreateBoardPage(),
    ),
    GetPage(
      name: editBoard,
      page: () => EditBoardPage(board: Get.arguments['board']),
    ),
    GetPage(
      name: boardManagement,
      page: () => const BoardManagementPage(),
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
    GetPage(
      name: editProfile,
      page: () => const EditProfilePage(),
    ),
    GetPage(
      name: webview,
      page: () => WebViewPage(
        url: Get.parameters['url'],
        title: Get.parameters['title'],
        parameters: Get.arguments as Map<String, dynamic>?,
      ),
    ),
    GetPage(
      name: fcmLogs,
      page: () => const FcmLogsPage(),
    ),
    GetPage(
      name: calendar,
      page: () => const CalendarPage(),
    ),
    GetPage(
      name: cardViewSettings,
      page: () {
        // Prefer parameters (?boardId=) then arguments (map with 'boardId'), fallback to empty string.
        final paramBoardId = Get.parameters['boardId'];
        String resolvedBoardId = '';
        if (paramBoardId != null && paramBoardId.isNotEmpty) {
          resolvedBoardId = paramBoardId;
        } else {
          final args = Get.arguments;
            if (args is Map && args['boardId'] is String) {
              resolvedBoardId = args['boardId'] as String;
            }
        }
        return CardViewSettingPage(boardId: resolvedBoardId);
      },
    ),
    GetPage(
      name: archive,
      page: () => const ArchivePage(),
    ),
    GetPage(
      name: customers,
      page: () => const CustomersPage(),
    ),
    GetPage(
      name: companies,
      page: () => const CompanyCenterPage(),
    ),
    // Forgot password pages
    GetPage(
      name: forgotPasswordEmail,
      page: () => const fpe.ForgotPasswordEmailPage(),
    ),
    GetPage(
      name: forgotPasswordOtp,
      page: () => const fpo.ForgotPasswordOtpPage(),
    ),
    GetPage(
      name: forgotPasswordReset,
      page: () => const fpr.ForgotPasswordResetPage(),
    ),
  ];
}
