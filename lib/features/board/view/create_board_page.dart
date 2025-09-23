import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../controller/board_controller.dart';
import '../../../data/services/mobile_permissions_service.dart';
import '../../../core/services/quota_guard.dart';

class CreateBoardPage extends StatefulWidget {
  final String? workspaceId;

  const CreateBoardPage({Key? key, this.workspaceId}) : super(key: key);

  @override
  State<CreateBoardPage> createState() => _CreateBoardPageState();
}

class _CreateBoardPageState extends State<CreateBoardPage> {
  final BoardController _controller = Get.find<BoardController>();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  bool get _canManageBoard => MobilePermissionsService.to.isOwner || MobilePermissionsService.to.can('settings:board:manage');

  @override
  void initState() {
    super.initState();
    _nameController.text = 'new_board'.tr;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createBoard() async {
    if (!_canManageBoard) {
      _showError('no_permission_create_boards'.tr);
      return;
    }

    final name = _nameController.text.trim();
    
    if (name.isEmpty) {
      _showError('board_name_required'.tr);
      return;
    }

    // Quota pre-check (fail-open if any error inside guard)
    final wsId = _controller.currentWorkspaceId.value;
    final canProceed = await QuotaGuard.ensureCanCreate(context, wsId, 'boards');
    if (!canProceed) return; // dialog already shown

    setState(() { _isLoading = true; });

    try {
      await _controller.createBoard(name);
      Get.snackbar(
        'success'.tr,
        'board_created_successfully'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Get.back();
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('quota_exceeded:boards')) {
        QuotaGuard.handleQuotaException(context, e);
      } else {
        _showError('failed_to_create_board'.tr + ': ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
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
    if (!_canManageBoard) {
      return Scaffold(
        appBar: AppBar(
          title: Text('create_board'.tr),
          backgroundColor: AppTheme.primaryOrange,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text('no_permission_create_board_msg'.tr, style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 8),
              Text('need_board_manage_permission'.tr, style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text('close_btn'.tr),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('create_board'.tr),
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'board_name'.tr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'enter_board_name'.tr,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _createBoard(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _createBoard,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'create_board'.tr,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'what_will_be_created'.tr,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('• ${'new_board_with_name'.tr}'),
                          Text('• ${'default_lanes_todo'.tr}'),
                          Text('• ${'board_added_to_workspace'.tr}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
