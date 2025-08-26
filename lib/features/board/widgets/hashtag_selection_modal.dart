import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../controller/board_controller.dart';

class HashtagSelectionModal extends StatefulWidget {
  final List<Map<String, dynamic>> selectedHashtags;
  final Function(List<Map<String, dynamic>>) onHashtagsSelected;

  const HashtagSelectionModal({
    super.key,
    required this.selectedHashtags,
    required this.onHashtagsSelected,
  });

  @override
  State<HashtagSelectionModal> createState() => _HashtagSelectionModalState();
}

class _HashtagSelectionModalState extends State<HashtagSelectionModal> {
  final BoardController _controller = Get.find<BoardController>();
  List<Map<String, dynamic>> _selectedHashtags = [];
  List<Map<String, dynamic>> _availableHashtags = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedHashtags = List.from(widget.selectedHashtags);
    _loadAvailableHashtags();
  }

  void _loadAvailableHashtags() async {
    try {
      final hashtags = await _controller.getWorkspaceHashtags();
      setState(() {
        _availableHashtags = hashtags;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Failed to load hashtags: $e');
      setState(() {
        _availableHashtags = [];
        _isLoading = false;
      });
    }
  }

  void _toggleHashtag(Map<String, dynamic> hashtag) {
    setState(() {
      final isSelected = _selectedHashtags.any((h) => h['id'] == hashtag['id']);
      if (isSelected) {
        _selectedHashtags.removeWhere((h) => h['id'] == hashtag['id']);
      } else {
        _selectedHashtags.add(hashtag);
      }
    });
  }



  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.tag, color: AppTheme.primaryOrange, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Select Hashtags',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Selected hashtags
            if (_selectedHashtags.isNotEmpty) ...[
              const Text(
                'Selected:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedHashtags.map((hashtag) {
                  return Chip(
                    label: Text('#${hashtag['text']}'),
                    backgroundColor: Color(int.parse(hashtag['color'].replaceFirst('#', '0xff'))),
                    labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                    deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white),
                    onDeleted: () => _toggleHashtag(hashtag),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],



            // Available hashtags
            const Text(
              'Available Hashtags:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // Scrollable list of available hashtags
            Flexible(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryOrange),
                      ),
                    )
                  : _availableHashtags.isEmpty
                      ? const Center(
                          child: Text(
                            'No hashtags available in workspace',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : SingleChildScrollView(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availableHashtags.map((hashtag) {
                              final isSelected = _selectedHashtags.any((h) => h['id'] == hashtag['id']);
                              return FilterChip(
                                label: Text('#${hashtag['text']}'),
                                selected: isSelected,
                                onSelected: (_) => _toggleHashtag(hashtag),
                                backgroundColor: Colors.grey[200],
                                selectedColor: Color(int.parse(hashtag['color'].replaceFirst('#', '0xff'))),
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontSize: 12,
                                ),
                                checkmarkColor: Colors.white,
                              );
                            }).toList(),
                          ),
                        ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onHashtagsSelected(_selectedHashtags);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
