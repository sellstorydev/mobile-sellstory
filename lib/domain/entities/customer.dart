import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class Customer {
  final String id;
  final String name;
  final String prefix;
  final String gender;
  final String age;
  final String customerType;
  final String emails;
  final String phones;
  final String companyNames;
  final String nationalId;
  final String address;
  final String source;
  final List<Map<String, dynamic>> hashtags;
  final String assignees;
  final String customId;
  final String workspaceId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;

  Customer({
    required this.id,
    required this.name,
    required this.prefix,
    required this.gender,
    required this.age,
    required this.customerType,
    required this.emails,
    required this.phones,
    required this.companyNames,
    required this.nationalId,
    required this.address,
    required this.source,
    required this.hashtags,
    required this.assignees,
    required this.customId,
    required this.workspaceId,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? prefix,
    String? gender,
    String? age,
    String? customerType,
    String? emails,
    String? phones,
    String? companyNames,
    String? nationalId,
    String? address,
    String? source,
    List<Map<String, dynamic>>? hashtags,
    String? assignees,
    String? customId,
    String? workspaceId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      prefix: prefix ?? this.prefix,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      customerType: customerType ?? this.customerType,
      emails: emails ?? this.emails,
      phones: phones ?? this.phones,
      companyNames: companyNames ?? this.companyNames,
      nationalId: nationalId ?? this.nationalId,
      address: address ?? this.address,
      source: source ?? this.source,
      hashtags: hashtags ?? this.hashtags,
      assignees: assignees ?? this.assignees,
      customId: customId ?? this.customId,
      workspaceId: workspaceId ?? this.workspaceId,
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
      'prefix': prefix,
      'gender': gender,
      'age': age,
      'customerType': customerType,
      'emails': emails,
      'phones': phones,
      'companyNames': companyNames,
      'nationalId': nationalId,
      'address': address,
      'source': source,
      'hashtags': hashtags,
      'assignees': assignees,
      'customId': customId,
      'workspaceId': workspaceId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }

  // Create from Map from Firestore
  factory Customer.fromMap(Map<String, dynamic> map, String id) {
    return Customer(
      id: id,
      name: map['name'] ?? '',
      prefix: map['prefix'] ?? '',
      gender: map['gender'] ?? '',
      age: map['age'] ?? '',
      customerType: map['customerType'] ?? '',
      emails: map['emails'] ?? '',
      phones: map['phones'] ?? '',
      companyNames: map['companyNames'] ?? '',
      nationalId: map['nationalId'] ?? '',
      address: map['address'] ?? '',
      source: map['source'] ?? '',
      hashtags: _parseHashtagsFromMap(map['hashtags']),
      assignees: map['assignees'] ?? '',
      customId: map['customId'] ?? '',
      workspaceId: map['workspaceId'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
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
        other.prefix == prefix &&
        other.gender == gender &&
        other.age == age &&
        other.customerType == customerType &&
        other.emails == emails &&
        other.phones == phones &&
        other.companyNames == companyNames &&
        other.nationalId == nationalId &&
        other.address == address &&
        other.source == source &&
        other.hashtags == hashtags &&
        other.assignees == assignees &&
        other.customId == customId &&
        other.workspaceId == workspaceId &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.createdBy == createdBy &&
        other.updatedBy == updatedBy;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        prefix.hashCode ^
        gender.hashCode ^
        age.hashCode ^
        customerType.hashCode ^
        emails.hashCode ^
        phones.hashCode ^
        companyNames.hashCode ^
        nationalId.hashCode ^
        address.hashCode ^
        source.hashCode ^
        hashtags.hashCode ^
        assignees.hashCode ^
        customId.hashCode ^
        workspaceId.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        createdBy.hashCode ^
        updatedBy.hashCode;
  }

  @override
  String toString() {
    return 'Customer(id: $id, name: $name, customId: $customId, customerType: $customerType)';
  }

  // Helper method to parse hashtags from different data types
  static List<Map<String, dynamic>> _parseHashtagsFromMap(dynamic hashtagsData) {
    try {
      // If hashtagsData is null or empty, return empty list
      if (hashtagsData == null || hashtagsData.toString().isEmpty) {
        return [];
      }

      // If it's already a List, try to convert it
      if (hashtagsData is List) {
        return hashtagsData.map((item) {
          if (item is Map<String, dynamic>) {
            return item;
          } else if (item is String) {
            // Convert string to hashtag object format
            return {
              'color': '#ef4444',
              'id': item,
              'text': item,
            };
          } else {
            // Fallback for unknown types
            return {
              'color': '#ef4444',
              'id': item.toString(),
              'text': item.toString(),
            };
          }
        }).toList();
      }

      // If it's a String, try to parse it as JSON or treat as single hashtag
      if (hashtagsData is String) {
        try {
          // Try to parse as JSON array
          final List<dynamic> parsed = jsonDecode(hashtagsData);
          return parsed.map((item) {
            if (item is Map<String, dynamic>) {
              return item;
            } else {
              return {
                'color': '#ef4444',
                'id': item.toString(),
                'text': item.toString(),
              };
            }
          }).toList();
        } catch (e) {
          // If JSON parsing fails, treat as single hashtag string
          if (hashtagsData.trim().isNotEmpty) {
            return [{
              'color': '#ef4444',
              'id': hashtagsData,
              'text': hashtagsData,
            }];
          }
          return [];
        }
      }

      // For any other type, convert to string and create hashtag object
      return [{
        'color': '#ef4444',
        'id': hashtagsData.toString(),
        'text': hashtagsData.toString(),
      }];
    } catch (e) {
      print('Error parsing hashtags: $e');
      print('Hashtags data: $hashtagsData');
      print('Hashtags data type: ${hashtagsData.runtimeType}');
      return [];
    }
  }
}


