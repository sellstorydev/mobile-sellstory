import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class JobCardPickerResult {
  final String cardId;
  final String title;
  final String boardId;
  final String laneId;
  final String docNo; // prefer customId then title
  JobCardPickerResult({
    required this.cardId,
    required this.title,
    required this.boardId,
    required this.laneId,
    required this.docNo,
  });
}

class JobCardPickerSheet extends StatefulWidget {
  final String workspaceId;
  final String? customerId; // optional filter by customer
  final List<String>? preselectedIds;
  final bool multiSelect;
  const JobCardPickerSheet({super.key, required this.workspaceId, this.customerId, this.preselectedIds, this.multiSelect = false});

  @override
  State<JobCardPickerSheet> createState() => _JobCardPickerSheetState();
}

class _JobCardPickerSheetState extends State<JobCardPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _loading = true;
  String _error = '';
  List<_CardRow> _cards = [];
  List<_CardRow> _visible = [];
  Set<String> _selectedCardIds = {};
  Map<String, String> _selectedCardTitles = {};
  Map<String, String> _selectedCardDocNos = {}; // id -> docNo

  @override
  void initState() {
    super.initState();
    if (widget.preselectedIds != null) {
      _selectedCardIds = Set<String>.from(widget.preselectedIds!);
    }
    _refresh();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_applyFilter);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() { _loading = true; _error = ''; });
    try {
      Query<Map<String, dynamic>> q = FirebaseFirestore.instance
          .collection('workspaces')
          .doc(widget.workspaceId)
          .collection('cards');
      if (widget.customerId != null && widget.customerId!.isNotEmpty) {
        q = q.where('customerId', isEqualTo: widget.customerId);
      }
      // Limit to avoid huge lists; can be increased or paginated later
      final qs = await q.limit(200).get();
      final rows = qs.docs.map((d) {
        final m = d.data();
        final title = (m['title'] ?? m['name'] ?? d.id).toString();
        final docNo = (m['customId'] ?? title).toString();
        return _CardRow(
          id: d.id,
          title: title,
          docNo: docNo,
          boardId: (m['boardId'] ?? '').toString(),
          laneId: (m['laneId'] ?? m['lane_id'] ?? '').toString(),
        );
      }).toList();
      rows.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      if (!mounted) return;
      setState(() {
        _cards = rows;
        _visible = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = '$e'; });
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() { _visible = List<_CardRow>.from(_cards); });
      return;
    }
    setState(() {
      _visible = _cards.where((c) {
        final t = c.title.toLowerCase();
        // allow filtering by docNo as well
        final n = c.docNo.toLowerCase();
        return t.contains(q) || c.id.toLowerCase().contains(q) || n.contains(q);
      }).toList();
    });
  }

  void _toggle(String id, String title, String docNo) {
    if (widget.multiSelect) {
      setState(() {
        if (_selectedCardIds.contains(id)) {
          _selectedCardIds.remove(id);
          _selectedCardTitles.remove(id);
          _selectedCardDocNos.remove(id);
        } else {
          _selectedCardIds.add(id);
          _selectedCardTitles[id] = title;
          _selectedCardDocNos[id] = docNo;
        }
      });
    } else {
      final row = _cards.firstWhere((e) => e.id == id, orElse: () => _CardRow(id: id, title: title, docNo: docNo, boardId: '', laneId: ''));
      Navigator.pop(context, [JobCardPickerResult(cardId: id, title: title, boardId: row.boardId, laneId: row.laneId, docNo: row.docNo)]);
    }
  }

  void _confirm() {
    final results = _selectedCardIds.map((id) {
      final row = _cards.firstWhere((e) => e.id == id, orElse: () => _CardRow(id: id, title: _selectedCardTitles[id] ?? id, docNo: _selectedCardDocNos[id] ?? (_selectedCardTitles[id] ?? id), boardId: '', laneId: ''));
      return JobCardPickerResult(
        cardId: id,
        title: _selectedCardTitles[id] ?? row.title,
        boardId: row.boardId,
        laneId: row.laneId,
        docNo: _selectedCardDocNos[id] ?? row.docNo,
      );
    }).toList();
    Navigator.pop(context, results);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ผู้ก Job Card'),
        actions: widget.multiSelect
            ? [
                TextButton(
                  onPressed: _selectedCardIds.isNotEmpty ? _confirm : null,
                  child: Text('เลือก (${_selectedCardIds.length})', style: const TextStyle(color: Colors.white)),
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'ค้นหา Job Card...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error.isNotEmpty)
              Expanded(
                child: Center(
                  child: Text('เกิดข้อผิดพลาดในการโหลด: $_error'),
                ),
              )
            else if (_visible.isEmpty)
              const Expanded(child: Center(child: Text('ไม่พบ Job Card')))
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _visible.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final c = _visible[index];
                    final selected = _selectedCardIds.contains(c.id);
                    return ListTile(
                      title: Text(c.title),
                      subtitle: Text(c.docNo),
                      leading: widget.multiSelect
                          ? Checkbox(
                              value: selected,
                              onChanged: (_) => _toggle(c.id, c.title, c.docNo),
                            )
                          : null,
                      onTap: () => _toggle(c.id, c.title, c.docNo),
                      selected: selected,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CardRow {
  final String id;
  final String title;
  final String docNo;
  final String boardId;
  final String laneId;
  _CardRow({required this.id, required this.title, required this.docNo, required this.boardId, required this.laneId});
}
