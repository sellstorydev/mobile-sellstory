import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sellstory/core/theme/app_theme.dart';
import '../../../data/services/firebase_auth_service.dart';

class CardViewSettingPage extends StatefulWidget {
  final String boardId;
  const CardViewSettingPage({super.key, required this.boardId});

  @override
  State<CardViewSettingPage> createState() => _CardViewSettingPageState();
}

class _CardViewSettingPageState extends State<CardViewSettingPage> {
  // Keys definition must align with display side
  static const List<String> _allKeys = [
    'customId', 'status', 'dateRange', 'createdAt', 'assignee', 'customerInterest', 'collaborators',
    'customer', 'company', 'hashtags', 'grandTotal', 'netTotal', 'totalAmountBeforeDiscount',
    'totalAmountAfterDiscount', 'totalAmountBeforeVat', 'description', 'todos'
  ];

  late List<String> _order;
  late Map<String, bool> _visible;
  bool _loading = true;
  bool _saving = false;

  String get _uid => (Get.find<FirebaseAuthService>().currentUser?.uid) ?? '';

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() async {
    setState(() { _loading = true; });
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(_uid).get();
      final data = userDoc.data() ?? {};
      final viewSettings = (data['viewSettings'] ?? {}) as Map<String, dynamic>;
      final key = 'kanbanCardDisplayFieldsConfig_${widget.boardId}';
      final cfg = (viewSettings[key] ?? {}) as Map<String, dynamic>;
      if (cfg.isEmpty) {
        // default order = allKeys sequence
        _order = List.from(_allKeys);
        _visible = { for (final k in _allKeys) k : true };
      } else {
        final entries = <MapEntry<String, int>>[];
        cfg.forEach((k, v) {
          if (v is Map && _allKeys.contains(k)) {
            entries.add(MapEntry(k, (v['order'] ?? 999) as int));
          }
        });
        entries.sort((a,b)=>a.value.compareTo(b.value));
        _order = entries.map((e)=>e.key).toList();
        // Ensure all keys present
        for (final k in _allKeys) { if (!_order.contains(k)) _order.add(k); }
        _visible = { for (final k in _allKeys) k : (cfg[k]?['isVisible'] ?? true) == true };
      }
    } catch (e) {
      _order = List.from(_allKeys);
      _visible = { for (final k in _allKeys) k : true };
      debugPrint('Load settings error: $e');
    }
    if (mounted) setState(() { _loading = false; });
  }

  void _saveSettings() async {
    if (_saving) return; setState(() { _saving = true; });
    try {
      final cfg = <String, dynamic>{};
      for (var i = 0; i < _order.length; i++) {
        final k = _order[i];
        cfg[k] = { 'order': i, 'isVisible': _visible[k] ?? true, 'style': {} };
      }
      await FirebaseFirestore.instance.collection('users').doc(_uid).update({
        'viewSettings.kanbanCardDisplayFieldsConfig_${widget.boardId}': cfg,
      });
      if (!mounted) return; Get.back(result: true);
      Get.snackbar('สำเร็จ', 'บันทึกการตั้งค่าการ์ดแล้ว', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green[100], colorText: Colors.green[800]);
    } catch (e) {
      if (mounted) {
        Get.snackbar('ผิดพลาด', 'บันทึกไม่สำเร็จ: $e', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red[100], colorText: Colors.red[800]);
      }
    } finally {
      if (mounted) setState(() { _saving = false; });
    }
  }

  void _toggleFieldVisibility(int index) {
    final key = _order[index];
    setState(() { _visible[key] = !(_visible[key] ?? true); });
  }

  void _reorderFields(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _order.removeAt(oldIndex);
      _order.insert(newIndex, item);
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
            child: Obx(() {
              if (_loading) {
                return const Center(child: CircularProgressIndicator());
              }
              return ReorderableListView.builder(
                itemCount: _order.length,
                onReorder: _reorderFields,
                itemBuilder: (context, index) {
                  final key = _order[index];
                  final isVisible = _visible[key] ?? true;
                  return Container(
                    key: ValueKey(key),
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
                            value: isVisible,
                            onChanged: (value) => _toggleFieldVisibility(index),
                            activeColor: AppTheme.primaryOrange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      title: Text(
                        key,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isVisible ? Colors.black87 : Colors.grey[600],
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


