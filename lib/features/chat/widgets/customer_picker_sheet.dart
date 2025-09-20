import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../../../domain/entities/customer.dart';

class CustomerItem {
  final String id;
  final String name;
  final String? customId;
  final String? company;
  CustomerItem({required this.id, required this.name, this.customId, this.company});
}

class CustomerPickerSheet extends StatefulWidget {
  final String workspaceId;
  final String? initialSelectedId;
  const CustomerPickerSheet({super.key, required this.workspaceId, this.initialSelectedId});

  @override
  State<CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<CustomerPickerSheet> {
  late Future<List<CustomerItem>> _future;
  String _query = '';
  final FirestoreRepository _repository = Get.find<FirestoreRepository>();
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _future = _loadCustomers();
    _selectedId = widget.initialSelectedId;
  }

  Future<List<CustomerItem>> _loadCustomers() async {
    final List<Customer> customers = await _repository.getCustomers(widget.workspaceId);
    final list = customers.map((c) {
      String? company;
      if (c.companyNames.isNotEmpty) {
        final first = c.companyNames.first;
        company = (first['value']?.toString() ?? '').isNotEmpty ? first['value'].toString() : null;
      }
      final displayName = c.name.isNotEmpty ? c.name : 'no_name'.tr;
      return CustomerItem(
        id: c.id,
        name: displayName,
        customId: c.customId.isNotEmpty ? c.customId : null,
        company: company,
      );
    }).toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('select_customer'.tr),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'search_customer_name_or_id'.tr,
                prefixIcon: const Icon(Icons.search),
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
                  return Center(child: Text('no_customers_in_workspace'.tr));
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
                    final selected = _selectedId == c.id;
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                      title: Text(c.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (c.company != null && c.company!.isNotEmpty) Text('${'company'.tr}: ${c.company}'),
                          if (c.customId != null && c.customId!.isNotEmpty) Text(c.customId!),
                        ],
                      ),
                      trailing: selected
                          ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                          : null,
                      selected: selected,
                      onTap: () => setState(() => _selectedId = c.id),
                      onLongPress: () => Navigator.pop(context, c.id), // quick select via long-press
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('cancel'.tr),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_selectedId == null)
                          ? null
                          : () => Navigator.pop(context, _selectedId),
                      child: Text('confirm'.tr),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
