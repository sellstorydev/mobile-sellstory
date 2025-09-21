import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../controller/board_controller.dart';
import '../../notifications/widgets/notifications_bell_button.dart';
import '../../chat/widgets/chat_unread_button.dart';
import '../../../data/services/mobile_permissions_service.dart';
import '../../../core/services/card_view_settings_service.dart';

/// Reusable AppBar matching the Board design (logo + workspace/board + actions)
class WorkspaceAppBar extends StatefulWidget implements PreferredSizeWidget {
  final BoardController? controller;
  final VoidCallback? onTitleTap;
  final void Function(String value)? onMenuAction;
  final VoidCallback? onCreateWorkspace;
  // Optional custom title builder for page-specific title UIs
  final Widget Function(BuildContext context, BoardController ctrl)? titleBuilder;

  const WorkspaceAppBar({
    super.key,
    this.controller,
    this.onTitleTap,
    this.onMenuAction,
    this.onCreateWorkspace,
    this.titleBuilder,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<WorkspaceAppBar> createState() => _WorkspaceAppBarState();
}

class _WorkspaceAppBarState extends State<WorkspaceAppBar> {
  // Local expansion state has moved into the modal using StatefulBuilder
  // Cache boards for non-current workspaces when expanded
  final Map<String, List<Map<String, dynamic>>> _workspaceBoardsCache = <String, List<Map<String, dynamic>>>{};
  // Cache card counts for boards in other workspaces
  final Map<String, int> _boardCardCounts = <String, int>{};
  // Track loading state per workspace during board fetch
  final Set<String> _loadingWorkspaceBoards = <String>{};
  // Track which workspaces have attempted load (to show empty state)
  final Set<String> _loadedWorkspaceBoards = <String>{};

  // Removed unused _workspaceHasBoardsSync helper (we now fetch boards on expand and cache results)

  // Get boards for a specific workspace - make it sync and reactive
  List<Map<String, dynamic>> _getWorkspaceBoardsSync(String workspaceId) {
    try {
      final ctrl = widget.controller!;
      
      // If this is the current workspace, return current boards
      if (workspaceId == ctrl.currentWorkspaceId.value) {
        return ctrl.boards.map((board) => {
          'id': board.id,
          'name': board.name,
        }).toList();
      }
  // For other workspaces, return cached list (may be empty if none)
  return _workspaceBoardsCache[workspaceId] ?? const [];
    } catch (e) {
      return [];
    }
  }

  // Default handlers so this app bar can be used without passing callbacks
  void _defaultOnCreateWorkspace() {
    Get.toNamed('/create-workspace');
  }

  void _defaultOnMenuAction(String value, BuildContext context) {
    final ctrl = widget.controller!;
    switch (value) {
      case 'refresh':
        ctrl.refresh();
        break;
      case 'calendar':
        Get.toNamed('/calendar');
        break;
      default:
        // Handle board และ workspace switching อย่างง่าย
        if (value.startsWith('board_')) {
          final boardId = value.substring(6);
          if (boardId != ctrl.currentBoardId.value) {
            ctrl.switchBoard(boardId);
          }
        } else if (value.startsWith('workspace_')) {
          final workspaceId = value.substring(10);
          if (workspaceId != ctrl.currentWorkspaceId.value) {
            ctrl.switchWorkspace(workspaceId);
          }
        }
        break;
    }
  }

  void _defaultOnTitleTap(BuildContext context) {
    final ctrl = widget.controller!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    builder: (_) {
    final canManageBoard = MobilePermissionsService.to.isOwner ||
      MobilePermissionsService.to.can('settings:board:manage');
    // One-time initializer flag for this modal build
    bool modalInitDone = false;
    // Snapshot other workspaces at open to avoid frequent Obx rebuilds
    final List<Map<String, dynamic>> otherWorkspacesSnapshot = ctrl.availableWorkspaces
      .where((w) => w['id'] != ctrl.currentWorkspaceId.value)
      .map((w) => {'id': w['id'], 'name': w['name']})
      .cast<Map<String, dynamic>>()
      .toList();

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'select_workspace_and_board'.tr,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Current workspace info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryOrange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.business, color: AppTheme.primaryOrange, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'current_workspace'.tr,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Obx(() => Text(
                                    ctrl.currentWorkspaceName.value.isNotEmpty
                                        ? ctrl.currentWorkspaceName.value
                                        : 'no_name'.tr,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )),
                            ],
                          ),
                        ),
                        if (canManageBoard)
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              final current = ctrl.availableWorkspaces.firstWhereOrNull(
                                (w) => w['id'] == ctrl.currentWorkspaceId.value,
                              );
                              if (current != null) {
                                Get.toNamed(
                                  '/edit-workspace',
                                  parameters: {
                                    'workspaceId': current['id'] as String,
                                    'currentName': current['name'] as String,
                                  },
                                );
                              }
                            },
                            icon: const Icon(Icons.settings, color: AppTheme.primaryOrange),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                // Boards section
                if (ctrl.boards.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'select_board'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Get.toNamed('/board-management');
                        },
                        child: Text('manage_board'.tr),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...ctrl.boards.map((board) {
                    final isSelected = board.id == ctrl.currentBoardId.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: isSelected ? null : () async {
                            Navigator.of(context).pop();
                            await ctrl.switchBoard(board.id);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryOrange.withOpacity(0.1) : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppTheme.primaryOrange : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.dashboard,
                                  color: isSelected ? AppTheme.primaryOrange : Colors.grey[600],
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        board.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: isSelected ? AppTheme.primaryOrange : Colors.black87,
                                        ),
                                      ),
                                      Obx(() {
                                        // Count cards in this board
                                        final boardCards = ctrl.lanes
                                            .where((lane) => lane.boardId == board.id)
                                            .expand((lane) => lane.cards)
                                            .length;
                                        return Text(
                                          'Job Card ของคุณ $boardCards ใบ',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppTheme.primaryOrange,
                                    size: 24,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                ],

                  // Workspaces section
                  if (ctrl.availableWorkspaces.isNotEmpty) ...[
                    if (ctrl.availableWorkspaces.length > 1) ...[
                      Text(
                        'change_workspace'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // แสดงรายชื่อบอร์ดของทุก Workspace อื่นแบบโชว์ไว้เลย (ไม่มี expand)
                      StatefulBuilder(
                        builder: (context, setModalState) {
                          // One-time prefetch boards for all other workspaces (sequential)
                          if (!modalInitDone) {
                            modalInitDone = true;
                            final others = otherWorkspacesSnapshot;

                          // Prefetch sequentially to avoid many parallel calls on large lists
                          Future.microtask(() async {
                            for (final ws in others) {
                              final id = ws['id'] as String;
                              if (_loadedWorkspaceBoards.contains(id) || _loadingWorkspaceBoards.contains(id)) {
                                continue;
                              }
                              _loadingWorkspaceBoards.add(id);
                              if (mounted) setModalState(() {});
                              try {
                                final boards = await ctrl.getBoardsForWorkspace(id);
                                _workspaceBoardsCache[id] = boards.map((b) => {
                                  'id': b.id,
                                  'name': b.name,
                                }).toList();
                              } catch (_) {
                                _workspaceBoardsCache[id] = const [];
                              } finally {
                                _loadingWorkspaceBoards.remove(id);
                                _loadedWorkspaceBoards.add(id);
                                if (mounted) setModalState(() {});
                              }
                            }
                          });
                        }
                        return Column(
                          children: otherWorkspacesSnapshot.map((workspace) {
                            final workspaceId = workspace['id'] as String;
                            final workspaceName = workspace['name'] as String;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Workspace header (no tap)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.business,
                                          color: Colors.grey[600],
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            workspaceName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        if (_loadingWorkspaceBoards.contains(workspaceId))
                                          const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppTheme.primaryOrange,
                                            ),
                                          )
                                        else if (_loadedWorkspaceBoards.contains(workspaceId) &&
                                            (_workspaceBoardsCache[workspaceId]?.isEmpty ?? true))
                                          const Icon(
                                            Icons.add,
                                            color: AppTheme.primaryOrange,
                                            size: 20,
                                          ),
                                      ],
                                    ),
                                  ),

                                  // Boards (always shown)
                                  () {
                                    if (_loadingWorkspaceBoards.contains(workspaceId)) {
                                      return Container(
                                        margin: const EdgeInsets.only(left: 16, bottom: 8),
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryOrange),
                                            ),
                                            SizedBox(width: 8),
                                            Text('loading_boards'.tr),
                                          ],
                                        ),
                                      );
                                    }

                                  final boards = _getWorkspaceBoardsSync(workspaceId);
                                  if (boards.isNotEmpty) {
                                    return Container(
                                      margin: const EdgeInsets.only(left: 16, bottom: 8),
                                      child: Column(
                                        children: boards.map((board) {
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 6),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () async {
                                                  Navigator.of(context).pop();
                                                  await ctrl.switchWorkspace(workspaceId);
                                                  await ctrl.switchBoard(board['id'] as String);
                                                },
                                                splashColor: AppTheme.primaryOrange.withOpacity(0.12),
                                                highlightColor: AppTheme.primaryOrange.withOpacity(0.06),
                                                borderRadius: BorderRadius.circular(8),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: Colors.grey[300]!, width: 1),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withOpacity(0.04),
                                                        blurRadius: 6,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.dashboard,
                                                        color: AppTheme.primaryOrange,
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              board['name'] as String,
                                                              style: TextStyle(
                                                                fontSize: 15,
                                                                fontWeight: FontWeight.w500,
                                                                color: Colors.black87,
                                                              ),
                                                            ),
                                                            Text(
                                                              'Job Card ของคุณ ${_boardCardCounts[board['id']] ?? 0} ใบ',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors.grey[600],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Icon(Icons.chevron_right, color: AppTheme.primaryOrange, size: 22),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    );
                                  }

                                    if (_loadedWorkspaceBoards.contains(workspaceId)) {
                                      return Container(
                                        margin: const EdgeInsets.only(left: 16, bottom: 8, right: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey[200]!),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.info_outline, color: Colors.grey[600], size: 18),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text('no_boards_in_workspace'.tr)),
                                            TextButton.icon(
                                              onPressed: () async {
                                                Navigator.of(context).pop();
                                                await ctrl.switchWorkspace(workspaceId);
                                                Get.toNamed('/board-management');
                                              },
                                              icon: const Icon(Icons.add, size: 18),
                                              label: Text('manage_board'.tr),
                                            )
                                          ],
                                        ),
                                      );
                                    }

