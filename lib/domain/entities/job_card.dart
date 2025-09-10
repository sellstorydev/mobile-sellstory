import 'package:cloud_firestore/cloud_firestore.dart';

class JobCard {
  final String id;
  final String title;
  final String description;
  final String assignedTo;         // Changed from assignee to assignedTo (user_id)
  final String status;
  final String customId;
  final DateTime? dueDate;
  final DateTime? startDate;
  final DateTime? endDate;
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
  final Map<String, dynamic>? company; // Add company field as object
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
  final List<String> collaborators; // Add collaborators field (array of user_ids)
  final String? priority; // Add priority field
  final bool isVatEnabled; // Add VAT enabled field
  final Map<String, dynamic>? additionalDiscount; // Add additional discount field
  final num withholdingTaxPercentage; // Add withholding tax percentage field
  final List<Map<String, dynamic>> attachments; // Add attachments field

  JobCard({
    required this.id,
    required this.title,
    this.description = '',
    required this.assignedTo,      // Changed from assignee to assignedTo
    this.status = 'To Do',
    this.customId = '',
    this.dueDate,
    this.startDate,
    this.endDate,
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
    this.collaborators = const [],
    this.priority,
    this.isVatEnabled = false,
    this.additionalDiscount,
    this.withholdingTaxPercentage = 0,
    this.attachments = const [],
  });

  JobCard copyWith({
    String? id,
    String? title,
    String? description,
    String? assignedTo,
    String? status,
    String? customId,
    DateTime? dueDate,
    DateTime? startDate,
    DateTime? endDate,
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
    Map<String, dynamic>? company,
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
    List<String>? collaborators,
    String? priority,
    bool? isVatEnabled,
    Map<String, dynamic>? additionalDiscount,
    num? withholdingTaxPercentage,
    List<Map<String, dynamic>>? attachments,
  }) {
    return JobCard(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedTo: assignedTo ?? this.assignedTo,
      status: status ?? this.status,
      customId: customId ?? this.customId,
      dueDate: dueDate ?? this.dueDate,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
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
      collaborators: collaborators ?? this.collaborators,
      priority: priority ?? this.priority,
      isVatEnabled: isVatEnabled ?? this.isVatEnabled,
      additionalDiscount: additionalDiscount ?? this.additionalDiscount,
      withholdingTaxPercentage: withholdingTaxPercentage ?? this.withholdingTaxPercentage,
      attachments: attachments ?? this.attachments,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'assignedTo': assignedTo,
      'status': status,
      'customId': customId,
      'dueDate': _dateToTimestamp(dueDate),
      'startDate': _dateToTimestamp(startDate),
      'endDate': _dateToTimestamp(endDate),
      'badges': badges,
      'amount': amount,
      'laneId': laneId,
      'boardId': boardId,
      'workspaceId': workspaceId,
      'order': order,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'customer': customer,
      'updatedByDisplayName': updatedByDisplayName,
      'customerId': customerId,
      'company': company,
      'hashtag': hashtag,
      'hashtags': hashtags,
      'customerInterest': customerInterest,
      'expenses': expenses,
      'todos': todos,
      'notes': notes,
      'watchers': watchers,
      'customFields': customFields,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'collaborators': collaborators,
      'priority': priority,
      'isVatEnabled': isVatEnabled,
      'additionalDiscount': additionalDiscount,
      'withholdingTaxPercentage': withholdingTaxPercentage,
      'attachments': attachments,
    };
  }

