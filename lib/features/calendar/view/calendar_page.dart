import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_font.dart';
import '../../../core/widgets/assignees_input_field.dart';
import '../../../core/services/workspace_members_service.dart';
import '../controller/calendar_controller.dart';
import '../../../domain/entities/job_card.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _eventsListKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToEventsList() {
    if (_eventsListKey.currentContext != null) {
      Scrollable.ensureVisible(
        _eventsListKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CalendarController());

    // Listen to date changes and auto-scroll
    ever(controller.selectedDate, (_) => _scrollToEventsList());

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'ปฏิทิน',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: AppTheme.fontSize18,
            fontFamily: AppFont.family,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.backgroundWhite,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => controller.refreshData(),
            icon: const Icon(Icons.refresh),
            color: AppTheme.primaryOrange,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryOrange),
          );
        }

        return SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              // Divider
              Container(
                height: 1,
                color: AppTheme.borderGrey.withValues(alpha: 0.3),
                margin: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing16,
                ),
              ),

              // Assignees Filter
              _buildAssigneesFilter(controller),

              // View Type Filter
              _buildViewTypeFilter(controller),

              // Calendar Widget
              _buildCalendarWidget(controller),

              // Events List - Show first for better UX
              _buildEventsList(controller),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildViewTypeFilter(CalendarController controller) {
    return Container(
      padding: const EdgeInsets.only(
        left: AppTheme.spacing16,
        right: AppTheme.spacing16,
        top: AppTheme.spacing16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withValues(alpha: 0.05),
            blurRadius: AppTheme.spacing8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildViewModeButton(
            controller,
            'month',
            'เดือน',
            Icons.calendar_view_month,
          ),
          const SizedBox(width: AppTheme.spacing8),
          _buildViewModeButton(
            controller,
            '2week',
            '2 สัปดาห์',
            Icons.view_week,
          ),
          const SizedBox(width: AppTheme.spacing8),
          _buildViewModeButton(controller, 'week', 'สัปดาห์', Icons.view_week),
        ],
      ),
    );
  }

  Widget _buildViewModeButton(
    CalendarController controller,
    String mode,
    String label,
    IconData icon,
  ) {
    final isSelected = controller.selectedViewMode.value == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () => controller.setViewMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing12,
            vertical: AppTheme.spacing8,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryOrange
                : AppTheme.backgroundGrey,
            borderRadius: BorderRadius.circular(AppTheme.spacing8),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryOrange
                  : AppTheme.borderGrey.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: AppTheme.iconSize16,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: AppTheme.spacing4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontSize: AppTheme.fontSize12,
                  fontFamily: AppFont.family,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssigneesFilter(CalendarController controller) {
    return Container(
      padding: const EdgeInsets.only(
        left: AppTheme.spacing16,
        right: AppTheme.spacing16,
        top: AppTheme.spacing16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderGrey.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Type Buttons
          Row(
            children: [
              _buildFilterTypeButton(
                controller,
                'all',
                'ทั้งหมด',
                Icons.all_inclusive,
              ),
              const SizedBox(width: AppTheme.spacing8),
              _buildFilterTypeButton(controller, 'jobcard', 'Job Card', Icons.work),
              const SizedBox(width: AppTheme.spacing8),
              _buildFilterTypeButton(
                controller,
                'todo',
                'Task',
                Icons.checklist,
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacing8),

          AssigneesInputField(
            selectedAssignees: controller.selectedAssignees,
            availableMembers: controller.availableMembers
                .map(
                  (member) => WorkspaceMember(
                    uid: member['uid'],
                    displayName: member['displayName'],
                    email: member['email'],
                    permission: 'member',
                  ),
                )
                .toList(),
            onAssigneesChanged: controller.setSelectedAssignees,
            label: 'เลือกผู้รับผิดชอบ',
            hintText: 'เลือกผู้รับผิดชอบที่ต้องการดู',
            isLoading: false,
            allowMultipleSelection: true,
            showBorder: false,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTypeButton(
    CalendarController controller,
    String type,
    String label,
    IconData icon,
  ) {
    final isSelected = controller.selectedFilterType.value == type;

    return Expanded(
      child: GestureDetector(
        onTap: () => controller.setFilterType(type),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing8,
            vertical: AppTheme.spacing8,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryOrange.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.spacing8),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryOrange
                  : AppTheme.borderGrey.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: AppTheme.iconSize14,
                color: isSelected
                    ? AppTheme.primaryOrange
                    : AppTheme.textSecondary,
              ),
              const SizedBox(width: AppTheme.spacing4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.primaryOrange
                      : AppTheme.textSecondary,
                  fontSize: AppTheme.fontSize11,
                  fontFamily: AppFont.family,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarWidget(CalendarController controller) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderGrey.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Calendar Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  final newDate = controller.selectedDate.value.subtract(
                    controller.selectedViewMode.value == 'month'
                        ? const Duration(days: 30)
                        : controller.selectedViewMode.value == 'week'
                        ? const Duration(days: 7)
                        : controller.selectedViewMode.value == '2week'
                        ? const Duration(days: 14)
                        : const Duration(days: 1),
                  );
                  controller.setSelectedDate(newDate);
                },
                icon: const Icon(Icons.chevron_left),
                color: AppTheme.textSecondary,
              ),

              Text(
                _getCalendarTitle(controller),
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: AppTheme.fontSize16,
                  fontFamily: AppFont.family,
                  fontWeight: FontWeight.w600,
                ),
              ),

              IconButton(
                onPressed: () {
                  final newDate = controller.selectedDate.value.add(
                    controller.selectedViewMode.value == 'month'
                        ? const Duration(days: 30)
                        : controller.selectedViewMode.value == 'week'
                        ? const Duration(days: 7)
                        : controller.selectedViewMode.value == '2week'
                        ? const Duration(days: 14)
                        : const Duration(days: 1),
                  );
                  controller.setSelectedDate(newDate);
                },
                icon: const Icon(Icons.chevron_right),
                color: AppTheme.textSecondary,
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacing16),

          // Calendar Grid
          _buildCalendarGrid(controller),
        ],
      ),
    );
  }

  String _getCalendarTitle(CalendarController controller) {
    final date = controller.selectedDate.value;
    final thaiMonths = [
      'มกราคม',
      'กุมภาพันธ์',
      'มีนาคม',
      'เมษายน',
      'พฤษภาคม',
      'มิถุนายน',
      'กรกฎาคม',
      'สิงหาคม',
      'กันยายน',
      'ตุลาคม',
      'พฤศจิกายน',
      'ธันวาคม',
    ];

    switch (controller.selectedViewMode.value) {
      case 'month':
        return '${thaiMonths[date.month - 1]} ${date.year + 543}';
      case 'week':
        final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return '${startOfWeek.day} ${thaiMonths[startOfWeek.month - 1]} - ${endOfWeek.day} ${thaiMonths[endOfWeek.month - 1]} ${endOfWeek.year + 543}';
      case '2week':
        final startOf2Week = date.subtract(Duration(days: date.weekday - 1));
        final endOf2Week = startOf2Week.add(const Duration(days: 13));
        return '${startOf2Week.day} ${thaiMonths[startOf2Week.month - 1]} - ${endOf2Week.day} ${thaiMonths[endOf2Week.month - 1]} ${endOf2Week.year + 543}';
      default:
        return '${date.day} ${thaiMonths[date.month - 1]} ${date.year + 543}';
    }
  }

  Widget _buildCalendarGrid(CalendarController controller) {
    switch (controller.selectedViewMode.value) {
      case 'month':
        return _buildMonthView(controller);
      case 'week':
        return _buildWeekView(controller);
      case '2week':
        return _build2WeekView(controller);
      default:
        return _buildMonthView(controller);
    }
  }

  Widget _buildMonthView(CalendarController controller) {
    final selectedDate = controller.selectedDate.value;
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final lastDayOfMonth = DateTime(
      selectedDate.year,
      selectedDate.month + 1,
      0,
    );
    final firstDayOfWeek = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    final days = <Widget>[];

    // Add empty cells for days before the first day of the month
    for (int i = 1; i < firstDayOfWeek; i++) {
      days.add(_buildCalendarDay(controller, null));
    }

    // Add days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(selectedDate.year, selectedDate.month, day);
      days.add(_buildCalendarDay(controller, date));
    }

    return Column(
      children: [
        // Weekday headers
        Row(
          children: ['อา', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส']
              .map(
                (day) => Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacing8,
                    ),
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: AppTheme.fontSize12,
                        fontFamily: AppFont.family,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),

        // Calendar grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 7,
          childAspectRatio: 1.2,
          children: days,
        ),
      ],
    );
  }

  Widget _buildWeekView(CalendarController controller) {
    final selectedDate = controller.selectedDate.value;
    final startOfWeek = selectedDate.subtract(
      Duration(days: selectedDate.weekday - 1),
    );

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      childAspectRatio: 1.2,
      children: List.generate(7, (index) {
        final date = startOfWeek.add(Duration(days: index));
        return _buildCalendarDay(controller, date);
      }),
    );
  }

  Widget _build2WeekView(CalendarController controller) {
    final selectedDate = controller.selectedDate.value;
    final startOf2Week = selectedDate.subtract(
      Duration(days: selectedDate.weekday - 1),
    );

    return Column(
      children: List.generate(2, (weekIndex) {
        final weekStart = startOf2Week.add(Duration(days: weekIndex * 7));
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 7,
          childAspectRatio: 1.2,
          children: List.generate(7, (dayIndex) {
            final date = weekStart.add(Duration(days: dayIndex));
            return _buildCalendarDay(controller, date);
          }),
        );
      }),
    );
  }

  Widget _buildCalendarDay(CalendarController controller, DateTime? date) {
    if (date == null) {
      return Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: AppTheme.backgroundGrey,
          borderRadius: BorderRadius.circular(AppTheme.spacing4),
        ),
      );
    }

    final isSelected =
        controller.selectedDate.value.year == date.year &&
        controller.selectedDate.value.month == date.month &&
        controller.selectedDate.value.day == date.day;

    final isToday =
        DateTime.now().year == date.year &&
        DateTime.now().month == date.month &&
        DateTime.now().day == date.day;

    final eventsForDay = controller.getEventsForDate(date);
    final hasEvents = eventsForDay.isNotEmpty;

    return GestureDetector(
      onTap: () {
        controller.setSelectedDate(date);
        // Auto-scroll to events list after a short delay to ensure the date is updated
        Future.delayed(const Duration(milliseconds: 100), () {
          _scrollToEventsList();
        });
      },
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryOrange
                  : isToday
                  ? AppTheme.primaryOrange.withValues(alpha: 0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.spacing4),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryOrange
                    : hasEvents
                    ? AppTheme.primaryOrange.withValues(alpha: 0.3)
                    : AppTheme.borderGrey.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                '${date.day}',
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : isToday
                      ? AppTheme.primaryOrange
                      : AppTheme.textPrimary,
                  fontSize: AppTheme.fontSize14,
                  fontFamily: AppFont.family,
                  fontWeight: isSelected || isToday
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
              ),
            ),
          ),
          if (hasEvents)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing4,
                  vertical: AppTheme.spacing2,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : AppTheme.primaryOrange,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(AppTheme.spacing4),
                  ),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryOrange : Colors.white,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  '${eventsForDay.length}',
                  style: TextStyle(
                    color: isSelected ? AppTheme.primaryOrange : Colors.white,
                    fontSize: AppTheme.fontSize10,
                    fontFamily: AppFont.family,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventsList(CalendarController controller) {
    final events = controller.getEventsForDate(controller.selectedDate.value);

    return Container(
      key: _eventsListKey,
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Events Header
          Row(
            children: [
              Icon(
                Icons.event_note,
                color: AppTheme.primaryOrange,
                size: AppTheme.iconSize20,
              ),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                'กิจกรรมในวันที่ ${controller.formatDate(controller.selectedDate.value.millisecondsSinceEpoch)}',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: AppTheme.fontSize18,
                  fontFamily: AppFont.family,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing8,
                  vertical: AppTheme.spacing4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.spacing8),
                ),
                child: Text(
                  '${events.length} รายการ',
                  style: TextStyle(
                    color: AppTheme.primaryOrange,
                    fontSize: AppTheme.fontSize12,
                    fontFamily: AppFont.family,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacing16),

          // Events List
          if (events.isEmpty)
            _buildEmptyState(controller)
          else
            ...events
                .map((event) => _buildEventCard(event, controller))
                .toList(),
        ],
      ),
    );
  }

  Widget _buildEventCard(
    Map<String, dynamic> event,
    CalendarController controller,
  ) {
    final title = event['title'] ?? 'Untitled';
    final type = event['type'] ?? 'unknown';
    final status = event['status'] ?? 'TODO';
    final priority = event['priority'] ?? 'medium';
    final description = event['description'] ?? '';
    final date = event['date'] ?? 0;
    final assignee = event['assignee'];
    final parentCardTitle = event['parentCardTitle'];

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.spacing12),
        border: Border.all(
          color: AppTheme.borderGrey.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withValues(alpha: 0.05),
            blurRadius: AppTheme.spacing8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.spacing12),
          onTap: () {
            // Navigate to appropriate page based on event type
            print(type);
            print(event);
            if (type == 'jobcard') {
              // For jobcard events, navigate to card view page
              final cardId = event['cardId'];
              if (cardId != null) {
                // Find the job card from the controller's data
                final jobCard = _findJobCardById(controller, cardId);
                if (jobCard != null) {
                  Get.toNamed(AppRoutes.editCard, arguments: jobCard);
                } else {
                  Get.snackbar(
                    'Error',
                    'ไม่พบข้อมูลงาน',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              } else {
                Get.snackbar(
                  'Error',
                  'ไม่พบข้อมูลงาน',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            } else if (type == 'todo') {
              // For todo events, navigate to the parent jobcard
              final parentCardId = event['parentCardId'];
              if (parentCardId != null) {
                // Find the parent job card from the controller's data
                final jobCard = _findJobCardById(controller, parentCardId);
                if (jobCard != null) {
                  Get.toNamed(AppRoutes.editCard, arguments: jobCard);
                } else {
                  Get.snackbar(
                    'Error',
                    'ไม่พบข้อมูลงานหลัก',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              } else {
                Get.snackbar(
                  'Error',
                  'ไม่พบข้อมูลงานหลัก',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            } else {
              // For unknown event types, show info
              Get.snackbar(
                'Info',
                'ไม่รองรับประเภทกิจกรรมนี้',
                snackPosition: SnackPosition.BOTTOM,
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    // Type icon
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: type == 'jobcard'
                            ? AppTheme.primaryOrange.withValues(alpha: 0.1)
                            : const Color(0xFF2196F3).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.spacing8),
                      ),
                      child: Icon(
                        type == 'jobcard' ? Icons.work : Icons.checklist,
                        size: AppTheme.iconSize16,
                        color: type == 'jobcard'
                            ? AppTheme.primaryOrange
                            : const Color(0xFF2196F3),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing12),

                    // Title and type
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: AppTheme.fontSize16,
                              fontFamily: AppFont.family,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (type == 'todo' && parentCardTitle != null) ...[
                            const SizedBox(height: AppTheme.spacing4),
                            Text(
                              'จาก: $parentCardTitle',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: AppTheme.fontSize12,
                                fontFamily: AppFont.family,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Status chip
                    _buildStatusChip(controller, status),
                  ],
                ),

                if (description.isNotEmpty) ...[
                   const SizedBox(height: AppTheme.spacing12),
                   Text(
                     description,
                     style: TextStyle(
                       color: AppTheme.textSecondary,
                       fontSize: AppTheme.fontSize14,
                       fontFamily: AppFont.family,
                     ),
                     maxLines: 2,
                     overflow: TextOverflow.ellipsis,
                   ),
                 ],

                 // Show todos for jobcard events
                 if (type == 'jobcard') ...[
                   const SizedBox(height: AppTheme.spacing12),
                   _buildTodosList(event, controller),
                 ],

                const SizedBox(height: AppTheme.spacing12),

                // Footer
                Row(
                  children: [
                    // Priority
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing8,
                        vertical: AppTheme.spacing4,
                      ),
                      decoration: BoxDecoration(
                        color: controller
                            .getPriorityColor(priority)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.spacing8),
                      ),
                      child: Text(
                        controller.getPriorityText(priority),
                        style: TextStyle(
                          color: controller.getPriorityColor(priority),
                          fontSize: AppTheme.fontSize10,
                          fontFamily: AppFont.family,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(width: AppTheme.spacing8),

                    // Date
                    Icon(
                      Icons.calendar_today,
                      size: AppTheme.iconSize12,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: AppTheme.spacing4),
                    Text(
                      controller.formatDate(date),
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: AppTheme.fontSize12,
                        fontFamily: AppFont.family,
                      ),
                    ),

                    const Spacer(),

                    // Assignee
                    if (assignee != null) ...[
                      Icon(
                        Icons.person,
                        size: AppTheme.iconSize12,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: AppTheme.spacing4),
                      Text(
                        assignee is String
                            ? assignee
                            : assignee['displayName'] ?? 'Unknown',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: AppTheme.fontSize12,
                          fontFamily: AppFont.family,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(CalendarController controller, String status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing8,
        vertical: AppTheme.spacing4,
      ),
      decoration: BoxDecoration(
        color: controller.getStatusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.spacing8),
      ),
      child: Text(
        controller.getStatusText(status),
        style: TextStyle(
          color: controller.getStatusColor(status),
          fontSize: AppTheme.fontSize10,
          fontFamily: AppFont.family,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  Widget _buildEmptyState(CalendarController controller) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing24),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.spacing16),
            ),
            child: Icon(
              Icons.event_note,
              size: 40,
              color: AppTheme.primaryOrange,
            ),
          ),
          const SizedBox(height: AppTheme.spacing24),
          Text(
            'ไม่มีกิจกรรมในวันที่เลือก',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: AppTheme.fontSize18,
              fontFamily: AppFont.family,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'ลองเปลี่ยนวันที่หรือตัวกรองเพื่อดูกิจกรรมอื่นๆ',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: AppTheme.fontSize14,
              fontFamily: AppFont.family,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

     // Helper method to find job card by ID from controller's data
   JobCard? _findJobCardById(CalendarController controller, String cardId) {
     try {
       // Search through the job cards data in the controller
       for (final cardData in controller.jobCards) {
         if (cardData['id'] == cardId) {
           // Convert the map data back to JobCard object
           return JobCard.fromMap(cardData, cardId);
         }
       }
       return null;
     } catch (e) {
       print('❌ Error finding job card by ID: $e');
       return null;
     }
   }

       // Helper method to build todos list for jobcard events
    Widget _buildTodosList(Map<String, dynamic> event, CalendarController controller) {
      final cardId = event['cardId'];
      if (cardId == null) return const SizedBox.shrink();

      // Get todos from the event data (they're stored in the card's todos field)
      final todosForCard = event['todos'] as List<dynamic>? ?? [];

      if (todosForCard.isEmpty) return const SizedBox.shrink();

     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Row(
           children: [
             Icon(
               Icons.checklist,
               size: AppTheme.iconSize14,
               color: AppTheme.textSecondary,
             ),
             const SizedBox(width: AppTheme.spacing4),
             Text(
               'งานย่อย (${todosForCard.length})',
               style: TextStyle(
                 color: AppTheme.textSecondary,
                 fontSize: AppTheme.fontSize12,
                 fontFamily: AppFont.family,
                 fontWeight: FontWeight.w600,
               ),
             ),
           ],
         ),
         const SizedBox(height: AppTheme.spacing8),
         ...todosForCard.map((todo) => _buildTodoItem(todo)).toList(),
       ],
     );
   }

       // Helper method to build individual todo item
    Widget _buildTodoItem(Map<String, dynamic> todo) {
      final rawTitle = todo['title'] ?? 'Untitled Todo';
      final title = rawTitle.toString().replaceAll(RegExp(r'<[^>]*>'), '');
      final status = todo['completed'] == true ? 'COMPLETED' : 'TODO';
      final priority = todo['priority'] ?? 'medium';
      final isCompleted = status == 'COMPLETED';

     return Container(
       margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
       padding: const EdgeInsets.all(AppTheme.spacing8),
       decoration: BoxDecoration(
         color: AppTheme.backgroundGrey.withValues(alpha: 0.3),
         borderRadius: BorderRadius.circular(AppTheme.spacing8),
         border: Border.all(
           color: AppTheme.borderGrey.withValues(alpha: 0.2),
           width: 1,
         ),
       ),
       child: Row(
         children: [
           // Checkbox Coming Soon
          //  Container(
          //    width: 16,
          //    height: 16,
          //    decoration: BoxDecoration(
          //      color: isCompleted ? AppTheme.primaryOrange : Colors.transparent,
          //      borderRadius: BorderRadius.circular(3),
          //      border: Border.all(
          //        color: isCompleted ? AppTheme.primaryOrange : AppTheme.borderGrey,
          //        width: 1.5,
          //      ),
          //    ),
          //    child: isCompleted
          //        ? const Icon(
          //            Icons.check,
          //            size: 10,
          //            color: Colors.white,
          //          )
          //        : null,
          //  ),
           const SizedBox(width: AppTheme.spacing8),

           // Todo content
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
                   title,
                   style: TextStyle(
                     color: isCompleted ? AppTheme.textSecondary : AppTheme.textPrimary,
                     fontSize: AppTheme.fontSize12,
                     fontFamily: AppFont.family,
                     fontWeight: FontWeight.w500,
                     decoration: isCompleted ? TextDecoration.lineThrough : null,
                   ),
                 ),
                 const SizedBox(height: AppTheme.spacing4),
                 Row(
                   children: [
                     // Priority chip
                     Container(
                       padding: const EdgeInsets.symmetric(
                         horizontal: AppTheme.spacing4,
                         vertical: AppTheme.spacing2,
                       ),
                       decoration: BoxDecoration(
                         color: _getPriorityColor(priority).withValues(alpha: 0.1),
                         borderRadius: BorderRadius.circular(AppTheme.spacing4),
                       ),
                       child: Text(
                         _getPriorityText(priority),
                         style: TextStyle(
                           color: _getPriorityColor(priority),
                           fontSize: AppTheme.fontSize8,
                           fontFamily: AppFont.family,
                           fontWeight: FontWeight.w600,
                         ),
                       ),
                     ),
                                            const SizedBox(width: AppTheme.spacing8),
                     // Status chip
                     Container(
                       padding: const EdgeInsets.symmetric(
                         horizontal: AppTheme.spacing4,
                         vertical: AppTheme.spacing2,
                       ),
                       decoration: BoxDecoration(
                         color: _getStatusColor(status).withValues(alpha: 0.1),
                         borderRadius: BorderRadius.circular(AppTheme.spacing4),
                       ),
                       child: Text(
                         _getStatusText(status),
                         style: TextStyle(
                           color: _getStatusColor(status),
                           fontSize: AppTheme.fontSize8,
                           fontFamily: AppFont.family,
                           fontWeight: FontWeight.w600,
                         ),
                       ),
                     ),
                   ],
                 ),
               ],
             ),
           ),
         ],
       ),
     );
   }

   // Helper methods for priority and status colors/text
   Color _getPriorityColor(String priority) {
     switch (priority.toLowerCase()) {
       case 'high':
         return Colors.red;
       case 'medium':
         return Colors.orange;
       case 'low':
         return Colors.green;
       default:
         return Colors.grey;
     }
   }

   String _getPriorityText(String priority) {
     switch (priority.toLowerCase()) {
       case 'high':
         return 'สูง';
       case 'medium':
         return 'ปานกลาง';
       case 'low':
         return 'ต่ำ';
       default:
         return 'ไม่ระบุ';
     }
   }

   Color _getStatusColor(String status) {
     switch (status.toUpperCase()) {
       case 'COMPLETED':
         return Colors.green;
       case 'IN_PROGRESS':
         return Colors.orange;
       case 'TODO':
         return Colors.blue;
       default:
         return Colors.grey;
     }
   }

   String _getStatusText(String status) {
     switch (status.toUpperCase()) {
       case 'COMPLETED':
         return 'เสร็จแล้ว';
       case 'IN_PROGRESS':
         return 'กำลังทำ';
       case 'TODO':
         return 'รอดำเนินการ';
       default:
         return 'ไม่ระบุ';
     }
   }
}
