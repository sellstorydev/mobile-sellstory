import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../controller/more_controller.dart';
import '../../../app/routes.dart';
import '../../board/controller/board_controller.dart';
import '../../../core/widgets/permission_guard.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MoreController());
    final boardController = Get.find<BoardController>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('อื่น ๆ'),
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
                    _buildMenuItem(
                      icon: Icons.people_outline,
                      title: 'บริหารจัดการเซล',
                      onTap: () {
                        Get.snackbar(
                          'Info',
                          'Sales Management coming soon',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.archive_outlined,
                      title: 'Archive',
                      onTap: () {
                        Get.snackbar(
                          'Info',
                          'Archive coming soon',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                    ),
                    _buildDivider(),
                    PermissionGuard(
                      anyOf: const ['settings:catalog:manage'],
                      child: _buildMenuItem(
                        icon: Icons.tag_outlined,
                        title: 'Hashtag Center',
                        onTap: () {
                          final workspaceId =
                              boardController.currentWorkspaceId.value;
                          if (workspaceId.isNotEmpty) {
                            controller.openHashtagSettings(workspaceId);
                          } else {
                            Get.snackbar(
                              'Error',
                              'No workspace selected',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Get.theme.colorScheme.error
                                  .withValues(alpha: 0.1),
                              colorText: Get.theme.colorScheme.error,
                            );
                          }
                        },
                      ),
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.web,
                      title: 'Web View Demo',
                      onTap: () {
                        // Example of opening WebView with parameters
                        final parameters = {
                          'userId': 'user123',
                          'workspaceId': 'workspace456',
                          'token': 'demo_token_789',
                          'timestamp': DateTime.now().millisecondsSinceEpoch
                              .toString(),
                          'platform': 'mobile',
                          'version': '1.10.9',
                        };

                        Get.toNamed(
                          '/webview',
                          arguments: parameters,
                          parameters: {
                            'url': 'https://example.com/demo',
                            'title': 'Web View Demo',
                          },
                        );
                      },
                    ),

                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.business_outlined,
                      title: 'ตั้งค่าบริษัท',
                      onTap: () {
                        final workspaceId =
                            boardController.currentWorkspaceId.value;
                        if (workspaceId.isNotEmpty) {
                          controller.openCompanySettings(workspaceId);
                        } else {
                          Get.snackbar(
                            'Error',
                            'No workspace selected',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Get.theme.colorScheme.error
                                .withValues(alpha: 0.1),
                            colorText: Get.theme.colorScheme.error,
                          );
                        }
                      },
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.dashboard_outlined,
                      title: 'ตั้งค่า Board',
                      onTap: () {
                        final workspaceId =
                            boardController.currentWorkspaceId.value;
                        if (workspaceId.isNotEmpty) {
                          controller.openBoardSettings(workspaceId);
                        } else {
                          Get.snackbar(
                            'Error',
                            'No workspace selected',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Get.theme.colorScheme.error
                                .withValues(alpha: 0.1),
                            colorText: Get.theme.colorScheme.error,
                          );
                        }
                      },
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.notifications_outlined,
                      title: 'ตั้งค่าการแจ้งเตือน',
                      onTap: () {
                        final workspaceId =
                            boardController.currentWorkspaceId.value;
                        if (workspaceId.isNotEmpty) {
                          controller.openNotificationSettings(workspaceId);
                        } else {
                          Get.snackbar(
                            'Error',
                            'No workspace selected',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Get.theme.colorScheme.error
                                .withValues(alpha: 0.1),
                            colorText: Get.theme.colorScheme.error,
                          );
                        }
                      },
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.message_outlined,
                      title: 'ข้อความต้อนรับ',
                      onTap: () {
                        final workspaceId =
                            boardController.currentWorkspaceId.value;
                        if (workspaceId.isNotEmpty) {
                          controller.openWelcomeMessageSettings(workspaceId);
                        } else {
                          Get.snackbar(
                            'Error',
                            'No workspace selected',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Get.theme.colorScheme.error
                                .withValues(alpha: 0.1),
                            colorText: Get.theme.colorScheme.error,
                          );
                        }
                      },
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.smart_toy_outlined,
                      title: 'ตั้งค่า Chatbot',
                      onTap: () {
                        final workspaceId =
                            boardController.currentWorkspaceId.value;
                        if (workspaceId.isNotEmpty) {
                          controller.openChatbotSettings(workspaceId);
                        } else {
                          Get.snackbar(
                            'Error',
                            'No workspace selected',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Get.theme.colorScheme.error
                                .withValues(alpha: 0.1),
                            colorText: Get.theme.colorScheme.error,
                          );
                        }
                      },
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.rule_outlined,
                      title: 'กฎการสร้าง ID',
                      onTap: () {
                        final workspaceId =
                            boardController.currentWorkspaceId.value;
                        if (workspaceId.isNotEmpty) {
                          controller.openIdGenerationRules(workspaceId);
                        } else {
                          Get.snackbar(
                            'Error',
                            'No workspace selected',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Get.theme.colorScheme.error
                                .withValues(alpha: 0.1),
                            colorText: Get.theme.colorScheme.error,
                          );
                        }
                      },
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.security_outlined,
                      title: 'บทบาทและสิทธิ์',
                      onTap: () {
                        final workspaceId =
                            boardController.currentWorkspaceId.value;
                        if (workspaceId.isNotEmpty) {
                          controller.openRolesPermissions(workspaceId);
                        } else {
                          Get.snackbar(
                            'Error',
                            'No workspace selected',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Get.theme.colorScheme.error
                                .withValues(alpha: 0.1),
                            colorText: Get.theme.colorScheme.error,
                          );
                        }
                      },
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.approval_outlined,
                      title: 'เงื่อนไขการอนุมัติ',
                      onTap: () {
                        final workspaceId =
                            boardController.currentWorkspaceId.value;
                        if (workspaceId.isNotEmpty) {
                          controller.openApprovalConditions(workspaceId);
                        } else {
                          Get.snackbar(
                            'Error',
                            'No workspace selected',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Get.theme.colorScheme.error
                                .withValues(alpha: 0.1),
                            colorText: Get.theme.colorScheme.error,
                          );
                        }
                      },
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.description_outlined,
                      title: 'ตั้งค่าเอกสาร',
                      onTap: () {
                        final workspaceId =
                            boardController.currentWorkspaceId.value;
                        if (workspaceId.isNotEmpty) {
                          controller.openDocumentSettings(workspaceId);
                        } else {
                          Get.snackbar(
                            'Error',
                            'No workspace selected',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Get.theme.colorScheme.error
                                .withValues(alpha: 0.1),
                            colorText: Get.theme.colorScheme.error,
                          );
                        }
                      },
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.inventory_2_outlined,
                      title: 'ตั้งค่าแคตตาล็อก',
                      onTap: () {
                        final workspaceId =
                            boardController.currentWorkspaceId.value;
                        if (workspaceId.isNotEmpty) {
                          controller.openCatalogSettings(workspaceId);
                        } else {
                          Get.snackbar(
                            'Error',
                            'No workspace selected',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Get.theme.colorScheme.error
                                .withValues(alpha: 0.1),
                            colorText: Get.theme.colorScheme.error,
                          );
                        }
                      },
                    ),
                    _buildDivider(),
                    PermissionGuard(
                      anyOf: const ['settings:company:manage'],
                      child: _buildMenuItem(
                        icon: Icons.business_outlined,
                        title: 'ตั้งค่าบริษัท',
                        onTap: () {
                          Get.snackbar(
                            'Info',
                            'Company Settings coming soon',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                      ),
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.privacy_tip_outlined,
                      title: 'การยินยอมเปิดเผยข้อมูล',
                      onTap: () {
                        Get.snackbar(
                          'Info',
                          'Data Disclosure Consent coming soon',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      isLogout: true,
                      onTap: controller.logout,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Delete Account Button
              Center(
                child: TextButton(
                  onPressed: () {
                    Get.snackbar(
                      'Info',
                      'Delete Account feature coming soon',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  child: const Text(
                    'ลบบัญชี ยกเลิกการใช้งาน',
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              ),

              const SizedBox(height: 16),

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
