import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../controller/board_controller.dart';
import '../../notifications/widgets/notifications_bell_button.dart';
import '../../chat/widgets/chat_unread_button.dart';
import '../../../data/services/mobile_permissions_service.dart';
import '../../../core/services/card_view_settings_service.dart';

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
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  'เลือก Workspace และ Board',
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
                            const Text(
                              'Workspace ปัจจุบัน',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Obx(() => Text(
                                  ctrl.currentWorkspaceName.value.isNotEmpty
                                      ? ctrl.currentWorkspaceName.value
                                      : 'ไม่มีชื่อ',
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
                      const Text(
                        'เลือก Board',
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
                        child: const Text('จัดการ Board'),
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
                                  child: Text(
                                    board.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected ? AppTheme.primaryOrange : Colors.black87,
                                    ),
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
                    const Text(
                      'เปลี่ยน Workspace',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // เปลี่ยน workspace section ให้เรียบง่าย
                    Column(
                      children: ctrl.availableWorkspaces.where((workspace) => 
                        workspace['id'] != ctrl.currentWorkspaceId.value
                      ).map((workspace) {
                        final workspaceId = workspace['id'] as String;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                // ตัวอย่างการทำงานแบบง่าย - ไปที่ board management เสมอ
                                Navigator.of(context).pop();
                                await ctrl.switchWorkspace(workspaceId);
                                Get.toNamed('/board-management');
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
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
                                        workspace['name'] as String,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.add,
                                      color: AppTheme.primaryOrange,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
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
                          const Expanded(
                            child: Text(
                              'คุณมีเพียง Workspace เดียว\nสร้าง Workspace ใหม่เพื่อสลับได้',
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
                        label: const Text('ตั้งค่าการ์ด'),
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
                          print('🔄 Manual refresh triggered from workspace app bar');
                          
                          // Force reload field configuration from CardViewSettingsService
                          try {
                            final settingsService = Get.find<CardViewSettingsService>();
                            await settingsService.refreshSettings();
                            print('🔄 CardViewSettingsService refreshed');
                          } catch (e) {
                            print('🔄 Error refreshing CardViewSettingsService: $e');
                          }
                          
                          // Then refresh the board
                          ctrl.refresh();
                          
                          print('🔄 Manual refresh completed');
                        },
                        icon: const Icon(Icons.refresh, size: 20),
                        label: const Text('รีเฟรช'),
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
                    onPressed: onCreateWorkspace ?? _defaultOnCreateWorkspace,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('สร้าง Workspace ใหม่'),
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
                onPressed: onCreateWorkspace ?? _defaultOnCreateWorkspace,
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
                tooltip: 'สร้าง Workspace',
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
