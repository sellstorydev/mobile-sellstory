import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../controller/board_controller.dart';

class CreateWorkspacePage extends StatefulWidget {
  const CreateWorkspacePage({super.key});

  @override
  State<CreateWorkspacePage> createState() => _CreateWorkspacePageState();
}

class _CreateWorkspacePageState extends State<CreateWorkspacePage> {
  final FirestoreRepository _repository = Get.find<FirestoreRepository>();
  final TextEditingController _workspaceNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _workspaceNameController.dispose();
    super.dispose();
  }

  Future<void> _createWorkspace() async {
    if (_workspaceNameController.text.trim().isEmpty) {
      _showError('Workspace name is required');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showError('User not authenticated');
        return;
      }

      final workspaceName = _workspaceNameController.text.trim();
      
      // Create workspace with default structure
      await _repository.createWorkspace(
        name: workspaceName,
        ownerId: currentUser.uid,
        ownerEmail: currentUser.email ?? '',
        ownerDisplayName: currentUser.displayName ?? 'User',
      );

      // Show success message
      Get.snackbar(
        'Success',
        'Workspace "$workspaceName" created successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Navigate back to board page and refresh data
      Get.offAllNamed('/board');
      
      // Refresh board controller after navigation
      try {
        final boardController = Get.find<BoardController>();
        await boardController.initializeWithUser(currentUser.uid);
      } catch (e) {
        print('⚠️ Failed to refresh board controller: $e');
        // Continue anyway, user can manually refresh
      }
    } catch (e) {
      _showError('Failed to create workspace: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Workspace'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              'Create New Workspace',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Description
            const Text(
              'A workspace contains its own boards, customers, products, and settings.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Workspace Name Input
            const Text(
              'Workspace Name',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 8),
            
            TextField(
              controller: _workspaceNameController,
              decoration: const InputDecoration(
                hintText: 'e.g. My New Business',
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primaryOrange, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primaryOrange, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              autofocus: true,
            ),
            
            const Spacer(),
            
            // Action Buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createWorkspace,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Create',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _isLoading ? null : () => Get.back(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
