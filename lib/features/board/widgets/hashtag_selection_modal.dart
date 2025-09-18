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

  // Parse hex string like #RGB, #RRGGBB, #AARRGGBB or raw to Color
  Color _hexToColor(String? hex) {
    final raw = (hex ?? '').trim();
    if (raw.isEmpty) return const Color(0xFFF97316);
    String h = raw;
    if (h.startsWith('#')) h = h.substring(1);
    if (h.toLowerCase().startsWith('0x')) h = h.substring(2);
    if (h.length == 3) {
      h = h.split('').map((c) => '$c$c').join();
      h = 'FF$h';
    } else if (h.length == 4) {
      final a = h[0], r = h[1], g = h[2], b = h[3];
      h = '$a$a$r$r$g$g$b$b';
    } else if (h.length == 6) {
      h = 'FF$h';
    } else if (h.length == 8) {
      // keep as is
    } else {
      return const Color(0xFFF97316);
    }
    final v = int.tryParse(h, radix: 16);
    return v == null ? const Color(0xFFF97316) : Color(v);
  }

  // Choose readable foreground color against bg
  Color _onColor(Color bg) => bg.computeLuminance() > 0.55 ? Colors.black87 : Colors.white;

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
                  final bg = _hexToColor(hashtag['color']?.toString());
                  final fg = _onColor(bg);
                  return Chip(
                    label: Text('#${hashtag['text']}', style: TextStyle(color: fg, fontSize: 12)),
                    backgroundColor: bg,
                    deleteIcon: Icon(Icons.close, size: 16, color: fg),
                    onDeleted: () => _toggleHashtag(hashtag),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(color: Color.fromARGB((0.25 * 255).round(), fg.red, fg.green, fg.blue)),
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
                              final bg = _hexToColor(hashtag['color']?.toString());
                              final fg = _onColor(bg);
                              return FilterChip(
                                label: Text('#${hashtag['text']}', style: TextStyle(color: fg, fontSize: 12)),
                                selected: isSelected,
                                onSelected: (_) => _toggleHashtag(hashtag),
                                backgroundColor: bg,
                                selectedColor: bg,
                                checkmarkColor: fg,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                side: BorderSide(
                                  color: isSelected
                                      ? Color.fromARGB((0.5 * 255).round(), fg.red, fg.green, fg.blue)
                                      : Color.fromARGB((0.25 * 255).round(), fg.red, fg.green, fg.blue),
                                  width: isSelected ? 2 : 1,
                                ),
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
                      print('🏷️ HashtagSelectionModal - OK pressed');
                      print('  - Selected hashtags: $_selectedHashtags');
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