                                    return const SizedBox.shrink();
                                  }(),
                                ],
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ] else ...[
                      // Show message when only one workspace
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue[600],
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'single_workspace_message'.tr,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],

                  // Quick actions
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Get.toNamed('/card-view-settings');
                          },
                          icon: const Icon(Icons.view_agenda, size: 20),
                          label: Text('card_settings'.tr),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.of(context).pop();

                            // Force reload field configuration from CardViewSettingsService
                            try {
                              final settingsService = Get.find<CardViewSettingsService>();
                              await settingsService.refreshSettings();
                            } catch (e) {
                              print('❌ Error refreshing CardViewSettingsService: $e');
                            }

                            // Then refresh the board
                            ctrl.refresh();
                          },
                          icon: const Icon(Icons.refresh, size: 20),
                          label: Text('refresh'.tr),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Create workspace button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: widget.onCreateWorkspace ?? _defaultOnCreateWorkspace,
                      icon: const Icon(Icons.add, size: 20),
                      label: Text('create_new_workspace'.tr),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryOrange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller == null) {
      return AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text('Workspace'),
      );
    }

    final ctrl = widget.controller!;

    return AppBar
    (
      backgroundColor: Colors.white,
      elevation: 0,
      foregroundColor: Colors.black87,
      title: widget.titleBuilder != null
          ? widget.titleBuilder!(context, ctrl)
          : Obx(() {
              if (ctrl.hasWorkspaces) {
                return GestureDetector(
                  onTap: widget.onTitleTap ?? () => _defaultOnTitleTap(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: const BoxDecoration(color: Colors.white),
                    child: Row(
                      children: [
                        // Icon with app icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Image.asset(
                            'assets/app_icon_original.png',
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Text content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                ctrl.currentWorkspaceName.value.isNotEmpty
                                    ? ctrl.currentWorkspaceName.value
                                    : 'My Workspace1',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),

                              if (ctrl.currentBoardName.value.isNotEmpty)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF6B35),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        ctrl.currentBoardName.value,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.keyboard_arrow_down,
                                      color: Colors.grey[600]!,
                                      size: 16,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const Text('Board');
            }),
      actions: [
        // Calendar Button
        Obx(() {
          if (ctrl.hasWorkspaces) {
            final wsId = ctrl.currentWorkspaceId.value;
            if (wsId.isEmpty) return const SizedBox.shrink();
            return IconButton(
              onPressed: () => (widget.onMenuAction ?? (v) => _defaultOnMenuAction(v, context))('calendar'),
              icon: const Icon(Icons.calendar_month),
              tooltip: 'Calendar',
            );
          }
          return const SizedBox.shrink();
        }),

        // Chat Center Button with unread badge
        Obx(() {
          if (ctrl.hasWorkspaces) {
            final wsId = ctrl.currentWorkspaceId.value;
            if (wsId.isEmpty) return const SizedBox.shrink();
            return ChatUnreadButton(workspaceId: wsId);
          }
          return const SizedBox.shrink();
        }),

        // Notifications Button
        Obx(() {
          if (ctrl.hasWorkspaces) {
            final wsId = ctrl.currentWorkspaceId.value;
            if (wsId.isEmpty) return const SizedBox.shrink();
            return NotificationsBellButton(workspaceId: wsId);
          }
          return const SizedBox.shrink();
        }),

        // ลบ PopupMenuButton ออก - ไม่มี menu แล้ว
        Obx(() {
          if (!ctrl.hasWorkspaces) {
            // Show create workspace button when no workspaces
            return Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryOrange, Color(0xFFFF6B35)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryOrange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: widget.onCreateWorkspace ?? _defaultOnCreateWorkspace,
                icon: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                tooltip: 'create_workspace'.tr,
                splashRadius: 20,
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }
}
