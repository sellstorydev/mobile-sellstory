import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/board_controller.dart';

class UnifiedFilterPage extends StatelessWidget {
  const UnifiedFilterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BoardController>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('filter_tasks'.tr),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          TextButton(
            onPressed: () => controller.clearFilter(),
            child: Text(
              'clear_all'.tr,
              style: TextStyle(color: Colors.red[600]),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Filter Section
            _buildDateFilterSection(controller),
            const SizedBox(height: 24),
            
            // Assignee Filter Section
            _buildAssigneeFilterSection(controller),
            const SizedBox(height: 24),
            
            // Customer Filter Section
            _buildCustomerFilterSection(controller),
            const SizedBox(height: 24),
            
            // Hashtag Filter Section
            _buildHashtagFilterSection(controller),
            const SizedBox(height: 24),
            
            // Interest Filter Section
            _buildInterestFilterSection(controller),
            const SizedBox(height: 32),
            
            // Apply Button
            _buildApplyButton(controller, context),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilterSection(BoardController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.blue[600], size: 20),
            const SizedBox(width: 8),
            Text(
              'date_filter_job_card'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Date Type Selection
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'select_date_type'.tr,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              
              // Date type options with checkboxes
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildDateTypeChip(controller, 'startDate', 'Start Date'),
                  _buildDateTypeChip(controller, 'endDate', 'End Date'),
                  _buildDateTypeChip(controller, 'createdAt', 'Created Date'),
                  _buildDateTypeChip(controller, 'dueDate', 'To-Do Date'),
                  _buildDateTypeChip(controller, 'updatedAt', 'Updated At'),

                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Quick Date Options
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'quick_options'.tr,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              
              // Quick date buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickDateChip(controller, 'today', 'today'.tr),
                  _buildQuickDateChip(controller, 'thisWeek', 'this_week'.tr),
                  _buildQuickDateChip(controller, 'thisMonth', 'this_month'.tr),
                  _buildQuickDateChip(controller, 'lastMonth', 'last_month'.tr),
                  _buildQuickDateChip(controller, '+1day', '+1_day'.tr),
                  _buildQuickDateChip(controller, '+3days', '+3_days'.tr),
                  _buildQuickDateChip(controller, '+7days', '+7_days'.tr),
                  _buildQuickDateChip(controller, '+14days', '+14_days'.tr),
                  _buildQuickDateChip(controller, '+30days', '+30_days'.tr),
                  _buildQuickDateChip(controller, 'lastWeek', 'last_week'.tr),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Show cards without date checkbox
              Obx(() => CheckboxListTile(
                value: controller.showCardsWithoutDate.value,
                onChanged: (bool? value) {
                  controller.toggleShowCardsWithoutDate();
                },
                title: Text(
                  'show_unselected_dates'.tr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'show_tasks_without_date_in_selected_type'.tr,
                  style: TextStyle(fontSize: 12),
                ),
                activeColor: Colors.orange[600],
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              )),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Custom Date Range
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'set_custom_date_range'.tr,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: Obx(() => OutlinedButton.icon(
                      onPressed: () => _selectDate(controller, true),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        controller.selectedStartDate.value != null
                            ? _formatDate(controller.selectedStartDate.value!)
                            : 'select_start_date'.tr,
                      ),
                    )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() => OutlinedButton.icon(
                      onPressed: () => _selectDate(controller, false),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        controller.selectedEndDate.value != null
                            ? _formatDate(controller.selectedEndDate.value!)
                            : 'select_end_date'.tr,
                      ),
                    )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAssigneeFilterSection(BoardController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.person, color: Colors.orange[600], size: 20),
            const SizedBox(width: 8),
            Text(
              'assignee'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'select_assignees_multiple'.tr,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.orange[800],
                ),
              ),
              const SizedBox(height: 12),
              
              Obx(() {
                if (controller.availableAssignees.isEmpty) {
                  return Text(
                    'no_assignees_in_system'.tr,
                    style: TextStyle(color: Colors.grey),
                  );
                }
                
                return Column(
                  children: controller.availableAssignees.map((assigneeId) {
                    final isSelected = controller.selectedAssignees.contains(assigneeId);
                    
                    return FutureBuilder<String>(
                      future: controller.getUserDisplayName(assigneeId),
                      builder: (context, snapshot) {
                        final displayName = snapshot.data ?? assigneeId;
                        
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (bool? value) {
                            controller.toggleAssigneeFilter(assigneeId);
                          },
                          secondary: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.orange[100],
                            child: Text(
                              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: Colors.orange[800],
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          title: Text(displayName),
                          subtitle: Text(_getAssigneeCardCount(controller, assigneeId)),
                          activeColor: Colors.orange[600],
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        );
                      },
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerFilterSection(BoardController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people_alt, color: Colors.green[600], size: 20),
            const SizedBox(width: 8),
            Text(
              'customer'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'select_customers_multiple'.tr,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.green[800],
                ),
              ),
              const SizedBox(height: 12),
              
              Obx(() {
                if (controller.availableCustomers.isEmpty) {
                  return Text(
                    'no_customers_in_system'.tr,
                    style: TextStyle(color: Colors.grey),
                  );
                }
                
                return Column(
                  children: controller.availableCustomers.map((customerName) {
                    final isSelected = controller.selectedCustomers.contains(customerName);
                    
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (bool? value) {
                        controller.toggleCustomerFilter(customerName);
                      },
                      secondary: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.green[100],
                        child: Text(
                          customerName.isNotEmpty ? customerName[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: Colors.green[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text(customerName),
                      subtitle: Text(_getCustomerCardCount(controller, customerName)),
                      activeColor: Colors.green[600],
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHashtagFilterSection(BoardController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.tag, color: Colors.purple[600], size: 20),
            const SizedBox(width: 8),
            Text(
              'hashtag'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'select_hashtags_multiple'.tr,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.purple[800],
                ),
              ),
              const SizedBox(height: 12),
              
              Obx(() {
                // Use computed property instead of reactive list
                final hashtags = controller.currentAvailableHashtags;
                
                print('🔍 UnifiedFilterPage - currentAvailableHashtags: $hashtags');
                print('🔍 UnifiedFilterPage - hashtags length: ${hashtags.length}');
                
                if (hashtags.isEmpty) {
                  return Text(
                    'no_hashtags_in_system'.tr,
                    style: TextStyle(color: Colors.grey),
                  );
                }
                
                return Column(
                  children: hashtags.map((hashtag) {
                    final isSelected = controller.selectedHashtags.contains(hashtag);
                    
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (bool? value) {
                        controller.toggleHashtagFilter(hashtag);
                      },
                      secondary: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.purple[100],
                        child: Text(
                          '#',
                          style: TextStyle(
                            color: Colors.purple[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text('#$hashtag'),
                      subtitle: Text(_getHashtagCardCount(controller, hashtag)),
                      activeColor: Colors.purple[600],
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInterestFilterSection(BoardController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.favorite, color: Colors.red[600], size: 20),
            const SizedBox(width: 8),
            Text(
              'interest'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'select_interests_multiple'.tr,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.red[800],
                ),
              ),
              const SizedBox(height: 12),
              
              Obx(() {
                final interests = controller.currentAvailableInterests;
                
                if (interests.isEmpty) {
                  return Text(
                    'no_interests_in_system'.tr,
                    style: TextStyle(color: Colors.grey),
                  );
                }
                
                return Column(
                  children: [
                    // Interest chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: interests.map((interest) =>
                        _buildInterestChip(controller, interest, interest)
                      ).toList(),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInterestChip(BoardController controller, String interest, String label) {
    return Obx(() {
      final isSelected = controller.selectedInterests.contains(interest);
      return FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (selected) {
          controller.toggleInterestFilter(interest);
        },
        selectedColor: Colors.red[100],
        checkmarkColor: Colors.red[800],
        side: BorderSide(color: Colors.red[200]!),
      );
    });
  }

  Widget _buildApplyButton(BoardController controller, BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Obx(() {
        final hasAnyFilter = controller.selectedAssignees.isNotEmpty ||
                           controller.selectedCustomers.isNotEmpty ||
                           controller.selectedHashtags.isNotEmpty ||
                           controller.selectedInterests.isNotEmpty ||
                           controller.selectedDateFilterTypes.isNotEmpty ||
                           controller.showCardsWithoutDate.value;
        
        return ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.check),
          label: Text(hasAnyFilter ? 'apply_filter'.tr : 'close'.tr),
          style: ElevatedButton.styleFrom(
            backgroundColor: hasAnyFilter ? Colors.blue[600] : Colors.grey[400],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDateTypeChip(BoardController controller, String type, String label) {
    return Obx(() {
      final isSelected = controller.selectedDateFilterTypes.contains(type);
      return FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (selected) {
          controller.toggleDateFilterType(type);
        },
        selectedColor: Colors.blue[100],
        checkmarkColor: Colors.blue[800],
      );
    });
  }

  Widget _buildQuickDateChip(BoardController controller, String type, String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        controller.setQuickDateFilter(type);
      },
      backgroundColor: Colors.grey[100],
      side: BorderSide(color: Colors.grey[300]!),
    );
  }

  Future<void> _selectDate(BoardController controller, bool isStartDate) async {
    final context = Get.context!;
    final initialDate = isStartDate 
        ? controller.selectedStartDate.value ?? DateTime.now()
        : controller.selectedEndDate.value ?? DateTime.now();
    
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (pickedDate != null) {
      if (isStartDate) {
        controller.selectedStartDate.value = pickedDate;
      } else {
        controller.selectedEndDate.value = pickedDate;
      }
      
      // Apply filter when date is selected
      if (controller.selectedDateFilterTypes.isNotEmpty) {
        controller.refresh();
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getAssigneeCardCount(BoardController controller, String assigneeId) {
    int count = 0;
    for (final lane in controller.lanes) {
      count += lane.cards.where((card) => card.assignedTo == assigneeId).length;
    }
    return '$count ${'tasks'.tr}';
  }

  String _getCustomerCardCount(BoardController controller, String customerName) {
    int count = 0;
    for (final lane in controller.lanes) {
      count += lane.cards.where((card) => card.customer == customerName).length;
    }
    return '$count ${'tasks'.tr}';
  }

  String _getHashtagCardCount(BoardController controller, String hashtag) {
    int count = 0;
    for (final lane in controller.lanes) {
      count += lane.cards.where((card) => 
        card.hashtags.any((hashtagObj) => 
          (hashtagObj['text'] ?? '').toString().toLowerCase().contains(hashtag.toLowerCase())
        )
      ).length;
    }
    return '$count ${'tasks'.tr}';
  }
}
