import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dialog_utils.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../controller/board_controller.dart';

class EditWorkspacePage extends StatefulWidget {
  final String workspaceId;
  final String currentName;

  const EditWorkspacePage({
    super.key,
    required this.workspaceId,
    required this.currentName,
  });

  @override
  State<EditWorkspacePage> createState() => _EditWorkspacePageState();
}

class _EditWorkspacePageState extends State<EditWorkspacePage> {
  final FirestoreRepository _repository = Get.find<FirestoreRepository>();
  final TextEditingController _workspaceNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _workspaceNameController.text = widget.currentName;
  }

  @override
  void dispose() {
    _workspaceNameController.dispose();
    super.dispose();
  }

  Future<void> _deleteWorkspace() async {
    // Show confirmation dialog
    final shouldDelete = await DialogUtils.showDeleteConfirmDialog(
      context: context,
      title: 'Delete Workspace',
      content: 'Are you sure you want to delete "${widget.currentName}"? This action cannot be undone and will delete all boards, cards, and data in this workspace.',
    );

    if (shouldDelete != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showError('User not authenticated');
        return;
      }

      // Delete workspace
      await _repository.deleteWorkspace(
        workspaceId: widget.workspaceId,
        userId: currentUser.uid,
      );

      // Show success message
      Get.snackbar(
        'Success',
        'Workspace deleted successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Navigate back to shell page (which contains the board page with bottom navigation)
      Get.offAllNamed('/shell');
      
      // Refresh board controller after navigation
      try {
        final boardController = Get.find<BoardController>();
        await boardController.initializeWithUser(currentUser.uid);
      } catch (e) {
        print('⚠️ Failed to refresh board controller: $e');
        // Continue anyway, user can manually refresh
      }
    } catch (e) {
      _showError('Failed to delete workspace: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateWorkspace() async {
    if (_workspaceNameController.text.trim().isEmpty) {
      _showError('Workspace name is required');
      return;
    }

    if (_workspaceNameController.text.trim() == widget.currentName) {
      _showError('No changes made');
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

      final newWorkspaceName = _workspaceNameController.text.trim();
      
      // Update workspace name
      await _repository.updateWorkspaceName(
        workspaceId: widget.workspaceId,
        newName: newWorkspaceName,
        userId: currentUser.uid,
      );

      // Show success message
      Get.snackbar(
        'Success',
        'Workspace name updated successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Navigate back to shell page (which contains the board page with bottom navigation)
      Get.offAllNamed('/shell');
      
      // Refresh board controller after navigation
      try {
        final boardController = Get.find<BoardController>();
        await boardController.initializeWithUser(currentUser.uid);
      } catch (e) {
        print('⚠️ Failed to refresh board controller: $e');
        // Continue anyway, user can manually refresh
      }
    } catch (e) {
      _showError('Failed to update workspace: ${e.toString()}');
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
        title: const Text('Edit Workspace'),
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
              'Edit Workspace',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Description
            const Text(
              'Update your workspace name. This will be reflected across all boards and team members.',
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
                hintText: 'Enter workspace name...',
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
            
            // Danger Zone
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Danger Zone',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Once you delete a workspace, there is no going back. Please be certain.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _deleteWorkspace,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.delete, size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            'Delete Workspace',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateWorkspace,
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
                            'Update',
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
