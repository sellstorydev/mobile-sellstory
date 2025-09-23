import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sellstory/core/enums/lane_display_mode.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/lane.dart';
import '../controller/lane_display_controller.dart';
import '../../../core/utils/lane_total_calculator.dart';

class LaneHeader extends StatelessWidget {
  final Lane lane;
  final VoidCallback? onMenuTap;
  final VoidCallback? onCreateCard;
  final VoidCallback? onCloneLane; // Clone lane callback
  final VoidCallback? onDeleteLane; // Delete lane callback
  final List<String>? allLaneIds; // For "Apply to All Lanes" functionality

  const LaneHeader({
    super.key,
    required this.lane,
    this.onMenuTap,
    this.onCreateCard,
    this.onCloneLane,
    this.onDeleteLane,
    this.allLaneIds,
  });

  @override
  Widget build(BuildContext context) {
    // Initialize display controller with fallback
    LaneDisplayController displayController;
    try {
      displayController = Get.find<LaneDisplayController>();
    } catch (e) {
      // If not found, create and register it
      displayController = Get.put(LaneDisplayController());
    }

    return Obx(() {
      final displayMode = displayController.getDisplayMode(lane.id);
      final displayText = _getDisplayText(displayMode);

      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16,
          vertical: AppTheme.spacing12,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Lane title, card count, menu
            Row(
              children: [
                // Lane title
                Expanded(
                  child: Text(
                    lane.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                Container(width: 4),

                // Card count badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange,
                    borderRadius: BorderRadius.circular(AppTheme.radius12),
                  ),
                  child: Text(
                    '${lane.cardCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Container(width: AppTheme.spacing8),
                Container(width: 4),

                // Menu button
                if (onMenuTap != null)
                  GestureDetector(
                    onTap: () {
                      print('🔥 Lane menu button tapped for lane: ${lane.id}');
                      try {
                        _showLaneOptions(context, displayController);
                      } catch (e) {
                        print('❌ Error showing lane options: $e');
                        // Fallback to original behavior if modal fails
                        onMenuTap?.call();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spacing4),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundGrey,
                        borderRadius: BorderRadius.circular(AppTheme.radius4),
                      ),
                      child: const Icon(
                        Icons.more_vert,
                        color: AppTheme.textSecondary,
                        size: AppTheme.iconSize16,
                      ),
                    ),
                  ),
              ],
            ),

            // Total amount below title (if enabled)
            if (displayMode != LaneDisplayMode.none) ...[
              const SizedBox(height: 4),
              Text(
                displayText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      );
    });
  }

  String _formatCurrency(double amount) {
    // Format with commas and 2 decimal places for single line display
    String formatted = amount.toStringAsFixed(2);
    
    // Split into integer and decimal parts
    List<String> parts = formatted.split('.');
    String integerPart = parts[0];
    String decimalPart = parts[1];
    
    // Add commas to integer part
    String withCommas = '';
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        withCommas += ',';
      }
      withCommas += integerPart[i];
    }
    
    // Return single line format since total is now below title
    return '฿$withCommas.$decimalPart';
  }

  String _getDisplayText(LaneDisplayMode mode) {
    if (mode == LaneDisplayMode.none) return '';

    final totals = LaneTotalCalculator.calculateTotals(lane.cards);

    switch (mode) {
      case LaneDisplayMode.totalBeforeDiscount:
        return _formatCurrency(totals.totalBeforeDiscount);
      case LaneDisplayMode.totalAfterDiscount:
        return _formatCurrency(totals.totalAfterDiscount);
      case LaneDisplayMode.grandTotal:
        return _formatCurrency(totals.grandTotal);
      case LaneDisplayMode.netTotal:
        return _formatCurrency(totals.netTotal);
      case LaneDisplayMode.none:
        return '';
    }
  }

  void _showLaneOptions(
    BuildContext context,
    LaneDisplayController displayController,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
          return StatefulBuilder(
            builder: (context, setState) {
              final currentDisplayMode = displayController.getDisplayMode(lane.id);
              
              return SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display Summary Section
                      Text(
                        'display_summary'.tr,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Total (before discount)
                      RadioListTile<LaneDisplayMode>(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: LaneDisplayMode.totalBeforeDiscount,
                        groupValue: currentDisplayMode,
                        title: Text('total_before_discount'.tr),
                        onChanged: (value) {
                          if (value != null) {
                            // Apply to all lanes automatically
                            if (allLaneIds != null) {
                              for (String laneId in allLaneIds!) {
                                displayController.setDisplayMode(laneId, value);
                              }
                            } else {
                              displayController.setDisplayMode(lane.id, value);
                            }
                            setState(() {});
                          }
                        },
                      ),

                      // Total (after discount)
                      RadioListTile<LaneDisplayMode>(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: LaneDisplayMode.totalAfterDiscount,
                        groupValue: currentDisplayMode,
                        title: Text('lane_total_after_discount'.tr),
                        onChanged: (value) {
                          if (value != null) {
                            // Apply to all lanes automatically
                            if (allLaneIds != null) {
                              for (String laneId in allLaneIds!) {
                                displayController.setDisplayMode(laneId, value);
                              }
                            } else {
                              displayController.setDisplayMode(lane.id, value);
                            }
                            setState(() {});
                          }
                        },
                      ),

                      // Grand Total (after VAT)
                      RadioListTile<LaneDisplayMode>(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: LaneDisplayMode.grandTotal,
                        groupValue: currentDisplayMode,
                        title: Text('grand_total_after_vat'.tr),
                        onChanged: (value) {
                          if (value != null) {
                            // Apply to all lanes automatically
                            if (allLaneIds != null) {
                              for (String laneId in allLaneIds!) {
                                displayController.setDisplayMode(laneId, value);
                              }
                            } else {
                              displayController.setDisplayMode(lane.id, value);
                            }
                            setState(() {});
                          }
                        },
                      ),

                      // Net Total (after VAT & WHT)
                      RadioListTile<LaneDisplayMode>(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: LaneDisplayMode.netTotal,
                        groupValue: currentDisplayMode,
                        title: Text('net_total_after_vat_wht'.tr),
                        onChanged: (value) {
                          if (value != null) {
                            // Apply to all lanes automatically
                            if (allLaneIds != null) {
                              for (String laneId in allLaneIds!) {
                                displayController.setDisplayMode(laneId, value);
                              }
                            } else {
                              displayController.setDisplayMode(lane.id, value);
                            }
                            setState(() {});
                          }
                        },
                      ),

                      // None
                      RadioListTile<LaneDisplayMode>(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: LaneDisplayMode.none,
                        groupValue: currentDisplayMode,
                        title: Text('lane_none'.tr),
                        onChanged: (value) {
                          if (value != null) {
                            // Apply to all lanes automatically
                            if (allLaneIds != null) {
                              for (String laneId in allLaneIds!) {
                                displayController.setDisplayMode(laneId, value);
                              }
                            } else {
                              displayController.setDisplayMode(lane.id, value);
                            }
                            setState(() {});
                          }
                        },
                      ),

                      const Divider(height: 24),

                      // Duplicate Lane
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.copy_rounded,
                          color: AppTheme.textSecondary,
                        ),
                        title: Text(
                          'duplicate_lane'.tr,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          onCloneLane?.call();
                        },
                      ),

                      // Delete Lane
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        title: Text(
                          'delete_lane'.tr,
                          style: TextStyle(color: Colors.red),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          onDeleteLane?.call();
                        },
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
  }
}
