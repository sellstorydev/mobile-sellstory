import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../controller/board_controller.dart';
import '../../notifications/widgets/notifications_bell_button.dart';
import '../../chat/widgets/chat_unread_button.dart';
import '../../../data/services/mobile_permissions_service.dart';

/// Reusable AppBar matching the Board design (logo + workspace/board + actions)
class WorkspaceAppBar extends StatelessWidget implements PreferredSizeWidget {
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

  // Default handlers so this app bar can be used without passing callbacks
  void _defaultOnCreateWorkspace() {
    Get.toNamed('/create-workspace');
  }

  void _defaultOnMenuAction(String value, BuildContext context) {
    final ctrl = controller!;
    switch (value) {
      case 'board_management':
        Get.toNamed('/board-management');
        break;
      case 'refresh':
        // Light refresh for current board/workspace
        ctrl.refresh();
        break;
      case 'calendar':
        Get.toNamed('/calendar');
        break;
      case 'edit_workspace':
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
        break;
      case 'card_view_settings':
        Get.toNamed('/card-view-settings');
        break;
      default:
        if (value.startsWith('board_')) {
          ctrl.switchBoard(value.substring(6));
        } else if (value.startsWith('workspace_')) {
          ctrl.switchWorkspace(value.substring(10));
        }
        break;
    }
  }

  void _defaultOnTitleTap(BuildContext context) {
    final ctrl = controller!;
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
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current workspace
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9D9D9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Image.asset('assets/app_icon_original.png', fit: BoxFit.cover),
                    ),
                    title: Obx(() => Text(
                          ctrl.currentWorkspaceName.value.isNotEmpty
                              ? ctrl.currentWorkspaceName.value
                              : 'Workspace',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        )),
                    trailing: canManageBoard
                        ? IconButton(
                            icon: const Icon(Icons.settings_outlined),
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
                          )
                        : null,
                  ),
                  const SizedBox(height: 8),

                  // Boards
                  if (ctrl.boards.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(top: 4, bottom: 6),
                      child: Text('บอร์ดของคุณ', style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 12)),
                    ),
                    ...ctrl.boards.map((b) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: Icon(
                            Icons.view_column,
                            color: b.id == ctrl.currentBoardId.value
                                ? AppTheme.primaryOrange
                                : Colors.grey[600],
                          ),
                          title: Text(b.name),
                          trailing: b.id == ctrl.currentBoardId.value
                              ? const Icon(Icons.check, color: AppTheme.primaryOrange)
                              : null,
                          onTap: () async {
                            Navigator.of(context).pop();
                            await ctrl.switchBoard(b.id);
                          },
                        )),
                    const Divider(),
                  ],

                  // Workspaces
                  if (ctrl.availableWorkspaces.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(top: 4, bottom: 6),
                      child: Text('Workspace ของคุณ', style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 12)),
                    ),
                    ...ctrl.availableWorkspaces.map((ws) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: Icon(
                            Icons.workspaces_outline,
                            color: ws['id'] == ctrl.currentWorkspaceId.value
                                ? AppTheme.primaryOrange
                                : Colors.grey[600],
                          ),
                          title: Text(ws['name'] as String),
                          trailing: ws['id'] == ctrl.currentWorkspaceId.value
                              ? const Icon(Icons.check, color: AppTheme.primaryOrange)
                              : null,
                          onTap: () async {
                            Navigator.of(context).pop();
                            await ctrl.switchWorkspace(ws['id'] as String);
                          },
                        )),
                  ],

                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: onCreateWorkspace ?? _defaultOnCreateWorkspace,
                    icon: const Icon(Icons.add, color: AppTheme.primaryOrange),
                    label: const Text('สร้าง Workspace', style: TextStyle(color: AppTheme.primaryOrange)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryOrange),
                    ),
                  ),
                  const SizedBox(height: 8),
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
    if (controller == null) {
      return AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text('Workspace'),
      );
    }

    final ctrl = controller!;

    return AppBar
    (
      backgroundColor: Colors.white,
      elevation: 0,
      foregroundColor: Colors.black87,
      title: titleBuilder != null
          ? titleBuilder!(context, ctrl)
          : Obx(() {
              if (ctrl.hasWorkspaces) {
                return GestureDetector(
                  onTap: onTitleTap ?? () => _defaultOnTitleTap(context),
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
              onPressed: () => (onMenuAction ?? (v) => _defaultOnMenuAction(v, context))('calendar'),
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

        // Main Menu Button - combines all actions
        Obx(() {
          if (ctrl.hasWorkspaces) {
            final canManageBoard = MobilePermissionsService.to.isOwner ||
                MobilePermissionsService.to.can('settings:board:manage');
            return PopupMenuButton<String>(
              onSelected: (value) => (onMenuAction ?? (v) => _defaultOnMenuAction(v, context))(value),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.more_vert),
              ),
              itemBuilder: (context) => [
                // Board Management
                if (canManageBoard)
                  PopupMenuItem<String>(
                    value: 'board_management',
                    child: Row(
                      children: [
                        const Icon(Icons.dashboard, size: 20),
                        const SizedBox(width: 12),
                        const Text('Board Management'),
                      ],
                    ),
                  ),
                // Board Selector
                if (ctrl.boards.isNotEmpty) ...[
                  const PopupMenuDivider(),
                  ...ctrl.boards.map((board) {
                    return PopupMenuItem<String>(
                      value: 'board_${board.id}',
                      child: Row(
                        children: [
                          Icon(
                            Icons.view_column,
                            size: 20,
                            color: board.id == ctrl.currentBoardId.value
                                ? AppTheme.primaryOrange
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(board.name)),
                          if (board.id == ctrl.currentBoardId.value)
                            const Icon(Icons.check, color: AppTheme.primaryOrange),
                        ],
                      ),
                    );
                  }).toList(),
                ],
                // Workspace Selector
                if (ctrl.availableWorkspaces.isNotEmpty) ...[
                  const PopupMenuDivider(),
                  ...ctrl.availableWorkspaces.map((workspace) {
                    return PopupMenuItem<String>(
                      value: 'workspace_${workspace['id']}',
                      child: Row(
                        children: [
                          Icon(
                            Icons.workspace_premium,
                            size: 20,
                            color: workspace['id'] == ctrl.currentWorkspaceId.value
                                ? AppTheme.primaryOrange
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(workspace['name'] as String)),
                          if (workspace['id'] == ctrl.currentWorkspaceId.value)
                            const Icon(Icons.check, color: AppTheme.primaryOrange),
                        ],
                      ),
                    );
                  }).toList(),
                  const PopupMenuDivider(),
                  if (canManageBoard)
                    PopupMenuItem<String>(
                      value: 'edit_workspace',
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 20),
                          const SizedBox(width: 12),
                          const Text('Edit Workspace'),
                        ],
                      ),
                    ),
                ],
                // Card View Settings
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'card_view_settings',
                  child: Row(
                    children: [
                      const Icon(Icons.view_agenda, size: 20),
                      const SizedBox(width: 12),
                      const Text('Card View Settings'),
                    ],
                  ),
                ),
                // Refresh
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'refresh',
                  child: Row(
                    children: const [
                      Icon(Icons.refresh, size: 20),
                      SizedBox(width: 12),
                      Text('Refresh'),
                    ],
                  ),
                ),
              ],
            );
          } else {
            // Show only Add Workspace when no workspaces
            return IconButton(
              onPressed: onCreateWorkspace ?? _defaultOnCreateWorkspace,
              icon: const Icon(Icons.add),
              tooltip: 'Add Workspace',
            );
          }
        }),
      ],
    );
  }
}
