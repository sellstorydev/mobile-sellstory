import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controller/board_controller.dart';
import '../widgets/job_card_tile.dart';
import '../widgets/board_auto_scroll_wrapper.dart';
import '../../../domain/entities/lane.dart';
import '../../chat/view/chat_center_page.dart'; // Add this import

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
          // Chat button
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
          // Refresh button
          IconButton(
            onPressed: () => _controller.refresh(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh data',
          ),
          // Workspace selector
          Obx(() {
            if (_controller.hasWorkspaces) {
              return PopupMenuButton<String>(
                onSelected: (workspaceId) {
                  _controller.switchWorkspace(workspaceId);
                },
                itemBuilder: (context) => _controller.availableWorkspaces
                    .map((workspace) => PopupMenuItem<String>(
                          value: workspace['id'] as String,
                          child: Text(workspace['name'] as String),
                        ))
                    .toList(),
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
        if (_controller.lanes.isNotEmpty) {
          return FloatingActionButton(
            onPressed: () => _showAddCardDialog(),
            child: const Icon(Icons.add),
          );
        }
        return const SizedBox.shrink();
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

      if (_controller.lanes.isEmpty) {
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
            children: laneData.cards.map((card) {
              return DragAndDropItem(
                child: JobCardTile(card: card),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLaneHeader(Lane lane) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lane.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${lane.cards.length} cards',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (lane.totalAmount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '\$${lane.totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.green[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
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
    final TextEditingController titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Lane'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Lane Title',
            hintText: 'Enter lane title...',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                _controller.onAddLane(titleController.text.trim());
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddCardDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController assigneeController = TextEditingController();
    String selectedLaneId = _controller.lanes.first.id;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Card'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Card Title',
                  hintText: 'Enter card title...',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: assigneeController,
                decoration: const InputDecoration(
                  labelText: 'Assignee',
                  hintText: 'Enter assignee...',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedLaneId,
                decoration: const InputDecoration(
                  labelText: 'Lane',
                ),
                items: _controller.lanes.map((lane) {
                  final laneData = lane as Lane;
                  return DropdownMenuItem<String>(
                    value: laneData.id,
                    child: Text(laneData.title),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedLaneId = value;
                  }
                },
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
              if (titleController.text.trim().isNotEmpty) {
                _controller.onAddCard(
                  laneId: selectedLaneId,
                  title: titleController.text.trim(),
                  assignee: assigneeController.text.trim(),
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
