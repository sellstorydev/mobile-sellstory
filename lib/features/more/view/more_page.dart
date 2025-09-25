import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../controller/more_controller.dart';
import '../../board/controller/board_controller.dart';
import '../../../core/widgets/permission_guard.dart';
import '../../../translation/widgets/language_switcher_widget.dart';
import '../../../app/routes.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MoreController());
    final boardController = Get.find<BoardController>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: Text('others_nav'.tr),
        backgroundColor: AppTheme.backgroundWhite,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryOrange),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile Section
              GestureDetector(
                onTap: () {
                  Get.toNamed('/edit-profile');
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      // Profile Picture
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: AppTheme.primaryOrange,
                        backgroundImage: controller.photoURL != null
                            ? NetworkImage(controller.photoURL!)
                            : null,
                        child: controller.photoURL == null
                            ? Text(
                                controller.displayName.isNotEmpty
                                    ? controller.displayName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),

                      // User Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              const Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 16,
                                  color: AppTheme.primaryOrange,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Profile',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              controller.displayName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Menu Items
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    // Language Settings
                    _buildMenuItem(
                      icon: Icons.language_outlined,
                      title: 'language'.tr,
                      onTap: () {
                        LanguageSelectionSheet.show(context);
                      },
                    ),
                    _buildDivider(),
                    // Show IAP menu on iOS OR when user locale is not Thai (non-TH market rollout)
                    // if (Platform.isIOS ||
                    //     (Get.locale?.languageCode != 'th')) ...[
                    //   _buildMenuItem(
                    //     icon: Icons.star_outline,
                    //     title: 'iap_menu'.tr,
                    //     onTap: () {
                    //       Get.toNamed(AppRoutes.iap);
                    //     },
                    //   ),
                    //   _buildDivider(),
                    // ],
                    // PermissionGuard(
                    //   anyOf: const ['settings:board:manage'],
                    //   child: _buildMenuItem(
                    //     icon: Icons.dashboard_outlined,
                    //     title: 'Operation บอร์ด',
                    //     onTap: () {
                    //       Get.snackbar(
                    //         'Info',
                    //         'Operation Board coming soon',
                    //         snackPosition: SnackPosition.BOTTOM,
                    //       );
                    //     },
                    //   ),
                    // ),
                    // _buildDivider(),
                    // _buildMenuItem(
                    //   icon: Icons.people_outline,
                    //   title: 'sales_management'.tr,
                    //   onTap: () {
                    //     Get.snackbar(
                    //       'Info',
                    //       'sales_management_coming_soon'.tr,
                    //       snackPosition: SnackPosition.BOTTOM,
                    //     );
                    //   },
                    // ),
                    // _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.archive_outlined,
                      title: 'archive'.tr,
                      onTap: () {
                        Get.toNamed('/archive');
                      },
                    ),
                    // _buildDivider(),
                    // PermissionGuard(
                    //   anyOf: const ['settings:catalog:manage'],
                    //   child: _buildMenuItem(
                    //     icon: Icons.tag_outlined,
                    //     title: 'hashtag_center'.tr,
                    //     onTap: () {
                    //       final workspaceId =
                    //           boardController.currentWorkspaceId.value;
                    //       if (workspaceId.isNotEmpty) {
                    //         controller.openHashtagSettings(workspaceId);
                    //       } else {
                    //         Get.snackbar(
                    //           'Error',
                    //           'no_workspace_selected'.tr,
                    //           snackPosition: SnackPosition.BOTTOM,
                    //           backgroundColor: Get.theme.colorScheme.error
                    //               .withValues(alpha: 0.1),
                    //           colorText: Get.theme.colorScheme.error,
                    //         );
                    //       }
                    //     },
                    //   ),
                    // ),
                    // _buildDivider(),
                    // _buildMenuItem(
                    //   icon: Icons.web,
                    //   title: 'Web View Demo',
                    //   onTap: () {
                    //     // Example of opening WebView with parameters
                    //     final parameters = {
                    //       'userId': 'user123',
                    //       'workspaceId': 'workspace456',
                    //       'token': 'demo_token_789',
                    //       'timestamp': DateTime.now().millisecondsSinceEpoch
                    //           .toString(),
                    //       'platform': 'mobile',
                    //       'version': '1.10.9',
                    //     };

                    //     Get.toNamed(
                    //       '/webview',
                    //       arguments: parameters,
                    //       parameters: {
                    //         'url': 'https://example.com/demo',
                    //         'title': 'Web View Demo',
                    //       },
                    //     );
                    //   },
                    // ),

                    // _buildDivider(),
                    // PermissionGuard(
                    //   anyOf: const ['settings:company:manage'],
                    //   child: _buildMenuItem(
                    //     icon: Icons.business_outlined,
                    //     title: 'company_settings'.tr,
                    //     onTap: () {
                    //       final workspaceId =
                    //           boardController.currentWorkspaceId.value;
                    //       if (workspaceId.isNotEmpty) {
                    //         controller.openCompanySettings(workspaceId);
                    //       } else {
                    //         Get.snackbar(
                    //           'Error',
                    //           '',
                    //           snackPosition: SnackPosition.BOTTOM,
                    //           backgroundColor: Get.theme.colorScheme.error
                    //               .withValues(alpha: 0.1),
                    //           colorText: Get.theme.colorScheme.error,
                    //         );
                    //       }
                    //     },
                    //   ),
                    // ),
                    // _buildDivider(),
                    // PermissionGuard(
                    //   anyOf: const ['settings:board:manage'],
                    //   child: _buildMenuItem(
                    //     icon: Icons.dashboard_outlined,
                    //     title: 'board_settings'.tr,
                    //     onTap: () {
                    //       final workspaceId =
                    //           boardController.currentWorkspaceId.value;
                    //       if (workspaceId.isNotEmpty) {
                    //         controller.openBoardSettings(workspaceId);
                    //       } else {
                    //         Get.snackbar(
                    //           'Error',
                    //           '',
                    //           snackPosition: SnackPosition.BOTTOM,
                    //           backgroundColor: Get.theme.colorScheme.error
                    //               .withValues(alpha: 0.1),
                    //           colorText: Get.theme.colorScheme.error,
                    //         );
                    //       }
                    //     },
                    //   ),
                    // ),
                    // _buildDivider(),
                    // _buildMenuItem(
                    //   icon: Icons.notifications_outlined,
                    //   title: 'notification_settings'.tr,
                    //   onTap: () {
                    //     final workspaceId =
                    //         boardController.currentWorkspaceId.value;
                    //     if (workspaceId.isNotEmpty) {
                    //       controller.openNotificationSettings(workspaceId);
                    //     } else {
                    //       Get.snackbar(
                    //         'Error',
                    //         '',
                    //         snackPosition: SnackPosition.BOTTOM,
                    //         backgroundColor: Get.theme.colorScheme.error
                    //             .withValues(alpha: 0.1),
                    //         colorText: Get.theme.colorScheme.error,
                    //       );
                    //     }
                    //   },
                    // ),
                    // _buildDivider(),
                    // _buildMenuItem(
                    //   icon: Icons.message_outlined,
                    //   title: 'welcome_message'.tr,
                    //   onTap: () {
                    //     final workspaceId =
                    //         boardController.currentWorkspaceId.value;
                    //     if (workspaceId.isNotEmpty) {
                    //       controller.openWelcomeMessageSettings(workspaceId);
                    //     } else {
                    //       Get.snackbar(
                    //         'Error',
                    //         '',
                    //         snackPosition: SnackPosition.BOTTOM,
                    //         backgroundColor: Get.theme.colorScheme.error
                    //             .withValues(alpha: 0.1),
                    //         colorText: Get.theme.colorScheme.error,
                    //       );
                    //     }
                    //   },
                    // ),
                    // _buildDivider(),
                    // _buildMenuItem(
                    //   icon: Icons.smart_toy_outlined,
                    //   title: 'chatbot_settings'.tr,
                    //   onTap: () {
                    //     final workspaceId =
                    //         boardController.currentWorkspaceId.value;
                    //     if (workspaceId.isNotEmpty) {
                    //       controller.openChatbotSettings(workspaceId);
                    //     } else {
                    //       Get.snackbar(
                    //         'Error',
                    //         '',
                    //         snackPosition: SnackPosition.BOTTOM,
                    //         backgroundColor: Get.theme.colorScheme.error
                    //             .withValues(alpha: 0.1),
                    //         colorText: Get.theme.colorScheme.error,
                    //       );
                    //     }
                    //   },
                    // ),
                    // _buildDivider(),
                    // _buildMenuItem(
                    //   icon: Icons.rule_outlined,
                    //   title: 'id_generation_rules'.tr,
                    //   onTap: () {
                    //     final workspaceId =
                    //         boardController.currentWorkspaceId.value;
                    //     if (workspaceId.isNotEmpty) {
                    //       controller.openIdGenerationRules(workspaceId);
                    //     } else {
                    //       Get.snackbar(
                    //         'Error',
                    //         '',
                    //         snackPosition: SnackPosition.BOTTOM,
                    //         backgroundColor: Get.theme.colorScheme.error
                    //             .withValues(alpha: 0.1),
                    //         colorText: Get.theme.colorScheme.error,
                    //       );
                    //     }
                    //   },
                    // ),
                    // _buildDivider(),
                    // _buildMenuItem(
                    //   icon: Icons.security_outlined,
                    //   title: 'roles_permissions'.tr,
                    //   onTap: () {
                    //     final workspaceId =
                    //         boardController.currentWorkspaceId.value;
                    //     if (workspaceId.isNotEmpty) {
                    //       controller.openRolesPermissions(workspaceId);
                    //     } else {
                    //       Get.snackbar(
                    //         'Error',
                    //         '',
                    //         snackPosition: SnackPosition.BOTTOM,
                    //         backgroundColor: Get.theme.colorScheme.error
                    //             .withValues(alpha: 0.1),
                    //         colorText: Get.theme.colorScheme.error,
                    //       );
                    //     }
                    //   },
                    // ),
                    // _buildDivider(),
                    // _buildMenuItem(
                    //   icon: Icons.approval_outlined,
                    //   title: 'approval_conditions'.tr,
                    //   onTap: () {
                    //     final workspaceId =
                    //         boardController.currentWorkspaceId.value;
                    //     if (workspaceId.isNotEmpty) {
                    //       controller.openApprovalConditions(workspaceId);
                    //     } else {
                    //       Get.snackbar(
                    //         'Error',
                    //         '',
                    //         snackPosition: SnackPosition.BOTTOM,
                    //         backgroundColor: Get.theme.colorScheme.error
                    //             .withValues(alpha: 0.1),
                    //         colorText: Get.theme.colorScheme.error,
                    //       );
                    //     }
                    //   },
                    // ),
                    // _buildDivider(),
                    // _buildMenuItem(
                    //   icon: Icons.description_outlined,
                    //   title: 'document_settings'.tr,
                    //   onTap: () {
                    //     final workspaceId =
                    //         boardController.currentWorkspaceId.value;
                    //     if (workspaceId.isNotEmpty) {
                    //       controller.openDocumentSettings(workspaceId);
                    //     } else {
                    //       Get.snackbar(
                    //         'Error',
                    //         '',
                    //         snackPosition: SnackPosition.BOTTOM,
                    //         backgroundColor: Get.theme.colorScheme.error
                    //             .withValues(alpha: 0.1),
                    //         colorText: Get.theme.colorScheme.error,
                    //       );
                    //     }
                    //   },
                    // ),
    
                    // _buildDivider(),
                    // PermissionGuard(
                    //   anyOf: const ['settings:company:manage'],
                    //   child: _buildMenuItem(
                    //     icon: Icons.business_outlined,
                    //     title: 'ตั้งค่าบริษัท',
                    //     onTap: () {
                    //       Get.snackbar(
                    //         'Info',
                    //         'Company Settings coming soon',
                    //         snackPosition: SnackPosition.BOTTOM,
                    //       );
                    //     },
                    //   ),
                    // ),
                    // _buildDivider(),
                    // _buildMenuItem(
                    //   icon: Icons.privacy_tip_outlined,
                    //   title: 'data_disclosure_consent'.tr,
                    //   onTap: () {
                    //     Get.snackbar(
                    //       'Info',
                    //       'data_disclosure_coming_soon'.tr,
                    //       snackPosition: SnackPosition.BOTTOM,
                    //     );
                    //   },
                    // ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.logout,
                      title: 'logout'.tr,
                      isLogout: true,
                      onTap: controller.logout,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // // Delete Account Button
              // Center(
              //   child: TextButton(
              //     onPressed: () {
              //       Get.snackbar(
              //         'Info',
              //         'delete_account_coming_soon'.tr,
              //         snackPosition: SnackPosition.BOTTOM,
              //       );
              //     },
              //     child: Text(
              //       'delete_account'.tr,
              //       style: const TextStyle(color: Colors.red, fontSize: 14),
              //     ),
              //   ),
              // ),

              // const SizedBox(height: 16),

              // App Version
              Center(
                child: Text(
                  'SellStory v1.10.9',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout ? Colors.red : AppTheme.primaryOrange,
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isLogout ? Colors.red : AppTheme.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            )
          : null,
      trailing: isLogout
          ? const Icon(Icons.arrow_forward, color: Colors.red, size: 16)
          : const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.grey.shade200,
      indent: 16,
      endIndent: 16,
    );
  }
}
