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
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16, vertical: AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.zero, // เอา border radius ออกให้ชนขอบจอ
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor,
            blurRadius: AppTheme.spacing4,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
        border: const Border(
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
            child: Text(
              lane.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          Container(width: AppTheme.spacing8),
          
          // Card count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing8, vertical: AppTheme.spacing4),
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange,
              borderRadius: BorderRadius.circular(AppTheme.radius12),
            ),
            child: Text(
              '${lane.cardCount}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: AppTheme.fontSize12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          Container(width: AppTheme.spacing12),
          
          // Total amount
          Text(
            '฿${lane.totalAmount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          
          Container(width: AppTheme.spacing8),
          
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
}
