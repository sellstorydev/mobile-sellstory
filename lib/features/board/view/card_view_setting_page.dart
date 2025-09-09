import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sellstory/core/theme/app_theme.dart';
import '../../../core/services/card_view_settings_service.dart';

class CardViewSettingPage extends StatefulWidget {
  final String boardId;
  const CardViewSettingPage({super.key, required this.boardId});

  @override
  State<CardViewSettingPage> createState() => _CardViewSettingPageState();
}

class _CardViewSettingPageState extends State<CardViewSettingPage> {
  final CardViewSettingsService _settingsService = CardViewSettingsService.to;
  
  // Field mapping from service to display names
  static const Map<String, String> _fieldDisplayNames = {
    'jobId': 'Job ID',
    'status': 'Status', 
    'dateRange': 'Date Range',
    'createdDate': 'Created Date',
    'assignee': 'Assignee',
    'customerInterest': 'Customer Interest', 
    'collaborators': 'Collaborators',
    'customer': 'Customer',
    'company': 'Company',
    'hashtags': 'Hashtags',
    'priority': 'Priority',
    'grandTotal': 'Grand Total',
    'netTotal': 'Net Total',
    'totalBeforeDiscount': 'Total (before discount)',
    'totalAfterDiscount': 'Total (after discount)',
    'totalBeforeVAT': 'Total (before VAT)',
    'description': 'Description',
    'todoList': 'To-Do List',
  };

  late List<CardFieldSetting> _fields;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() async {
    setState(() { _loading = true; });
    try {
      print('📱 Loading card view settings...');
      print('Service initialized: ${_settingsService.isInitialized}');
      
      // Wait for service to be initialized if needed
      if (!_settingsService.isInitialized) {
        print('⏳ Waiting for service initialization...');
        // Give service some time to initialize
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // Load current fields from the service (service should already be initialized)
      _fields = List.from(_settingsService.cardFields);
      print('📱 Loaded ${_fields.length} fields from service');
      for (var field in _fields) {
        print('   ${field.name}: order=${field.order}, visible=${field.isVisible}');
      }
    } catch (e) {
      debugPrint('Load settings error: $e');
      _fields = [];
    }
    if (mounted) setState(() { _loading = false; });
  }

  void _saveSettings() async {
    if (_saving) return; 
    setState(() { _saving = true; });
    try {
      print('💾 Saving card view settings...');
      print('Fields to save:');
      for (var field in _fields) {
        print('   ${field.name}: order=${field.order}, visible=${field.isVisible}');
      }
      
      // Update the service with new field order and visibility
      await _settingsService.updateMultipleFields(_fields);
      
      print('✅ Settings saved successfully');
      
      if (!mounted) return; 
      Get.back(result: true);
      Get.snackbar('สำเร็จ', 'บันทึกการตั้งค่าการ์ดแล้ว', 
        snackPosition: SnackPosition.BOTTOM, 
        backgroundColor: Colors.green[100], 
        colorText: Colors.green[800]);
    } catch (e) {
      print('❌ Error saving settings: $e');
      if (mounted) {
        Get.snackbar('ผิดพลาด', 'บันทึกไม่สำเร็จ: $e', 
          snackPosition: SnackPosition.BOTTOM, 
          backgroundColor: Colors.red[100], 
          colorText: Colors.red[800]);
      }
    } finally {
      if (mounted) setState(() { _saving = false; });
    }
  }

  void _toggleFieldVisibility(int index) {
    setState(() { 
      _fields[index] = _fields[index].copyWith(isVisible: !_fields[index].isVisible);
    });
  }

  void _reorderFields(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _fields.removeAt(oldIndex);
      _fields.insert(newIndex, item);
      
      // Update order values
      for (int i = 0; i < _fields.length; i++) {
        _fields[i] = _fields[i].copyWith(order: i + 1); // Start from 1, not 0
      }
      
      print('🔄 Reordered fields: moved "${item.name}" from $oldIndex to $newIndex');
      for (var field in _fields) {
        print('   ${field.name}: order=${field.order}, visible=${field.isVisible}');
      }
    });
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
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ReorderableListView.builder(
                    itemCount: _fields.length,
                    onReorder: _reorderFields,
                    itemBuilder: (context, index) {
                  final field = _fields[index];
                  final displayName = _fieldDisplayNames[field.id] ?? field.name;
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
                        displayName,
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
              ),
          ),
          
          // Save Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _saving ? null : _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
        child: _saving
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}


