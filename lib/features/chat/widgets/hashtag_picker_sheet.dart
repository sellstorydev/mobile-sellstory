import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HashtagPickerResult {
  final List<String> ids;
  final List<String> names; // raw names without '#'
  HashtagPickerResult({required this.ids, required this.names});
}


class HashtagPickerSheet extends StatefulWidget {
  final String workspaceId;
  final List<String> initialIds;
  final List<String> initialNames; // may include '#'

  const HashtagPickerSheet({
    Key? key,
    required this.workspaceId,
    this.initialIds = const [],
    this.initialNames = const [],
  }) : super(key: key);

  @override
  State<HashtagPickerSheet> createState() => _HashtagPickerSheetState();
}

class _HashtagPickerSheetState extends State<HashtagPickerSheet> {
  bool _loading = true;
  String _error = '';
  List<_TagItem> _all = [];
  final Set<String> _selectedIds = {};
  String _query = '';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(widget.workspaceId)
          .get();
      final data = snap.data() ?? {};

      // Safely coerce hashtagSettings from root or companyProfile.hashtagSettings
      Map<String, dynamic> hs = const {};
      final rawRoot = data['hashtagSettings'];
      if (rawRoot is Map) {
        hs = Map<String, dynamic>.from(rawRoot);
      } else {
        final cp = data['companyProfile'];
        if (cp is Map) {
          final cpMap = Map<String, dynamic>.from(cp);
          final rawCpHs = cpMap['hashtagSettings'];
          if (rawCpHs is Map) {
            hs = Map<String, dynamic>.from(rawCpHs);
          }
        }
      }


      final enabled = (hs['isEnabled'] == true);

      // Safely read masterList as List
      final dynamic ml = hs['masterList'];
      final List<dynamic> rawList = (ml is List) ? ml : const [];

      final items = <_TagItem>[];
      for (final dynamic e in rawList) {
        if (e is Map) {
          final m = Map<String, dynamic>.from(e);
          final id = (m['id'] ?? '').toString();
          final name = (m['name'] ?? '').toString();
          final color = (m['color'] ?? '').toString();
          final enabledItem = m['enabled'] != false;

          // scopes may be missing or any map type
          Map<String, dynamic> scopes = const {};
          final s = m['scopes'];
          if (s is Map) {
            scopes = Map<String, dynamic>.from(s);
          }
          final allowChat = scopes.isEmpty || (scopes['chat'] == true);

          if (id.isEmpty || name.isEmpty) continue;
          if (!enabledItem || !allowChat) continue;
          items.add(_TagItem(id: id, name: name, colorHex: color));
        }
      }

      // Sort by name for stable UX
      items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      // initialize selection
      _selectedIds
        ..clear()
        ..addAll(widget.initialIds)
        ..addAll(items.where((t) => widget.initialNames
            .map((n) => n.toString().replaceFirst('#', '').trim().toLowerCase())
            .contains(t.name.toLowerCase()))
            .map((t) => t.id));

      setState(() {
        _all = enabled ? items : <_TagItem>[];
        _loading = false;
      });

    } catch (e) {
      // ignore: avoid_print
      print('HashtagPickerSheet fetch error: $e');
      setState(() { _error = 'โหลดรายการไม่สำเร็จ'; _loading = false; });
    }
  }

  List<_TagItem> get _filtered {
    if (_query.trim().isEmpty) return _all;
    final q = _query.toLowerCase();
    return _all.where((t) => t.name.toLowerCase().contains(q) || t.id.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            height: 4,
            width: 48,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(999)),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: const [
                Icon(Icons.tag, color: Colors.black87),
                SizedBox(width: 8),
                Text('เลือก Hashtag', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ค้นหา hashtag...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                    ? Center(child: Text(_error))
                    : _all.isEmpty
                        ? const Center(child: Text('ไม่มีรายการ hashtag'))
                        : ListView.builder(
                            itemCount: _filtered.length,
                            itemBuilder: (ctx, i) {
                              final t = _filtered[i];
                              final selected = _selectedIds.contains(t.id);
                              return CheckboxListTile(
                                value: selected,
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true) {
                                      _selectedIds.add(t.id);
                                    } else {
                                      _selectedIds.remove(t.id);
                                    }
                                  });
                                },
                                title: Row(
                                  children: [
                                    _ColorDot(hex: t.colorHex),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('#${t.name}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('ยกเลิก'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final ids = _selectedIds.toList();
                      final names = _all.where((t) => _selectedIds.contains(t.id)).map((t) => t.name).toList();
                      Navigator.pop(context, HashtagPickerResult(ids: ids, names: names));
                    },
                    child: const Text('บันทึก'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TagItem {
  final String id;
  final String name;
  final String colorHex;
  _TagItem({required this.id, required this.name, required this.colorHex});
}

class _ColorDot extends StatelessWidget {
  final String hex;
  const _ColorDot({Key? key, required this.hex}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color c = Colors.grey;
    try {
      if (hex.startsWith('#') && (hex.length == 7 || hex.length == 9)) {
        final clean = hex.substring(1);
        int value = int.parse(clean, radix: 16);
        if (clean.length == 6) {
          c = Color(0xFF000000 | value);
        } else if (clean.length == 8) {
          c = Color(value);
        }
      }
    } catch (_) {}
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1)),
    );
  }
}
