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
    try {
      return Customer(
        id: id,
        name: map['name']?.toString() ?? '',
        customId: map['customId']?.toString() ?? '',
        workspaceId: map['workspaceId']?.toString() ?? '',
        emails: _parseListOfMaps(map['emails']),
        phones: _parseListOfMaps(map['phones']),
        companyNames: _parseListOfStrings(map['companyNames']),
        customFields: _parseListOfMaps(map['customFields']),
        assignees: _parseAssignees(map['assignees']),
        createdAt: _parseDateTime(map['createdAt']),
        updatedAt: _parseDateTime(map['updatedAt']),
        createdBy: map['createdBy']?.toString() ?? '',
        updatedBy: map['updatedBy']?.toString() ?? '',
      );
    } catch (e) {
      print('❌ Error parsing Customer.fromMap: $e');
      print('  - Document ID: $id');
      print('  - Raw data: $map');
      rethrow;
    }
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

  // Helper method to parse assignees field which can be either List<String> or Map<String, dynamic>
  static List<String> _parseAssignees(dynamic assignees) {
    if (assignees == null) return [];
    
    if (assignees is List) {
      return assignees.map((item) {
        if (item is String) return item;
        if (item is Map<String, dynamic>) {
          // If it's a map, try to extract id or name
          return item['id']?.toString() ?? item['name']?.toString() ?? '';
        }
        return item.toString();
      }).where((item) => item.isNotEmpty).toList();
    }
    
    if (assignees is Map<String, dynamic>) {
      // If it's a map, convert to list of keys or values
      return assignees.keys.toList();
    }
    
    return [];
  }

  // Helper method to parse list of maps
  static List<Map<String, dynamic>> _parseListOfMaps(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((item) {
        if (item is Map<String, dynamic>) return item;
        return <String, dynamic>{};
      }).toList();
    }
    return [];
  }

  // Helper method to parse list of strings
  static List<String> _parseListOfStrings(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((item) => item.toString()).toList();
    }
    return [];
  }

  // Helper method to parse DateTime
  static DateTime _parseDateTime(dynamic data) {
    if (data == null) return DateTime.now();
    
    if (data is Timestamp) {
      return data.toDate();
    }
    
    if (data is int) {
      return DateTime.fromMillisecondsSinceEpoch(data);
    }
    
    if (data is String) {
      try {
        return DateTime.parse(data);
      } catch (e) {
        return DateTime.now();
      }
    }
    
    return DateTime.now();
  }
}
