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
      backgroundColor: AppTheme.backgroundGrey,
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
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Profile Picture
                      CircleAvatar(
                        radius: 30,
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
                                  fontSize: 20,
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
                            Text(
                              controller.displayName,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              controller.email,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Edit Profile Icon
                      IconButton(
                        onPressed: () {
                          // TODO: Navigate to edit profile page
                          Get.snackbar(
                            'Info',
                            'Edit profile feature coming soon',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                        icon: const Icon(
                          Icons.edit,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Menu Items
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Profile Menu Item
                    ListTile(
                      leading: const Icon(
                        Icons.person_outline,
                        color: AppTheme.primaryOrange,
                      ),
                      title: const Text(
                        'โปรไฟล์',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: const Text('จัดการข้อมูลส่วนตัว'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // TODO: Navigate to profile page
                        Get.snackbar(
                          'Info',
                          'Profile page coming soon',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                    ),
                    
                    const Divider(height: 1),
                    
                    // Settings Menu Item
                    ListTile(
                      leading: const Icon(
                        Icons.settings_outlined,
                        color: AppTheme.primaryOrange,
                      ),
                      title: const Text(
                        'ตั้งค่า',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: const Text('การตั้งค่าแอปพลิเคชัน'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // TODO: Navigate to settings page
                        Get.snackbar(
                          'Info',
                          'Settings page coming soon',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                    ),
                    
                    const Divider(height: 1),
                    
                    // Help Menu Item
                    ListTile(
                      leading: const Icon(
                        Icons.help_outline,
                        color: AppTheme.primaryOrange,
                      ),
                      title: const Text(
                        'ช่วยเหลือ',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: const Text('คู่มือการใช้งาน'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // TODO: Navigate to help page
                        Get.snackbar(
                          'Info',
                          'Help page coming soon',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: controller.logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('ออกจากระบบ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // App Version
              Text(
                'SellStory v1.0.0',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
