import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../controller/board_controller.dart';
import '../../../data/services/mobile_permissions_service.dart';

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
    _nameController.text = 'New Board';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createBoard() async {
    if (!_canManageBoard) {
      _showError('You do not have permission to create boards');
      return;
    }

    final name = _nameController.text.trim();
    
    if (name.isEmpty) {
      _showError('Board name is required');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _controller.createBoard(name);
      
      Get.snackbar(
        'Success',
        'Board created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      Get.back();
    } catch (e) {
      _showError('Failed to create board: ${e.toString()}');
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
    if (!_canManageBoard) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Create Board'),
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
              const Text('คุณไม่มีสิทธิ์สร้างบอร์ด', style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 8),
              const Text('ต้องการสิทธิ์ settings:board:manage หรือเป็นเจ้าของ Workspace', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('ปิด'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Board'),
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
                  const Text(
                    'Board Name',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter board name',
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
                      child: const Text(
                        'Create Board',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'What will be created:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text('• A new board with the specified name'),
                          Text('• Default lanes: To Do, In Progress, Done'),
                          Text('• Board will be added to current workspace'),
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
