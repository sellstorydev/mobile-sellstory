import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class JobCardPickerResult {
  final String cardId;
  final String title;
  final String boardId;
  final String laneId;
  JobCardPickerResult({
    required this.cardId,
    required this.title,
    required this.boardId,
    required this.laneId,
  });
}

class JobCardPickerSheet extends StatefulWidget {
  final String workspaceId;
  const JobCardPickerSheet({super.key, required this.workspaceId});

  @override
  State<JobCardPickerSheet> createState() => _JobCardPickerSheetState();
}

class _JobCardPickerSheetState extends State<JobCardPickerSheet> {
  String? _selectedBoardId;
  String? _selectedBoardName;
  String? _selectedLaneId;
  String? _selectedLaneName;

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _loadBoards() async {
    final qs = await FirebaseFirestore.instance
        .collection('workspaces')
        .doc(widget.workspaceId)
        .collection('boards')
        .orderBy('name')
        .get();
    return qs.docs;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _loadLanes(String boardId) async {
    final qs = await FirebaseFirestore.instance
        .collection('workspaces')
        .doc(widget.workspaceId)
        .collection('lanes')
        .where('boardId', isEqualTo: boardId)
        .orderBy('order')
        .get();
    return qs.docs;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _loadCards(String boardId, String laneId) async {
    final qs = await FirebaseFirestore.instance
        .collection('workspaces')
        .doc(widget.workspaceId)
        .collection('cards')
        .where('boardId', isEqualTo: boardId)
        .where('laneId', isEqualTo: laneId)
        .orderBy('order')
        .get();
    return qs.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ผูก Job Card'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBreadcrumb(),
              const Divider(height: 1),
              Expanded(
                child: _selectedBoardId == null
                    ? _BoardsList(onPick: (id, name) {
                        setState(() {
                          _selectedBoardId = id;
                          _selectedBoardName = name;
                        });
                      }, loadBoards: _loadBoards)
                    : _selectedLaneId == null
                        ? _LanesList(
                            boardId: _selectedBoardId!,
                            onPick: (id, name) {
                              setState(() {
                                _selectedLaneId = id;
                                _selectedLaneName = name;
                              });
                            },
                            loadLanes: _loadLanes,
                          )
                        : _CardsList(
                            boardId: _selectedBoardId!,
                            laneId: _selectedLaneId!,
                            onPick: (id, title) {
                              Navigator.pop(
                                context,
                                JobCardPickerResult(
                                  cardId: id,
                                  title: title,
                                  boardId: _selectedBoardId!,
                                  laneId: _selectedLaneId!,
                                ),
                              );
                            },
                            loadCards: _loadCards,
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumb() {
    final items = <Widget>[];
    void add(String label, {VoidCallback? onTap}) {
      items.add(GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: TextStyle(color: onTap != null ? Colors.blue : Colors.black87, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              if (onTap != null) const Icon(Icons.chevron_right, size: 18, color: Colors.blue),
            ],
          ),
        ),
      ));
    }

    add('Boards', onTap: () => setState(() {
          _selectedBoardId = null;
          _selectedLaneId = null;
        }));
    if (_selectedBoardId != null) {
      add(_selectedBoardName ?? 'Board');
    }
    if (_selectedLaneId != null) {
      items.add(const Icon(Icons.chevron_right, size: 18, color: Colors.black38));
      items.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Text(_selectedLaneName ?? 'Lane', style: const TextStyle(fontWeight: FontWeight.w600)),
      ));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(children: items),
    );
  }
}

class _BoardsList extends StatelessWidget {
  final Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> Function() loadBoards;
  final void Function(String id, String name) onPick;
  const _BoardsList({required this.loadBoards, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      future: loadBoards(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('ไม่พบบอร์ดในเวิร์กสเปซ'));
        }
        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final d = docs[index];
            final m = d.data();
            final name = (m['name'] ?? 'Board').toString();
            return ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: Text(name),
              onTap: () => onPick(d.id, name),
            );
          },
        );
      },
    );
  }
}

class _LanesList extends StatelessWidget {
  final String boardId;
  final Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> Function(String boardId) loadLanes;
  final void Function(String id, String name) onPick;
  const _LanesList({required this.boardId, required this.loadLanes, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      future: loadLanes(boardId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('ไม่มีเลนในบอร์ดนี้'));
        }
        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final d = docs[index];
            final m = d.data();
            final name = (m['name'] ?? 'Lane').toString();
            return ListTile(
              leading: const Icon(Icons.view_column_outlined),
              title: Text(name),
              onTap: () => onPick(d.id, name),
            );
          },
        );
      },
    );
  }
}

class _CardsList extends StatelessWidget {
  final String boardId;
  final String laneId;
  final Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> Function(String boardId, String laneId) loadCards;
  final void Function(String id, String title) onPick;
  const _CardsList({required this.boardId, required this.laneId, required this.loadCards, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      future: loadCards(boardId, laneId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('ไม่มีการ์ดในเลนนี้'));
        }
        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final d = docs[index];
            final m = d.data();
            final title = (m['title'] ?? m['name'] ?? 'Card').toString();
            final subtitle = (m['customId'] ?? m['status'] ?? '').toString();
            return ListTile(
              leading: const Icon(Icons.style_outlined),
              title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: subtitle.isNotEmpty ? Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
              onTap: () => onPick(d.id, title),
            );
          },
        );

      },
    );
  }
}

