import 'package:flutter/material.dart';
import '../../../domain/entities/job_card.dart';

class StatusSummaryCards extends StatelessWidget {
  final List<JobCard> cards;

  const StatusSummaryCards({super.key, required this.cards});

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
              title: 'รอดำเนินการ',
              amount: _calculateAmountByStatus('Pending'),
              count: _getCountByStatus('Pending'),
              color: const Color(0xFFFAB73F),
              bgColor: const Color(0xFFFEF7EB),
              width: 120,
            ),
            const SizedBox(width: 12),
            _buildSummaryCard(
              title: 'กำลังดำเนินการ',
              amount: _calculateAmountByStatus('In Progress'),
              count: _getCountByStatus('In Progress'),
              color: const Color(0xFFFF6C0C),
              bgColor: const Color(0xFFFFF0E6),
              width: 110,
            ),
            const SizedBox(width: 12),
            _buildSummaryCard(
              title: 'เสร็จสิ้น',
              amount: _calculateAmountByStatus('Completed'),
              count: _getCountByStatus('Completed'),
              color: const Color(0xFF027F00),
              bgColor: const Color(0xFFE5F2E5),
              width: 110,
            ),
            const SizedBox(width: 12),
            _buildSummaryCard(
              title: 'ยกเลิก',
              amount: _calculateAmountByStatus('Cancelled'),
              count: _getCountByStatus('Cancelled'),
              color: const Color(0xFF666666),
              bgColor: const Color(0xFFEEEEEE),
              width: 110,
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
  }) {
    return Container(
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

  double _calculateAmountByStatus(String status) {
    return cards
        .where((card) => card.status == status)
        .fold(0.0, (sum, card) => sum + card.amount);
  }

  double _calculateTotalAmount() {
    return cards.fold(0.0, (sum, card) => sum + card.amount);
  }

  int _getCountByStatus(String status) {
    return cards.where((card) => card.status == status).length;
  }
}
