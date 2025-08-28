import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../controller/more_controller.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MoreController());

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
            child: CircularProgressIndicator(
              color: AppTheme.primaryOrange,
            ),
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
                    _buildMenuItem(
                      icon: Icons.dashboard_outlined,
                      title: 'Operation บอร์ด',
                      onTap: () {
                        Get.snackbar(
                          'Info',
                          'Operation Board coming soon',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                    ),
                    _buildDivider(),
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
                    _buildMenuItem(
                      icon: Icons.shopping_cart_outlined,
                      title: 'แหล่งที่มาลูกค้า',
                      onTap: () {
                        Get.snackbar(
                          'Info',
                          'Customer Source coming soon',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.tag_outlined,
                      title: '# Hashtag Center',
                      onTap: () {
                        Get.snackbar(
                          'Info',
                          'Hashtag Center coming soon',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
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
                          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
                          'platform': 'mobile',
                          'version': '1.10.9',
                        };
                        
                        Get.toNamed('/webview', arguments: parameters, parameters: {
                          'url': 'https://example.com/demo',
                          'title': 'Web View Demo',
                        });
                      },
                    ),
                    _buildDivider(),
                    _buildMenuItem(
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
                      icon: Icons.switch_account_outlined,
                      title: 'สลับบัญชี',
                      subtitle: 'BewLnwZa007',
                      onTap: () {
                        Get.snackbar(
                          'Info',
                          'Switch Account coming soon',
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
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
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
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
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
    return const Divider(
      height: 1,
      indent: 56,
      endIndent: 16,
    );
  }
}
