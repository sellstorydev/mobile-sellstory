import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';

class CardFieldDisplay extends StatelessWidget {
  final String? fieldId;
  final String? fieldName;
  final dynamic value;
  final bool isVisible;
  final int order;
  final TextStyle? style;

  const CardFieldDisplay({
    super.key,
    required this.fieldId,
    required this.fieldName,
    required this.value,
    required this.isVisible,
    required this.order,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Field label with colon
          Text(
            '${fieldName ?? 'Unknown'}: ',
            style: (style ?? const TextStyle()).copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          // Field value
          Expanded(
            child: _buildFieldValue(),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldValue() {
    if (value == null || value.toString().isEmpty) {
      return Text(
        '-',
        style: (style ?? const TextStyle()).copyWith(
          fontSize: 12,
          color: Colors.grey[400],
          fontStyle: FontStyle.italic,
        ),
      );
    }

    switch (fieldId) {
      case 'priority':
        return _buildPriorityBadge(value?.toString() ?? 'low');
      case 'status':
        return _buildStatusBadge(value?.toString() ?? 'pending');
      case 'hashtags':
        return _buildHashtagsList(value);
      case 'collaborators':
        return _buildCollaboratorsList(value);
      case 'dueDate':
        return _buildDateDisplay(value);
      case 'createdDate':
        return _buildDateDisplay(value);
      case 'dateRange':
        return _buildDateRangeDisplay(value);
      case 'assignee':
        return _buildAssigneeDisplay(value);
      case 'customer':
        return _buildCustomerDisplay(value);
      case 'company':
        return _buildCompanyDisplay(value);
      case 'description':
        return _buildDescriptionDisplay(value);
      case 'todoList':
        return _buildTodoListDisplay(value);
      case 'grandTotal':
      case 'netTotal':
      case 'totalBeforeDiscount':
      case 'totalAfterDiscount':
      case 'totalBeforeVAT':
        return _buildCurrencyDisplay(value);
      case null:
      default:
        return Text(
          value?.toString() ?? '-',
          style: (style ?? const TextStyle()).copyWith(
            fontSize: 12,
            color: Colors.black87,
            fontWeight: FontWeight.w400,
          ),
        );
    }
  }

  Widget _buildPriorityBadge(String priority) {
    // Handle null or empty priority
    if (priority.isEmpty || priority == 'null') {
      priority = 'low'; // Default to low priority
    }
    
    Color badgeColor;
    String displayText;
    
    switch (priority.toLowerCase()) {
      case 'high':
        badgeColor = Colors.red[100]!;
        displayText = 'priority_high_label'.tr;
        break;
      case 'medium':
        badgeColor = Colors.orange[100]!;
        displayText = 'priority_medium_label'.tr;
        break;
      case 'low':
        badgeColor = Colors.green[100]!;
        displayText = 'priority_low_label'.tr;
        break;
      default:
        badgeColor = Colors.grey[100]!;
        displayText = priority;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: badgeColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: badgeColor == Colors.grey[100] ? Colors.grey[700] : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primaryOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryOrange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryOrange,
        ),
      ),
    );
  }

  Widget _buildHashtagsList(dynamic hashtags) {
    if (hashtags is! List || hashtags.isEmpty) {
      return const Text('-', style: TextStyle(fontSize: 12, color: Colors.grey));
    }

    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: hashtags.map<Widget>((hashtag) {
        final text = hashtag is Map 
            ? (hashtag['text']?.toString() ?? hashtag['id']?.toString() ?? 'tag') 
            : (hashtag?.toString() ?? 'tag');
        final color = hashtag is Map ? hashtag['color'] ?? '#f97316' : '#f97316';
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: _parseColor(color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _parseColor(color).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            '#$text',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: _parseColor(color),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCollaboratorsList(dynamic collaborators) {
    if (collaborators == null || collaborators.toString() == '0' || collaborators.toString() == '-') {
      return const Text('-', style: TextStyle(fontSize: 12, color: Colors.grey));
    }

    // If it's a number (count), show it as a badge
    if (collaborators is num || (collaborators is String && int.tryParse(collaborators) != null)) {
      final count = collaborators is num ? collaborators : int.parse(collaborators);
      if (count == 0) return const Text('-', style: TextStyle(fontSize: 12, color: Colors.grey));
      
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.blue[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.blue[300]!,
            width: 1,
          ),
        ),
        child: Text(
          count.toString(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.blue[700]!,
          ),
        ),
      );
    }

    // If it's a list, show count
    if (collaborators is List) {
      if (collaborators.isEmpty) return const Text('-', style: TextStyle(fontSize: 12, color: Colors.grey));
      
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.blue[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.blue[300]!,
            width: 1,
          ),
        ),
        child: Text(
          collaborators.length.toString(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.blue[700]!,
          ),
        ),
      );
    }

    return Text(collaborators.toString(), style: const TextStyle(fontSize: 12));
  }

  Widget _buildDateDisplay(dynamic date) {
    if (date == null) return const Text('-', style: TextStyle(fontSize: 12, color: Colors.grey));
    
    DateTime dateTime;
    if (date is DateTime) {
      dateTime = date;
    } else if (date is int) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(date);
    } else {
      return Text(date.toString(), style: const TextStyle(fontSize: 12));
    }

    return Text(
      '${dateTime.day}/${dateTime.month}/${dateTime.year}',
      style: const TextStyle(fontSize: 12, color: Colors.black87),
    );
  }

  Widget _buildDateRangeDisplay(dynamic dateRange) {
    if (dateRange == null || dateRange.toString() == '-') {
      return const Text('-', style: TextStyle(fontSize: 12, color: Colors.grey));
    }
    
    // Handle different date range formats
    if (dateRange is Map) {
      final start = dateRange['startDate'];
      final end = dateRange['endDate'];
      if (start != null && end != null) {
        return Text(
          '${_formatDate(start)} - ${_formatDate(end)}',
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        );
      }
    }
    
    // If it's already a formatted string, use it directly
    if (dateRange is String && dateRange.contains(' - ')) {
      return Text(
        dateRange,
        style: const TextStyle(fontSize: 12, color: Colors.black87),
      );
    }
    
    return Text(dateRange.toString(), style: const TextStyle(fontSize: 12));
  }

  Widget _buildAssigneeDisplay(dynamic assignee) {
    if (assignee == null || assignee.toString().isEmpty) {
      return const Text('-', style: TextStyle(fontSize: 12, color: Colors.grey));
    }

    final name = assignee is Map 
        ? (assignee['displayName']?.toString() ?? assignee['name']?.toString() ?? 'Unknown') 
        : (assignee?.toString() ?? 'Unknown');
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 8,
          backgroundColor: AppTheme.primaryOrange,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerDisplay(dynamic customer) {
    if (customer == null || customer.toString().isEmpty) {
      return const Text('-', style: TextStyle(fontSize: 12, color: Colors.grey));
    }

    final name = customer is Map 
        ? (customer['name']?.toString() ?? 'Unknown Customer') 
        : (customer?.toString() ?? 'Unknown Customer');
    
    return Text(
      name,
      style: const TextStyle(fontSize: 12, color: Colors.black87),
    );
  }

  Widget _buildCompanyDisplay(dynamic company) {
    if (company == null || company.toString().isEmpty) {
      return const Text('-', style: TextStyle(fontSize: 12, color: Colors.grey));
    }

    final name = company is Map 
        ? (company['name']?.toString() ?? 'Unknown Company') 
        : (company?.toString() ?? 'Unknown Company');
    
    return Text(
      name,
      style: const TextStyle(fontSize: 12, color: Colors.black87),
    );
  }

  Widget _buildDescriptionDisplay(dynamic description) {
    if (description == null || description.toString().isEmpty) {
      return const Text('-', style: TextStyle(fontSize: 12, color: Colors.grey));
    }

    final text = description.toString();
    if (text.length <= 50) {
      return Text(
        text,
        style: const TextStyle(fontSize: 12, color: Colors.black87),
      );
    }

    return Text(
      '${text.substring(0, 50)}...',
      style: const TextStyle(fontSize: 12, color: Colors.black87),
    );
  }

  Widget _buildTodoListDisplay(dynamic todoList) {
    if (todoList is! List || todoList.isEmpty) {
      return const Text('-', style: TextStyle(fontSize: 12, color: Colors.grey));
    }

    final completedCount = todoList.where((todo) => 
      todo is Map ? todo['completed'] == true : false
    ).length;

    return Text(
      '$completedCount/${todoList.length} completed',
      style: const TextStyle(fontSize: 12, color: Colors.black87),
    );
  }

  Widget _buildCurrencyDisplay(dynamic amount) {
    if (amount == null) return const Text('-', style: TextStyle(fontSize: 12, color: Colors.grey));
    
    final numValue = amount is num ? amount : double.tryParse(amount.toString());
    if (numValue == null) return Text(amount.toString(), style: const TextStyle(fontSize: 12));
    
    return Text(
      '\$${numValue.toStringAsFixed(2)}',
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date is DateTime) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (date is int) {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(date);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
    return date.toString();
  }

  Color _parseColor(String hexColor) {
    try {
      hexColor = hexColor.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }
}
