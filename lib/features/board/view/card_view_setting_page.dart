import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sellstory/core/theme/app_theme.dart';
import 'package:sellstory/core/services/card_view_settings_service.dart';

class CardViewSettingPage extends StatefulWidget {
  const CardViewSettingPage({super.key});

  @override
  State<CardViewSettingPage> createState() => _CardViewSettingPageState();
}

class _CardViewSettingPageState extends State<CardViewSettingPage> {
  final CardViewSettingsService _settingsService = Get.find<CardViewSettingsService>();
  
  // Get available fields from service
  List<CardFieldSetting> get _availableFields => _settingsService.cardFields;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    // Load current settings from user preferences or workspace settings
    // This would typically come from the user's viewSettings in Firestore
    // For now, we'll use the default values defined above
  }

  void _saveSettings() async {
    try {
      // Save settings to local storage via service
      await _settingsService.updateMultipleFields(_availableFields);
      
      Get.snackbar(
        'Success',
        'Card view settings saved successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[800],
      );
      
      Get.back(); // Return to previous page
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save settings: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    }
  }

  void _toggleFieldVisibility(int index) {
    final field = _availableFields[index];
    _settingsService.updateFieldVisibility(field.id, !field.isVisible);
  }

  void _reorderFields(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final List<CardFieldSetting> reorderedFields = List.from(_availableFields);
    final item = reorderedFields.removeAt(oldIndex);
    reorderedFields.insert(newIndex, item);
    
    // Update order values
    for (int i = 0; i < reorderedFields.length; i++) {
      reorderedFields[i] = reorderedFields[i].copyWith(order: i + 1);
    }
    
    _settingsService.updateMultipleFields(reorderedFields);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text(
          'Card View Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Visible Card Fields',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          
          // Fields List
          Expanded(
            child: Obx(() {
              final fields = _settingsService.cardFields;
              if (fields.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              
              return ReorderableListView.builder(
                itemCount: fields.length,
                onReorder: _reorderFields,
                itemBuilder: (context, index) {
                  final field = fields[index];
                  return Container(
                    key: ValueKey(field.id),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Drag Handle
                          Icon(
                            Icons.drag_handle,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                          const SizedBox(width: 16),
                          // Checkbox
                          Checkbox(
                            value: field.isVisible,
                            onChanged: (value) => _toggleFieldVisibility(index),
                            activeColor: AppTheme.primaryOrange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      title: Text(
                        field.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: field.isVisible ? Colors.black87 : Colors.grey[600],
                        ),
                      ),
                      trailing: Icon(
                        Icons.push_pin,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          
          // Save Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Save',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


