import 'dart:convert';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double costPrice;
  final String unit;
  final String barcode;
  final String sku;
  final String imageUrl; // Cover image
  final List<String> imageSet; // Other images
  final List<Map<String, dynamic>> hashtags;
  final List<Map<String, dynamic>> customFields;
  final List<Map<String, dynamic>> features;
  final int initialStock;
  final int reorderLevel;
  final int targetStockLevel;
  final bool showInCatalog;
  final String status;
  final String category;
  final String workspaceId;
  final List<String> searchableKeywords;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.costPrice,
    required this.unit,
    required this.barcode,
    required this.sku,
    required this.imageUrl,
    required this.imageSet,
    required this.hashtags,
    required this.customFields,
    required this.features,
    required this.initialStock,
    required this.reorderLevel,
    required this.targetStockLevel,
    required this.showInCatalog,
    required this.status,
    required this.category,
    required this.workspaceId,
    required this.searchableKeywords,
    required this.createdAt,
    required this.updatedAt,
  });

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? costPrice,
    String? unit,
    String? barcode,
    String? sku,
    String? imageUrl,
    List<String>? imageSet,
    List<Map<String, dynamic>>? hashtags,
    List<Map<String, dynamic>>? customFields,
    List<Map<String, dynamic>>? features,
    int? initialStock,
    int? reorderLevel,
    int? targetStockLevel,
    bool? showInCatalog,
    String? status,
    String? category,
    String? workspaceId,
    List<String>? searchableKeywords,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      unit: unit ?? this.unit,
      barcode: barcode ?? this.barcode,
      sku: sku ?? this.sku,
      imageUrl: imageUrl ?? this.imageUrl,
      imageSet: imageSet ?? this.imageSet,
      hashtags: hashtags ?? this.hashtags,
      customFields: customFields ?? this.customFields,
      features: features ?? this.features,
      initialStock: initialStock ?? this.initialStock,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      targetStockLevel: targetStockLevel ?? this.targetStockLevel,
      showInCatalog: showInCatalog ?? this.showInCatalog,
      status: status ?? this.status,
      category: category ?? this.category,
      workspaceId: workspaceId ?? this.workspaceId,
      searchableKeywords: searchableKeywords ?? this.searchableKeywords,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'costPrice': costPrice,
      'unit': unit,
      'barcode': barcode,
      'sku': sku,
      'imageUrl': imageUrl,
      'imageSet': imageSet,
      'hashtags': hashtags,
      'customFields': customFields,
      'features': features,
      'initialStock': initialStock,
      'reorderLevel': reorderLevel,
      'targetStockLevel': targetStockLevel,
      'showInCatalog': showInCatalog,
      'status': status,
      'category': category,
      'workspaceId': workspaceId,
      'searchableKeywords': searchableKeywords,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Create from Map from Firestore
  factory Product.fromMap(Map<String, dynamic> map, String id) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      costPrice: (map['costPrice'] ?? 0).toDouble(),
      unit: map['unit'] ?? '',
      barcode: map['barcode'] ?? '',
      sku: map['sku'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      imageSet: List<String>.from(map['imageSet'] ?? []),
      hashtags: _parseHashtagsFromMap(map['hashtags']),
      customFields: List<Map<String, dynamic>>.from(map['customFields'] ?? []),
      features: List<Map<String, dynamic>>.from(map['features'] ?? []),
      initialStock: map['initialStock'] ?? 0,
      reorderLevel: map['reorderLevel'] ?? 0,
      targetStockLevel: map['targetStockLevel'] ?? 0,
      showInCatalog: map['showInCatalog'] ?? true,
      status: map['status'] ?? 'active',
      category: map['category'] ?? '',
      workspaceId: map['workspaceId'] ?? '',
      searchableKeywords: List<String>.from(map['searchableKeywords'] ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }

  // Parse hashtags from map
  static List<Map<String, dynamic>> _parseHashtagsFromMap(dynamic hashtagsData) {
    if (hashtagsData == null) return [];
    
    try {
      if (hashtagsData is List) {
        return hashtagsData.map((item) {
          if (item is Map<String, dynamic>) {
            return item;
          } else if (item is String) {
            // Handle legacy string format
            return {
              'id': item,
              'text': item,
              'color': '#3b82f6', // Default color
            };
          }
          return <String, dynamic>{};
        }).toList();
      }
    } catch (e) {
      print('Error parsing hashtags: $e');
    }
    
    return [];
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.price == price &&
        other.costPrice == costPrice &&
        other.unit == unit &&
        other.barcode == barcode &&
        other.sku == sku &&
        other.imageUrl == imageUrl &&
        other.imageSet == imageSet &&
        other.hashtags == hashtags &&
        other.customFields == customFields &&
        other.features == features &&
        other.initialStock == initialStock &&
        other.reorderLevel == reorderLevel &&
        other.targetStockLevel == targetStockLevel &&
        other.showInCatalog == showInCatalog &&
        other.status == status &&
        other.workspaceId == workspaceId &&
        other.searchableKeywords == searchableKeywords &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        price.hashCode ^
        costPrice.hashCode ^
        unit.hashCode ^
        barcode.hashCode ^
        sku.hashCode ^
        imageUrl.hashCode ^
        imageSet.hashCode ^
        hashtags.hashCode ^
        customFields.hashCode ^
        features.hashCode ^
        initialStock.hashCode ^
        reorderLevel.hashCode ^
        targetStockLevel.hashCode ^
        showInCatalog.hashCode ^
        status.hashCode ^
        workspaceId.hashCode ^
        searchableKeywords.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price, sku: $sku)';
  }
}
