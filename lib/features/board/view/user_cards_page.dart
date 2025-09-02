import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/board_controller.dart';
import '../../../../core/services/logger_service.dart';
import '../../../domain/entities/job_card.dart';

class UserCardsPage extends StatefulWidget {
  const UserCardsPage({Key? key}) : super(key: key);

  @override
  State<UserCardsPage> createState() => _UserCardsPageState();
}

class _UserCardsPageState extends State<UserCardsPage> {
  final BoardController _controller = Get.find<BoardController>();
  final LoggerService _logger = Get.find<LoggerService>();

  @override
  void initState() {
    super.initState();
    _logger.methodEntry('UserCardsPage.initState');
    
    // Load user's assigned cards if not already loaded
    if (_controller.isInitialized.value) {
      _controller.loadUserAssignedCards();
    }
    
    _logger.methodExit('UserCardsPage.initState');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cards'),
        actions: [
          // Refresh button
          IconButton(
            onPressed: () {
              if (_controller.isInitialized.value) {
                _controller.loadUserAssignedCards();
              }
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Obx(() {
        if (!_controller.isInitialized.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Initializing...'),
              ],
            ),
          );
        }

        if (_controller.userAssignedCards.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No cards assigned to you',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cards assigned to you will appear here',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return _buildCardsList();
      }),
    );
  }

  Widget _buildCardsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _controller.userAssignedCards.length,
      itemBuilder: (context, index) {
        final card = _controller.userAssignedCards[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _showCardDetails(card),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          card.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(card),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusText(card),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        card.assignedTo,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      if (card.amount > 0) ...[
                        Icon(Icons.attach_money, size: 16, color: Colors.green[600]),
                        const SizedBox(width: 4),
                        Text(
                          '\$${card.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (card.dueDate != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Due: ${_formatDate(card.dueDate!)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (card.badges.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: card.badges.map((badge) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(JobCard card) {
    // You can implement your own status logic here
    if (card.dueDate != null && card.dueDate!.isBefore(DateTime.now())) {
      return Colors.red;
    }
    return Colors.blue;
  }

  String _getStatusText(JobCard card) {
    // You can implement your own status logic here
    if (card.dueDate != null && card.dueDate!.isBefore(DateTime.now())) {
      return 'Overdue';
    }
    return 'Active';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showCardDetails(JobCard card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(card.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Assignee', card.assignedTo),
              if (card.amount > 0) _buildDetailRow('Amount', '\$${card.amount.toStringAsFixed(2)}'),
              if (card.dueDate != null) _buildDetailRow('Due Date', _formatDate(card.dueDate!)),
              if (card.badges.isNotEmpty) _buildDetailRow('Badges', card.badges.join(', ')),
              _buildDetailRow('Created', _formatDate(card.createdAt)),
              _buildDetailRow('Updated', _formatDate(card.updatedAt)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to board page and highlight this card
              Get.toNamed('/board');
            },
            child: const Text('View in Board'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
