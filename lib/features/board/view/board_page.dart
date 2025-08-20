import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_font.dart';
import '../../../core/utils/firebase_test.dart';
import '../../../domain/entities/job_card.dart';
import '../../../domain/entities/lane.dart';
import '../controller/board_controller.dart';
import '../presenter/board_presenter.dart';
import '../widgets/job_card_tile.dart';
import '../widgets/lane_header.dart';
import '../../debug/firebase_debug_page.dart';

class BoardPage extends StatefulWidget {
  const BoardPage({super.key});

  @override
  State<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<BoardController>(
      init: BoardController(presenter: Get.find<BoardPresenter>()),
      builder: (controller) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              // Status Bar
              Container(
                width: double.infinity,
                height: AppTheme.statusBarHeight,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing28,
                ),
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
                        fontFamily: AppFont.family,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: AppTheme.iconSize16,
                          height: AppTheme.iconSize16,
                        ),
                        Container(width: AppTheme.spacing2),
                        const SizedBox(
                          width: AppTheme.iconSize14,
                          height: AppTheme.iconSize14,
                        ),
                        Container(width: AppTheme.spacing2),
                        const SizedBox(
                          width: AppTheme.iconSize14,
                          height: AppTheme.iconSize14,
                        ),
                        Container(width: AppTheme.spacing2),
                        const Text(
                          '100%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: AppTheme.fontSize12,
                            fontFamily: AppFont.family,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Container(width: AppTheme.spacing2),
                        const SizedBox(
                          width: AppTheme.iconSize16,
                          height: AppTheme.iconSize14,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Header
              Container(
                width: double.infinity,
                height: AppTheme.headerHeight,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing20,
                ),
                decoration: const BoxDecoration(
                  color: AppTheme.backgroundWhite,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.shadowColor,
                      blurRadius: AppTheme.spacing8,
                      offset: Offset(0, 1),
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
                            borderRadius: BorderRadius.circular(
                              AppTheme.radius8,
                            ),
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
                                fontFamily: AppFont.family,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: AppTheme.iconSize16,
                                  height: AppTheme.iconSize16,
                                  decoration: BoxDecoration(
                                    color: AppTheme.figmaYellow,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radius4,
                                    ),
                                  ),
                                ),
                                Container(width: AppTheme.spacing2),
                                const Text(
                                  'ชื่อบอร์ด 1',
                                  style: TextStyle(
                                    color: AppTheme.textMedium,
                                    fontSize: AppTheme.fontSize12,
                                    fontFamily: AppFont.family,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: AppTheme.iconSize24,
                          height: AppTheme.iconSize24,
                          child: Icon(
                            Icons.calendar_today,
                            size: AppTheme.iconSize20,
                          ),
                        ),
                        Container(width: AppTheme.spacing16),
                        const SizedBox(
                          width: AppTheme.iconSize24,
                          height: AppTheme.iconSize24,
                          child: Icon(
                            Icons.chat_bubble_outline,
                            size: AppTheme.iconSize20,
                          ),
                        ),
                        Container(width: AppTheme.spacing16),
                        const SizedBox(
                          width: AppTheme.iconSize24,
                          height: AppTheme.iconSize24,
                          child: Icon(
                            Icons.notifications_none,
                            size: AppTheme.iconSize20,
                          ),
                        ),
                        Container(width: AppTheme.spacing16),
                        // Firebase Test Button
                        GestureDetector(
                          onTap: () =>
                              FirebaseTest.showConnectionStatus(context),
                          child: Container(
                            width: AppTheme.iconSize24,
                            height: AppTheme.iconSize24,
                            decoration: BoxDecoration(
                              color: AppTheme.figmaOrange,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radius8,
                              ),
                            ),
                            child: const Icon(
                              Icons.cloud_done,
                              color: Colors.white,
                              size: AppTheme.iconSize20,
                            ),
                          ),
                        ),
                        Container(width: AppTheme.spacing8),
                        // Firebase Debug Page Button
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FirebaseDebugPage(),
                              ),
                            );
                          },
                          child: Container(
                            width: AppTheme.iconSize24,
                            height: AppTheme.iconSize24,
                            decoration: BoxDecoration(
                              color: AppTheme.figmaGreen,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radius8,
                              ),
                            ),
                            child: const Icon(
                              Icons.bug_report,
                              color: Colors.white,
                              size: AppTheme.iconSize20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Search and Filter Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing20,
                  vertical: AppTheme.spacing16,
                ),
                decoration: const BoxDecoration(
                  color: AppTheme.backgroundWhite,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.shadowColor,
                      blurRadius: AppTheme.spacing4,
                      offset: Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Search Bar with Filter
                    Row(
                      children: [
                        // Search Bar
                        Expanded(
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundGrey,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radius12,
                              ),
                              border: Border.all(
                                color: AppTheme.borderGrey,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: AppTheme.iconSize20,
                                  height: AppTheme.iconSize20,
                                  margin: const EdgeInsets.only(
                                    left: AppTheme.spacing12,
                                  ),
                                  child: const Icon(
                                    Icons.search,
                                    color: AppTheme.textGrey,
                                    size: AppTheme.iconSize20,
                                  ),
                                ),
                                const Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: AppTheme.spacing12,
                                    ),
                                    child: TextField(
                                      decoration: InputDecoration(
                                        hintText: 'ค้นหา Job Card...',
                                        hintStyle: TextStyle(
                                          color: AppTheme.textGrey,
                                          fontSize: AppTheme.fontSize14,
                                          fontFamily: AppFont.family,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(width: AppTheme.spacing12),
                        // Filter Button
                        Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing16,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.figmaOrange,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radius12,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.figmaOrange.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: AppTheme.spacing8,
                                offset: const Offset(0, 2),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.filter_list,
                                color: Colors.white,
                                size: AppTheme.iconSize20,
                              ),
                              Container(width: AppTheme.spacing8),
                              const Text(
                                'ตัวกรอง',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: AppTheme.fontSize14,
                                  fontFamily: AppFont.family,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Summary Cards Section - Single Row
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing20,
                  vertical: AppTheme.spacing16,
                ),
                decoration: const BoxDecoration(
                  color: AppTheme.backgroundWhite,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.shadowColor,
                      blurRadius: AppTheme.spacing4,
                      offset: Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Cards - Single Row
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        // Sales Summary Card
                        Expanded(
                          child: Container(
                            height: 80,
                            padding: const EdgeInsets.all(AppTheme.spacing12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radius12,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: AppTheme.iconSize20,
                                      height: AppTheme.iconSize20,
                                      decoration: BoxDecoration(
                                        color: AppTheme.figmaOrange,
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.radius8,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.attach_money,
                                        color: Colors.white,
                                        size: AppTheme.iconSize14,
                                      ),
                                    ),
                                    Container(width: AppTheme.spacing8),
                                    const Expanded(
                                      child: Text(
                                        'สรุปยอดขาย',
                                        style: TextStyle(
                                          color: AppTheme.figmaOrange,
                                          fontSize: AppTheme.fontSize12,
                                          fontFamily: AppFont.family,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(height: AppTheme.spacing8),
                                const Text(
                                  '48 รายการ',
                                  style: TextStyle(
                                    color: AppTheme.textDark,
                                    fontSize: AppTheme.fontSize14,
                                    fontFamily: AppFont.family,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(width: AppTheme.spacing12),
                        // Completed Jobs Card
                        Expanded(
                          child: Container(
                            height: 80,
                            padding: const EdgeInsets.all(AppTheme.spacing12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radius12,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'สำเร็จ',
                                  style: TextStyle(
                                    color: AppTheme.textDark,
                                    fontSize: AppTheme.fontSize12,
                                    fontFamily: AppFont.family,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Container(height: AppTheme.spacing8),
                                const Text(
                                  '฿9,605,000,000',
                                  style: TextStyle(
                                    color: AppTheme.figmaGreen,
                                    fontSize: AppTheme.fontSize14,
                                    fontFamily: AppFont.family,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(width: AppTheme.spacing12),
                        // In Progress Card
                        Expanded(
                          child: Container(
                            height: 80,
                            padding: const EdgeInsets.all(AppTheme.spacing12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radius12,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'กำลังดำเนินการ',
                                  style: TextStyle(
                                    color: AppTheme.textDark,
                                    fontSize: AppTheme.fontSize12,
                                    fontFamily: AppFont.family,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Container(height: AppTheme.spacing8),
                                const Text(
                                  '฿4,318,000,000',
                                  style: TextStyle(
                                    color: AppTheme.figmaYellow,
                                    fontSize: AppTheme.fontSize14,
                                    fontFamily: AppFont.family,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(width: AppTheme.spacing12),
                        // Unsuccessful Jobs Card
                        Expanded(
                          child: Container(
                            height: 80,
                            padding: const EdgeInsets.all(AppTheme.spacing12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radius12,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ไม่สำเร็จ',
                                  style: TextStyle(
                                    color: AppTheme.textDark,
                                    fontSize: AppTheme.fontSize12,
                                    fontFamily: AppFont.family,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Container(height: AppTheme.spacing8),
                                const Text(
                                  '฿4,159,000,432',
                                  style: TextStyle(
                                    color: AppTheme.figmaRed,
                                    fontSize: AppTheme.fontSize14,
                                    fontFamily: AppFont.family,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
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
            decoration: const BoxDecoration(
              gradient: AppTheme.fabGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.fabShadowColor,
                  blurRadius: AppTheme.spacing4,
                  offset: Offset(0.75, 3),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const AlwaysScrollableScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: controller.lanes.asMap().entries.map((entry) {
          final laneIndex = entry.key;
          final lane = entry.value;
          
          return SizedBox(
            width: controller.lanes.length <= 3 
                ? MediaQuery.of(context).size.width / controller.lanes.length
                : 350, // Fixed width สำหรับ lane มากกว่า 3
            child: DragTarget<JobCard>(
              onWillAccept: (data) => data != null,
              onAccept: (card) {
                // Handle dropping card from another lane
                final fromLaneIndex = controller.lanes.indexWhere((l) => l.cards.contains(card));
                if (fromLaneIndex != -1 && fromLaneIndex != laneIndex) {
                  final fromLane = controller.lanes[fromLaneIndex];
                  controller.onMoveCard(
                    cardId: card.id,
                    fromLaneId: fromLane.id,
                    toLaneId: lane.id,
                    toIndex: lane.cards.length,
                  );
                }
              },
              builder: (context, candidateData, rejectedData) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing4),
                  decoration: BoxDecoration(
                    color: AppTheme.laneBackground,
                    border: Border.all(
                      color: candidateData.isNotEmpty 
                          ? AppTheme.primaryOrange 
                          : AppTheme.borderGrey, 
                      width: candidateData.isNotEmpty ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Lane Header
                      LaneHeader(
                        lane: lane,
                        onMenuTap: () => _showLaneMenu(context, controller, lane),
                      ),
                      // Cards Container with ScrollView - Lock vertical scroll here
                      Expanded(
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (scrollNotification) {
                            // Block vertical scroll during drag
                            if (scrollNotification is ScrollStartNotification) {
                              // Allow scroll only if not dragging
                              return false;
                            }
                            return false;
                          },
                          child: DragAndDropLists(
                            children: [
                              DragAndDropList(
                                children: lane.cards.map((card) {
                                  return DragAndDropItem(
                                    child: LongPressDraggable<JobCard>(
                                      data: card,
                                      delay: const Duration(milliseconds: 500),
                                      feedback: Material(
                                        elevation: 8,
                                        child: SizedBox(
                                          width: controller.lanes.length <= 3 
                                              ? (MediaQuery.of(context).size.width / controller.lanes.length) - 16
                                              : 334, // 350 - 16 margin
                                          child: JobCardTile(
                                            card: card,
                                            onTap: () => _showCardDetails(context, card),
                                          ),
                                        ),
                                      ),
                                      childWhenDragging: Opacity(
                                        opacity: 0.3,
                                        child: JobCardTile(
                                          card: card,
                                          onTap: () => _showCardDetails(context, card),
                                        ),
                                      ),
                                      child: JobCardTile(
                                        card: card,
                                        onTap: () => _showCardDetails(context, card),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                            onItemReorder: (int oldItemIndex, int oldListIndex, int newItemIndex, int newListIndex) {
                              // Handle reordering within the same lane
                              if (oldListIndex == newListIndex) {
                                controller.onReorderInLane(
                                  laneId: lane.id,
                                  oldIndex: oldItemIndex,
                                  newIndex: newItemIndex,
                                );
                              }
                            },
                            onListReorder: (int oldListIndex, int newListIndex) {
                              // Not used for single list
                            },
                            axis: Axis.vertical,
                            listWidth: double.infinity,
                            listPadding: EdgeInsets.zero,
                            listDecoration: const BoxDecoration(),
                          ),
                        ),
                      ),
                      // Lane Footer
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacing16),
                        child: Center(
                          child: TextButton.icon(
                            onPressed: () =>
                                _showAddCardDialog(context, controller, lane.id),
                            icon: const Icon(Icons.add, size: AppTheme.iconSize16),
                            label: const Text('เพิ่ม Job Card'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.figmaOrange,
                              textStyle: const TextStyle(
                                fontSize: AppTheme.fontSize10,
                                fontFamily: AppFont.family,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showAddCardDialog(
    BuildContext context,
    BoardController controller, [
    String? laneId,
  ]) {
    final titleController = TextEditingController();
    final assigneeController = TextEditingController();
    final amountController = TextEditingController();
    String selectedLaneId = laneId ?? controller.lanes.first.id;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Card'),
        content: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                decoration: const InputDecoration(labelText: 'Lane'),
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

  void _showLaneMenu(
    BuildContext context,
    BoardController controller,
    Lane lane,
  ) {
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
              title: const Text(
                'Delete Lane',
                style: TextStyle(color: AppTheme.errorRed),
              ),
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
