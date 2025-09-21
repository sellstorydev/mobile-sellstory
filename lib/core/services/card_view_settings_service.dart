import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CardViewSettingsService extends GetxService {
  static CardViewSettingsService get to => Get.find<CardViewSettingsService>();

  final RxList<CardFieldSetting> _cardFields = <CardFieldSetting>[].obs;
  final RxBool _isInitialized = false.obs;

  List<CardFieldSetting> get cardFields => _cardFields;
  RxList<CardFieldSetting> get cardFieldsRx => _cardFields;
  bool get isInitialized => _isInitialized.value;

  // Default card field settings
  static const List<CardFieldSetting> _defaultFields = [
    CardFieldSetting(id: 'jobId', name: 'Job ID', isVisible: true, order: 1),
    CardFieldSetting(id: 'status', name: 'Status', isVisible: true, order: 2),
    CardFieldSetting(
      id: 'dateRange',
      name: 'Date Range',
      isVisible: true,
      order: 3,
    ),
    CardFieldSetting(
      id: 'createdDate',
      name: 'Created Date',
      isVisible: true,
      order: 4,
    ),
    CardFieldSetting(
      id: 'assignee',
      name: 'Assignee',
      isVisible: true,
      order: 5,
    ),
    CardFieldSetting(
      id: 'customerInterest',
      name: 'Customer Interest',
      isVisible: true,
      order: 6,
    ),
    CardFieldSetting(
      id: 'collaborators',
      name: 'Collaborators',
      isVisible: false,
      order: 7,
    ),
    CardFieldSetting(
      id: 'customer',
      name: 'Customer',
      isVisible: true,
      order: 8,
    ),
    CardFieldSetting(
      id: 'company',
      name: 'Company',
      isVisible: false,
      order: 9,
    ),
    CardFieldSetting(
      id: 'hashtags',
      name: 'Hashtags',
      isVisible: false,
      order: 10,
    ),
    CardFieldSetting(
      id: 'grandTotal',
      name: 'Grand Total',
      isVisible: false,
      order: 11,
    ),
    CardFieldSetting(
      id: 'netTotal',
      name: 'Net Total',
      isVisible: true,
      order: 12,
    ),
    CardFieldSetting(
      id: 'totalBeforeDiscount',
      name: 'Total (before discount)',
      isVisible: false,
      order: 13,
    ),
    CardFieldSetting(
      id: 'totalAfterDiscount',
      name: 'Total (after discount)',
      isVisible: false,
      order: 14,
    ),
    CardFieldSetting(
      id: 'totalBeforeVAT',
      name: 'Total (before VAT)',
      isVisible: false,
      order: 15,
    ),
    CardFieldSetting(
      id: 'description',
      name: 'Description',
      isVisible: false,
      order: 16,
    ),
    CardFieldSetting(
      id: 'todoList',
      name: 'To-Do List',
      isVisible: false,
      order: 17,
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    try {
      // Load settings from local storage
      await _loadSettingsFromLocal();

      // If no settings found, use defaults
      if (_cardFields.isEmpty) {
        _cardFields.value = List.from(_defaultFields);
        await _saveSettingsToLocal();
      }

      _isInitialized.value = true;
    } catch (e) {
      print('❌ Failed to initialize Card View Settings Service: $e');
      // Fallback to defaults
      _cardFields.value = List.from(_defaultFields);
      _isInitialized.value = true;
    }
  }

  /// Public method to refresh settings from local storage
  Future<void> refreshSettings() async {
    await _initializeSettings();
  }

  Future<void> _loadSettingsFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('card_view_settings');

      if (settingsJson != null) {
        final List<dynamic> settingsList = json.decode(settingsJson);
        _cardFields.value = settingsList
            .map((json) => CardFieldSetting.fromJson(json))
            .toList();
      }
    } catch (e) {
      print('❌ Failed to load settings from local storage: $e');
    }
  }

  Future<void> _saveSettingsToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = json.encode(
        _cardFields.map((field) => field.toJson()).toList(),
      );
      await prefs.setString('card_view_settings', settingsJson);

      // Verify save by reading back
      final savedJson = prefs.getString('card_view_settings');
    } catch (e) {
      print('❌ Failed to save settings to local storage: $e');
      rethrow;
    }
  }

  // Get visible fields ordered by their order value
  List<CardFieldSetting> getVisibleFields() {
    return _cardFields.where((field) => field.isVisible).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  // Get field setting by ID
  CardFieldSetting? getFieldById(String id) {
    try {
      return _cardFields.firstWhere((field) => field.id == id);
    } catch (e) {
      return null;
    }
  }

  // Check if field is visible
  bool isFieldVisible(String id) {
    final field = getFieldById(id);
    return field?.isVisible ?? false;
  }

  // Update field visibility
  Future<void> updateFieldVisibility(String id, bool isVisible) async {
    final fieldIndex = _cardFields.indexWhere((field) => field.id == id);
    if (fieldIndex != -1) {
      _cardFields[fieldIndex] = _cardFields[fieldIndex].copyWith(
        isVisible: isVisible,
      );
      await _saveSettingsToLocal();
    }
  }

  // Update field order
  Future<void> updateFieldOrder(String id, int newOrder) async {
    final fieldIndex = _cardFields.indexWhere((field) => field.id == id);
    if (fieldIndex != -1) {
      _cardFields[fieldIndex] = _cardFields[fieldIndex].copyWith(
        order: newOrder,
      );
      await _saveSettingsToLocal();
    }
  }

  // Update multiple fields at once (for reordering)
  Future<void> updateMultipleFields(
    List<CardFieldSetting> updatedFields,
  ) async {
    // Use assignAll to properly trigger RxList listeners
    _cardFields.assignAll(updatedFields);
    await _saveSettingsToLocal();
  }

  // Reorder fields
  Future<void> reorderFields(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final List<CardFieldSetting> reorderedFields = List.from(_cardFields);
    final item = reorderedFields.removeAt(oldIndex);
    reorderedFields.insert(newIndex, item);

    // Update order values
    for (int i = 0; i < reorderedFields.length; i++) {
      reorderedFields[i] = reorderedFields[i].copyWith(order: i + 1);
    }

    _cardFields.value = reorderedFields;
    await _saveSettingsToLocal();
  }

  // Save to storage (alias for _saveSettingsToLocal)
  Future<void> saveToStorage() async {
    await _saveSettingsToLocal();
  }

  // Reset to default settings
  Future<void> resetToDefaults() async {
    _cardFields.value = List.from(_defaultFields);
    await _saveSettingsToLocal();
  }

  // Export settings as JSON
  Map<String, dynamic> exportSettings() {
    return {
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'fields': _cardFields.map((field) => field.toJson()).toList(),
    };
  }

  // Import settings from JSON
  Future<void> importSettings(Map<String, dynamic> settings) async {
    try {
      if (settings['fields'] != null) {
        final List<dynamic> fieldsList = settings['fields'];
        _cardFields.value = fieldsList
            .map((json) => CardFieldSetting.fromJson(json))
            .toList();
        await _saveSettingsToLocal();
      }
    } catch (e) {
      print('❌ Failed to import settings: $e');
      rethrow;
    }
  }
}

class CardFieldSetting {
  final String id;
  final String name;
  final bool isVisible;
  final int order;

  const CardFieldSetting({
    required this.id,
    required this.name,
    required this.isVisible,
    required this.order,
  });

  CardFieldSetting copyWith({
    String? id,
    String? name,
    bool? isVisible,
    int? order,
  }) {
    return CardFieldSetting(
      id: id ?? this.id,
      name: name ?? this.name,
      isVisible: isVisible ?? this.isVisible,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'isVisible': isVisible, 'order': order};
  }

  factory CardFieldSetting.fromJson(Map<String, dynamic> json) {
    return CardFieldSetting(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      isVisible: json['isVisible'] ?? false,
      order: json['order'] ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CardFieldSetting &&
        other.id == id &&
        other.name == name &&
        other.isVisible == isVisible &&
        other.order == order;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ isVisible.hashCode ^ order.hashCode;
  }

  @override
  String toString() {
    return 'CardFieldSetting(id: $id, name: $name, isVisible: $isVisible, order: $order)';
  }
}
