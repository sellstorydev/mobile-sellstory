import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sellstory/core/enums/lane_display_mode.dart';
import '../../../domain/entities/job_card.dart';
import '../../../core/utils/lane_total_calculator.dart';

class StatusSummaryCards extends StatelessWidget {
  // cards: รายการการ์ดที่ผ่านการกรอง/ค้นหาจาก board แล้ว
  final List<JobCard> cards;
  final Function(String status)? onStatusTap; // Callback เมื่อกดที่ status card
  final List<String> selectedStatuses; // รายการ status ที่ถูกเลือกอยู่
  final LaneDisplayMode displayMode; // Display mode from lane header

  const StatusSummaryCards({
    super.key, 
    required this.cards,
    this.onStatusTap,
    this.selectedStatuses = const [],
    this.displayMode = LaneDisplayMode.netTotal, // Default to netTotal
  });

  @override
  Widget build(BuildContext context) {
    print('🎯 StatusSummaryCards build() called with ${cards.length} cards');
    print('🎯 Selected statuses: $selectedStatuses');
    print('🎯 Display mode: $displayMode');
    
    // Test calculation for debugging
    final inProgressCards = cards.where((card) => card.status == 'In Progress').toList();
    if (inProgressCards.isNotEmpty) {
      final totals = LaneTotalCalculator.calculateTotals(inProgressCards);
      print('🎯 In Progress totals - before: ${totals.totalBeforeDiscount}, after: ${totals.totalAfterDiscount}, grand: ${totals.grandTotal}, net: ${totals.netTotal}');
    }
    
    // Show summary cards even if no cards are available
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(color: Colors.white),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildSummaryCard(
              title: 'Completed',
              amount: _calculateAmountByStatus('Done'),
              count: _getCountByStatus('Done'),
              color: const Color(0xFF027F00),
              bgColor: const Color(0xFFE5F2E5),
              width: 110,
              isSelected: selectedStatuses.contains('Done'),
              onTap: () => onStatusTap?.call('Done'),
            ),
            const SizedBox(width: 12),
            _buildSummaryCard(
              title: 'In Progress',
              amount: _calculateAmountByStatus('In Progress'),
              count: _getCountByStatus('In Progress'),
              color: const Color(0xFFFAB73F),
              bgColor: const Color(0xFFFEF7EB),
              width: 110,
              isSelected: selectedStatuses.contains('In Progress'),
              onTap: () => onStatusTap?.call('In Progress'),
            ),
            const SizedBox(width: 12),
            _buildSummaryCard(
              title: 'Pending',
              amount: _calculateAmountByStatus('Pending'),
              count: _getCountByStatus('Pending'),
              color: const Color(0xFF6B7280),
              bgColor: const Color(0xFFF3F4F6),
              width: 110,
              isSelected: selectedStatuses.contains('Pending'),
              onTap: () => onStatusTap?.call('Pending'),
            ),
            const SizedBox(width: 12),
            _buildSummaryCard(
              title: 'Cancelled',
              amount: _calculateAmountByStatus('Cancelled'),
              count: _getCountByStatus('Cancelled'),
              color: const Color(0xFFFF6C0C),
              bgColor: const Color(0xFFFFF0E6),
              width: 110,
              isSelected: selectedStatuses.contains('Cancelled'),
              onTap: () => onStatusTap?.call('Cancelled'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required int count,
    required Color color,
    required Color bgColor,
    required double width,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? color : Colors.transparent,
              width: isSelected ? 2 : 0,
            ),
          ),
          shadows: [
            BoxShadow(
              color: isSelected ? color.withOpacity(0.3) : const Color(0x19000000),
              blurRadius: isSelected ? 8 : 5,
              offset: const Offset(0, 0),
              spreadRadius: isSelected ? 1 : 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      color: bgColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFD9D9D9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$title ($count)',
                    style: const TextStyle(
                      color: Color(0xFF4D4D4D),
                      fontSize: 8,
                      fontFamily: 'Prompt',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              displayMode == LaneDisplayMode.none ? '-' : '฿${_formatAmount(amount)}',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontFamily: 'Prompt',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    // Format as full number with commas
    if (amount == 0) return '0';
    
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(amount.round());
  }

  double _calculateAmountByStatus(String status) {
    final statusCards = cards.where((card) => card.status == status).toList();
    
    if (statusCards.isEmpty || displayMode == LaneDisplayMode.none) {
      return 0.0;
    }
    
    // Use LaneTotalCalculator to get totals for all cards of this status
    final totals = LaneTotalCalculator.calculateTotals(statusCards);
    
    print('🎯 Calculating amount for status: $status, mode: $displayMode');
    print('🎯 Totals - before: ${totals.totalBeforeDiscount}, after: ${totals.totalAfterDiscount}, grand: ${totals.grandTotal}, net: ${totals.netTotal}');
    
    // Return the amount based on display mode
    switch (displayMode) {
      case LaneDisplayMode.totalBeforeDiscount:
        print('🎯 Returning totalBeforeDiscount: ${totals.totalBeforeDiscount}');
        return totals.totalBeforeDiscount;
      case LaneDisplayMode.totalAfterDiscount:
        print('🎯 Returning totalAfterDiscount: ${totals.totalAfterDiscount}');
        return totals.totalAfterDiscount;
      case LaneDisplayMode.grandTotal:
        print('🎯 Returning grandTotal: ${totals.grandTotal}');
        return totals.grandTotal;
      case LaneDisplayMode.netTotal:
        print('🎯 Returning netTotal: ${totals.netTotal}');
        return totals.netTotal;
      case LaneDisplayMode.none:
        return 0.0;
    }
  }

  int _getCountByStatus(String status) {
    return cards.where((card) => card.status == status).length;
  }
}
