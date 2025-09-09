import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dialog_utils.dart';
import '../controller/board_controller.dart';
import '../../../domain/entities/board.dart';
import '../../../data/services/mobile_permissions_service.dart';
import '../../../core/widgets/permission_guard.dart';

class BoardManagementPage extends StatefulWidget {
  final String? workspaceId;

  const BoardManagementPage({Key? key, this.workspaceId}) : super(key: key);

  @override
  State<BoardManagementPage> createState() => _BoardManagementPageState();
}

class _BoardManagementPageState extends State<BoardManagementPage> {
  final BoardController _controller = Get.find<BoardController>();
  bool _isLoading = false;

  bool get _canManageBoards {
    final svc = MobilePermissionsService.to;
    return svc.isOwner || svc.can('settings:board:manage');
  }

  void _denySnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('คุณไม่มีสิทธิ์จัดการบอร์ด')),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadBoards();
  }

  Future<void> _loadBoards() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _controller.getBoards();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load boards: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToCreateBoard() {
    if (!_canManageBoards) return _denySnack();
    Get.toNamed('/create-board');
  }

  void _navigateToEditBoard(Board board) {
    if (!_canManageBoards) return _denySnack();
    Get.toNamed('/edit-board', arguments: {'board': board});
  }

  void _showBoardMenu(BuildContext context, Board board) {
    if (!_canManageBoards) return _denySnack();
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Board'),
              onTap: () {
                Navigator.of(context).pop();
                _navigateToEditBoard(board);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Board', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.of(context).pop();
                _showDeleteConfirmation(board);
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Board board) async {
    if (!_canManageBoards) return _denySnack();
    final confirmed = await DialogUtils.showDeleteConfirmDialog(
      context: context,
      title: 'Delete Board',
      content: 'Are you sure you want to delete "${board.name}"?\n\nThis will also delete all lanes and cards in this board. This action cannot be undone.',
    );

    if (confirmed == true) {
      await _deleteBoard(board);
    }
  }

  Future<void> _deleteBoard(Board board) async {
    if (!_canManageBoards) return _denySnack();
    try {
      await _controller.deleteBoard(board.id);
      Get.snackbar(
        'Success',
        'Board deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete board: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Board Management'),
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadBoards,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Obx(() {
              final boards = _controller.boards;
              
              if (boards.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.dashboard_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No boards found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create your first board to get started',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      PermissionGuard(
                        permission: 'settings:board:manage',
                        hideIfUnauthorized: true,
                        child: ElevatedButton.icon(
                          onPressed: _navigateToCreateBoard,
                          icon: const Icon(Icons.add),
                          label: const Text('Create Board'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryOrange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _loadBoards,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: boards.length,
                  itemBuilder: (context, index) {
                    final board = boards[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppTheme.primaryOrange,
                          child: Icon(
                            Icons.dashboard,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          board.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Lanes: ${board.lanes.length}')
                            ,Text('Members: ${board.memberUids.length}'),
                            Text('Created: ${_formatDate(board.createdAt)}'),
                          ],
                        ),
                        trailing: PermissionGuard(
                          permission: 'settings:board:manage',
                          child: IconButton(
                            onPressed: () => _showBoardMenu(context, board),
                            icon: const Icon(Icons.more_vert),
                          ),
                        ),
                        onTap: () => _canManageBoards ? _navigateToEditBoard(board) : _denySnack(),
                      ),
                    );
                  },
                ),
              );
            }),
      floatingActionButton: PermissionGuard(
        permission: 'settings:board:manage',
        hideIfUnauthorized: true,
        child: FloatingActionButton(
          onPressed: _navigateToCreateBoard,
          backgroundColor: AppTheme.primaryOrange,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
