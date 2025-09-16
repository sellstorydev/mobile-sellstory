// filepath: /Users/sarawutpromdee/Documents/Sellstoory/mobile-sellstory/lib/features/chat/widgets/canned_responses_sheet.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/services/canned_responses_service.dart';
import '../../../models/canned_responses.dart';

class CannedResponsesSheet extends StatefulWidget {
  final String workspaceId;

  final void Function(String) onSendText;
  final void Function(String) onSendImage;

  const CannedResponsesSheet({super.key, required this.workspaceId, required this.onSendText, required this.onSendImage});

  @override
  State<CannedResponsesSheet> createState() => _CannedResponsesSheetState();
}

class _CannedResponsesSheetState extends State<CannedResponsesSheet> {
  final CannedResponsesService _service = Get.find<CannedResponsesService>();

  final TextEditingController _searchController = TextEditingController();

  var _loading = true;
  String? _error;
  List<CannedResponseGroup> _groups = [];



  // Multi-select state
  final List<CannedResponse> _selected = [];
  bool _sending = false;
  int _sendingIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }



  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final groups = await _service.fetchGroups(workspaceId: widget.workspaceId, search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim());
      setState(() {
        _groups = groups;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createGroup() async {
    final name = await _promptText(title: 'สร้างกลุ่มใหม่', label: 'ชื่อกลุ่ม');
    if (name == null || name.trim().isEmpty) return;
    try {
      final group = await _service.createGroup(workspaceId: widget.workspaceId, name: name.trim());
      setState(() => _groups = [..._groups, group]);
    } catch (e) {
      _showSnack('สร้างกลุ่มไม่สำเร็จ: $e');
    }
  }

  Future<void> _renameGroup(CannedResponseGroup group) async {
    final newName = await _promptText(title: 'แก้ไขชื่อกลุ่ม', label: 'ชื่อกลุ่ม', initial: group.name);
    if (newName == null || newName.trim().isEmpty) return;
    try {
      await _service.updateGroup(workspaceId: widget.workspaceId, groupId: group.id, name: newName.trim());
      setState(() => group.name = newName.trim());
    } catch (e) {
      _showSnack('อัปเดตกลุ่มไม่สำเร็จ: $e');
    }
  }

  Future<void> _deleteGroup(CannedResponseGroup group) async {
    final ok = await _confirm('ลบกลุ่มนี้และคำตอบทั้งหมดภายใน?');
    if (ok != true) return;
    try {
      await _service.deleteGroup(workspaceId: widget.workspaceId, groupId: group.id);
      setState(() => _groups = _groups.where((g) => g.id != group.id).toList());
    } catch (e) {
      _showSnack('ลบกลุ่มไม่สำเร็จ: $e');
    }
  }

  Future<void> _addResponse(CannedResponseGroup group) async {
    final title = await _promptText(title: 'เพิ่มคำตอบ (ข้อความ)', label: 'ชื่อหัวข้อ');
    if (title == null || title.trim().isEmpty) return;
    final text = await _promptText(title: 'ข้อความที่ตอบ', label: 'ข้อความ');
    if (text == null || text.trim().isEmpty) return;
    try {
      final resp = await _service.addResponse(
        workspaceId: widget.workspaceId,
        groupId: group.id,
        title: title.trim(),
        type: 'text',
        text: text.trim(),
      );
      setState(() => group.responses.add(resp));
    } catch (e) {
      _showSnack('เพิ่มคำตอบไม่สำเร็จ: $e');
    }
  }

  Future<void> _editResponse(CannedResponseGroup group, CannedResponse resp) async {
    final title = await _promptText(title: 'แก้ไขคำตอบ', label: 'ชื่อหัวข้อ', initial: resp.title);
    if (title == null || title.trim().isEmpty) return;
    String? text;
    if (resp.type == 'text') {
      text = await _promptText(title: 'แก้ไขข้อความ', label: 'ข้อความ', initial: resp.text ?? '');
      if (text == null || text.trim().isEmpty) return;
    }
    try {
      final updated = CannedResponse(
        id: resp.id,
        title: title.trim(),
        type: resp.type,
        text: resp.type == 'text' ? text!.trim() : resp.text,
        imageUrl: resp.imageUrl,
      );
      await _service.updateResponse(workspaceId: widget.workspaceId, groupId: group.id, response: updated);
      setState(() {
        resp.title = updated.title;
        resp.text = updated.text;
      });
    } catch (e) {
      _showSnack('อัปเดตคำตอบไม่สำเร็จ: $e');
    }
  }

  Future<void> _deleteResponse(CannedResponseGroup group, CannedResponse resp) async {
    final ok = await _confirm('ลบคำตอบนี้?');
    if (ok != true) return;
    try {
      await _service.deleteResponse(workspaceId: widget.workspaceId, groupId: group.id, responseId: resp.id);
      setState(() => group.responses.removeWhere((r) => r.id == resp.id));
      _selected.removeWhere((s) => s.id == resp.id);
    } catch (e) {
      _showSnack('ลบคำตอบไม่สำเร็จ: $e');
    }
  }

  // Selection helpers
  bool _isSelected(CannedResponse r) => _selected.any((s) => s.id == r.id);
  void _toggleSelect(CannedResponse r) {
    setState(() {
      final idx = _selected.indexWhere((s) => s.id == r.id);
      if (idx >= 0) {
        _selected.removeAt(idx);
      } else {
        _selected.add(r);
      }
    });
  }

  // Preview & send
  void _showPreviewDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ตัวอย่างก่อนส่ง', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ConstrainedBox(

                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
                child: ListView.separated(


                  shrinkWrap: true,
                  itemCount: _selected.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {


                    final r = _selected[i];
                    return ListTile(

                      leading: CircleAvatar(
                        backgroundColor:  Colors.white,
                        child: Icon(r.type == 'image' ? Icons.image_outlined : Icons.text_snippet_outlined, color: Colors.black87),
                      ),
                      title: Text(r.title.isEmpty ? '(ไม่มีชื่อ)' : r.title),
                      subtitle: r.type == 'text' ? Text(r.text ?? '', maxLines: 6) : Text(r.imageUrl ?? ''),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('ปิด'),
                    ),
                  ),


                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _sending ? null : () {
                        Navigator.pop(context);
                        _sendSelected();
                      },
                      icon: const Icon(Icons.send),
                      label: Text('ส่ง (${_selected.length})'),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendSelected() async {
    if (_selected.isEmpty || _sending) return;
    setState(() { _sending = true; _sendingIndex = 0; });
    try {
      for (var i = 0; i < _selected.length; i++) {
        final r = _selected[i];
        setState(() => _sendingIndex = i + 1);
        if (r.type == 'image' && (r.imageUrl ?? '').isNotEmpty) {
          widget.onSendImage(r.imageUrl!);
        } else if ((r.text ?? '').trim().isNotEmpty) {
          widget.onSendText(r.text!.trim());
        }
        await Future.delayed(const Duration(milliseconds: 180));
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _showSnack('ส่งไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() { _sending = false; _sendingIndex = 0; });
    }
  }

  Future<String?> _promptText({required String title, required String label, String? initial}) async {
    final controller = TextEditingController(text: initial ?? '');
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: label),
            autofocus: true,
            maxLines: null,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr)),
            FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: Text('save'.tr)),
          ],
        );
      },
    );
  }

  Future<bool?> _confirm(String message) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('confirm'.tr),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('cancel'.tr)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text('ok'.tr)),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomInset = mq.viewInsets.bottom; // keyboard
    final screenH = mq.size.height;
    final desired = screenH * 0.85;
    final sheetHeight = (desired - bottomInset).clamp(240.0, screenH);

    return SafeArea(

      child: SizedBox(
        height: sheetHeight,
        child: Column(
          children: [
            const SizedBox(height: 6),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: CustomScrollView(

                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          const Expanded(child: Text('คำตอบที่ใช้บ่อย', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                          IconButton(
                            tooltip: 'รีโหลด',
                            onPressed: _load,
                            icon: const Icon(Icons.refresh),
                          ),
                          FilledButton.icon(onPressed: _createGroup, icon: const Icon(Icons.add), label: const Text('สร้างกลุ่ม')),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'ค้นหา...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _load();
                            },
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF1F2F4),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                        onSubmitted: (_) => _load(),
                      ),
                    ),
                  ),
                  if (_loading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _ErrorRetry(message: _error!, onRetry: _load),
                    )
                  else if (_groups.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: Text('ไม่พบรายการ')),
                      )
                    else
                      SliverList.builder(
                        itemCount: _groups.length,
                        itemBuilder: (ctx, i) {
                          final g = _groups[i];
                          return _GroupTile(
                            group: g,
                            isSelected: _isSelected,
                            onToggleSelect: _toggleSelect,
                            onRename: () => _renameGroup(g),
                            onDelete: () => _deleteGroup(g),
                            onAddResponse: () => _addResponse(g),
                            onEditResponse: (r) => _editResponse(g, r),
                            onDeleteResponse: (r) => _deleteResponse(g, r),
                          );
                        },
                      ),
                ],
              ),
            ),

            if (_selected.isNotEmpty)
              Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2)),
                    ],
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child:         Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      Text('${_selected.length} รายการ', style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _sending ? null : () => setState(() => _selected.clear()),
                        icon: const Icon(Icons.clear_all),
                        label: const Text('ล้าง'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(

                        onPressed: _sending ? null : _showPreviewDialog,
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('ตัวอย่าง'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _sending ? null : _sendSelected,
                        icon: _sending ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send),
                        label: Text(_sending ? 'กำลังส่ง ${_sendingIndex}/${_selected.length}' : 'ส่ง (${_selected.length})'),
                      ),
                    ],
                  )
              ),
          ],
        ),
      ),
    );
  }
}


