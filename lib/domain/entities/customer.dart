import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id;
  final String name;
  final String customId;
  final String workspaceId;
  final List<Map<String, dynamic>> emails;
  final List<Map<String, dynamic>> phones;
  final List<String> companyNames;
  final List<Map<String, dynamic>> customFields;
  final List<String> assignees;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;

  Customer({
    required this.id,
    required this.name,
    required this.customId,
    required this.workspaceId,
    required this.emails,
    required this.phones,
    required this.companyNames,
    required this.customFields,
    required this.assignees,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? customId,
    String? workspaceId,
    List<Map<String, dynamic>>? emails,
    List<Map<String, dynamic>>? phones,
    List<String>? companyNames,
    List<Map<String, dynamic>>? customFields,
    List<String>? assignees,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      customId: customId ?? this.customId,
      workspaceId: workspaceId ?? this.workspaceId,
      emails: emails ?? this.emails,
      phones: phones ?? this.phones,
      companyNames: companyNames ?? this.companyNames,
      customFields: customFields ?? this.customFields,
      assignees: assignees ?? this.assignees,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'customId': customId,
      'workspaceId': workspaceId,
      'emails': emails,
      'phones': phones,
      'companyNames': companyNames,
      'customFields': customFields,
      'assignees': assignees,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }

  // Create from Map from Firestore
  factory Customer.fromMap(Map<String, dynamic> map, String id) {
    return Customer(
      id: id,
      name: map['name'] ?? '',
      customId: map['customId'] ?? '',
      workspaceId: map['workspaceId'] ?? '',
      emails: List<Map<String, dynamic>>.from(map['emails'] ?? []),
      phones: List<Map<String, dynamic>>.from(map['phones'] ?? []),
      companyNames: List<String>.from(map['companyNames'] ?? []),
      customFields: List<Map<String, dynamic>>.from(map['customFields'] ?? []),
      assignees: List<String>.from(map['assignees'] ?? []),
      createdAt: (map['createdAt'] is Timestamp) 
                 ? (map['createdAt'] as Timestamp).toDate()
                 : DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: (map['updatedAt'] is Timestamp)
                 ? (map['updatedAt'] as Timestamp).toDate()
                 : DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
      createdBy: map['createdBy'] ?? '',
      updatedBy: map['updatedBy'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Customer &&
        other.id == id &&
        other.name == name &&
        other.customId == customId &&
        other.workspaceId == workspaceId &&
        other.emails == emails &&
        other.phones == phones &&
        other.companyNames == companyNames &&
        other.customFields == customFields &&
        other.assignees == assignees &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.createdBy == createdBy &&
        other.updatedBy == updatedBy;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        customId.hashCode ^
        workspaceId.hashCode ^
        emails.hashCode ^
        phones.hashCode ^
        companyNames.hashCode ^
        customFields.hashCode ^
        assignees.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        createdBy.hashCode ^
        updatedBy.hashCode;
  }

  @override
  String toString() {
    return 'Customer(id: $id, name: $name, customId: $customId, workspaceId: $workspaceId, emails: $emails, phones: $phones, companyNames: $companyNames, customFields: $customFields, assignees: $assignees, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, updatedBy: $updatedBy)';
  }
}
