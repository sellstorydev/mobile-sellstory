import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _filteredHashtags = widget.availableHashtags;
    _searchController.addListener(_filterHashtags);
  }

  @override
  void didUpdateWidget(HashtagInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update filtered hashtags when available hashtags change
    if (oldWidget.availableHashtags != widget.availableHashtags) {
      _filteredHashtags = widget.availableHashtags;
      _filterHashtags(null);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterHashtags([StateSetter? setModalState]) {
    final query = _searchController.text.toLowerCase();
    if (setModalState != null) {
      setModalState(() {
        if (query.isEmpty) {
          _filteredHashtags = widget.availableHashtags;
        } else {
          _filteredHashtags = widget.availableHashtags
              .where((hashtag) =>
                  hashtag.name.toLowerCase().contains(query) ||
                  hashtag.id.toLowerCase().contains(query))
              .toList();
        }
      });
    } else {
      setState(() {
        if (query.isEmpty) {
          _filteredHashtags = widget.availableHashtags;
        } else {
          _filteredHashtags = widget.availableHashtags
              .where((hashtag) =>
                  hashtag.name.toLowerCase().contains(query) ||
                  hashtag.id.toLowerCase().contains(query))
              .toList();
        }
      });
    }
  }

  void _toggleHashtag(String hashtagId, [StateSetter? setModalState]) {
    final List<String> newSelectedHashtags = List.from(widget.selectedHashtags);
    
    if (newSelectedHashtags.contains(hashtagId)) {
      newSelectedHashtags.remove(hashtagId);
    } else {
      if (!widget.allowMultiple) {
        newSelectedHashtags.clear();
      }
      newSelectedHashtags.add(hashtagId);
    }
    
    // Call the callback to update parent widget
    widget.onHashtagsChanged(newSelectedHashtags);
    
    // Force rebuild to show selection changes immediately
    if (setModalState != null) {
      setModalState(() {});
    } else {
      setState(() {});
    }
  }

  void _showHashtagSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return _buildHashtagSelector(setModalState);
        },
      ),
    );
  }

  Widget _buildHashtagSelector([StateSetter? setModalState]) {
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
          
                                // Search bar
            if (widget.showSearch) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ค้นหาแฮชแท็ก...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                                     onChanged: (value) {
                     // Trigger search immediately when text changes
                     _filterHashtags(setModalState);
                   },
                ),
              ),
              const SizedBox(height: 8),
            ],
          
                                // Selected hashtags display
            if (widget.selectedHashtags.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: widget.selectedHashtags.map((hashtagId) {
                        final hashtag = widget.availableHashtags
                            .firstWhere(
                              (h) => h.id == hashtagId,
                              orElse: () => HashtagOption(
                                id: hashtagId,
                                name: hashtagId,
                                color: '#ef4444',
                                totalUsage: 0,
                                enabled: true,
                                scopes: {},
                              ),
                            );
                        return _buildSelectedHashtagChip(hashtag, setModalState);
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 4),
            ],
          
                     // Hashtag list
           Expanded(
             child: _filteredHashtags.isEmpty
                 ? const Center(
                     child: Text(
                       'ไม่พบแฮชแท็ก',
                       style: TextStyle(
                         color: AppTheme.textSecondary,
                         fontSize: 14,
                       ),
                     ),
                   )
                 : GridView.builder(
                     padding: const EdgeInsets.symmetric(horizontal: 12),
                     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                       crossAxisCount: 2,
                       childAspectRatio: 3.5,
                       crossAxisSpacing: 8,
                       mainAxisSpacing: 4,
                     ),
                     itemCount: _filteredHashtags.length,
                     itemBuilder: (context, index) {
                       final hashtag = _filteredHashtags[index];
                       final isSelected = widget.selectedHashtags.contains(hashtag.id);
                       
                       return _buildHashtagGridItem(hashtag, isSelected, setModalState);
                     },
                   ),
           ),
          
                     // Action buttons
           Container(
             padding: const EdgeInsets.all(12),
             child: Row(
               children: [
                 Expanded(
                   child: OutlinedButton(
                     onPressed: () {
                       widget.onHashtagsChanged([]);
                       Navigator.pop(context);
                     },
                     style: OutlinedButton.styleFrom(
                       padding: const EdgeInsets.symmetric(vertical: 8),
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(6),
                       ),
                     ),
                     child: const Text(
                       'ล้างทั้งหมด',
                       style: TextStyle(fontSize: 12),
                     ),
                   ),
                 ),
                 const SizedBox(width: 8),
                 Expanded(
                   child: ElevatedButton(
                     onPressed: () => Navigator.pop(context),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: AppTheme.primaryOrange,
                       padding: const EdgeInsets.symmetric(vertical: 8),
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(6),
                       ),
                     ),
                     child: Text(
                       'confirm'.tr,
                       style: const TextStyle(color: Colors.white, fontSize: 12),
                     ),
                   ),
                 ),
               ],
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildSelectedHashtagChip(HashtagOption hashtag, [StateSetter? setModalState]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _parseColor(hashtag.color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#${hashtag.name}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 3),
          GestureDetector(
            onTap: () => _toggleHashtag(hashtag.id, setModalState),
            child: const Icon(
              Icons.close,
              color: Colors.white,
              size: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHashtagGridItem(HashtagOption hashtag, bool isSelected, [StateSetter? setModalState]) {
    return GestureDetector(
      onTap: () => _toggleHashtag(hashtag.id, setModalState),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryOrange.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryOrange : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: _parseColor(hashtag.color),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '#${hashtag.name}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryOrange : AppTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 6),
              child: Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color: isSelected ? AppTheme.primaryOrange : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
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
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            if (widget.isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showHashtagSelector,
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
                       ? Text(
                           widget.hintText,
                           style: TextStyle(
                             color: Colors.grey.shade500,
                             fontSize: 14,
                           ),
                         )
                       : Wrap(
                           spacing: 8,
                           runSpacing: 4,
                           children: widget.selectedHashtags.map((hashtagId) {
                             final hashtag = widget.availableHashtags
                                 .firstWhere(
                                   (h) => h.id == hashtagId,
                                   orElse: () => HashtagOption(
                                     id: hashtagId,
                                     name: hashtagId,
                                     color: '#ef4444',
                                     totalUsage: 0,
                                     enabled: true,
                                     scopes: {},
                                   ),
                                 );
                             return _buildSelectedHashtagChip(hashtag, null);
                           }).toList(),
                         ),
                 ),
                const Icon(
                  Icons.arrow_drop_down,
                  color: AppTheme.textSecondary,
                ),
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

  HashtagOption({
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
