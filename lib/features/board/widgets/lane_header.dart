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
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing12),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.zero, // เอา border radius ออกให้ชนขอบจอ
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor,
            blurRadius: AppTheme.spacing4,
            offset: Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderGrey,
            width: 1,
          ),
        ),
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
              onTap: onMenuTap,
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
}
