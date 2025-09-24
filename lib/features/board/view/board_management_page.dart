import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dialog_utils.dart';
import '../controller/board_controller.dart';
import '../../../domain/entities/board.dart';
import '../../../data/services/mobile_permissions_service.dart';
import '../../../core/widgets/permission_guard.dart';
import '../../../core/services/quota_guard.dart';

class BoardManagementPage extends StatefulWidget {
  final String? workspaceId;

  const BoardManagementPage({Key? key, this.workspaceId}) : super(key: key);

  @override
  State<BoardManagementPage> createState() => _BoardManagementPageState();
}

class _BoardManagementPageState extends State<BoardManagementPage> {
  final BoardController _controller = Get.find<BoardController>();
  bool _isLoading = false;

  // Quota state for boards
  int _boardsUsed = 0;
  int _boardsLimit = -2; // -1 unlimited, -2 unknown
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _quotaSub;
  StreamSubscription<String>? _wsIdSub;

  bool get _canManageBoards {
    final svc = MobilePermissionsService.to;
    return svc.isOwner || svc.can('settings:board:manage');
  }

  bool get _isBoardsQuotaFull {
    if (_boardsLimit == -1) return false; // unlimited
    if (_boardsLimit <= 0) return false; // unknown -> fail-open
    return _boardsUsed >= _boardsLimit;
  }

  void _denySnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('no_permission_manage_boards'.tr)),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadBoards();
    // Subscribe to workspace changes and quota
    _subscribeWorkspaceListener();
    // Also try initial subscribe if ws id is present
    final initWs = widget.workspaceId ?? _controller.currentWorkspaceId.value;
    if (initWs.isNotEmpty) _subscribeQuota(initWs);
  }

  @override
  void dispose() {
    _quotaSub?.cancel();
    _wsIdSub?.cancel();
    super.dispose();
  }

  void _subscribeWorkspaceListener() {
    try {
      _wsIdSub = _controller.currentWorkspaceId.listen((wsId) {
        if (wsId.isNotEmpty) {
          _subscribeQuota(wsId);
        }
      });
    } catch (_) {}
  }

  void _subscribeQuota(String workspaceId) {
    _quotaSub?.cancel();
    setState(() {
      _boardsUsed = 0;
      _boardsLimit = -2;
    });
    _quotaSub = FirebaseFirestore.instance
        .collection('workspaces')
        .doc(workspaceId)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      if (!snap.exists) {
        setState(() {
          _boardsUsed = 0;
          _boardsLimit = -2;
        });
        return;
      }
      final data = snap.data() ?? {};
      final quota = Map<String, dynamic>.from(data['quota'] ?? {});

      int asInt(dynamic v, {int fallback = 0}) {
        if (v is int) return v;
        if (v is double) return v.toInt();
        if (v is String) return int.tryParse(v) ?? fallback;
        return fallback;
      }

      int used = 0;
      int limit = -1;
      dynamic entry = quota['boards'];
      if (entry is Map) {
        used = asInt(entry['used']);
        final rawLimit = entry['limit'] ?? entry['max'];
        limit = rawLimit == null ? -1 : asInt(rawLimit, fallback: -1);
      } else if (entry is int || entry is double || entry is String) {
        limit = asInt(entry, fallback: -1);
      }
      final usedContainer = quota['used'];
      if (usedContainer is Map) {
        final alt = usedContainer['boards'];
        if (alt != null) used = asInt(alt, fallback: used);
      }
      if (used < 0) used = 0;

      setState(() {
        _boardsUsed = used;
        _boardsLimit = limit;
      });
    }, onError: (_) {
      if (!mounted) return;
      setState(() {
        _boardsUsed = 0;
        _boardsLimit = -2;
      });
    });
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

  Future<void> _navigateToCreateBoard() async {
    if (!_canManageBoards) return _denySnack();
    final wsId = widget.workspaceId ?? _controller.currentWorkspaceId.value;
    final ok = await QuotaGuard.ensureCanCreate(context, wsId, 'boards');
    if (!ok) return;
    Get.toNamed('/create-board');
  }

  void _navigateToEditBoard(Board board) {
    if (!_canManageBoards) return _denySnack();
    Get.toNamed('/edit-board', arguments: {'board': board});
  }

  // Usage header
  Widget _buildUsageHeader(int totalBoards) {
    final isUnlimited = _boardsLimit == -1;
    final isOver = !isUnlimited && _boardsLimit > 0 && _boardsUsed > _boardsLimit;
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Text('Total: ', style: TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
                Text('$totalBoards', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primaryOrange)),
                const Text(' boards', style: TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
              ]),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.storage_rounded, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  isUnlimited ? 'Usage: $_boardsUsed / ∞' : 'Usage: $_boardsUsed / $_boardsLimit',
                  style: TextStyle(fontSize: 12, color: isOver ? Colors.red : AppTheme.textSecondary, fontWeight: isOver ? FontWeight.w600 : FontWeight.w400),
                ),
              ]),
            ],
          ),
          const Spacer(),
          PermissionGuard(
            permission: 'settings:board:manage',
            hideIfUnauthorized: true,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _isBoardsQuotaFull ? AppTheme.textSecondary : AppTheme.primaryOrange,
                side: BorderSide(color: _isBoardsQuotaFull ? AppTheme.textSecondary : AppTheme.primaryOrange, width: 1),
              ),
              onPressed: _navigateToCreateBoard,
              icon: const Icon(Icons.add),
              label: Text(_isBoardsQuotaFull ? 'Quota full' : 'Create Board'),
            ),
          ),
        ],
      ),
    );
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
        title: Text('board_management'.tr),
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
              final total = boards.length;

              return Column(
                children: [
                  _buildUsageHeader(total),
                  Expanded(
                    child: boards.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.dashboard_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'no_boards_found'.tr,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'create_first_board'.tr,
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
                                    label: Text('create_board'.tr),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryOrange,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
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
                                        Text('${'board_lanes'.tr}: ${board.lanes.length}')
                                        ,Text('${'board_members'.tr}: ${board.memberUids.length}'),
                                        Text('${'board_created'.tr}: ${_formatDate(board.createdAt)}'),
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
                          ),
                  ),
                ],
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
