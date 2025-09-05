import 'package:cloud_firestore/cloud_firestore.dart';

class Company {
  final String id;
  final String name;
  final String branch;
  final String taxId;
  final List<Map<String, dynamic>> emails;
  final List<Map<String, dynamic>> phones;
  final String website;
  final String addressLine1;
  final String province;
  final String district;
  final String subdistrict;
  final String postalCode;
  final String country;
  final String workspaceId;
  final String customId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;
  final List<String> associatedCustomerIds;
  final List<Map<String, dynamic>> customFields;
  final List<Map<String, dynamic>> hashtags;
  final List<Map<String, dynamic>> notes;

  Company({
    required this.id,
    required this.name,
    this.branch = '',
    this.taxId = '',
    required this.emails,
    required this.phones,
    this.website = '',
    this.addressLine1 = '',
    this.province = '',
    this.district = '',
    this.subdistrict = '',
    this.postalCode = '',
    this.country = '',
    required this.workspaceId,
    required this.customId,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
    required this.associatedCustomerIds,
    this.customFields = const [],
    this.hashtags = const [],
    this.notes = const [],
  });

  Company copyWith({
    String? id,
    String? name,
    String? branch,
    String? taxId,
    List<Map<String, dynamic>>? emails,
    List<Map<String, dynamic>>? phones,
    String? website,
    String? addressLine1,
    String? province,
    String? district,
    String? subdistrict,
    String? postalCode,
    String? country,
    String? workspaceId,
    String? customId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    List<String>? associatedCustomerIds,
    List<Map<String, dynamic>>? customFields,
    List<Map<String, dynamic>>? hashtags,
    List<Map<String, dynamic>>? notes,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      branch: branch ?? this.branch,
      taxId: taxId ?? this.taxId,
      emails: emails ?? this.emails,
      phones: phones ?? this.phones,
      website: website ?? this.website,
      addressLine1: addressLine1 ?? this.addressLine1,
      province: province ?? this.province,
      district: district ?? this.district,
      subdistrict: subdistrict ?? this.subdistrict,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      workspaceId: workspaceId ?? this.workspaceId,
      customId: customId ?? this.customId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      associatedCustomerIds: associatedCustomerIds ?? this.associatedCustomerIds,
      customFields: customFields ?? this.customFields,
      hashtags: hashtags ?? this.hashtags,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'branch': branch,
      'taxId': taxId,
      'emails': emails,
      'phones': phones,
      'website': website,
      'addressLine1': addressLine1,
      'province': province,
      'district': district,
      'subdistrict': subdistrict,
      'postalCode': postalCode,
      'country': country,
      'workspaceId': workspaceId,
      'customId': customId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'associatedCustomerIds': associatedCustomerIds,
      'customFields': customFields,
      'hashtags': hashtags,
      'notes': notes,
    };
  }

  factory Company.fromMap(Map<String, dynamic> map, String id) {
    return Company(
      id: id,
      name: map['name'] ?? '',
      branch: map['branch'] ?? '',
      taxId: map['taxId'] ?? '',
      emails: List<Map<String, dynamic>>.from(map['emails'] ?? []),
      phones: List<Map<String, dynamic>>.from(map['phones'] ?? []),
      website: map['website'] ?? '',
      addressLine1: map['addressLine1'] ?? '',
      province: map['province'] ?? '',
      district: map['district'] ?? '',
      subdistrict: map['subdistrict'] ?? '',
      postalCode: map['postalCode'] ?? '',
      country: map['country'] ?? '',
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
      customFields: List<Map<String, dynamic>>.from(map['customFields'] ?? []),
      hashtags: List<Map<String, dynamic>>.from(map['hashtags'] ?? []),
      notes: List<Map<String, dynamic>>.from(map['notes'] ?? []),
    );
  }

  String get fullAddress {
    final parts = [
      addressLine1,
      subdistrict,
      district,
      province,
      postalCode,
      country,
    ].where((part) => part.isNotEmpty).toList();

    return parts.join(', ');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Company &&
        other.id == id &&
        other.name == name &&
        other.branch == branch &&
        other.taxId == taxId &&
        other.workspaceId == workspaceId &&
        other.customId == customId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        branch.hashCode ^
        taxId.hashCode ^
        workspaceId.hashCode ^
        customId.hashCode;
  }

  @override
  String toString() {
    return 'Company(id: $id, name: $name, branch: $branch, taxId: $taxId, customId: $customId)';
  }
}
