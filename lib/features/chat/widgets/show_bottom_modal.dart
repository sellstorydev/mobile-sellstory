// show_bottom_modal.dart
import 'package:flutter/material.dart';

const _accent = Color(0xFFFF7A00); // โทมส้มตามภาพ

enum ChatStatus { autoReply, inProgress, done }
class ShowBottomModal {
  static Future<void> open(
      BuildContext context, {
        ChatStatus current = ChatStatus.inProgress,
        bool pinned = false,
        List<String> assignOptions = const [],
        String? selectedAssign,
        required ValueChanged<ChatStatus> onStatusChange,
        ValueChanged<bool>? onPinChanged,
        ValueChanged<String?>? onAssignChanged,
        VoidCallback? onNote,
        VoidCallback? onAddSale,
        VoidCallback? onRename,
        VoidCallback? onResetName,
        VoidCallback? onDelete,
      }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ChatMoreSheet(
        current: current,
        pinned: pinned,
        assignOptions: assignOptions,
        selectedAssign: selectedAssign,
        onStatusChange: onStatusChange,
        onPinChanged: onPinChanged,
        onAssignChanged: onAssignChanged,
        onNote: onNote,
        onAddSale: onAddSale,
        onRename: onRename,
        onResetName: onResetName,
        onDelete: onDelete,
      ),
    );
  }
}

class _ChatMoreSheet extends StatefulWidget {
  final ChatStatus current;
  final bool pinned;
  final List<String> assignOptions;
  final String? selectedAssign;

  final ValueChanged<ChatStatus> onStatusChange;
  final ValueChanged<bool>? onPinChanged;
  final ValueChanged<String?>? onAssignChanged;

  final VoidCallback? onNote;
  final VoidCallback? onAddSale;
  final VoidCallback? onRename;
  final VoidCallback? onResetName;
  final VoidCallback? onDelete;

  const _ChatMoreSheet({
    Key? key,
    required this.current,
    required this.pinned,
    required this.assignOptions,
    required this.selectedAssign,
    required this.onStatusChange,
    this.onPinChanged,
    this.onAssignChanged,
    this.onNote,
    this.onAddSale,
    this.onRename,
    this.onResetName,
    this.onDelete,
  }) : super(key: key);

  @override
  State<_ChatMoreSheet> createState() => _ChatMoreSheetState();
}

class _ChatMoreSheetState extends State<_ChatMoreSheet> {
  late ChatStatus _status;
  late bool _pinned;
  String? _assign;

  @override
  void initState() {
    super.initState();
    _status = widget.current;
    _pinned = widget.pinned;
    _assign = widget.selectedAssign;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // จุดส้มตกแต่งซ้ายบนเหมือนภาพ
                Container(
                  width: 6, height: 22,
                  margin: const EdgeInsets.only(top: 6, right: 10),
                  decoration: BoxDecoration(
                    color: _accent, borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('เมนูเพิ่มเติม',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          )),
                      const SizedBox(height: 6),
                      Text('เปลี่ยนสถานะห้องแชท',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.black54,
                          )),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatusButton(
                  icon: Icons.smart_toy_outlined,
                  label: 'ตอบกลับ\nอัตโนมัติ',
                  selected: _status == ChatStatus.autoReply,
                  onTap: () {
                    setState(() => _status = ChatStatus.autoReply);
                    widget.onStatusChange(_status);
                  },
                ),
                _StatusButton(
                  icon: Icons.chat_bubble,
                  label: 'กำลัง\nดำเนินการ',
                  selected: _status == ChatStatus.inProgress,
                  onTap: () {
                    setState(() => _status = ChatStatus.inProgress);
                    widget.onStatusChange(_status);
                  },
                ),
                _StatusButton(
                  icon: Icons.check,
                  label: 'สำเร็จ',
                  selected: _status == ChatStatus.done,
                  onTap: () {
                    setState(() => _status = ChatStatus.done);
                    widget.onStatusChange(_status);
                  },
                ),
                _StatusButton(
                  icon: Icons.push_pin_outlined,
                  label: 'ปักหมุด',
                  selected: _pinned,
                  // ปักหมุดเป็น toggle แยก
                  onTap: () {
                    setState(() => _pinned = !_pinned);
                    widget.onPinChanged?.call(_pinned);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Dropdown "กรุณาเลือก"
            if (widget.assignOptions.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _assign,
                items: widget.assignOptions
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) {
                  setState(() => _assign = v);
                  widget.onAssignChanged?.call(v);
                },
                decoration: InputDecoration(
                  hintText: 'กรุณาเลือก',
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  isDense: true,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            if (widget.assignOptions.isNotEmpty) const SizedBox(height: 8),

            // เมนูรายการ
            const Divider(height: 24),
            _MenuTile(
              icon: Icons.sticky_note_2_outlined,
              text: 'โน้ต',
              onTap: widget.onNote,
            ),
            _MenuTile(
              icon: Icons.badge_outlined,
              text: 'เพิ่มเซล',
              onTap: widget.onAddSale,
            ),
            _MenuTile(
              icon: Icons.edit_outlined,
              text: 'เปลี่ยนชื่อแชท',
              onTap: widget.onRename,
            ),
            _MenuTile(
              icon: Icons.refresh_outlined,
              text: 'รีเซ็ตชื่อแชท',
              onTap: widget.onResetName,
            ),
            _MenuTile(
              icon: Icons.delete_outline,
              text: 'ลบแชท',
              danger: true,
              onTap: widget.onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bg = selected ? _accent.withValues(alpha: 0.1) : const Color(0xFFF3F4F6);
    final ic = selected ? _accent : Colors.black54;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? _accent : Colors.black12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: ic),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.15,
                color: ic,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Opacity(
              opacity: selected ? 1 : 0,
              child: Icon(Icons.check_circle, size: 16, color: _accent),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool danger;
  final VoidCallback? onTap;

  const _MenuTile({
    Key? key,
    required this.icon,
    required this.text,
    this.danger = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.red.shade700 : Colors.black87;
    return Column(
      children: [
        ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: Icon(icon, color: danger ? Colors.red.shade400 : Colors.black54),
          title: Text(text, style: TextStyle(color: color, fontSize: 15)),
          onTap: () {
            Navigator.pop(context);
            onTap?.call();
          },
        ),
        const Divider(height: 1),
      ],
    );
  }
}
