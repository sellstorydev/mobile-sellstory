import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../controller/board_controller.dart';
import '../widgets/job_card_tile.dart';
import '../widgets/board_auto_scroll_wrapper.dart';
import '../widgets/lane_header.dart';
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
        title: Obx(() => Text(_controller.currentWorkspaceName.value.isNotEmpty 
          ? _controller.currentWorkspaceName.value 
          : 'Board')),
        actions: [
          // Refresh button
          IconButton(
            onPressed: () => _initializeWithCurrentUser(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh data',
          ),
          // Add Workspace button - show when no workspaces
          Obx(() {
            if (!_controller.hasWorkspaces) {
              return IconButton(
                onPressed: () => _navigateToCreateWorkspace(),
                icon: const Icon(Icons.add),
                tooltip: 'Add Workspace',
              );
            }
            return const SizedBox.shrink();
          }),
          // Workspace selector - only show if user has workspaces
          Obx(() {
            if (_controller.hasWorkspaces && _controller.availableWorkspaces.isNotEmpty) {
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit_workspace') {
                    _navigateToEditWorkspace();
                  } else {
                    _controller.switchWorkspace(value);
                  }
                },
                itemBuilder: (context) => [
                  ..._controller.availableWorkspaces
                      .map((workspace) => PopupMenuItem<String>(
                            value: workspace['id'] as String,
                            child: Text(workspace['name'] as String),
                          ))
                      .toList(),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'edit_workspace',
                    child: Row(
                      children: [
                        const Icon(Icons.edit, size: 16),
                        const SizedBox(width: 8),
                        const Text('Edit Workspace'),
                      ],
                    ),
                  ),
                ],
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.workspace_premium),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: _buildBoardView(),
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
                // TODO: Implement edit lane functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete Lane'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Implement delete lane functionality
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
        onTap: () => _showAddCardDialog(lane),
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
