import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/job_card.dart';
import '../../../domain/entities/lane.dart';
import '../controller/board_controller.dart';
import '../presenter/board_presenter.dart';
import '../widgets/job_card_tile.dart';
import '../widgets/lane_header.dart';

class BoardPage extends StatefulWidget {
  const BoardPage({super.key});

  @override
  State<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<BoardController>(
      init: BoardController(
        presenter: Get.find<BoardPresenter>(),
      ),
      builder: (controller) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              // Status Bar
              Container(
                width: double.infinity,
                height: AppTheme.statusBarHeight,
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing28),
                decoration: const BoxDecoration(
                  gradient: AppTheme.statusBarGradient,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      '9:41',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppTheme.fontSize14,
                        fontFamily: 'Kanit',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Row(
                      children: [
                        Container(width: AppTheme.iconSize16, height: AppTheme.iconSize16),
                        Container(width: AppTheme.spacing2),
                        Container(width: AppTheme.iconSize14, height: AppTheme.iconSize14),
                        Container(width: AppTheme.spacing2),
                        Container(width: AppTheme.iconSize14, height: AppTheme.iconSize14),
                        Container(width: AppTheme.spacing2),
                        const Text(
                          '100%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: AppTheme.fontSize12,
                            fontFamily: 'Kanit',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Container(width: AppTheme.spacing2),
                        Container(width: AppTheme.iconSize16, height: AppTheme.iconSize14),
                      ],
                    ),
                  ],
                ),
              ),
              // Header
              Container(
                width: double.infinity,
                height: AppTheme.headerHeight,
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing20),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundWhite,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.shadowColor,
                      blurRadius: AppTheme.spacing8,
                      offset: const Offset(0, 1),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: AppTheme.iconSize20 * 2,
                          height: AppTheme.iconSize20 * 2,
                          decoration: BoxDecoration(
                            gradient: AppTheme.logoGradient,
                            borderRadius: BorderRadius.circular(AppTheme.radius8),
                          ),
                          child: const Center(
                            child: Text(
                              'S',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: AppTheme.fontSize20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Container(width: AppTheme.spacing8),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Job Card',
                              style: TextStyle(
                                color: AppTheme.textDark,
                                fontSize: AppTheme.fontSize20,
                                fontFamily: 'Prompt',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: AppTheme.iconSize16,
                                  height: AppTheme.iconSize16,
                                  decoration: BoxDecoration(
                                    color: AppTheme.figmaYellow,
                                    borderRadius: BorderRadius.circular(AppTheme.radius4),
                                  ),
                                ),
                                Container(width: AppTheme.spacing2),
                                const Text(
                                  'ชื่อบอร์ด 1',
                                  style: TextStyle(
                                    color: AppTheme.textMedium,
                                    fontSize: AppTheme.fontSize12,
                                    fontFamily: 'Prompt',
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                Container(width: AppTheme.spacing4),
                                Transform.rotate(
                                  angle: 1.57,
                                  child: const Icon(
                                    Icons.keyboard_arrow_down,
                                    size: AppTheme.iconSize16,
                                    color: AppTheme.textMedium,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          width: AppTheme.iconSize24,
                          height: AppTheme.iconSize24,
                          child: const Icon(Icons.calendar_today, size: AppTheme.iconSize20),
                        ),
                        Container(width: AppTheme.spacing16),
                        Container(
                          width: AppTheme.iconSize24,
                          height: AppTheme.iconSize24,
                          child: const Icon(Icons.monitor, size: AppTheme.iconSize20),
                        ),
                        Container(width: AppTheme.spacing16),
                        Container(
                          width: AppTheme.iconSize24,
                          height: AppTheme.iconSize24,
                          child: const Icon(Icons.notifications, size: AppTheme.iconSize20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Padding between header and content
              Container(
                height: AppTheme.spacing16,
                color: AppTheme.backgroundGrey,
              ),
              // Main Content
              Expanded(
                child: Obx(() {
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
                          Container(height: AppTheme.spacing16),
                          Text(
                            'Error: ${controller.error?.value}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: AppTheme.fontSize16,
                            ),
                          ),
                          Container(height: AppTheme.spacing16),
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
              ),
            ],
          ),
          floatingActionButton: Container(
            width: AppTheme.fabSize,
            height: AppTheme.fabSize,
            decoration: BoxDecoration(
              gradient: AppTheme.fabGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.fabShadowColor,
                  blurRadius: AppTheme.spacing4,
                  offset: const Offset(0.75, 3),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: AppTheme.iconSize24,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBoard(BuildContext context, BoardController controller) {
    return DragAndDropLists(
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
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Center(
              child: TextButton.icon(
                onPressed: () => _showAddCardDialog(context, controller, lane.id),
                icon: const Icon(Icons.add, size: AppTheme.iconSize16),
                label: const Text('เพิ่ม Job Card'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.figmaOrange,
                  textStyle: const TextStyle(
                    fontSize: AppTheme.fontSize10,
                    fontFamily: 'Prompt',
                    fontWeight: FontWeight.w400,
                  ),
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
      listWidth: 360,
      listPadding: EdgeInsets.zero, // เอา padding ออกให้ lane ชนขอบจอ
      listDecoration: BoxDecoration(
        color: AppTheme.laneBackground,
        borderRadius: BorderRadius.zero, // เอา border radius ออกให้ชนขอบจอ
        border: Border.all(
          color: AppTheme.borderGrey,
          width: 1,
        ),
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
