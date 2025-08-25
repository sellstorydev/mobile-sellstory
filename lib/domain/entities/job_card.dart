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
  final String? hashtag; // Add hashtag field
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
    // Build the map based on DTB.md structure and only include non-empty values
    final Map<String, dynamic> data = {
      'workspaceId': workspaceId,
    };

    // Required fields
    if (title.isNotEmpty) data['name'] = title; // Map title -> name per DTB.md
    if (createdBy.isNotEmpty) data['createdBy'] = createdBy;
    
    // Optional fields - only add if they have values
    if (description.isNotEmpty) data['description'] = description;
    if (assignee.isNotEmpty) data['assignedTo'] = assignee;
    if (status.isNotEmpty) data['status'] = status;
    if (customId.isNotEmpty) data['customId'] = customId;
    if (dueDate != null) data['dueDate'] = Timestamp.fromDate(dueDate!);
    if (badges.isNotEmpty) data['badges'] = badges;
    if (amount > 0) data['amount'] = amount;
    if (laneId.isNotEmpty) data['laneId'] = laneId;
    if (boardId.isNotEmpty) data['boardId'] = boardId;
    if (order > 0) data['order'] = order;
    if (customer.isNotEmpty) data['customer'] = customer;
    if (updatedByDisplayName.isNotEmpty) data['updatedByDisplayName'] = updatedByDisplayName;
    if (customerId?.isNotEmpty == true) data['customerId'] = customerId;
    if (company?.isNotEmpty == true) data['company'] = company;
    if (hashtag?.isNotEmpty == true) data['hashtag'] = hashtag;
    if (expenses.isNotEmpty) data['expenses'] = expenses;
    if (todos.isNotEmpty) data['todos'] = todos;
    if (notes.isNotEmpty) data['notes'] = notes;
    if (watchers.isNotEmpty) data['watchers'] = watchers;
    if (customFields.isNotEmpty) data['customFields'] = customFields;
    if (updatedBy.isNotEmpty) data['updatedBy'] = updatedBy;

    // Always include timestamps
    data['createdAt'] = Timestamp.fromDate(createdAt);
    data['updatedAt'] = Timestamp.fromDate(updatedAt);

    // DTB.md structure fields
    if (laneId.isNotEmpty) {
      data['lanes'] = [laneId]; // lanes: array per DTB.md
    }

    return data;
  }

  // Create from Map from Firestore
  factory JobCard.fromMap(Map<String, dynamic> map, String id) {
    // Handle DTB.md structure mapping
    String title = map['title'] ?? map['name'] ?? ''; // Support both title and name
    String laneId = map['laneId'] ?? '';
    
    // Handle lanes array from DTB.md structure
    if (laneId.isEmpty && map['lanes'] is List && (map['lanes'] as List).isNotEmpty) {
      laneId = (map['lanes'] as List).first?.toString() ?? '';
    }

    return JobCard(
      id: id,
      title: title,
      description: map['description'] ?? '',
      assignee: map['assignedTo'] ?? map['assignee'] ?? '',
      status: map['status'] ?? 'To Do',
      customId: map['customId'] ?? '',
      dueDate: (map['dueDate'] as Timestamp?)?.toDate(),
      badges: List<String>.from(map['badges'] ?? []),
      amount: (map['amount'] ?? 0.0).toDouble(),
      laneId: laneId,
      boardId: map['boardId'] ?? '',
      workspaceId: map['workspaceId'] ?? '',
      order: map['order'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? 
                 DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? 
                 DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
      customer: map['customer'] ?? '',
      updatedByDisplayName: map['updatedByDisplayName'] ?? '',
      customerId: map['customerId'],
      company: map['company'],
      hashtag: map['hashtag'],
      expenses: List<Map<String, dynamic>>.from(map['expenses'] ?? []),
      todos: List<Map<String, dynamic>>.from(map['todos'] ?? []),
      notes: List<Map<String, dynamic>>.from(map['notes'] ?? []),
      watchers: List<String>.from(map['watchers'] ?? []),
      customFields: List<Map<String, dynamic>>.from(map['customFields'] ?? []),
      createdBy: map['createdBy'] ?? '',
      updatedBy: map['updatedBy'] ?? '',
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
    return 'JobCard(id: $id, title: $title, description: $description, assignee: $assignee, status: $status, customId: $customId, dueDate: $dueDate, badges: $badges, amount: $amount, laneId: $laneId, boardId: $boardId, workspaceId: $workspaceId, order: $order, createdAt: $createdAt, updatedAt: $updatedAt, customer: $customer, updatedByDisplayName: $updatedByDisplayName, customerId: $customerId, company: $company, hashtag: $hashtag, expenses: $expenses, todos: $todos, notes: $notes, watchers: $watchers, customFields: $customFields, createdBy: $createdBy, updatedBy: $updatedBy)';
  }
}
