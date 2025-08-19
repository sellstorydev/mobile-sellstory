import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/lane.dart';

class LaneHeader extends StatelessWidget {
  final Lane lane;
  final VoidCallback? onMenuTap;

  const LaneHeader({
    super.key,
    required this.lane,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Text(
            lane.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Card count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${lane.cardCount}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const Spacer(),
          
          // Total amount
          Text(
            '฿${lane.totalAmount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Menu button
          if (onMenuTap != null)
            GestureDetector(
              onTap: onMenuTap,
              child: Icon(
                Icons.more_vert,
                color: AppTheme.textSecondary,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}