  factory JobCard.fromMap(Map<String, dynamic> map, [String? docId]) {
    // Handle legacy assignee field
    String assignee = _stringFrom(map['assignedTo']).isNotEmpty 
        ? _stringFrom(map['assignedTo'])
        : _stringFrom(map['assignee']);
    
    // Handle dates
    DateTime createdAt = _dateTimeFrom(map['createdAt']) ?? DateTime.now();
    DateTime updatedAt = _dateTimeFrom(map['updatedAt']) ?? DateTime.now();
    
    // Handle badges
    List<String> badges = List<String>.from(map['badges'] ?? const []);
    
    // Handle status conversion
    String statusStr = _stringFrom(map['status']);
    
    // Handle laneId - this might be coming as an object, we need the string ID
    String laneId;
    if (map['laneId'] is Map) {
      laneId = (map['laneId'] as Map)['id']?.toString() ?? '';
    } else {
      laneId = _stringFrom(map['laneId']);
    }
    
    // Handle customer
    String customer;
    if (map['customer'] is Map) {
      final customerMap = map['customer'] as Map<String, dynamic>;
      customer = customerMap['company_name']?.toString() ?? 
                 customerMap['name']?.toString() ?? 
                 customerMap['title']?.toString() ?? '';
    } else {
      customer = _stringFrom(map['customer']);
    }
    
    // Handle customerId  
    String? customerId;
    if (map['customer'] is Map) {
      final customerMap = map['customer'] as Map<String, dynamic>;
      customerId = customerMap['id']?.toString();
    } else {
      customerId = _nullableStringFrom(map['customerId']);
    }
    
    // Handle company - keep as object
    Map<String, dynamic>? company;
    if (map['customer'] is Map) {
      company = Map<String, dynamic>.from(map['customer'] as Map);
    } else {
      company = map['company'] != null ? Map<String, dynamic>.from(map['company'] as Map) : null;
    }
    
    // Handle priority
    String? priority = _nullableStringFrom(map['priority']);
    
    // Handle watchers with type safety
    List<String> watchers = [];
    if (map['watchers'] != null) {
      final watchersData = map['watchers'];
      if (watchersData is List) {
        watchers = watchersData.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      }
    }
    
    // Handle collaborators with type safety
    List<String> collaborators = [];
    if (map['collaborators'] != null) {
      final collaboratorsData = map['collaborators'];
      if (collaboratorsData is List) {
        collaborators = collaboratorsData.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      }
    }


    // Handle hashtags with type safety
    List<Map<String, dynamic>> hashtags = [];
    if (map['hashtags'] != null) {
      final hashtagsData = map['hashtags'];
      if (hashtagsData is List) {
        for (final item in hashtagsData) {
          if (item is Map) {
            hashtags.add(Map<String, dynamic>.from(item));
          }
        }
      }
    }
    
    // Handle board and workspace IDs
    String boardId = _stringFrom(map['boardId']);
    String workspaceId = _stringFrom(map['workspaceId']);

    return JobCard(
      id: docId ?? _stringFrom(map['id']),
      title: _stringFrom(map['title']),
      description: _stringFrom(map['description']),
      assignedTo: assignee,
      status: statusStr.isNotEmpty ? statusStr : 'To Do',
      customId: _stringFrom(map['customId']),
      dueDate: _dateTimeFrom(map['dueDate']),
      startDate: _dateTimeFrom(map['startDate']),
      endDate: _dateTimeFrom(map['endDate']),
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
      collaborators: collaborators,
      priority: priority,
      isVatEnabled: map['isVatEnabled'] ?? false,
      additionalDiscount: map['additionalDiscount'] != null ? Map<String, dynamic>.from(map['additionalDiscount'] as Map) : null,
      withholdingTaxPercentage: map['withholdingTaxPercentage'] ?? 0,
      attachments: List<Map<String, dynamic>>.from(map['attachments'] ?? const []),
    );
  }

  static int? _dateToTimestamp(DateTime? date) {
    return date?.millisecondsSinceEpoch;
  }

  static String _stringFrom(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static String? _nullableStringFrom(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  static double _doubleFrom(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static DateTime? _dateTimeFrom(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
      final timestamp = int.tryParse(value);
      if (timestamp != null) return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  static int _orderFrom(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JobCard &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.assignedTo == assignedTo &&
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
        other.updatedBy == updatedBy &&
        other.collaborators == collaborators &&
        other.priority == priority &&
        other.isVatEnabled == isVatEnabled &&
        other.additionalDiscount == additionalDiscount &&
        other.withholdingTaxPercentage == withholdingTaxPercentage;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        assignedTo.hashCode ^
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
        updatedBy.hashCode ^
        collaborators.hashCode ^
        priority.hashCode ^
        isVatEnabled.hashCode ^
        additionalDiscount.hashCode ^
        withholdingTaxPercentage.hashCode;
  }

  @override
  String toString() {
    return 'JobCard(id: $id, title: $title, description: $description, assignedTo: $assignedTo, status: $status, customId: $customId, dueDate: $dueDate, badges: $badges, amount: $amount, laneId: $laneId, boardId: $boardId, workspaceId: $workspaceId, order: $order, createdAt: $createdAt, updatedAt: $updatedAt, customer: $customer, updatedByDisplayName: $updatedByDisplayName, customerId: $customerId, company: $company, hashtag: $hashtag, hashtags: $hashtags, customerInterest: $customerInterest, expenses: $expenses, todos: $todos, notes: $notes, watchers: $watchers, customFields: $customFields, createdBy: $createdBy, updatedBy: $updatedBy, collaborators: $collaborators, priority: $priority, isVatEnabled: $isVatEnabled, additionalDiscount: $additionalDiscount, withholdingTaxPercentage: $withholdingTaxPercentage)';
  }
}
