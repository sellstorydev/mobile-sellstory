import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/job_card.dart';

class StatusSummaryCards extends StatelessWidget {
  final List<JobCard> cards;

  const StatusSummaryCards({
    super.key,
    required this.cards,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: 'ปิดงานสำเร็จ',
              amount: _calculateAmountByStatus('Closed Successfully'),
              color: Colors.green,
              icon: Icons.sentiment_satisfied,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildSummaryCard(
              title: 'กำลังดำเนินการ',
              amount: _calculateAmountByStatus('In Progress'),
              color: Colors.orange,
              icon: Icons.schedule,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildSummaryCard(
              title: 'ปิดงานไม่สำเร็จ',
              amount: _calculateAmountByStatus('Closed Unsuccessfully'),
              color: Colors.red,
              icon: Icons.sentiment_dissatisfied,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 14,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '฿${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  double _calculateAmountByStatus(String status) {
    return cards
        .where((card) => card.status == status)
        .fold(0.0, (sum, card) => sum + (card.amount ?? 0.0));
  }
}
