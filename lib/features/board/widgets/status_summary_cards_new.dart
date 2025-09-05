import 'package:flutter/material.dart';
import '../../../domain/entities/job_card.dart';

class StatusSummaryCards extends StatelessWidget {
  // cards: รายการการ์ดที่ผ่านการกรอง/ค้นหาจาก board แล้ว
  final List<JobCard> cards;
  final Function(String status)? onStatusTap; // Callback เมื่อกดที่ status card

  const StatusSummaryCards({
    super.key, 
    required this.cards,
    this.onStatusTap,
  });

  @override
  Widget build(BuildContext context) {
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
              title: 'Done',
              amount: _calculateAmountByStatus('Done'),
              count: _getCountByStatus('Done'),
              color: const Color(0xFF027F00),
              bgColor: const Color(0xFFE5F2E5),
              width: 110,
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
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          shadows: const [
            BoxShadow(
              color: Color(0x19000000),
              blurRadius: 5,
              offset: Offset(0, 0),
              spreadRadius: 0,
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
              '฿${_formatAmount(amount)}',
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
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  // Helper function to round to 2 decimal places
  double _round2(double value) {
    return (value * 100).round() / 100;
  }

  // Calculate amount from expenses instead of using card.amount field
  double _calculateExpenseTotal(List<Map<String, dynamic>> expenses, bool isVatEnabled, Map<String, dynamic>? additionalDiscount, num withholdingTaxPercentage) {
    if (expenses.isEmpty) return 0.0;
    
    double totalBeforeDiscount = 0;
    
    // Calculate base amount from expenses
    for (final expense in expenses) {
      final quantity = (expense['quantity'] ?? 0).toDouble();
      final pricePerUnit = (expense['pricePerUnit'] ?? 0).toDouble();
      final base = quantity * pricePerUnit;
      totalBeforeDiscount += base;
    }
    
    // Use totalBeforeDiscount as base for additional discount (matching job_card_tile logic)
    double baseForAdditional = totalBeforeDiscount;
    double totalAfterDiscount = baseForAdditional;
    
    // Apply additional discount if exists
    if (additionalDiscount != null && (additionalDiscount['value'] ?? 0) != 0) {
      final discountValue = (additionalDiscount['value'] ?? 0).toDouble();
      final discountType = (additionalDiscount['type'] ?? 'amount') as String?;
      
      if (discountType == 'percentage') {
        totalAfterDiscount = baseForAdditional * (1 - (discountValue / 100.0));
      } else {
        totalAfterDiscount = baseForAdditional - discountValue;
      }
    }
    
    totalAfterDiscount = _round2(totalAfterDiscount.clamp(0, double.infinity));
    final totalBeforeVat = totalAfterDiscount;
    
    // Calculate VAT if enabled
    final vatAmount = isVatEnabled ? _round2(totalBeforeVat * 0.07) : 0.0;
    final grandTotal = _round2(totalBeforeVat + vatAmount);
    
    // Calculate withholding tax
    final wht = _round2(totalBeforeVat * (withholdingTaxPercentage / 100.0));
    final netTotal = _round2(grandTotal - wht);
    
    return netTotal;
  }

  double _calculateAmountByStatus(String status) {
    return cards
        .where((card) => card.status == status)
        .fold(0.0, (sum, card) {
          // Get financial settings from card (these might be null)
          final isVatEnabled = card.isVatEnabled;
          final additionalDiscount = card.additionalDiscount;
          final withholdingTaxPercentage = card.withholdingTaxPercentage;
          
          // Calculate total from expenses
          final expenseTotal = _calculateExpenseTotal(
            card.expenses, 
            isVatEnabled, 
            additionalDiscount, 
            withholdingTaxPercentage
          );
          
          return sum + expenseTotal;
        });
  }

  int _getCountByStatus(String status) {
    return cards.where((card) => card.status == status).length;
  }
}
