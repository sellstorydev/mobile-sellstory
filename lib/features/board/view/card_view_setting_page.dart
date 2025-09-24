import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sellstory/core/theme/app_theme.dart';
import '../../../core/services/card_view_settings_service.dart';
import '../../../data/services/mobile_permissions_service.dart';

class CardViewSettingPage extends StatefulWidget {
  final String boardId;
  const CardViewSettingPage({super.key, required this.boardId});

  @override
  State<CardViewSettingPage> createState() => _CardViewSettingPageState();
}

class _CardViewSettingPageState extends State<CardViewSettingPage> {
  final CardViewSettingsService _settingsService = CardViewSettingsService.to;
  bool get _canManageSettings => MobilePermissionsService.to.isOwner || MobilePermissionsService.to.can('settings:board:manage');

  // Field mapping from service to translation keys
  static const Map<String, String> _fieldDisplayKeys = {
    'jobId': 'field_job_id',
    'status': 'field_status', 
    'dateRange': 'field_date_range',
    'createdDate': 'field_created_date',
    'assignee': 'field_assignee',
    'customerInterest': 'field_customer_interest', 
    'collaborators': 'field_collaborators',
    'customer': 'field_customer',
    'company': 'field_company',
    'hashtags': 'field_hashtags',
    'grandTotal': 'field_grand_total',
    'netTotal': 'field_net_total',
    'totalBeforeDiscount': 'field_total_before_discount',
    'totalAfterDiscount': 'field_total_after_discount',
    'totalBeforeVAT': 'field_total_before_vat',
    'description': 'field_description',
    'todoList': 'field_todo_list',
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
      // Wait for service to be initialized if needed
      if (!_settingsService.isInitialized) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      _fields = List.from(_settingsService.cardFields);
    } catch (e) {
      debugPrint('❌ Load settings error: $e');
      _fields = [];
    }
    if (mounted) setState(() { _loading = false; });
  }

  void _saveSettings() async {
    if (_saving) return; 
    setState(() { _saving = true; });
    try {
      
      // Update the service with new field order and visibility
      await _settingsService.updateMultipleFields(_fields);
      
      if (!mounted) return; 
      Get.back(result: true);
      Get.snackbar('success'.tr, 'card_settings_saved_success'.tr, 
        snackPosition: SnackPosition.BOTTOM, 
        backgroundColor: Colors.green[100], 
        colorText: Colors.green[800]);
    } catch (e) {
      debugPrint('❌ Error saving settings: $e');
      if (mounted) {
        Get.snackbar('error'.tr, 'card_settings_save_failed'.trParams({'error': e.toString()}), 
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
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_canManageSettings) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black87,
          title: Text(
            'card_view_settings'.tr,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Get.back(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text('no_permission_card_settings'.tr, style: const TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 8),
              Text('need_card_settings_permission'.tr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  foregroundColor: Colors.white,
                ),
                child: Text('close'.tr),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: Text(
          'card_view_settings'.tr,
          style: const TextStyle(
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
            child: Text(
              'visible_card_fields'.tr,
              style: const TextStyle(
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
                  final displayKey = _fieldDisplayKeys[field.id];
                  final displayName = displayKey != null ? displayKey.tr : field.name;
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
          : Text('save'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
