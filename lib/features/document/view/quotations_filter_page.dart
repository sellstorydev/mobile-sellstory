import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_font.dart';
import '../../../core/widgets/assignees_input_field.dart';
import '../../../core/services/workspace_members_service.dart';
import '../controller/quotations_list_controller.dart';

class QuotationsFilterPage extends StatefulWidget {
  final QuotationsListController controller;

  const QuotationsFilterPage({super.key, required this.controller});

  @override
  State<QuotationsFilterPage> createState() => _QuotationsFilterPageState();
}

class _QuotationsFilterPageState extends State<QuotationsFilterPage> {
  final Set<String> tempSelectedStatuses = {};
  final WorkspaceMembersService _workspaceMembersService = Get.find<WorkspaceMembersService>();
  List<WorkspaceMember> _availableMembers = [];
  bool _isLoadingMembers = true;

  @override
  void initState() {
    super.initState();
    tempSelectedStatuses.addAll(widget.controller.selectedStatuses);
    _loadWorkspaceMembers();
  }

  Future<void> _loadWorkspaceMembers() async {
    try {
      setState(() {
        _isLoadingMembers = true;
      });

      final workspaceId = widget.controller.currentWorkspaceId.value;
      if (workspaceId.isNotEmpty) {
        final members = await _workspaceMembersService.getAssignableMembers(workspaceId);
        setState(() {
          _availableMembers = members;
          _isLoadingMembers = false;
        });
      } else {
        setState(() {
          _isLoadingMembers = false;
        });
      }
    } catch (e) {
      print('❌ Error loading workspace members: $e');
      setState(() {
        _isLoadingMembers = false;
      });
    }
  }

