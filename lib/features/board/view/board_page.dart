import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/job_card.dart';
import '../../../domain/entities/lane.dart';
import '../controller/board_controller.dart';
import '../presenter/board_presenter.dart';
import '../widgets/job_card_tile.dart';
import '../widgets/lane_header.dart';
import '../widgets/board_auto_scroll_wrapper.dart';
import '../config/drag_config.dart';

class BoardPage extends StatefulWidget {
  const BoardPage({super.key});

  @override
  State<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  late ScrollController _horizontalScrollController;
  final Map<String, ScrollController> _laneScrollControllers = {};
  final DragAutoScrollConfig _scrollConfig = const DragAutoScrollConfig(
    edgeExtent: 56.0,
    velocityScalar: 120.0,
    maxStep: 48.0,
    tick: Duration(milliseconds: 16),
  );

  @override
  void initState() {
    super.initState();
    _horizontalScrollController = ScrollController();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    for (final controller in _laneScrollControllers.values) {
      controller.dispose();
    }
    _laneScrollControllers.clear();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return GetBuilder<BoardController>(
      init: BoardController(
        presenter: Get.find<BoardPresenter>(),
      ),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundGrey,
          appBar: AppBar(
            title: const Text(
              'Job Card Dashboard',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddLaneDialog(context, controller),
                color: AppTheme.primaryOrange,
              ),
            ],
          ),
          body: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryOrange,
                ),
              );
            }

            if (controller.error?.value.isNotEmpty == true) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppTheme.errorRed,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${controller.error?.value}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => controller.load(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return _buildBoard(context, controller);
          }),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddCardDialog(context, controller),
            backgroundColor: AppTheme.primaryOrange,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildBoard(BuildContext context, BoardController controller) {
    return BoardAutoScrollWrapper(
      horizontalController: _horizontalScrollController,
      laneControllers: _laneScrollControllers,
      config: _scrollConfig,
      onScrollStart: () => debugPrint('Board auto-scroll started'),
      onScrollEnd: () => debugPrint('Board auto-scroll ended'),
      child: DragAndDropLists(
        children: controller.lanes.map((lane) {
          return DragAndDropList(
            header: LaneHeader(
              lane: lane,
              onMenuTap: () => _showLaneMenu(context, controller, lane),
            ),
            children: lane.cards.map((card) {
              return DragAndDropItem(
                child: JobCardTile(
                  card: card,
                  onTap: () => _showCardDetails(context, card),
                ),
              );
            }).toList(),
            footer: Container(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: TextButton.icon(
                  onPressed: () => _showAddCardDialog(context, controller, lane.id),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Card'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryOrange,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
        onItemReorder: (int oldItemIndex, int oldListIndex, int newItemIndex, int newListIndex) {
          final fromLane = controller.lanes[oldListIndex];
          final toLane = controller.lanes[newListIndex];
          final card = fromLane.cards[oldItemIndex];
          
          controller.onMoveCard(
            cardId: card.id,
            fromLaneId: fromLane.id,
            toLaneId: toLane.id,
            toIndex: newItemIndex,
          );
        },
        onListReorder: (int oldListIndex, int newListIndex) {
          // Handle lane reordering if needed
        },
        axis: Axis.horizontal,
        listWidth: 300,
        listPadding: const EdgeInsets.all(8),
        listDecoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.borderGrey,
            width: 1,
          ),
        ),
      ),
    );
  }

  void _showAddLaneDialog(BuildContext context, BoardController controller) {
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Lane'),
        content: TextField(
          controller: textController,
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
              if (textController.text.isNotEmpty) {
                controller.onAddLane(textController.text);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddCardDialog(BuildContext context, BoardController controller, [String? laneId]) {
    final titleController = TextEditingController();
    final assigneeController = TextEditingController();
    final amountController = TextEditingController();
    String selectedLaneId = laneId ?? controller.lanes.first.id;
    
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
                  hintText: 'Enter assignee name...',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: 'Enter amount...',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedLaneId,
                decoration: const InputDecoration(
                  labelText: 'Lane',
                ),
                items: controller.lanes.map((lane) {
                  return DropdownMenuItem(
                    value: lane.id,
                    child: Text(lane.title),
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
              if (titleController.text.isNotEmpty &&
                  assigneeController.text.isNotEmpty &&
                  amountController.text.isNotEmpty) {
                final amount = double.tryParse(amountController.text) ?? 0.0;
                controller.onAddCard(
                  laneId: selectedLaneId,
                  title: titleController.text,
                  assignee: assigneeController.text,
                  badges: ['New'],
                  amount: amount,
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

  void _showLaneMenu(BuildContext context, BoardController controller, Lane lane) {
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
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.errorRed),
              title: const Text('Delete Lane', style: TextStyle(color: AppTheme.errorRed)),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCardDetails(BuildContext context, JobCard card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(card.id),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${card.title}'),
            const SizedBox(height: 8),
            Text('Assignee: ${card.assignee}'),
            const SizedBox(height: 8),
            Text('Amount: ฿${card.amount.toStringAsFixed(2)}'),
            if (card.dueDate != null) ...[
              const SizedBox(height: 8),
              Text('Due Date: ${card.dueDate!.toString().split(' ')[0]}'),
            ],
            if (card.badges.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Badges: ${card.badges.join(', ')}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
