import 'package:cloud_firestore/cloud_firestore.dart';

class JobCard {
  final String id;
  final String title;
  final String description;
  final String assignee;
  final String status;
  final String customId;
  final DateTime? dueDate;
  final List<String> badges;
  final double amount;
  final String laneId;
  final String boardId;
  final String workspaceId;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String customer; // Add customer field
  final String updatedByDisplayName; // Add display name field
  final String? customerId; // Add customer ID field
  final String? company; // Add company field
  final String? hashtag; // Add hashtag field (legacy)
  final List<Map<String, dynamic>> hashtags; // Add hashtags field (new DTB structure)
  final String? customerInterest; // Add customer interest field
  final List<Map<String, dynamic>> expenses; // Add expenses field
  final List<Map<String, dynamic>> todos; // Add todos field
  final List<Map<String, dynamic>> notes; // Add notes field
  final List<String> watchers; // Add watchers field
  final List<Map<String, dynamic>> customFields; // Add custom fields
  final String createdBy; // Add created by field
  final String updatedBy; // Add updated by field

  JobCard({
    required this.id,
    required this.title,
    this.description = '',
    required this.assignee,
    this.status = 'To Do',
    this.customId = '',
    this.dueDate,
    required this.badges,
    required this.amount,
    required this.laneId,
    this.boardId = '',
    this.workspaceId = '',
    required this.order,
    required this.createdAt,
    required this.updatedAt,
    this.customer = '',
    this.updatedByDisplayName = '',
    this.customerId,
    this.company,
    this.hashtag,
    this.hashtags = const [],
    this.customerInterest,
    this.expenses = const [],
    this.todos = const [],
    this.notes = const [],
    this.watchers = const [],
    this.customFields = const [],
    this.createdBy = '',
    this.updatedBy = '',
  });