class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          FilledButton(onPressed: onRetry, child: const Text('ลองใหม่')),
        ],
      ),
    );
  }
}

class _GroupTile extends StatefulWidget {
  final CannedResponseGroup group;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onAddResponse;
  final bool Function(CannedResponse) isSelected;
  final void Function(CannedResponse) onToggleSelect;
  final void Function(CannedResponse) onEditResponse;
  final void Function(CannedResponse) onDeleteResponse;
  const _GroupTile({required this.group, required this.onRename, required this.onDelete, required this.onAddResponse, required this.isSelected, required this.onToggleSelect, required this.onEditResponse, required this.onDeleteResponse});

  @override
  State<_GroupTile> createState() => _GroupTileState();
}

class _GroupTileState extends State<_GroupTile> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        initiallyExpanded: _expanded,
        onExpansionChanged: (v) => setState(() => _expanded = v),
        title: Text(g.name.isEmpty ? '(ไม่มีชื่อกลุ่ม)' : g.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(tooltip: 'เพิ่มคำตอบ', icon: const Icon(Icons.add_comment_outlined), onPressed: widget.onAddResponse),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'rename') widget.onRename();
                if (v == 'delete') widget.onDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'rename', child: Text('เปลี่ยนชื่อกลุ่ม')),
                PopupMenuItem(value: 'delete', child: Text('ลบกลุ่ม')),
              ],
            )
          ],
        ),
        children: [
          if (g.responses.isEmpty)
            const ListTile(title: Text('— ยังไม่มีคำตอบ —'))
          else
            ...g.responses.map((r) {
              final selected = widget.isSelected(r);
              return ListTile(
                tileColor: selected ? const Color(0xFFFFF7E6) : null,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFF1F2F4),
                  child: Icon(r.type == 'image' ? Icons.image_outlined : Icons.text_snippet_outlined, color: Colors.black87),
                ),
                title: Text(r.title.isEmpty ? '(ไม่มีชื่อ)' : r.title),
                subtitle: r.type == 'text' && (r.text ?? '').isNotEmpty ? Text(r.text!, maxLines: 2, overflow: TextOverflow.ellipsis) : null,
                onTap: () => widget.onToggleSelect(r),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: selected,
                      onChanged: (_) => widget.onToggleSelect(r),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit') widget.onEditResponse(r);
                        if (v == 'delete') widget.onDeleteResponse(r);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('แก้ไข')),
                        PopupMenuItem(value: 'delete', child: Text('ลบ')),
                      ],
                    ),
                  ],
                ),
              );
            })
        ],
      ),
    );
  }
}

class _SelectedPreviewChip extends StatelessWidget {
  final CannedResponse response;
  final VoidCallback onRemove;
  const _SelectedPreviewChip({required this.response, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final isImage = response.type == 'image' && (response.imageUrl ?? '').isNotEmpty;
    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F2F4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(isImage ? Icons.image_outlined : Icons.text_snippet_outlined, color: Colors.black87),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(response.title.isEmpty ? '(ไม่มีชื่อ)' : response.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(isImage ? (response.imageUrl ?? '') : (response.text ?? ''), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black87)),
              ],
            ),
          ),
          const SizedBox(width: 4),
          InkWell(onTap: onRemove, child: const Icon(Icons.close, size: 18)),
        ],
      ),
    );
  }
}
