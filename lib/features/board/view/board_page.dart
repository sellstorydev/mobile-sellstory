import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../controller/board_controller.dart';
import '../widgets/job_card_tile.dart';
import '../widgets/board_auto_scroll_wrapper.dart';
import '../widgets/lane_header.dart';
import '../widgets/status_summary_cards.dart';
import 'unified_filter_page.dart';
import '../../../domain/entities/lane.dart';
import '../../../domain/entities/board.dart';
import '../../notifications/widgets/notifications_bell_button.dart';
import '../../chat/widgets/chat_unread_button.dart';
import '../../../data/services/mobile_permissions_service.dart';

class BoardPage extends StatefulWidget {
  const BoardPage({super.key});

  @override
  State<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  final BoardController _controller = Get.find<BoardController>();
  Worker? _wsWorker;

  @override
  void initState() {
    super.initState();
    print('🚀 BoardPage initialized');
    
    // Initialize with current user
    _initializeWithCurrentUser();

    // React to workspace changes to prefetch permissions
    _wsWorker = ever<String>(_controller.currentWorkspaceId, (wsId) {
      if (wsId.isNotEmpty) {
        _ensurePermissions(wsId);
      }
    });
  }

  Future<void> _ensurePermissions(String workspaceId) async {
    try {
      final permsSvc = MobilePermissionsService.to;
      if (permsSvc.current.value == null || permsSvc.currentWorkspaceId.value != workspaceId) {
        await permsSvc.getMyPermissions(workspaceId: workspaceId);
      }
    } catch (_) {
      // Ignore on UI page; actions will simply be hidden
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when returning to this page
    _refreshDataIfNeeded();
  }

  @override
  void dispose() {
    _wsWorker?.dispose();
    super.dispose();
  }

  void _refreshDataIfNeeded() {
    // Check if we need to refresh data (e.g., after creating new workspace)
    if (_controller.currentWorkspaceId.value.isEmpty && !_controller.isLoading.value) {
      _initializeWithCurrentUser();
    } else if (_controller.currentWorkspaceId.value.isNotEmpty && _controller.currentBoardId.value.isNotEmpty) {
      // Refresh board data when returning to this page
      _controller.refresh();
    }
  }

  void _handleMenuAction(String value) {
    switch (value) {
      case 'board_management':
        Get.toNamed('/board-management');
        break;
      case 'refresh':
        _initializeWithCurrentUser();
        break;
      case 'calendar':
        Get.toNamed('/calendar');
        break;
      case 'edit_workspace':
        _navigateToEditWorkspace();
        break;
      default:
        if (value.startsWith('board_')) {
          final boardId = value.substring(6); // Remove 'board_' prefix
          _controller.switchBoard(boardId);
        } else if (value.startsWith('workspace_')) {
          final workspaceId = value.substring(10); // Remove 'workspace_' prefix
          _controller.switchWorkspace(workspaceId);
        }
        break;
    }
  }

  Future<void> _initializeWithCurrentUser() async {
    try {
      // Get current user ID from Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ No authenticated user found');
        return;
      }
      
      final String currentUserId = currentUser.uid;
      print('👤 Initializing board with user: $currentUserId');
      
      await _controller.initializeWithUser(currentUserId);
      
      // Load user's assigned cards
      await _controller.loadUserAssignedCards();

      // Prefetch permissions for current workspace if available
      final wsId = _controller.currentWorkspaceId.value;
      if (wsId.isNotEmpty) {
        _ensurePermissions(wsId);
      }
    } catch (e) {
      print('❌ Failed to initialize board page: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: Obx(() {
          if (_controller.hasWorkspaces) {
            return GestureDetector(
              onTap: _showWorkspaceBoardSelector,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
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
                            _controller.currentWorkspaceName.value.isNotEmpty 
                              ? _controller.currentWorkspaceName.value 
                              : 'My Workspace1',
                            style: const TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          if (_controller.currentBoardName.value.isNotEmpty)
                            Row(
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
                                Text(
                                  _controller.currentBoardName.value,
                                  style: TextStyle(
                                    fontSize: 12, 
                                    color: Colors.grey[600],
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

          


          // Notifications Button
          Obx(() {
            if (_controller.hasWorkspaces) {
              final wsId = _controller.currentWorkspaceId.value;
              if (wsId.isEmpty) return const SizedBox.shrink();
              return NotificationsBellButton(workspaceId: wsId);
            }
            return const SizedBox.shrink();
          }),

          // Chat Center Button with unread badge
          Obx(() {
            if (_controller.hasWorkspaces) {
              final wsId = _controller.currentWorkspaceId.value;
              if (wsId.isEmpty) return const SizedBox.shrink();
              return ChatUnreadButton(workspaceId: wsId);
            }
            return const SizedBox.shrink();
          }),

          // Main Menu Button - combines all actions
          Obx(() {
            if (_controller.hasWorkspaces) {
              final canManageBoard = MobilePermissionsService.to.isOwner ||
                  MobilePermissionsService.to.can('settings:board:manage');
               return PopupMenuButton<String>(
                 onSelected: (value) => _handleMenuAction(value),
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
                   if (_controller.boards.isNotEmpty) ...[
                     const PopupMenuDivider(),
                     ..._controller.boards.map((board) {
                       return PopupMenuItem<String>(
                         value: 'board_${board.id}',
                         child: Row(
                           children: [
                             Icon(
                               Icons.view_column,
                               size: 20,
                               color: board.id == _controller.currentBoardId.value
                                   ? AppTheme.primaryOrange
                                   : null,
                             ),
                             const SizedBox(width: 12),
                             Expanded(child: Text(board.name)),
                             if (board.id == _controller.currentBoardId.value)
                               const Icon(Icons.check, color: AppTheme.primaryOrange),
                           ],
                         ),
                       );
                     }).toList(),
                   ],
                   // Workspace Selector
                   if (_controller.availableWorkspaces.isNotEmpty) ...[
                     const PopupMenuDivider(),
                     ..._controller.availableWorkspaces.map((workspace) {
                       return PopupMenuItem<String>(
                         value: 'workspace_${workspace['id']}',
                         child: Row(
                           children: [
                             Icon(
                               Icons.workspace_premium,
                               size: 20,
                               color: workspace['id'] == _controller.currentWorkspaceId.value
                                   ? AppTheme.primaryOrange
                                   : null,
                             ),
                             const SizedBox(width: 12),
                             Expanded(child: Text(workspace['name'] as String)),
                             if (workspace['id'] == _controller.currentWorkspaceId.value)
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
                   // Refresh
                   const PopupMenuDivider(),
                   PopupMenuItem<String>(
                     value: 'refresh',
                     child: Row(
                       children: [
                         const Icon(Icons.refresh, size: 20),
                         const SizedBox(width: 12),
                         const Text('Refresh'),
                      ],
                    ),
                  ),

                   // Refresh
                   const PopupMenuDivider(),
                   PopupMenuItem<String>(
                     value: 'calendar',
                     child: Row(
                       children: [
                         const Icon(Icons.calendar_month, size: 20),
                         const SizedBox(width: 12),
                         const Text('Calendar'),
                        ],
                      ),
                    ),
                 ],
               );
            } else {
              // Show only Add Workspace when no workspaces
              return IconButton(
                onPressed: () => _navigateToCreateWorkspace(),
                icon: const Icon(Icons.add),
                tooltip: 'Add Workspace',
              );
            }
          }),
        ],
      ),
      body: Column(
        children: [

          
          // Search and Filter Section
          Obx(() {
            if (_controller.hasWorkspaces) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    // Search Bar
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: TextField(
                          controller: _controller.searchTextController,
                          onChanged: (value) {
                            _controller.updateSearchQuery(value);
                          },
                          textAlign: TextAlign.left,
                          textDirection: TextDirection.ltr,
                          keyboardType: TextInputType.text,
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Prompt',
                            letterSpacing: 0.0,
                          ),
                          decoration: InputDecoration(
                            hintText: 'รหัส Job Card ชื่อ-นามสกุล ลูกค้าและเซล',
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            suffixIcon: Obx(() {
                              if (_controller.searchQuery.value.isNotEmpty) {
                                return GestureDetector(
                                  onTap: () {
                                    _controller.updateSearchQuery('');
                                  },
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.grey[500],
                                    size: 20,
                                  ),
                                );
                              } else {
                                return Icon(
                                  Icons.search,
                                  color: Colors.grey[500],
                                  size: 20,
                                );
                              }
                            }),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Filter Button
                    GestureDetector(
                      onTap: _showUnifiedFilterPage,
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Check if screen width is mobile (less than 600px)
                            final isMobile = MediaQuery.of(context).size.width < 600;
                            
                            if (isMobile) {
                              // Mobile: show only icon
                              return Icon(
                                Icons.filter_list,
                                color: Colors.grey[600],
                                size: 20,
                              );
                            } else {
                              // Desktop/Tablet: show icon + text
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.filter_list,
                                    color: Colors.grey[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ตัวกรอง',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          
          // Status Summary Cards
          Obx(() {
            if (_controller.hasWorkspaces && _controller.lanes.isNotEmpty) {
              final hasAnyFilter = _controller.selectedAssignees.isNotEmpty || 
                                 _controller.selectedCustomers.isNotEmpty ||
                                 _controller.selectedHashtags.isNotEmpty ||
                                 _controller.selectedDateFilterType.value.isNotEmpty;
              final displayLanes = (_controller.isSearching.value || hasAnyFilter)
                  ? _controller.filteredLanes 
                  : _controller.lanes;
              final allCards = displayLanes
                  .expand((lane) => lane.cards)
                  .toList();
              return SizedBox(
                height: 65,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: StatusSummaryCards(cards: allCards),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          // Board View
          Expanded(child: _buildBoardView()),
        ],
      ),
      floatingActionButton: Obx(() {
        // Only show FAB if user has workspaces and has permission to create jobcards
        if (_controller.hasWorkspaces) {
          final canCreate = MobilePermissionsService.to.isOwner ||
              MobilePermissionsService.to.can('jobcard:create');
          if (!canCreate) return const SizedBox.shrink();
           return FloatingActionButton(
             onPressed: () => _showAddOptionsDialog(),
             backgroundColor: AppTheme.primaryOrange,
             foregroundColor: Colors.white,
             child: const Icon(Icons.add),
             tooltip: 'Add New Item',
           );
         }
         return const SizedBox.shrink(); // Hide FAB when no workspaces
       }),
     );
   }

  Widget _buildBoardView() {
    return Obx(() {
      if (_controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_controller.error.value.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _controller.error.value,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _controller.load(),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }

      if (!_controller.hasWorkspaces && _controller.isInitialized.value) {
        return Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome to KanbanFlow',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Create a workspace to get started and organize your workflow.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _navigateToCreateWorkspace(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Create Workspace',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'You can also use the + button in the top right corner',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      if (!_controller.isInitialized.value) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing board...'),
            ],
          ),
        );
      }

      final hasAnyFilter = _controller.selectedAssignees.isNotEmpty || 
                         _controller.selectedCustomers.isNotEmpty ||
                         _controller.selectedHashtags.isNotEmpty ||
                         _controller.selectedDateFilterType.value.isNotEmpty;
      final displayLanes = (_controller.isSearching.value || hasAnyFilter)
          ? _controller.filteredLanes 
          : _controller.lanes;

      if (displayLanes.isEmpty && _controller.hasWorkspaces) {
        if (hasAnyFilter) {
          // Show filter no results
          String filterMessage = '';
          final hasAssignee = _controller.selectedAssignees.isNotEmpty;
          final hasCustomer = _controller.selectedCustomers.isNotEmpty;
          final hasHashtag = _controller.selectedHashtags.isNotEmpty;
          final hasDate = _controller.selectedDateFilterType.value.isNotEmpty;
          
          // Count the number of active filters
          final filterCount = [hasAssignee, hasCustomer, hasHashtag, hasDate].where((x) => x).length;
          
          if (filterCount >= 3) {
            filterMessage = 'ไม่พบงานสำหรับเงื่อนไขที่เลือกทั้งหมด';
          } else if (hasAssignee && hasCustomer) {
            filterMessage = 'ไม่พบงานสำหรับผู้รับผิดชอบและลูกค้าที่เลือก';
          } else if (hasAssignee && hasHashtag) {
            filterMessage = 'ไม่พบงานสำหรับผู้ร��บผิดชอบและแฮชแท็กที่เลือก';
          } else if (hasAssignee && hasDate) {
            filterMessage = 'ไม่พบงานสำหรับผู้ร���บผิดชอบและช่วงวันที่ที่เลือก';
          } else if (hasCustomer && hasHashtag) {
            filterMessage = 'ไม่พบงานสำหรับลูกค้าและแฮชแท็กที่เลือก';
          } else if (hasCustomer && hasDate) {
            filterMessage = 'ไม่พบงานสำหรับลูกค้าและช่วงวันที่ที่เลือก';
          } else if (hasHashtag && hasDate) {
            filterMessage = 'ไม่พบงานสำหรับแฮชแท็กและช่วงวันที่ที่เลือก';
          } else if (hasAssignee) {
            filterMessage = 'ไม่พบงานสำหรับผู้รับผิดชอบที่เลือก';
          } else if (hasCustomer) {
            filterMessage = 'ไม่พบงานสำหรับลูกค้าที่เลือก';
          } else if (hasHashtag) {
            filterMessage = 'ไม่พบงานสำหรับแฮชแท็กที่เลือก';
          } else if (hasDate) {
            filterMessage = 'ไม่พบงานในช่วงวันที่ที่เลือก';
          }
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.filter_list_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  filterMessage,
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  'ลองเปลี่ยนเงื่อนไขการกรอง หรือ',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _controller.clearFilter(),
                  icon: const Icon(Icons.clear),
                  label: const Text('ล้างการกรอง'),
                ),
              ],
            ),
          );
        } else if (_controller.isSearching.value) {
          // Show search no results
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'ไม่พบผลการค้นหา',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  'ลองค้นหาด้วยคำอื่น หรือ',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _controller.clearSearch(),
                  icon: const Icon(Icons.clear),
                  label: const Text('ล้างการค้นหา'),
                ),
              ],
            ),
          );
        } else {
          // Show no lanes
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.dashboard_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No lanes found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create your first lane to get started',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                if (MobilePermissionsService.to.isOwner ||
                    MobilePermissionsService.to.can('settings:board:manage'))
                  ElevatedButton.icon(
                    onPressed: () => _showAddLaneDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Lane'),
                  ),
              ],
            ),
          );
        }
      }

      return _buildBoard();
    });
  }

  Widget _buildBoard() {
    final displayLanes = _controller.isSearching.value 
        ? _controller.filteredLanes 
        : _controller.lanes;
        
    return BoardAutoScrollWrapper(
      child: DragAndDropLists(
        onItemReorder: (int oldItemIndex, int oldListIndex, int newItemIndex, int newListIndex) {
          _handleCardReorder(oldItemIndex, oldListIndex, newItemIndex, newListIndex);
        },
        onListReorder: (int oldListIndex, int newListIndex) {
          // Lane reordering disabled - do nothing
        },
        axis: Axis.horizontal,
        listWidth: 300,
        listPadding: const EdgeInsets.all(8),
        listDragHandle: null, // Disable lane drag handle

        children: [
          ...displayLanes.map((lane) {
            final laneData = lane;
            return DragAndDropList(
              header: _buildLaneHeader(laneData),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(8),
              ),
              children: [
                ...laneData.cards.map((card) {
                  return DragAndDropItem(
                    child: JobCardTile(card: card),
                  );
                }).toList(),
                // Add card button at the bottom of each lane
                DragAndDropItem(
                  child: _buildAddCardButton(laneData),
                ),
              ],
            );
          }).toList(),
          // Add Lane Column
          DragAndDropList(
            header: _buildAddLaneHeader(),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(8),
            ),
            children: [
              DragAndDropItem(
                child: _buildAddLaneButton(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLaneHeader(Lane lane) {
    return LaneHeader(
      lane: lane,
      onCreateCard: () => _navigateToCreateCardWithLane(lane),
      onMenuTap: () => _showLaneMenu(lane),
    );
  }

  Widget _buildAddLaneHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF9F9F9),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.add_circle_outline,
            color: AppTheme.primaryOrange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'เพิ่ม Lane',
            style: TextStyle(
              color: AppTheme.primaryOrange,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddLaneButton() {
    return Container(
      margin: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () => _showAddLaneDialog(),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.primaryOrange.withOpacity(0.3),
              style: BorderStyle.solid,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                color: AppTheme.primaryOrange,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'เพิ่ม Lane ใหม่',
                style: TextStyle(
                  color: AppTheme.primaryOrange,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCreateCardWithLane(Lane lane) {
    print('🔄 Navigating to create card with lane:');
    print('  - Lane ID: ${lane.id}');
    print('  - Lane Name: ${lane.title}');
    print('  - Workspace ID: ${_controller.currentWorkspaceId.value}');
    
    Get.toNamed(
      '/create-card',
      parameters: {
        'laneId': lane.id,
        'workspaceId': _controller.currentWorkspaceId.value,
      },
    );
  }

  void _showLaneMenu(Lane lane) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (MobilePermissionsService.to.isOwner ||
                MobilePermissionsService.to.can('settings:board:manage')) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('แก้ไข Lane'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showEditLaneDialog(lane);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('คัดลอก Lane'),
                onTap: () {
                  Navigator.of(context).pop();
                  // TODO: Implement copy lane functionality
                  Get.snackbar(
                    'Info',
                    'Copy Lane functionality coming soon',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.open_with),
                title: const Text('Move Lane'),
                onTap: () {
                  Navigator.of(context).pop();
                  // TODO: Implement move lane functionality
                  Get.snackbar(
                    'Info',
                    'Move Lane functionality coming soon',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.archive),
                title: const Text('Archive Lane'),
                onTap: () {
                  Navigator.of(context).pop();
                  // TODO: Implement archive lane functionality
                  Get.snackbar(
                    'Info',
                    'Archive Lane functionality coming soon',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('ลบ Lane'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showDeleteLaneConfirmation(lane);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddCardButton(Lane lane) {
    final canCreate = MobilePermissionsService.to.isOwner ||
        MobilePermissionsService.to.can('jobcard:create');
    if (!canCreate) return const SizedBox.shrink();
    return Container(

      child: InkWell(
        onTap: () => _navigateToCreateCardWithLane(lane),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                size: 20,
                color: Colors.orange[600],
              ),
              const SizedBox(width: 8),
              Text(
                'Add a card',
                style: TextStyle(
                  color: Colors.orange[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCardReorder(int oldItemIndex, int oldListIndex, int newItemIndex, int newListIndex) {
    try {
      // Permission check: moving cards
      final canMove = MobilePermissionsService.to.isOwner ||
          MobilePermissionsService.to.can('jobcard:move');
      if (!canMove) {
        Get.snackbar(
          'Permission',
          'You do not have permission to move cards',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
       final oldLane = _controller.lanes[oldListIndex];
       final newLane = _controller.lanes[newListIndex];
       final card = oldLane.cards[oldItemIndex];

       print('🔄 Card reordered: ${card.id} from ${oldLane.title} to ${newLane.title}');

       _controller.onMoveCard(
         cardId: card.id,
         fromLaneId: oldLane.id,
         toLaneId: newLane.id,
         toIndex: newItemIndex,
       );
     } catch (e) {
       print('❌ Failed to handle card reorder: $e');
     }
  }

  void _showAddLaneDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController orderController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Lane'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Lane Name *',
                  hintText: 'Enter lane name...',
                  prefixIcon: Icon(Icons.label),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: orderController,
                decoration: const InputDecoration(
                  labelText: 'Order',
                  hintText: 'Enter order (optional)',
                  prefixIcon: Icon(Icons.sort),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Lane Structure',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• boardId: Auto-generated\n'
                      '• workspaceId: Current workspace\n'
                      '• name: Lane name\n'
                      '• order: Position in board\n'
                      '• cards: Empty array\n'
                      '• hasMoreCards: false',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                final order = orderController.text.trim().isNotEmpty 
                    ? int.tryParse(orderController.text.trim()) ?? _controller.lanes.length
                    : _controller.lanes.length;
                
                print('🔄 Adding new lane:');
                print('  - Name: ${nameController.text.trim()}');
                print('  - Order: $order');
                
                _controller.onAddLane(nameController.text.trim());
                Navigator.of(context).pop();
              } else {
                // Show error for required fields
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lane name is required'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Add Lane'),
          ),
        ],
      ),
    );
  }

  void _showAddOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (MobilePermissionsService.to.isOwner ||
                MobilePermissionsService.to.can('settings:board:manage'))
              ListTile(
                leading: const Icon(Icons.view_column),
                title: const Text('Add New Lane'),
                subtitle: const Text('Create a new column in the board'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAddLaneDialog();
                },
              ),
            const Divider(),
            if (MobilePermissionsService.to.isOwner ||
                MobilePermissionsService.to.can('jobcard:create'))
              ListTile(
                leading: const Icon(Icons.note_add),
                title: const Text('Create New Card'),
                subtitle: const Text('Create a new card with full details'),
                onTap: () {
                  Navigator.of(context).pop();
                  _navigateToCreateCard();
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.workspace_premium),
              title: const Text('Add New Workspace'),
              subtitle: const Text('Create a new workspace with boards'),
              onTap: () {
                Navigator.of(context).pop();
                _navigateToCreateWorkspace();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _navigateToCreateCard() {
    Get.toNamed(
      '/create-card',
      parameters: {
        'workspaceId': _controller.currentWorkspaceId.value,
      },
    );
  }

  void _navigateToCreateWorkspace() {
    Get.toNamed('/create-workspace');
  }

  void _navigateToEditWorkspace() {
    final currentWorkspace = _controller.availableWorkspaces.firstWhereOrNull(
      (workspace) => workspace['id'] == _controller.currentWorkspaceId.value,
    );
    
    if (currentWorkspace != null) {
      Get.toNamed(
        '/edit-workspace',
        parameters: {
          'workspaceId': currentWorkspace['id'] as String,
          'currentName': currentWorkspace['name'] as String,
        },
      );
    }
  }

  void _showEditLaneDialog(Lane lane) {
    final TextEditingController nameController = TextEditingController(text: lane.title);
    final TextEditingController orderController = TextEditingController(text: lane.order.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Lane: ${lane.title}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Lane Name *',
                  hintText: 'Enter lane name...',
                  prefixIcon: Icon(Icons.label),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: orderController,
                decoration: const InputDecoration(
                  labelText: 'Order',
                  hintText: 'Enter order (optional)',
                  prefixIcon: Icon(Icons.sort),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final newOrder = int.tryParse(orderController.text.trim()) ?? lane.order;
                
                print('🔄 Updating lane:');
                print('  - Lane ID: ${lane.id}');
                print('  - Old Title: ${lane.title}');
                print('  - New Title: ${nameController.text.trim()}');
                print('  - Old Order: ${lane.order}');
                print('  - New Order: $newOrder');
                
                try {
                  await _controller.updateLane(
                    laneId: lane.id,
                    title: nameController.text.trim(),
                    order: newOrder,
                  );
                  
                  Navigator.of(context).pop();
                  
                  Get.snackbar(
                    'Success',
                    'Lane updated successfully',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                } catch (e) {
                  print('❌ Error updating lane: $e');
                  Get.snackbar(
                    'Error',
                    'Failed to update lane: ${e.toString()}',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lane name is required'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Update Lane'),
          ),
        ],
      ),
    );
  }

  void _showDeleteLaneConfirmation(Lane lane) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lane'),
        content: Text(
          'Are you sure you want to delete "${lane.title}"? This action cannot be undone and will also delete all cards in this lane.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _controller.deleteLane(laneId: lane.id);
              
              Get.snackbar(
                'Success',
                'Lane deleted successfully',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    if (_controller.isSearching.value) {
      // If already searching, clear search
      _controller.clearSearch();
      return;
    }

    final TextEditingController searchController = TextEditingController(
      text: _controller.searchQuery.value,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ค้นหางาน'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'คำค้นหา',
                hintText: 'ชื่องาน, รหัสงาน, ลูกค้า, ผู้รับผิดชอบ...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              autofocus: true,
                                    onChanged: (value) {
                // Real-time search as user types
                _controller.updateSearchQuery(value);
              },
              onSubmitted: (value) {
                _controller.updateSearchQuery(value);
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 16),
            // Debug button for testing search
            ElevatedButton(
              onPressed: () {
                print('🔍 DEBUG: Testing search with common terms...');
                final testTerms = ['New', 'Card', 'To Do', 'test', 'JB'];
                for (final term in testTerms) {
                  print('🔍 Testing search for: "$term"');
                  _controller.updateSearchQuery(term);
                  // Wait a bit then clear
                  Future.delayed(Duration(milliseconds: 100), () {
                    _controller.clearSearch();
                  });
                }
              },
              child: Text('Debug Search'),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'ค้นหาจาก',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• ชื่องาน\n'
                    '• รายละเอียดงาน\n'
                    '• รหัสงาน\n'
                    '• ชื่อลูกค้า\n'
                    '• ผู้รับผิดชอบ\n'
                    '• สถานะ��าน\n'
                    '• ชื่อเลน',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _controller.clearSearch();
              Navigator.of(context).pop();
            },
            child: const Text('ล้าง'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              final query = searchController.text.trim();
              if (query.isNotEmpty) {
                _controller.updateSearchQuery(query);
              }
              Navigator.of(context).pop();
            },
            child: const Text('ค้นหา'),
          ),
        ],
      ),
    );
  }

  void _showUnifiedFilterPage() {
    Get.to(() => const UnifiedFilterPage());
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showWorkspaceBoardSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Workspace Section
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    _navigateToEditWorkspace();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(color: Color(0xFFD9D9D9)),
                          child: Image.asset(
                            'assets/app_icon_original.png',
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Workspace ปัจจุบัน',
                                style: TextStyle(
                                  color: Color(0xFFFF6C0C),
                                  fontSize: 12,
                                  fontFamily: 'Prompt',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Obx(() => Text(
                                _controller.currentWorkspaceName.value.isNotEmpty 
                                  ? _controller.currentWorkspaceName.value 
                                  : 'My Workspace1',
                                style: const TextStyle(
                                  color: Color(0xFF4D4D4D),
                                  fontSize: 16,
                                  fontFamily: 'Prompt',
                                  fontWeight: FontWeight.w500,
                                ),
                              )),
                            ],
                          ),
                        ),
                        Icon(Icons.settings, color: Colors.grey[400], size: 20),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Current Board Section
                const Text(
                  'บอร์ดปัจจุบัน',
                  style: TextStyle(
                    color: Color(0xFFFF6C0C),
                    fontSize: 12,
                    fontFamily: 'Prompt',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                
                Obx(() {
                  final currentBoard = _controller.boards.firstWhereOrNull(
                    (board) => board.id == _controller.currentBoardId.value,
                  );
                  if (currentBoard != null) {
                    return _buildBoardItemWithAction(
                      currentBoard.name,
                      'Job Card ของคุณ ${currentBoard.lanes.length} ใบ',
                      const Color(0xFFFF6C0C),
                      currentBoard.id,
                      workspaceId: _controller.currentWorkspaceId.value,
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                }),
                
                const SizedBox(height: 24),
                
                // Your Boards Section
                const Text(
                  'บอร์ดของคุณ',
                  style: TextStyle(
                    color: Color(0xFFB3B3B3),
                    fontSize: 12,
                    fontFamily: 'Prompt',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                
                Obx(() {
                  if (_controller.boards.isNotEmpty) {
                    return Column(
                      children: _controller.boards.where((board) => 
                        board.id != _controller.currentBoardId.value
                      ).map((board) {
                        return _buildBoardItemWithAction(
                          board.name,
                          'Job Card ของคุณ ${board.lanes.length} ใบ',
                          const Color(0xFFFAB73F),
                          board.id,
                          workspaceId: _controller.currentWorkspaceId.value,
                        );
                      }).toList(),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                }),
                
                const SizedBox(height: 24),
                
                // Your Workspaces Section
                const Text(
                  'Workspace ของคุณ',
                  style: TextStyle(
                    color: Color(0xFFB3B3B3),
                    fontSize: 12,
                    fontFamily: 'Prompt',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                
                Obx(() {
                  if (_controller.availableWorkspaces.isNotEmpty) {
                    return Column(
                      children: _controller.availableWorkspaces.where((workspace) => 
                        workspace['id'] != _controller.currentWorkspaceId.value
                      ).map((workspace) {
                        final isCurrentWorkspace = workspace['id'] == _controller.currentWorkspaceId.value;
                        return _buildWorkspaceItemWithAction(
                          workspace['name'] as String,
                          'Job Board ของคุณ ${workspace['boardCount'] ?? 0} บอร์ด',
                          false,
                          workspace['id'] as String,
                        );
                      }).toList(),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                }),
                

                
                const SizedBox(height: 24),
                
                // Create Workspace Button
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    _navigateToCreateWorkspace();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFF6C0C)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6C0C),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 12),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'สร้าง Workspace',
                          style: TextStyle(
                            color: Color(0xFFFF6C0C),
                            fontSize: 14,
                            fontFamily: 'Prompt',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 40), // Extra space for scrolling
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBoardItemWithAction(String title, String subtitle, Color color, String boardId, {String? workspaceId}) {
    return GestureDetector(
      onTap: () async {
        Navigator.of(context).pop();
        
        // If workspaceId is provided and different from current workspace, switch workspace first
        if (workspaceId != null && workspaceId != _controller.currentWorkspaceId.value) {
          try {
            print('🔄 Switching to workspace: $workspaceId');
            await _controller.switchWorkspace(workspaceId);
            
            // Wait a bit for workspace switch to complete
            await Future.delayed(const Duration(milliseconds: 500));
            
            // Then switch to the board
            print('🔄 Switching to board: $boardId');
            await _controller.switchBoard(boardId);
          } catch (e) {
            print('❌ Error switching workspace and board: $e');
            Get.snackbar(
              'Error',
              'เกิดข้อผิดพลาดในการเปลี่ยน workspace และ board',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        } else {
          // Just switch board if in same workspace
          try {
            await _controller.switchBoard(boardId);
          } catch (e) {
            print('❌ Error switching board: $e');
            Get.snackbar(
              'Error',
              'เกิดข้อผิดพลาดในการเปลี่ยน board',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          // borderRadius: BorderRadius.circular(8),
          // border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF4D4D4D),
                      fontSize: 16,
                      fontFamily: 'Prompt',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 14,
                        fontFamily: 'Prompt',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.settings, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBoardItemSimple(String title, String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF4D4D4D),
                    fontSize: 16,
                    fontFamily: 'Prompt',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF999999),
                      fontSize: 14,
                      fontFamily: 'Prompt',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.settings, color: Colors.grey[400], size: 20),
        ],
      ),
    );
  }

    Future<List<Board>> _getBoardsForWorkspace(String workspaceId) async {
    try {
      // Get boards for the specific workspace from Firestore
      final boards = await _controller.getBoardsForWorkspace(workspaceId);
      return boards;
    } catch (e) {
      print('❌ Failed to get boards for workspace $workspaceId: $e');
      return [];
    }
  }

  Widget _buildWorkspaceItemWithAction(String title, String subtitle, bool isExpanded, String workspaceId) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  isExpanded = !isExpanded;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  // borderRadius: BorderRadius.circular(8),
                  // border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.grey[500],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Color(0xFF4D4D4D),
                              fontSize: 16,
                              fontFamily: 'Prompt',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: Color(0xFF999999),
                              fontSize: 14,
                              fontFamily: 'Prompt',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.settings, color: Colors.grey[400], size: 20),
                  ],
                ),
              ),
            ),
            // Expanded boards section
            if (isExpanded) ...[
              Container(
                margin: const EdgeInsets.only(left: 24, top: 8, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sub-header for boards
                    const Padding(
                      padding: EdgeInsets.only(left: 12, bottom: 8),
                      child: Text(
                        'บอร์ดของคุณ',
                        style: TextStyle(
                          color: Color(0xFFB3B3B3),
                          fontSize: 12,
                          fontFamily: 'Prompt',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // Boards list
                    FutureBuilder<List<Board>>(
                      future: _getBoardsForWorkspace(workspaceId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6C0C)),
                              ),
                            ),
                          );
                        }
                        
                        if (snapshot.hasError) {
                          return Container(
                            padding: const EdgeInsets.all(16.0),
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red, size: 16),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'เกิดข้อผิดพลาดในการโหลดข้อมูล',
                                    style: TextStyle(color: Colors.red, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        final boards = snapshot.data ?? [];
                        if (boards.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16.0),
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.grey, size: 16),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'ไม่มีบอร์ดใน workspace นี้',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        
                                                 return Column(
                           children: boards.map((board) {
                             return Container(
                               margin: const EdgeInsets.only(bottom: 4),
                               child: _buildBoardItemWithAction(
                                 board.name,
                                 'Job Card ของคุณ ${board.lanes.length} ใบ',
                                 const Color(0xFF44B87B),
                                 board.id,
                                 workspaceId: workspaceId,
                               ),
                             );
                           }).toList(),
                         );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildWorkspaceItemSimple(String title, String subtitle, bool isExpanded) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: Colors.grey[500],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF4D4D4D),
                    fontSize: 16,
                    fontFamily: 'Prompt',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 14,
                    fontFamily: 'Prompt',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.settings, color: Colors.grey[400], size: 20),
        ],
      ),
    );
  }


}