  JobCard copyWith({
    String? id,
    String? title,
    String? description,
    String? assignee,
    String? status,
    String? customId,
    DateTime? dueDate,
    List<String>? badges,
    double? amount,
    String? laneId,
    String? boardId,
    String? workspaceId,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? customer,
    String? updatedByDisplayName,
    String? customerId,
    String? company,
    String? hashtag,
    List<Map<String, dynamic>>? hashtags,
    String? customerInterest,
    List<Map<String, dynamic>>? expenses,
    List<Map<String, dynamic>>? todos,
    List<Map<String, dynamic>>? notes,
    List<String>? watchers,
    List<Map<String, dynamic>>? customFields,
    String? createdBy,
    String? updatedBy,
  }) {
    return JobCard(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      assignee: assignee ?? this.assignee,
      status: status ?? this.status,
      customId: customId ?? this.customId,
      dueDate: dueDate ?? this.dueDate,
      badges: badges ?? this.badges,
      amount: amount ?? this.amount,
      laneId: laneId ?? this.laneId,
      boardId: boardId ?? this.boardId,
      workspaceId: workspaceId ?? this.workspaceId,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
              customer: customer ?? this.customer,
        updatedByDisplayName: updatedByDisplayName ?? this.updatedByDisplayName,
        customerId: customerId ?? this.customerId,
        company: company ?? this.company,
        hashtag: hashtag ?? this.hashtag,
        hashtags: hashtags ?? this.hashtags,
        customerInterest: customerInterest ?? this.customerInterest,
        expenses: expenses ?? this.expenses,
        todos: todos ?? this.todos,
        notes: notes ?? this.notes,
        watchers: watchers ?? this.watchers,
        customFields: customFields ?? this.customFields,
        createdBy: createdBy ?? this.createdBy,
        updatedBy: updatedBy ?? this.updatedBy,
      );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    // Build the map based on DTB.md Card structure
    final Map<String, dynamic> data = {
      'workspaceId': workspaceId,
      'name': title, // Card name per DTB.md
      'title': title, // Also include title field for compatibility
    };

    // Required fields per DTB.md Card structure
    if (createdBy.isNotEmpty) data['createdBy'] = createdBy;
    
    // DTB.md Card structure requires these arrays
    data['memberUids'] = watchers.isNotEmpty ? watchers : [createdBy]; // Use watchers or creator
    data['members'] = []; // Will be populated by backend/system
    
    // lanes array per DTB.md (may store lane IDs related to this card)
    if (laneId.isNotEmpty) {
      data['lanes'] = [laneId];
    } else {
      data['lanes'] = [];
    }
    
    // Optional workspaces array per DTB.md
    if (workspaceId.isNotEmpty) {
      data['workspaces'] = [{
        'id': workspaceId,
        'name': '', // Will be populated by backend
        'role': 'member'
      }];
    }

    // Job card specific fields (not in DTB.md Card but needed for job cards)
    if (description.isNotEmpty) data['description'] = description;
    if (assignee.isNotEmpty) data['assignedTo'] = assignee;
    if (status.isNotEmpty) data['status'] = status;
    if (customId.isNotEmpty) data['customId'] = customId;
    if (dueDate != null) data['dueDate'] = Timestamp.fromDate(dueDate!);
    if (badges.isNotEmpty) data['badges'] = badges;
    if (amount > 0) data['amount'] = amount;
    if (laneId.isNotEmpty) data['laneId'] = laneId;
    if (boardId.isNotEmpty) data['boardId'] = boardId;
    if (order >= 0) data['order'] = order; // Allow 0 order
    if (customer.isNotEmpty) data['customer'] = customer;
    if (updatedByDisplayName.isNotEmpty) data['updatedByDisplayName'] = updatedByDisplayName;
    if (customerId?.isNotEmpty == true) data['customerId'] = customerId;
    if (company?.isNotEmpty == true) data['company'] = company;
    if (hashtag?.isNotEmpty == true) data['hashtag'] = hashtag;
    if (hashtags.isNotEmpty) data['hashtags'] = hashtags;
    if (customerInterest?.isNotEmpty == true) data['customerInterest'] = customerInterest;
    if (expenses.isNotEmpty) data['expenses'] = expenses;
    if (todos.isNotEmpty) data['todos'] = todos;
    if (notes.isNotEmpty) data['notes'] = notes;
    if (customFields.isNotEmpty) data['customFields'] = customFields;
    if (updatedBy.isNotEmpty) data['updatedBy'] = updatedBy;

    // Always include timestamps (convert to epoch ms per DTB.md conventions)
    data['createdAt'] = createdAt.millisecondsSinceEpoch;
    data['updatedAt'] = updatedAt.millisecondsSinceEpoch;

    return data;
  }

  // Create from Map from Firestore
  factory JobCard.fromMap(Map<String, dynamic> map, String id) {
    // Helpers to safely extract values that might come in different shapes
    String _stringFrom(dynamic v) {
      if (v == null) return '';
      if (v is String) return v;
      if (v is Map) {
        // Prefer common name fields
        if (v['name'] is String) return v['name'] as String;
        if (v['displayName'] is String) return v['displayName'] as String;
        if (v['text'] is String) return v['text'] as String;
        if (v['id'] is String) return v['id'] as String;
        return v.toString();
      }
      return v.toString();
    }

    String? _nullableStringFrom(dynamic v) {
      if (v == null) return null;
      if (v is String) return v;
      if (v is Map) {
        if (v['name'] is String) return v['name'] as String;
        if (v['displayName'] is String) return v['displayName'] as String;
        if (v['text'] is String) return v['text'] as String;
        if (v['id'] is String) return v['id'] as String;
        return v.toString();
      }
      return v.toString();
    }

    double _doubleFrom(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) {
        final parsed = double.tryParse(v);
        return parsed ?? 0.0;
      }
      return 0.0;
    }

