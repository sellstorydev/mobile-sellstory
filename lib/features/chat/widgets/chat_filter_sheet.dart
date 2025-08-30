import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/user_picker_sheet.dart';
import '../widgets/hashtag_picker_sheet.dart';
import '../widgets/customer_picker_sheet.dart';

class ChatFilterResult {
  final Set<String> platforms;
  final String status;
  final List<String> hashtagIds;
  final String salesUid;
  final String customerId;
  final bool cleared;

  ChatFilterResult({
    required this.platforms,
    required this.status,
    required this.hashtagIds,
    required this.salesUid,
    required this.customerId,
    this.cleared = false,
  });
}

class ChatFilterSheet extends StatefulWidget {
  final String wsId;
  final Set<String> initialPlatforms;
  final String initialStatus;
  final List<String> initialHashtagIds;
  final String initialSalesUid;
  final String initialCustomerId;

  const ChatFilterSheet({
    Key? key,
    required this.wsId,
    required this.initialPlatforms,
    required this.initialStatus,
    required this.initialHashtagIds,
    required this.initialSalesUid,
    required this.initialCustomerId,
  }) : super(key: key);

  @override
  State<ChatFilterSheet> createState() => _ChatFilterSheetState();
}

class _ChatFilterSheetState extends State<ChatFilterSheet> {
  late Set<String> _platforms;
  late String _status;
  late List<String> _selectedHashtagIds;
  List<String> _selectedHashtagNames = const [];
  late String _salesUid;
  late String _customerId;

  String? _salesName;
  String? _customerName;

  @override
  void initState() {
    super.initState();
    _platforms = Set<String>.from(widget.initialPlatforms);
    _status = widget.initialStatus;
    _selectedHashtagIds = List<String>.from(widget.initialHashtagIds);
    _salesUid = widget.initialSalesUid;
    _customerId = widget.initialCustomerId;

    if (_salesUid.isNotEmpty) _loadUserName(_salesUid);
    if (_customerId.isNotEmpty) _loadCustomerName(_customerId);
    // Preload hashtag names for selected IDs so they show on reopen
    if (_selectedHashtagIds.isNotEmpty) {
      _preloadHashtagNames();
    }
  }


  Future<void> _loadUserName(String uid) async {
    try {
      final u = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final m = u.data() ?? {};
      setState(() {
        _salesName = (m['displayName'] ?? m['name'] ?? uid).toString();
      });
    } catch (_) {}
  }

  Future<void> _loadCustomerName(String cid) async {
    if (widget.wsId.isEmpty) return;
    try {
      final c = await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(widget.wsId)
          .collection('customers')
          .doc(cid)
          .get();
      final m = c.data() ?? {};
      setState(() {
        _customerName = (m['name'] ?? m['displayName'] ?? m['customerName'] ?? cid).toString();
      });
    } catch (_) {}
  }

