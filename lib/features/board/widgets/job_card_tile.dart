import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/job_card.dart';

class JobCardTile extends StatelessWidget {
  final JobCard card;
  final VoidCallback? onTap;

  const JobCardTile({
    super.key,
    required this.card,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = card.dueDate != null && 
        card.dueDate!.isBefore(DateTime.now());

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Overdue banner
            if (isOverdue)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: const BoxDecoration(
                    color: AppTheme.errorRed,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Overdue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges
                  if (card.badges.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: card.badges.take(3).map((badge) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getBadgeColor(badge),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              color: _getBadgeTextColor(badge),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // Job Card ID and Priority
                  Row(
                    children: [
                      Text(
                        card.id,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.infoBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getPriorityText(card.amount),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Due date
                  if (card.dueDate != null) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(card.dueDate!),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isOverdue ? AppTheme.errorRed : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // Assignee info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.primaryOrange.withValues(alpha: 0.1),
                        child: Text(
                          _getInitials(card.assignee),
                          style: const TextStyle(
                            color: AppTheme.primaryOrange,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          card.assignee,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Amount badge
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.infoBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '฿${card.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBadgeColor(String badge) {
    final colors = {
      'High Priority': Colors.red[100]!,
      'Design': Colors.purple[100]!,
      'Development': Colors.blue[100]!,
      'Marketing': Colors.green[100]!,
      'Testing': Colors.orange[100]!,
      'Security': Colors.red[100]!,
      'Content': Colors.pink[100]!,
      'Planning': Colors.indigo[100]!,
      'Setup': Colors.teal[100]!,
      'Complete': Colors.green[100]!,
    };
    return colors[badge] ?? Colors.grey[100]!;
  }

  Color _getBadgeTextColor(String badge) {
    final colors = {
      'High Priority': Colors.red[700]!,
      'Design': Colors.purple[700]!,
      'Development': Colors.blue[700]!,
      'Marketing': Colors.green[700]!,
      'Testing': Colors.orange[700]!,
      'Security': Colors.red[700]!,
      'Content': Colors.pink[700]!,
      'Planning': Colors.indigo[700]!,
      'Setup': Colors.teal[700]!,
      'Complete': Colors.green[700]!,
    };
    return colors[badge] ?? Colors.grey[700]!;
  }

  String _getPriorityText(double amount) {
    if (amount > 20000) return 'High';
    if (amount > 10000) return 'Medium';
    return 'Low';
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }
}
