import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/lane.dart';

class LaneHeader extends StatelessWidget {
  final Lane lane;
  final VoidCallback? onMenuTap;
  final VoidCallback? onCreateCard;

  const LaneHeader({
    super.key,
    required this.lane,
    this.onMenuTap,
    this.onCreateCard,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(
          8,
        ), // เอา border radius ออกให้ชนขอบจอ
      ),
      child: Row(
        children: [
          // Lane title
          Expanded(
            flex: 2,
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

          Container(width: 6),

          // Total amount (pricePerUnit)
          Expanded(
            flex: 1,
            child: Text(
              '฿${_calculateTotalPricePerUnit().toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),

          Container(width: AppTheme.spacing8),

          // Create card button - REMOVED as per user request
          // if (onCreateCard != null)
          //   GestureDetector(
          //     onTap: onCreateCard,
          //     child: Container(
          //       padding: const EdgeInsets.all(AppTheme.spacing4),
          //       decoration: BoxDecoration(
          //         color: AppTheme.primaryOrange,
          //         borderRadius: BorderRadius.circular(AppTheme.radius4),
          //       ),
          //       child: const Icon(
          //         Icons.add,
          //         color: Colors.white,
          //         size: AppTheme.iconSize16,
          //       ),
          //     ),
          //   ),
          Container(width: 4),

          // Menu button
          if (onMenuTap != null)
            GestureDetector(
              onTap: () {
                _showLaneOptions(context);
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
    );
  }

  double _calculateTotalPricePerUnit() {
    return lane.cards.fold(0.0, (sum, card) {
      // Use the amount field which represents the total value
      return sum + (card.amount);
    });
  }

  void _showLaneOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        String selectedKey = 'before_discount';
        return StatefulBuilder(
          builder: (context, setState) {
            Widget buildRadio(String label, String key) {
              final bool isSelected = selectedKey == key;
              return InkWell(
                onTap: () => setState(() => selectedKey = key),
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
                          color: isSelected ? AppTheme.textPrimary : Colors.transparent,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Display Summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 8),

                    // Summary options
                    buildRadio('Total (before discount)', 'before_discount'),
                    buildRadio('Total (after discount)', 'after_discount'),
                    buildRadio('Grand Total (after VAT)', 'grand_total'),
                    buildRadio('Net Total (after VAT & WHT)', 'net_total'),
                    buildRadio('None', 'none'),

                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // Apply to all lanes
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Apply to All Lanes',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                      onTap: () {}, // UI only for now
                    ),

                    const SizedBox(height: 4),

                    // Duplicate lane
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.copy_rounded, color: AppTheme.textSecondary),
                      title: Text(
                        'Duplicate Lane',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textPrimary,
                            ),
                      ),
                      onTap: () {}, // UI only for now
                    ),

                    // Delete lane
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.delete_outline, color: Colors.red),
                      title: const Text(
                        'Delete Lane',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () {}, // UI only for now
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
