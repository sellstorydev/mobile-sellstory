import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class HashtagInputField extends StatefulWidget {
  final List<String> selectedHashtags;
  final List<HashtagOption> availableHashtags;
  final Function(List<String>) onHashtagsChanged;
  final String label;
  final String hintText;
  final bool isRequired;
  final bool allowMultiple;
  final bool showSearch;
  final String? workspaceId;

  const HashtagInputField({
    super.key,
    required this.selectedHashtags,
    required this.availableHashtags,
    required this.onHashtagsChanged,
    this.label = 'แฮชแท็ก',
    this.hintText = 'เลือกแฮชแท็ก',
    this.isRequired = false,
    this.allowMultiple = true,
    this.showSearch = true,
    this.workspaceId,
  });

  @override
  State<HashtagInputField> createState() => _HashtagInputFieldState();
}

class _HashtagInputFieldState extends State<HashtagInputField> {
  final TextEditingController _searchController = TextEditingController();
  List<HashtagOption> _filteredHashtags = [];

  @override
  void initState() {
    super.initState();
    _filteredHashtags = widget.availableHashtags;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(covariant HashtagInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.availableHashtags != widget.availableHashtags) {
      _filteredHashtags = widget.availableHashtags;
      _applyFilter();
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() => _applyFilter();

  void _applyFilter([StateSetter? setModalState]) {
    final q = _searchController.text.toLowerCase();
    final run = () {
      if (q.isEmpty) {
        _filteredHashtags = widget.availableHashtags;
      } else {
        _filteredHashtags = widget.availableHashtags
            .where((h) => h.name.toLowerCase().contains(q) || h.id.toLowerCase().contains(q))
            .toList();
      }
    };
    if (setModalState != null) {
      setModalState(run);
    } else {
      setState(run);
    }
  }

  void _toggle(String id, [StateSetter? setModalState]) {
    final next = List<String>.from(widget.selectedHashtags);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      if (!widget.allowMultiple) next.clear();
      next.add(id);
    }
    try { HapticFeedback.selectionClick(); } catch (_) {}
    widget.onHashtagsChanged(next);
    if (setModalState != null) setModalState(() {}); else setState(() {});
  }

  void _openSelector() {
    // Work on a local copy to avoid rebuilding parent on each toggle
    final localSelected = List<String>.from(widget.selectedHashtags);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => _buildSelector(setModalState, localSelected),
      ),
    );
  }

  Widget _buildSelector(StateSetter setModalState, List<String> localSelected) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.label,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Search
          if (widget.showSearch) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ค้นหาแฮชแท็ก...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (_) => _applyFilter(setModalState),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Selected
          if (localSelected.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 10,
                runSpacing: 6,
                children: localSelected.map((id) {
                  final tag = widget.availableHashtags.firstWhere(
                    (h) => h.id == id,
                    orElse: () => HashtagOption(id: id, name: id, color: '#ef4444', totalUsage: 0, enabled: true, scopes: const {}),
                  );
                  return _selectedChip(tag, () {
                    // remove via X only
                    localSelected.remove(tag.id);
                    setModalState(() {});
                  });
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 4),
          ],

          // Grid
          Expanded(
            child: _filteredHashtags.isEmpty
                ? const Center(
                    child: Text('ไม่พบแฮชแท็ก', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 3.2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _filteredHashtags.length,
                    itemBuilder: (context, index) {
                      final tag = _filteredHashtags[index];
                      final selected = localSelected.contains(tag.id);
                      return _gridItem(tag, selected, () {
                        if (selected) {
                          localSelected.remove(tag.id);
                        } else {
                          if (!widget.allowMultiple) localSelected.clear();
                          localSelected.add(tag.id);
                        }
                        try { HapticFeedback.selectionClick(); } catch (_) {}
                        setModalState(() {});
                      });
                    },
                  ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      localSelected.clear();
                      setModalState(() {});
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('ล้างทั้งหมด', style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onHashtagsChanged(List<String>.from(localSelected));
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('confirm'.tr, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Chip is NOT tappable as a whole; only the X removes it to prevent accidental clearing
  Widget _selectedChip(HashtagOption tag, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _parseColor(tag.color),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('#${tag.name}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          InkResponse(
            onTap: onRemove,
            radius: 16,
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gridItem(HashtagOption tag, bool selected, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryOrange.withAlpha(26) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppTheme.primaryOrange : Colors.grey.shade300, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(left: 2),
              decoration: BoxDecoration(color: _parseColor(tag.color), borderRadius: BorderRadius.circular(9)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '#${tag.name}',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppTheme.primaryOrange : AppTheme.textPrimary,
                ),
              ),
            ),
            Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked, size: 20, color: selected ? AppTheme.primaryOrange : AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return AppTheme.primaryOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
            ),
            if (widget.isRequired) ...[
              const SizedBox(width: 4),
              const Text('*', style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _openSelector,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: widget.selectedHashtags.isEmpty
                      ? Text(widget.hintText, style: TextStyle(color: Colors.grey.shade500, fontSize: 14))
                      : Wrap(
                          spacing: 10,
                          runSpacing: 6,
                          children: widget.selectedHashtags.map((id) {
                            final tag = widget.availableHashtags.firstWhere(
                              (h) => h.id == id,
                              orElse: () => HashtagOption(id: id, name: id, color: '#ef4444', totalUsage: 0, enabled: true, scopes: const {}),
                            );
                            // In the field display, chips are also non-tappable; only the X is active inside the selector.
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _parseColor(tag.color),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text('#${tag.name}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                            );
                          }).toList(),
                        ),
                ),
                const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class HashtagOption {
  final String id;
  final String name;
  final String color;
  final int totalUsage;
  final bool enabled;
  final Map<String, bool> scopes;

  const HashtagOption({
    required this.id,
    required this.name,
    required this.color,
    required this.totalUsage,
    required this.enabled,
    required this.scopes,
  });

  factory HashtagOption.fromMap(Map<String, dynamic> map) {
    return HashtagOption(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      color: map['color'] ?? '#ef4444',
      totalUsage: map['totalUsage'] ?? 0,
      enabled: map['enabled'] ?? true,
      scopes: Map<String, bool>.from(map['scopes'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'totalUsage': totalUsage,
      'enabled': enabled,
      'scopes': scopes,
    };
  }
}
