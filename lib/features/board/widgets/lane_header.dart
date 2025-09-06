import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/lane.dart';
import '../enums/lane_display_mode.dart';
import '../controllers/lane_display_controller.dart';
import '../utils/lane_total_calculator.dart';

class LaneHeader extends StatelessWidget {
  final Lane lane;
  final VoidCallback? onMenuTap;
  final VoidCallback? onCreateCard;
  final List<String>? allLaneIds; // For "Apply to All Lanes" functionality

  const LaneHeader({
    super.key,
    required this.lane,
    this.onMenuTap,
    this.onCreateCard,
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
      builder: (ctx) {
        final currentMode = displayController.getDisplayMode(lane.id);
        LaneDisplayMode selectedMode = currentMode;

          return StatefulBuilder(
            builder: (context, setState) {
              Widget buildRadio(LaneDisplayMode mode) {
                final bool isSelected = selectedMode == mode;
                return InkWell(
                  onTap: () {
                    // Update the display mode immediately and close modal
                    displayController.setDisplayMode(lane.id, mode);
                    Navigator.of(context).pop();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        // Bullet dot when selected
                        Container(
                          width: 18,
                          alignment: Alignment.centerLeft,
                          child: Icon(
                            Icons.circle,
                            size: 8,
                            color: isSelected
                                ? AppTheme.textPrimary
                                : Colors.transparent,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            mode.label,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppTheme.textPrimary,
                                  height: 1.1,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

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
                      Text(
                        'Display Summary',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 8),

                      // Summary options
                      buildRadio(LaneDisplayMode.totalBeforeDiscount),
                      buildRadio(LaneDisplayMode.totalAfterDiscount),
                      buildRadio(LaneDisplayMode.grandTotal),
                      buildRadio(LaneDisplayMode.netTotal),
                      buildRadio(LaneDisplayMode.none),

                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      // Apply to all lanes
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Apply to All Lanes',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                        ),
                        onTap: () {
                          // Apply current lane's mode to all lanes
                          final currentLaneMode = displayController.getDisplayMode(lane.id);
                          if (allLaneIds != null && allLaneIds!.isNotEmpty) {
                            displayController.applyToAllLanes(
                              allLaneIds!,
                              currentLaneMode,
                            );
                          }
                          Navigator.of(context).pop();
                        },
                      ),

                      const SizedBox(height: 4),

                      // Duplicate lane
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.copy_rounded,
                          color: AppTheme.textSecondary,
                        ),
                        title: Text(
                          'Duplicate Lane',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.textPrimary),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          // Call original onMenuTap for duplication if needed
                          onMenuTap?.call();
                        },
                      ),

                      // Delete lane
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        title: const Text(
                          'Delete Lane',
                          style: TextStyle(color: Colors.red),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          // Call original onMenuTap for deletion if needed
                          onMenuTap?.call();
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
