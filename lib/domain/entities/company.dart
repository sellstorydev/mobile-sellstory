import 'package:cloud_firestore/cloud_firestore.dart';

class Company {
  final String id;
  final String name;
  final List<Map<String, dynamic>> emails;
  final List<Map<String, dynamic>> phones;
  final String workspaceId;
  final String customId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;
  final List<String> associatedCustomerIds;

  Company({
    required this.id,
    required this.name,
    required this.emails,
    required this.phones,
    required this.workspaceId,
    required this.customId,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
    required this.associatedCustomerIds,
  });

  Company copyWith({
    String? id,
    String? name,
    List<Map<String, dynamic>>? emails,
    List<Map<String, dynamic>>? phones,
    String? workspaceId,
    String? customId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    List<String>? associatedCustomerIds,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      emails: emails ?? this.emails,
      phones: phones ?? this.phones,
      workspaceId: workspaceId ?? this.workspaceId,
      customId: customId ?? this.customId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      associatedCustomerIds: associatedCustomerIds ?? this.associatedCustomerIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'emails': emails,
      'phones': phones,
      'workspaceId': workspaceId,
      'customId': customId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'associatedCustomerIds': associatedCustomerIds,
    };
  }

  factory Company.fromMap(Map<String, dynamic> map, String id) {
    return Company(
      id: id,
      name: map['name'] ?? '',
      emails: List<Map<String, dynamic>>.from(map['emails'] ?? []),
      phones: List<Map<String, dynamic>>.from(map['phones'] ?? []),
      workspaceId: map['workspaceId'] ?? '',
      customId: map['customId'] ?? '',
      createdAt: (map['createdAt'] is Timestamp) 
                 ? (map['createdAt'] as Timestamp).toDate()
                 : DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: (map['updatedAt'] is Timestamp)
                 ? (map['updatedAt'] as Timestamp).toDate()
                 : DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
      createdBy: map['createdBy'] ?? '',
      updatedBy: map['updatedBy'] ?? '',
      associatedCustomerIds: List<String>.from(map['associatedCustomerIds'] ?? []),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Company &&
        other.id == id &&
        other.name == name &&
        other.emails == emails &&
        other.phones == phones &&
        other.workspaceId == workspaceId &&
        other.customId == customId &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.createdBy == createdBy &&
        other.updatedBy == updatedBy &&
        other.associatedCustomerIds == associatedCustomerIds;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        emails.hashCode ^
        phones.hashCode ^
        workspaceId.hashCode ^
        customId.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        createdBy.hashCode ^
        updatedBy.hashCode ^
        associatedCustomerIds.hashCode;
  }

  @override
  String toString() {
    return 'Company(id: $id, name: $name, emails: $emails, phones: $phones, workspaceId: $workspaceId, customId: $customId, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, updatedBy: $updatedBy, associatedCustomerIds: $associatedCustomerIds)';
  }
}
