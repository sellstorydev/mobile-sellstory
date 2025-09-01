import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/job_card.dart';
import '../../../../app/routes.dart';
import '../../../core/services/card_view_settings_service.dart';
import 'card_field_display.dart';

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
    // Debug logging to track card data
    print('🔄 JobCardTile.build - Card data:');
    print('  - ID: ${card.id}');
    print('  - Title: ${card.title}');
    print('  - Custom ID: ${card.customId} (length: ${card.customId.length})');
    print('  - Status: ${card.status}');
    print('  - Assignee: ${card.assignee}');
    print('  - Customer: ${card.customer}');
    
    return GestureDetector(
      onTap: onTap ?? () {
        // Navigate to card view page (read-only)
        Get.toNamed(AppRoutes.cardView, arguments: card);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and menu button
              Row(
                children: [
                  Expanded(
                    child: Text(
                      card.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          Get.toNamed(AppRoutes.cardDetail, arguments: card);
                          break;
                        case 'detail':
                          Get.toNamed(AppRoutes.cardView, arguments: card);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 8),
                            Text('Edit Card'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'detail',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, size: 16),
                            SizedBox(width: 8),
                            Text('View Details'),
                          ],
                        ),
                      ),
                    ],
                    child: const Icon(
                      Icons.more_vert,
                      size: 20,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Card Fields (using settings)
              _buildCardFields(),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'NA';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.length >= 2 
      ? name.substring(0, 2).toUpperCase()
      : name.toUpperCase();
  }

  Widget _buildCardFields() {
    try {
      // Check if service is registered and ready
      if (!Get.isRegistered<CardViewSettingsService>()) {
        return const SizedBox.shrink();
      }
      
      final settingsService = Get.find<CardViewSettingsService>();
      
      // Check if service is initialized
      if (!settingsService.isInitialized) {
        return const SizedBox.shrink();
      }
      
      return Obx(() {
        // Get visible fields ordered by their order value
        final visibleFields = settingsService.getVisibleFields();
        
        if (visibleFields.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: visibleFields.map((field) {
            return CardFieldDisplay(
              fieldId: field.id,
              fieldName: field.name,
              value: _getFieldValue(field.id),
              isVisible: field.isVisible,
              order: field.order,
            );
          }).toList(),
        );
      });
    } catch (e) {
      print('Error in _buildCardFields: $e');
      return const SizedBox.shrink();
    }
  }

  dynamic _getFieldValue(String fieldId) {
    switch (fieldId) {
      case 'jobId':
        return card.customId.isNotEmpty ? card.customId : null;
      case 'status':
        return card.status;
      case 'dateRange':
        return card.dueDate != null ? {'startDate': card.dueDate, 'endDate': card.dueDate} : null;
      case 'createdDate':
        return card.createdAt;
      case 'assignee':
        return card.assignee;
      case 'customerInterest':
        return card.description.isNotEmpty ? card.description : null;
      case 'collaborators':
        return card.watchers.isNotEmpty ? card.watchers : null;
      case 'customer':
        return card.customer.isNotEmpty ? card.customer : null;
      case 'company':
        return card.company != null && card.company!.isNotEmpty ? card.company : null;
      case 'hashtags':
        return card.hashtags.isNotEmpty ? card.hashtags : null;
      case 'priority':
        return _getPriorityFromStatus(card.status);
      case 'grandTotal':
        return card.amount > 0 ? card.amount : null;
      case 'netTotal':
        return card.amount > 0 ? card.amount : null;
      case 'totalBeforeDiscount':
        return card.amount > 0 ? card.amount : null;
      case 'totalAfterDiscount':
        return card.amount > 0 ? card.amount : null;
      case 'totalBeforeVAT':
        return card.amount > 0 ? card.amount : null;
      case 'description':
        return card.description.isNotEmpty ? card.description : null;
      case 'todoList':
        return card.todos.isNotEmpty ? card.todos : null;
      default:
        return null;
    }
  }

  String? _getPriorityFromStatus(String status) {
    switch (status.toLowerCase()) {
      case 'high':
      case 'urgent':
        return 'high';
      case 'medium':
      case 'normal':
        return 'medium';
      case 'low':
      case 'pending':
        return 'low';
      default:
        return null;
    }
  }
}
