import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerItem {
  final String id;
  final String name;
  final String? customId;
  final String? company;
  CustomerItem({required this.id, required this.name, this.customId, this.company});
}

class CustomerPickerSheet extends StatefulWidget {
  final String workspaceId;
  const CustomerPickerSheet({super.key, required this.workspaceId});

  @override
  State<CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<CustomerPickerSheet> {
  late Future<List<CustomerItem>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _loadCustomers();
  }

  Future<List<CustomerItem>> _loadCustomers() async {
    final qs = await FirebaseFirestore.instance
        .collection('workspaces')
        .doc(widget.workspaceId)
        .collection('customers')
        .limit(500)
        .get();
    final list = qs.docs.map((d) {
      final m = d.data();
      final name = (m['name'] ?? m['displayName'] ?? m['customerName'] ?? '').toString();
      final customId = m['customId']?.toString();
      String? company;
      final companies = (m['companyNames'] as List?)?.cast<Map?>();
      if (companies != null && companies.isNotEmpty) {
        final first = companies.first as Map?;
        final firstMap = first as Map<String, dynamic>?;
        company = firstMap?['value']?.toString();
      }
      return CustomerItem(id: d.id, name: name.isEmpty ? '(ไม่มีชื่อ)' : name, customId: customId, company: company);
    }).toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เลือกลูกค้า')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'ค้นหาชื่อลูกค้า / รหัสลูกค้า',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<CustomerItem>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = (snap.data ?? []);
                if (list.isEmpty) {
                  return const Center(child: Text('ไม่พบบัญชีลูกค้าในเวิร์กสเปซ'));
                }
                final q = _query.toLowerCase();
                final filtered = q.isEmpty
                    ? list
                    : list.where((c) {
                        return c.name.toLowerCase().contains(q) ||
                               (c.customId?.toLowerCase().contains(q) ?? false) ||
                               (c.company?.toLowerCase().contains(q) ?? false);
                      }).toList();
                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final c = filtered[index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                      title: Text(c.name),
                      subtitle: Text([
                        if (c.customId != null && c.customId!.isNotEmpty) 'ID: ${c.customId}',
                        if (c.company != null && c.company!.isNotEmpty) 'บริษัท: ${c.company}',
                      ].join('  ')),
                      onTap: () => Navigator.pop(context, c.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