  Future<void> _preloadHashtagNames() async {
    if (widget.wsId.isEmpty) return;
    try {
      final snap = await FirebaseFirestore.instance.collection('workspaces').doc(widget.wsId).get();
      final ws = snap.data() ?? {};
      final hs = (ws['hashtagSettings'] ?? ws['companyProfile']?['hashtagSettings']) as Map<String, dynamic>?;
      final masterRaw = hs?['masterList'];
      final List master = (masterRaw is List) ? masterRaw : const [];
      // Build id -> name map
      final Map<String, String> byId = {};
      for (final item in master) {
        if (item is Map) {
          final id = (item['id'] ?? '').toString();
          final name = (item['name'] ?? '').toString();
          if (id.isNotEmpty && name.isNotEmpty) {
            byId[id] = name.startsWith('#') ? name.substring(1) : name;
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _selectedHashtagNames = _selectedHashtagIds.map((id) => byId[id] ?? '').where((s) => s.isNotEmpty).toList();
      });
    } catch (_) {
      // Silent: keep names empty if master not available
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget platformCheckbox(String key, String label) {
      final checked = _platforms.contains(key);
      return CheckboxListTile(
        value: checked,
        onChanged: (v) {
          setState(() {
            if (v == true) {
              _platforms.add(key);
            } else {
              _platforms.remove(key);
            }
          });
        },
        title: Text(label),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
      );
    }

    Widget statusRadio(String value, String label) {
      return RadioListTile<String>(
        value: value,
        groupValue: _status,
        onChanged: (v) => setState(() => _status = v ?? ''),
        title: Text(label),
        contentPadding: EdgeInsets.zero,
      );
    }

    Widget pickerTile({
      required IconData icon,
      required String label,
      required String placeholder,
      String? value,
      VoidCallback? onTap,
    }) {
      return InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            isDense: true,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.black54),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  (value != null && value.isNotEmpty) ? value : placeholder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: (value != null && value.isNotEmpty) ? Colors.black87 : Colors.grey,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black45),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'ค้นหา',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Clear local selections and return cleared result
                      setState(() {
                        _platforms.clear();
                        _status = '';
                        _selectedHashtagIds = [];
                        _selectedHashtagNames = [];
                        _salesUid = '';
                        _salesName = null;
                        _customerId = '';
                        _customerName = null;
                      });
                      Navigator.pop(
                        context,
                        ChatFilterResult(
                          platforms: {},
                          status: '',
                          hashtagIds: const [],
                          salesUid: '',
                          customerId: '',
                          cleared: true,
                        ),
                      );
                    },
                    child: const Text('ล้างค่า'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              const Text('ช่องทาง', style: TextStyle(fontWeight: FontWeight.w700)),
              platformCheckbox('facebook', 'ช่องทาง Facebook'),
              platformCheckbox('instagram', 'ช่องทาง Instagram'),
              platformCheckbox('line', 'ช่องทาง LINE'),

              const SizedBox(height: 8),
              const Text('สถานะ', style: TextStyle(fontWeight: FontWeight.w700)),
              statusRadio('NEW', 'ใหม่'),
              statusRadio('IN_PROGRESS', 'กำลังดำเนินการ'),
              statusRadio('DONE', 'เสร็จสิ้น'),

              const SizedBox(height: 8),
              const Text('Hashtag', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              pickerTile(
                icon: Icons.tag,
                label: '',
                placeholder: 'เลือก Hashtag',
                value: _selectedHashtagNames.isNotEmpty ? _selectedHashtagNames.map((n) => '#$n').join(', ') : null,
                onTap: () async {
                  if (widget.wsId.isEmpty) return;
                  final result = await showModalBottomSheet<HashtagPickerResult>(
                    context: context,
                    useSafeArea: true,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (c) {
                      final h = MediaQuery.of(c).size.height;
                      return SizedBox(
                        height: h * 0.9,
                        child: HashtagPickerSheet(
                          workspaceId: widget.wsId,
                          initialIds: _selectedHashtagIds,
                          initialNames: _selectedHashtagNames,
                        ),
                      );
                    },
                  );
                  if (result != null) {
                    setState(() {
                      _selectedHashtagIds = result.ids;
                      _selectedHashtagNames = result.names;
                    });
                  }
                },
              ),

              const SizedBox(height: 12),
              const Text('เซล', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              pickerTile(
                icon: Icons.person_outline,
                label: '',
                placeholder: 'เลือกเซลผู้รับผิดชอบ',
                value: _salesName,
                onTap: () async {
                  if (widget.wsId.isEmpty) return;
                  final pickedUid = await showModalBottomSheet<String>(
                    context: context,
                    useSafeArea: true,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (c) {
                      final h = MediaQuery.of(c).size.height;
                      return SizedBox(height: h * 0.9, child: UserPickerSheet(workspaceId: widget.wsId));
                    },
                  );
                  if (pickedUid != null && pickedUid.isNotEmpty) {
                    await _loadUserName(pickedUid);
                    setState(() {
                      _salesUid = pickedUid;
                    });
                  }
                },
              ),

              const SizedBox(height: 12),
              const Text('ลูกค้า', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              pickerTile(
                icon: Icons.people_outline,
                label: '',
                placeholder: 'เลือกลูกค้า',
                value: _customerName,
                onTap: () async {
                  if (widget.wsId.isEmpty) return;
                  final pickedCustomerId = await showModalBottomSheet<String>(
                    context: context,
                    useSafeArea: true,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (c) {
                      final h = MediaQuery.of(c).size.height;
                      return SizedBox(height: h * 0.9, child: CustomerPickerSheet(workspaceId: widget.wsId));
                    },
                  );
                  if (pickedCustomerId != null && pickedCustomerId.isNotEmpty) {
                    await _loadCustomerName(pickedCustomerId);
                    setState(() {
                      _customerId = pickedCustomerId;
                    });
                  }
                },
              ),

              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      ChatFilterResult(
                        platforms: _platforms,
                        status: _status,
                        hashtagIds: _selectedHashtagIds,
                        salesUid: _salesUid,
                        customerId: _customerId,
                        cleared: false,
                      ),
                    );
                  },
                  child: const Text('ยืนยัน'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

