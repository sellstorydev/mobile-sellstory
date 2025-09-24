import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dialog_utils.dart';
import '../controller/board_controller.dart';
import '../../../domain/entities/board.dart';
import '../../../data/services/mobile_permissions_service.dart';

class EditBoardPage extends StatefulWidget {
  final Board board;

  const EditBoardPage({Key? key, required this.board}) : super(key: key);

  @override
  State<EditBoardPage> createState() => _EditBoardPageState();
}

class _EditBoardPageState extends State<EditBoardPage> {
  final BoardController _controller = Get.find<BoardController>();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  bool get _canManageBoard => MobilePermissionsService.to.isOwner || MobilePermissionsService.to.can('settings:board:manage');

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.board.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateBoard() async {
    if (!_canManageBoard) {
      _showError('no_permission_edit_board'.tr);
      return;
    }
    final name = _nameController.text.trim();
    
    if (name.isEmpty) {
      _showError('board_name_required'.tr);
      return;
    }

    if (name == widget.board.name) {
      Get.back();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _controller.updateBoard(widget.board.id, name);
      
      Get.snackbar(
        'success'.tr,
        'board_updated_successfully'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      Get.back();
    } catch (e) {
      _showError('${'failed_to_update_board'.tr}: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteBoard() async {
    if (!_canManageBoard) {
      _showError('no_permission_delete_board'.tr);
      return;
    }
    final confirmed = await DialogUtils.showDeleteConfirmDialog(
      context: context,
      title: 'delete_board'.tr,
      content: 'delete_board_confirmation'.tr.replaceAll('{name}', widget.board.name),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _controller.deleteBoard(widget.board.id);
      
      Get.snackbar(
        'success'.tr,
        'board_deleted_successfully'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      Get.back();
    } catch (e) {
      _showError('${'failed_to_delete_board'.tr}: ${e.toString()}');
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
    if (!_canManageBoard) {
      return Scaffold(
        appBar: AppBar(
          title: Text('edit_board'.tr),
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
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text('no_permission_edit_board_msg'.tr, style: const TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 8),
              Text('need_board_manage_permission'.tr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
        title: Text('edit_board'.tr),
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
                    onSubmitted: (_) => _updateBoard(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _updateBoard,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'update_board'.tr,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _deleteBoard,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'delete_board'.tr,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'board_information'.tr,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('• ${'name'.tr}: ${widget.board.name}'),
                          Text('• ${'board_created'.tr}: ${_formatDate(widget.board.createdAt)}'),
                          Text('• ${'updated_at_label'.tr}: ${_formatDate(widget.board.updatedAt)}'),
                          // Text('• ${'board_lanes'.tr}: ${widget.board.lanes.length}'),
                          Text('• ${'board_members'.tr}: ${widget.board.memberUids.length}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
