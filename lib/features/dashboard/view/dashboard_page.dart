import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/services/firebase_auth_service.dart';
import '../../../core/theme/theme_controller.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final authService = Get.find<FirebaseAuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Theme toggle
          IconButton(
            onPressed: () {
              Get.find<ThemeController>().toggle();
            },
            icon: Obx(() {
              final themeController = Get.find<ThemeController>();
              return Icon(
                themeController.mode.value == ThemeMode.dark 
                    ? Icons.light_mode 
                    : Icons.dark_mode,
              );
            }),
          ),
          // Sign out
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirmed = await Get.dialog<bool>(
                AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(result: false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Get.back(result: true),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await authService.signOut();
                Get.offAllNamed('/login');
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user?.email ?? user?.phoneNumber ?? 'User',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (user?.displayName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        user!.displayName!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // User info section
            Text(
              'Account Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow('User ID', user?.uid ?? 'N/A'),
                    if (user?.email != null) 
                      _buildInfoRow('Email', user!.email!),
                    if (user?.phoneNumber != null) 
                      _buildInfoRow('Phone', user!.phoneNumber!),
                    if (user?.emailVerified != null) 
                      _buildInfoRow('Email Verified', user!.emailVerified ? 'Yes' : 'No'),
                    _buildInfoRow('Provider', user?.providerData.first.providerId ?? 'N/A'),
                    _buildInfoRow('Created', user?.metadata.creationTime?.toString().split(' ')[0] ?? 'N/A'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Quick actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to profile
                      Get.snackbar('Info', 'Profile feature coming soon!');
                    },
                    icon: const Icon(Icons.person),
                    label: const Text('Profile'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to settings
                      Get.snackbar('Info', 'Settings feature coming soon!');
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Settings'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
