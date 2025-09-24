import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dialog_utils.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../../../data/services/mobile_permissions_service.dart';
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

  // Permission helpers
  bool get _isOwner {
    try { return MobilePermissionsService.to.isOwner; } catch (_) { return false; }
  }
  bool _can(String code) {
    try { return MobilePermissionsService.to.can(code); } catch (_) { return false; }
  }
  // Edit name: require owner or board settings manage
  bool get _canEditName => _isOwner || _can('settings:board:manage');
  // Delete workspace: require owner or roles manage (more sensitive)
  bool get _canDeleteWorkspace => _isOwner || _can('settings:roles:manage');

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
    if (!_canDeleteWorkspace) {
      _showError('no_permission_delete_workspace'.tr);
      return;
    }

    // Show confirmation dialog
    final shouldDelete = await DialogUtils.showDeleteConfirmDialog(
      context: context,
      title: 'delete_workspace'.tr,
      content: 'delete_workspace_confirmation'.trParams({'name': widget.currentName}),
    );

    if (shouldDelete != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showError('user_not_authenticated'.tr);
        return;
      }

      // Delete workspace
      await _repository.deleteWorkspace(
        workspaceId: widget.workspaceId,
        userId: currentUser.uid,
      );

      // Show success message
      Get.snackbar(
        'success'.tr,
        'workspace_deleted_successfully'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Navigate back to shell page (which contains the board page with bottom navigation)
      Get.offAllNamed('/shell');
      
      // Defer board controller refresh to after navigation completes
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          // Safely check if controller is still registered and not disposed
          if (Get.isRegistered<BoardController>()) {
            final boardController = Get.find<BoardController>();
            await boardController.initializeWithUser(currentUser.uid);
          }
        } catch (e) {
          print('⚠️ Failed to refresh board controller: $e');
          // Continue anyway, user can manually refresh
        }
      });
    } catch (e) {
      _showError('failed_to_delete_workspace'.tr + ': ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateWorkspace() async {
    if (!_canEditName) {
      _showError('no_permission_update_workspace'.tr);
      return;
    }

    if (_workspaceNameController.text.trim().isEmpty) {
      _showError('workspace_name_required'.tr);
      return;
    }

    if (_workspaceNameController.text.trim() == widget.currentName) {
      _showError('no_changes_made'.tr);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showError('user_not_authenticated'.tr);
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
        'success'.tr,
        'workspace_updated_successfully'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Navigate back to shell page (which contains the board page with bottom navigation)
      Get.offAllNamed('/shell');
      
      // Defer board controller refresh to after navigation completes
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          // Safely check if controller is still registered and not disposed
          if (Get.isRegistered<BoardController>()) {
            final boardController = Get.find<BoardController>();
            await boardController.initializeWithUser(currentUser.uid);
          }
        } catch (e) {
          print('⚠️ Failed to refresh board controller: $e');
          // Continue anyway, user can manually refresh
        }
      });
    } catch (e) {
      _showError('failed_to_update_workspace'.tr + ': ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'error'.tr,
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
        title: Text('edit_workspace'.tr),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close, color: Colors.black),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Title
            Text(
              'edit_workspace_title'.tr,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            // Lightweight permission hint
            if (!_canEditName || !_canDeleteWorkspace) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFFFF7E6),
                  border: Border.all(color: Color(0xFFFFE0B2)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  !_canEditName && !_canDeleteWorkspace
                      ? 'read_only_workspace_access'.tr
                      : !_canEditName
                          ? 'cannot_edit_workspace_name'.tr
                          : 'cannot_delete_workspace'.tr,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
            ],

            const SizedBox(height: 8),
            
            // Description
            Text(
              'edit_workspace_description'.tr,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Workspace Name Input
            Text(
              'workspace_name'.tr,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 8),
            
            TextField(
              controller: _workspaceNameController,
              enabled: _canEditName,
              decoration: InputDecoration(
                hintText: 'enter_workspace_name_hint'.tr,
                border: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primaryOrange, width: 2),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primaryOrange, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              autofocus: true,
            ),
            
            // Add spacing to push content properly
            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
            
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
                        'danger_zone'.tr,
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
                    'workspace_delete_warning'.tr,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading || !_canDeleteWorkspace ? null : _deleteWorkspace,
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
                          Text(
                            'delete_workspace'.tr,
                            style: const TextStyle(
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
                    onPressed: _isLoading || !_canEditName ? null : _updateWorkspace,
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
                        : Text(
                            'update_btn'.tr,
                            style: const TextStyle(
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
                    child: Text(
                      'cancel'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Bottom padding for keyboard space
            const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
