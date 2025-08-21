import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/job_card.dart';
import '../controller/board_controller.dart';

class CardDetailPage extends StatefulWidget {
  final JobCard card;

  const CardDetailPage({
    super.key,
    required this.card,
  });

  @override
  State<CardDetailPage> createState() => _CardDetailPageState();
}

class _CardDetailPageState extends State<CardDetailPage> {
  final BoardController _controller = Get.find<BoardController>();
  
  // Form controllers
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _assigneeController;
  late TextEditingController _customerController;
  late TextEditingController _customIdController;
  
  // Form state
  String _selectedStatus = 'To Do';
  bool _isEditing = false;
  bool _isLoading = false;
  
  // Current card data (will be updated from controller)
  late JobCard _currentCard;

  @override
  void initState() {
    super.initState();
    _currentCard = widget.card;
    _initializeControllers();
    
    // Add a small delay to ensure controller is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshCardData();
    });
  }

  // Refresh card data from controller
  void _refreshCardData() {
    try {
      final latestCard = _getLatestCardData();
      if (latestCard != null) {
        print('🔄 CardDetailPage._refreshCardData - Refreshing card data');
        setState(() {
          _currentCard = latestCard;
          _initializeControllers();
        });
      }
    } catch (e) {
      print('❌ Error refreshing card data: $e');
    }
  }

  void _initializeControllers() {
    _titleController = TextEditingController(text: _currentCard.title);
    _descriptionController = TextEditingController(text: _currentCard.description);
    _assigneeController = TextEditingController(text: _currentCard.assignee);
    _customerController = TextEditingController(text: _currentCard.customer);
    _customIdController = TextEditingController(text: _currentCard.customId);
    _selectedStatus = _currentCard.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _assigneeController.dispose();
    _customerController.dispose();
    _customIdController.dispose();
    super.dispose();
  }

  // Helper method to get the latest card data from controller
  JobCard? _getLatestCardData() {
    try {
      // Check if controller is ready
      if (!_controller.isInitialized.value) {
        print('⚠️ CardDetailPage._getLatestCardData - Controller not initialized yet');
        return null;
      }
      
      final lanes = _controller.lanes;
      if (lanes.isEmpty) {
        print('⚠️ CardDetailPage._getLatestCardData - No lanes available yet');
        return null;
      }
      
      for (final lane in lanes) {
        final card = lane.cards.firstWhereOrNull((c) => c.id == widget.card.id);
        if (card != null) {
          print('✅ CardDetailPage._getLatestCardData - Found card: ${card.title}');
          return card;
        }
      }
      
      print('⚠️ CardDetailPage._getLatestCardData - Card not found in any lane');
      return null;
    } catch (e) {
      print('❌ Error getting latest card data: $e');
      return null;
    }
  }

  // Update current card data from controller
  void _updateCurrentCard() {
    final latestCard = _getLatestCardData();
    if (latestCard != null && latestCard != _currentCard) {
      print('🔄 CardDetailPage._updateCurrentCard - Updating card data:');
      print('  - Old Custom ID: ${_currentCard.customId}');
      print('  - New Custom ID: ${latestCard.customId}');
      print('  - Old Title: ${_currentCard.title}');
      print('  - New Title: ${latestCard.title}');
      
      setState(() {
        _currentCard = latestCard;
        if (!_isEditing) {
          _initializeControllers();
        }
      });
    } else if (latestCard == null) {
      print('ℹ️ CardDetailPage._updateCurrentCard - No update needed, using original card data');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to controller state changes
    return Obx(() {
      try {
        _updateCurrentCard();
      } catch (e) {
        print('❌ Error in CardDetailPage build: $e');
        // Continue with current card data if there's an error
      }
      
      return Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Card' : 'Card Details'),
          actions: [
            if (!_isEditing)
              IconButton(
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
                icon: const Icon(Icons.edit),
                tooltip: 'Edit Card',
              ),
            if (_isEditing) ...[
              IconButton(
                onPressed: _cancelEdit,
                icon: const Icon(Icons.close),
                tooltip: 'Cancel',
              ),
              IconButton(
                onPressed: _saveChanges,
                icon: const Icon(Icons.save),
                tooltip: 'Save Changes',
              ),
            ],
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCardHeader(),
                    const SizedBox(height: 24),
                    _buildCardDetails(),
                    const SizedBox(height: 24),
                    _buildCardMetadata(),
                  ],
                ),
              ),
      );
    });
  }

  Widget _buildCardHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _isEditing
                      ? TextField(
                          controller: _titleController,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Card Title',
                          ),
                        )
                      : Text(
                          _currentCard.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                if (!_isEditing)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(_currentCard.status),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _currentCard.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (_currentCard.customId.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '#${_currentCard.customId}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCardDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Status
            _buildDetailRow(
              'Status',
              _isEditing
                  ? DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'To Do', child: Text('To Do')),
                        DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                        DropdownMenuItem(value: 'Review', child: Text('Review')),
                        DropdownMenuItem(value: 'Done', child: Text('Done')),
                        DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value!;
                        });
                      },
                    )
                  : Text(_currentCard.status),
            ),
            
            const SizedBox(height: 16),
            
            // Assignee
            _buildDetailRow(
              'Assignee',
              _isEditing
                  ? TextField(
                      controller: _assigneeController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter assignee',
                      ),
                    )
                  : Text(_currentCard.assignee),
            ),
            
            const SizedBox(height: 16),
            
            // Customer
            _buildDetailRow(
              'Customer',
              _isEditing
                  ? TextField(
                      controller: _customerController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter customer',
                      ),
                    )
                  : Text(_currentCard.customer),
            ),
            
            const SizedBox(height: 16),
            
            // Custom ID
            _buildDetailRow(
              'Custom ID',
              _isEditing
                  ? TextField(
                      controller: _customIdController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter custom ID',
                      ),
                    )
                  : Text(_currentCard.customId),
            ),
            
            const SizedBox(height: 16),
            
            // Description
            _buildDetailRow(
              'Description',
              _isEditing
                  ? TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter description',
                      ),
                    )
                  : Text(
                      _currentCard.description.isEmpty ? 'No description' : _currentCard.description,
                      style: TextStyle(
                        color: _currentCard.description.isEmpty ? Colors.grey : null,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardMetadata() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Metadata',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildMetadataRow('Card ID', _currentCard.id),
            _buildMetadataRow('Lane ID', _currentCard.laneId),
            _buildMetadataRow('Board ID', _currentCard.boardId),
            _buildMetadataRow('Workspace ID', _currentCard.workspaceId),
            _buildMetadataRow('Order', _currentCard.order.toString()),
            _buildMetadataRow('Created', _formatDate(_currentCard.createdAt)),
            _buildMetadataRow('Updated', _formatDate(_currentCard.updatedAt)),
            if (_currentCard.updatedByDisplayName.isNotEmpty)
              _buildMetadataRow('Updated By', _currentCard.updatedByDisplayName),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, Widget child) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 16),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'to do':
        return Colors.grey;
      case 'in progress':
        return Colors.blue;
      case 'review':
        return Colors.purple;
      case 'done':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _initializeControllers(); // Reset to original values
    });
  }

  Future<void> _saveChanges() async {
    // Validate required fields
    if (_titleController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Title is required',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (_customIdController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Custom ID is required',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 CardDetailPage._saveChanges - Original card data:');
      print('  - Custom ID: ${_currentCard.customId}');
      print('  - Title: ${_currentCard.title}');
      print('  - Status: ${_currentCard.status}');
      
      print('🔄 CardDetailPage._saveChanges - Form data:');
      print('  - Custom ID: ${_customIdController.text.trim()}');
      print('  - Title: ${_titleController.text.trim()}');
      print('  - Status: $_selectedStatus');
      
      // Create updated card
      final updatedCard = _currentCard.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        assignee: _assigneeController.text.trim(),
        customer: _customerController.text.trim(),
        customId: _customIdController.text.trim(),
        status: _selectedStatus,
        updatedAt: DateTime.now(),
      );

      print('🔄 CardDetailPage._saveChanges - Updated card data:');
      print('  - Custom ID: ${updatedCard.customId}');
      print('  - Title: ${updatedCard.title}');
      print('  - Status: ${updatedCard.status}');

      // Update card using controller
      await _controller.updateCard(updatedCard);

      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      // Refresh card data after successful update
      _refreshCardData();

      Get.snackbar(
        'Success',
        'Card updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      print('❌ Error updating card: $e');

      Get.snackbar(
        'Error',
        'Failed to update card: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