  void _onAssigneesChanged(List<String> assigneeIds) {
    if (assigneeIds.isEmpty) {
      widget.controller.selectedSeller.value = null;
    } else {
      // For seller filter, we only allow one selection, so take the first one
      final selectedId = assigneeIds.first;
      final selectedMember = _availableMembers.firstWhere(
        (member) => member.uid == selectedId,
        orElse: () => WorkspaceMember(
          uid: selectedId,
          email: 'Unknown',
          displayName: 'Unknown User',
          permission: 'member',
        ),
      );
      widget.controller.selectedSeller.value = selectedMember;
    }
    widget.controller.applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final statusOptions = [
      {'value': 'DRAFT', 'label': 'ร่าง', 'icon': Icons.edit_outlined},
      {'value': 'SENT', 'label': 'ส่งแล้ว', 'icon': Icons.send},
      {
        'value': 'PENDING_APPROVAL',
        'label': 'รออนุมัติ',
        'icon': Icons.pending,
      },
      {'value': 'APPROVED', 'label': 'อนุมัติแล้ว', 'icon': Icons.check_circle},
      {'value': 'REJECTED', 'label': 'ปฏิเสธ', 'icon': Icons.cancel},
      {'value': 'VOID', 'label': 'ยกเลิก', 'icon': Icons.block},
      {
        'value': 'INVOICED',
        'label': 'ออกใบแจ้งหนี้แล้ว',
        'icon': Icons.receipt,
      },
      {'value': 'FULLY_PAID', 'label': 'ชำระแล้ว', 'icon': Icons.payment},
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'ตัวกรอง',
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
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.controller.clearFilters();
              setState(() {
                tempSelectedStatuses.clear();
              });
            },
            child: const Text(
              'ล้างตัวกรอง',
              style: TextStyle(
                color: AppTheme.primaryOrange,
                fontSize: AppTheme.fontSize14,
                fontFamily: AppFont.family,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seller Filter Section
            _buildSectionTitle('เซล'),
            const SizedBox(height: AppTheme.spacing12),

            // Seller selection using AssigneesInputField
            Obx(() => AssigneesInputField(
              selectedAssignees: widget.controller.selectedSeller.value != null 
                  ? [widget.controller.selectedSeller.value!.uid] 
                  : [],
              availableMembers: _availableMembers,
              onAssigneesChanged: _onAssigneesChanged,
              label: 'เลือกเซล',
              hintText: 'เลือกเซลที่ต้องการกรอง',
              isLoading: _isLoadingMembers,
              allowMultipleSelection: false, // Single selection for filtering
            )),

            const SizedBox(height: AppTheme.spacing24),

            // Date Filter Section
            _buildSectionTitle('วันที่'),
            const SizedBox(height: AppTheme.spacing12),

            Container(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.spacing12),
                border: Border.all(color: AppTheme.borderGrey, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadowColor.withValues(alpha: 0.05),
                    blurRadius: AppTheme.spacing8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Date range options
                  _buildDateOption('ทั้งหมด', null, Icons.all_inclusive, () {
                    setState(() {
                      widget.controller.selectedDateRange.value = null;
                      widget.controller.selectedCustomDateRange.value = null;
                      widget.controller.applyFilters();
                    });
                  }),

                  const SizedBox(height: AppTheme.spacing8),

                  _buildDateOption('วันนี้', 'today', Icons.today, () {
                    setState(() {
                      widget.controller.selectedDateRange.value = 'today';
                      widget.controller.applyFilters();
                    });
                  }),

                  const SizedBox(height: AppTheme.spacing8),

                  _buildDateOption(
                    'สัปดาห์นี้',
                    'this_week',
                    Icons.view_week,
                    () {
                      setState(() {
                        widget.controller.selectedDateRange.value = 'this_week';
                        widget.controller.applyFilters();
                      });
                    },
                  ),

                  const SizedBox(height: AppTheme.spacing8),

                  _buildDateOption(
                    'เดือนนี้',
                    'this_month',
                    Icons.calendar_view_month,
                    () {
                      setState(() {
                        widget.controller.selectedDateRange.value =
                            'this_month';
                        widget.controller.applyFilters();
                      });
                    },
                  ),

                  const SizedBox(height: AppTheme.spacing8),

                  _buildDateOption(
                    'เลือกช่วงวันที่เอง',
                    'custom',
                    Icons.date_range,
                    () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDateRange:
                            widget.controller.selectedCustomDateRange.value,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: Theme.of(context).colorScheme
                                  .copyWith(primary: AppTheme.primaryOrange),
                            ),
                            child: child!,
                          );
                        },
                      );

                      if (picked != null) {
                        setState(() {
                          widget.controller.selectedDateRange.value = 'custom';
                          widget.controller.selectedCustomDateRange.value =
                              picked;
                          widget.controller.applyFilters();
                        });
                      }
                    },
                  ),

                  // Show selected date range if custom
                  if (widget.controller.selectedDateRange.value == 'custom' &&
                      widget.controller.selectedCustomDateRange.value != null)
                    Container(
                      margin: const EdgeInsets.only(top: AppTheme.spacing12),
                      padding: const EdgeInsets.all(AppTheme.spacing12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(AppTheme.spacing8),
                        border: Border.all(
                          color: AppTheme.primaryOrange.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: AppTheme.primaryOrange,
                          ),
                          const SizedBox(width: AppTheme.spacing8),
                          Expanded(
                            child: Text(
                              '${widget.controller.selectedCustomDateRange.value!.start.day}/${widget.controller.selectedCustomDateRange.value!.start.month}/${widget.controller.selectedCustomDateRange.value!.start.year} - ${widget.controller.selectedCustomDateRange.value!.end.day}/${widget.controller.selectedCustomDateRange.value!.end.month}/${widget.controller.selectedCustomDateRange.value!.end.year}',
                              style: TextStyle(
                                color: AppTheme.primaryOrange,
                                fontSize: AppTheme.fontSize14,
                                fontFamily: AppFont.family,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacing24),

            // Status Filter Section
            Row(
              children: [
                _buildSectionTitle('สถานะ'),
                const SizedBox(width: AppTheme.spacing8),
                if (tempSelectedStatuses.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.only(
                      left: AppTheme.spacing8,
                      right: AppTheme.spacing8,
                      top: AppTheme.spacing4,
                      bottom: AppTheme.spacing4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppTheme.spacing8),
                      border: Border.all(
                        color: AppTheme.primaryOrange.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      style: TextStyle(
                        color: AppTheme.primaryOrange,
                        fontSize: AppTheme.fontSize14,
                        fontFamily: AppFont.family,
                        fontWeight: FontWeight.w500,
                      ),
                      'เลือกแล้ว ${tempSelectedStatuses.length} รายการ',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing12),

            Container(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.spacing12),
                border: Border.all(color: AppTheme.borderGrey, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadowColor.withValues(alpha: 0.05),
                    blurRadius: AppTheme.spacing8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (tempSelectedStatuses.isNotEmpty)
                    const SizedBox(height: AppTheme.spacing12),

                  // Status options
                  ...statusOptions.map((status) {
                    final isSelected = tempSelectedStatuses.contains(
                      status['value'],
                    );

                    return Container(
                      margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
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
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing12,
                          vertical: AppTheme.spacing4,
                        ),
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryOrange
                                : AppTheme.backgroundGrey,
                            borderRadius: BorderRadius.circular(
                              AppTheme.spacing8,
                            ),
                          ),
                          child: Icon(
                            status['icon'] as IconData,
                            size: AppTheme.iconSize20,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textSecondary,
                          ),
                        ),
                        title: Text(
                          status['label'] as String,
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.primaryOrange
                                : AppTheme.textPrimary,
                            fontSize: AppTheme.fontSize16,
                            fontFamily: AppFont.family,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (isSelected) {
                                tempSelectedStatuses.remove(
                                  status['value'] as String,
                                );
                              } else {
                                tempSelectedStatuses.add(
                                  status['value'] as String,
                                );
                              }
                              // Apply filters immediately
                              widget.controller.selectedStatuses.clear();
                              widget.controller.selectedStatuses.addAll(
                                tempSelectedStatuses,
                              );
                              widget.controller.applyFilters();
                            });
                          },
                          activeColor: AppTheme.primaryOrange,
                        ),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              tempSelectedStatuses.remove(
                                status['value'] as String,
                              );
                            } else {
                              tempSelectedStatuses.add(
                                status['value'] as String,
                              );
                            }
                            // Apply filters immediately
                            widget.controller.selectedStatuses.clear();
                            widget.controller.selectedStatuses.addAll(
                              tempSelectedStatuses,
                            );
                            widget.controller.applyFilters();
                          });
                        },
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacing24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppTheme.textPrimary,
        fontSize: AppTheme.fontSize16,
        fontFamily: AppFont.family,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDateOption(
    String title,
    String? value,
    IconData icon,
    VoidCallback onTap,
  ) {
    final isSelected = widget.controller.selectedDateRange.value == value;

    return Container(
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing12,
          vertical: AppTheme.spacing4,
        ),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryOrange
                : AppTheme.backgroundGrey,
            borderRadius: BorderRadius.circular(AppTheme.spacing8),
          ),
          child: Icon(
            icon,
            size: AppTheme.iconSize20,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryOrange : AppTheme.textPrimary,
            fontSize: AppTheme.fontSize16,
            fontFamily: AppFont.family,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: AppTheme.primaryOrange)
            : null,
        onTap: onTap,
      ),
    );
  }
}
