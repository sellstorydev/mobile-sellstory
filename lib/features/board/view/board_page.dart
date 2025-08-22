import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../chat/view/chat_center_page.dart';
import '../controller/board_controller.dart';
import '../widgets/job_card_tile.dart';
import '../widgets/board_auto_scroll_wrapper.dart';
import '../widgets/lane_header.dart';
import '../widgets/status_summary_cards.dart';
import '../../../domain/entities/lane.dart';

class BoardPage extends StatefulWidget {
  const BoardPage({super.key});

  @override
  State<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  final BoardController _controller = Get.find<BoardController>();

  @override
  void initState() {
    super.initState();
    print('🚀 BoardPage initialized');
    
    // Initialize with current user
    _initializeWithCurrentUser();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when returning to this page
    _refreshDataIfNeeded();
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
    } catch (e) {
      print('❌ Failed to initialize board page: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          if (_controller.hasWorkspaces) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _controller.currentWorkspaceName.value.isNotEmpty 
                    ? _controller.currentWorkspaceName.value 
                    : 'Board',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_controller.currentBoardName.value.isNotEmpty)
                  Text(
                    _controller.currentBoardName.value,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
              ],
            );
          }
          return const Text('Board');
        }),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatCenterPage(),
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Chat Center',
          ),

          // Main Menu Button - combines all actions
          Obx(() {
            if (_controller.hasWorkspaces) {
              return PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.more_vert),
                ),
                itemBuilder: (context) => [
                  // Board Management
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
          // Status Summary Cards
          Obx(() {
            if (_controller.hasWorkspaces && _controller.lanes.isNotEmpty) {
              final allCards = _controller.lanes
                  .expand((lane) => lane.cards)
                  .toList();
              return StatusSummaryCards(cards: allCards);
            }
            return const SizedBox.shrink();
          }),
          // Board View
          Expanded(child: _buildBoardView()),
        ],
      ),
      floatingActionButton: Obx(() {
        // Only show FAB if user has workspaces
        if (_controller.hasWorkspaces) {
          return FloatingActionButton(
            onPressed: () => _showAddOptionsDialog(),
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

      if (_controller.lanes.isEmpty && _controller.hasWorkspaces) {
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
              ElevatedButton.icon(
                onPressed: () => _showAddLaneDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Lane'),
              ),
            ],
          ),
        );
      }

      return _buildBoard();
    });
  }

  Widget _buildBoard() {
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
        children: _controller.lanes.map((lane) {
          final laneData = lane as Lane;
          return DragAndDropList(
            header: _buildLaneHeader(laneData),
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

  void _navigateToCreateCardWithLane(Lane lane) {
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
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Lane'),
              onTap: () {
                Navigator.of(context).pop();
                _showEditLaneDialog(lane);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete Lane'),
              onTap: () {
                Navigator.of(context).pop();
                _showDeleteLaneConfirmation(lane);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCardButton(Lane lane) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => _navigateToCreateCard(),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
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
      final oldLane = _controller.lanes[oldListIndex] as Lane;
      final newLane = _controller.lanes[newListIndex] as Lane;
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

  void _showAddCardDialog(Lane lane) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController assigneeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Card to ${lane.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Card Title *',
                hintText: 'Enter card title...',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: assigneeController,
              decoration: const InputDecoration(
                labelText: 'Assignee',
                hintText: 'Enter assignee...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                _controller.onAddCard(
                  laneId: lane.id,
                  title: titleController.text.trim(),
                  assignee: assigneeController.text.trim(),
                );
                Navigator.of(context).pop();
              } else {
                // Show error for required fields
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Title is required'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Add Card'),
          ),
        ],
      ),
    );
  }
}