    DateTime? _dateTimeFrom(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is double) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
      return null;
    }

    // Handle DTB.md structure mapping
    final String title = _stringFrom(map['title'] ?? map['name'] ?? '');

    // laneId can be string or lanes array with strings/maps
    String laneId = _stringFrom(map['laneId']);
    if (laneId.isEmpty && map['lanes'] is List && (map['lanes'] as List).isNotEmpty) {
      final firstLane = (map['lanes'] as List).first;
      laneId = _stringFrom(firstLane);
    }

    // Handle memberUids from DTB.md structure for watchers
    List<String> watchers = [];
    if (map['memberUids'] is List) {
      try {
        watchers = List<String>.from(map['memberUids']);
      } catch (_) {
        watchers = (map['memberUids'] as List).map((e) => _stringFrom(e)).where((s) => s.isNotEmpty).toList();
      }
    } else if (map['watchers'] is List) {
      try {
        watchers = List<String>.from(map['watchers']);
      } catch (_) {
        watchers = (map['watchers'] as List).map((e) => _stringFrom(e)).where((s) => s.isNotEmpty).toList();
      }
    }

    // Handle timestamps - DTB.md uses epoch ms (number) but Firestore may use Timestamp
    DateTime createdAt = DateTime.now();
    DateTime updatedAt = DateTime.now();
    final createdAtRaw = map['createdAt'];
    final updatedAtRaw = map['updatedAt'];
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtRaw);
    } else if (createdAtRaw is double) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtRaw.toInt());
    }
    if (updatedAtRaw is Timestamp) {
      updatedAt = updatedAtRaw.toDate();
    } else if (updatedAtRaw is int) {
      updatedAt = DateTime.fromMillisecondsSinceEpoch(updatedAtRaw);
    } else if (updatedAtRaw is double) {
      updatedAt = DateTime.fromMillisecondsSinceEpoch(updatedAtRaw.toInt());
    }

    // Parse hashtags: support List<Map> and List<String>
    List<Map<String, dynamic>> hashtags = [];
    if (map['hashtags'] is List) {
      final raw = map['hashtags'] as List;
      if (raw.isNotEmpty) {
        if (raw.first is Map) {
          hashtags = List<Map<String, dynamic>>.from(raw);
        } else {
          // Convert strings to {id,text,color}
          final colors = ['#f97316', '#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#06b6d4', '#84cc16', '#f472b6', '#6b7280'];
          hashtags = raw.asMap().entries.map((e) {
            return {
              'id': 'existing_${e.key}',
              'text': _stringFrom(e.value),
              'color': colors[e.key % colors.length],
            };
          }).toList();
        }
      }
    }

    // Badges: support List<String> or List<Map>
    List<String> badges = [];
    if (map['badges'] is List) {
      final raw = map['badges'] as List;
      if (raw.isNotEmpty) {
        if (raw.first is String) {
          badges = List<String>.from(raw);
        } else {
          badges = raw.map((e) => _stringFrom(e)).where((s) => s.isNotEmpty).toList();
        }
      }
    }

    // AssignedTo can be string (uid) or map
    String assignee = '';
    if (map['assignedTo'] != null) {
      final v = map['assignedTo'];
      if (v is String) {
        assignee = v;
      } else if (v is Map) {
        assignee = _stringFrom(v['id'] ?? v['uid'] ?? v['name'] ?? v);
      } else {
        assignee = _stringFrom(v);
      }
    } else if (map['assignee'] != null) {
      assignee = _stringFrom(map['assignee']);
    }

    // Customer fields can be string or map
    final customerRaw = map['customer'];
    final String customer = customerRaw == null
        ? ''
        : (customerRaw is String ? customerRaw : _stringFrom(customerRaw['name'] ?? customerRaw));
    final String? customerId = map['customerId'] is String
        ? map['customerId'] as String
        : (customerRaw is Map && customerRaw['id'] is String ? customerRaw['id'] as String : null);

    // Company can be string or map
    final companyRaw = map['company'];
    final String? company = companyRaw == null
        ? null
        : (companyRaw is String ? companyRaw : _nullableStringFrom(companyRaw['name'] ?? companyRaw));

    // Board/workspace may be direct strings
    final String boardId = _stringFrom(map['boardId']);
    final String workspaceId = _stringFrom(map['workspaceId']);

    // Status from string or map
    final String statusStr = _stringFrom(map['status']);

    // Order as any numeric or string
    int _orderFrom(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return JobCard(
      id: id,
      title: title,
      description: _stringFrom(map['description']),
      assignee: assignee,
      status: statusStr.isNotEmpty ? statusStr : 'To Do',
      customId: _stringFrom(map['customId']),
      dueDate: _dateTimeFrom(map['dueDate']),
      badges: badges,
      amount: _doubleFrom(map['amount']),
      laneId: laneId,
      boardId: boardId,
      workspaceId: workspaceId,
      order: _orderFrom(map['order']),
      createdAt: createdAt,
      updatedAt: updatedAt,
      customer: customer,
      updatedByDisplayName: _stringFrom(map['updatedByDisplayName']),
      customerId: customerId,
      company: company,
      hashtag: _nullableStringFrom(map['hashtag']),
      hashtags: hashtags,
      customerInterest: _nullableStringFrom(map['customerInterest']),
      expenses: List<Map<String, dynamic>>.from(map['expenses'] ?? const []),
      todos: List<Map<String, dynamic>>.from(map['todos'] ?? const []),
      notes: List<Map<String, dynamic>>.from(map['notes'] ?? const []),
      watchers: watchers,
      customFields: List<Map<String, dynamic>>.from(map['customFields'] ?? const []),
      createdBy: _stringFrom(map['createdBy']),
      updatedBy: _stringFrom(map['updatedBy']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JobCard &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.assignee == assignee &&
        other.status == status &&
        other.customId == customId &&
        other.dueDate == dueDate &&
        other.badges == badges &&
        other.amount == amount &&
        other.laneId == laneId &&
        other.boardId == boardId &&
        other.workspaceId == workspaceId &&
        other.order == order &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.customer == customer &&
        other.updatedByDisplayName == updatedByDisplayName &&
        other.customerId == customerId &&
        other.company == company &&
        other.hashtag == hashtag &&
        other.hashtags == hashtags &&
        other.customerInterest == customerInterest &&
        other.expenses == expenses &&
        other.todos == todos &&
        other.notes == notes &&
        other.watchers == watchers &&
        other.customFields == customFields &&
        other.createdBy == createdBy &&
        other.updatedBy == updatedBy;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        assignee.hashCode ^
        status.hashCode ^
        customId.hashCode ^
        dueDate.hashCode ^
        badges.hashCode ^
        amount.hashCode ^
        laneId.hashCode ^
        boardId.hashCode ^
        workspaceId.hashCode ^
        order.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        customer.hashCode ^
        updatedByDisplayName.hashCode ^
        customerId.hashCode ^
        company.hashCode ^
        hashtag.hashCode ^
        hashtags.hashCode ^
        customerInterest.hashCode ^
        expenses.hashCode ^
        todos.hashCode ^
        notes.hashCode ^
        watchers.hashCode ^
        customFields.hashCode ^
        createdBy.hashCode ^
        updatedBy.hashCode;
  }

  @override
  String toString() {
    return 'JobCard(id: $id, title: $title, description: $description, assignee: $assignee, status: $status, customId: $customId, dueDate: $dueDate, badges: $badges, amount: $amount, laneId: $laneId, boardId: $boardId, workspaceId: $workspaceId, order: $order, createdAt: $createdAt, updatedAt: $updatedAt, customer: $customer, updatedByDisplayName: $updatedByDisplayName, customerId: $customerId, company: $company, hashtag: $hashtag, hashtags: $hashtags, customerInterest: $customerInterest, expenses: $expenses, todos: $todos, notes: $notes, watchers: $watchers, customFields: $customFields, createdBy: $createdBy, updatedBy: $updatedBy)';
  }
}
