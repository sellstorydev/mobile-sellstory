import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSendText;
  final Function(String) onSendImage;
  final Function(String, String) onSendFile; // (fileUrl, fileName)
  final bool enabled;

  const ChatInput({
    Key? key,
    required this.onSendText,
    required this.onSendImage,
    required this.onSendFile,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;
  bool _showAttachmentOptions = false;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty || !widget.enabled) return;

    final message = text.trim();
    _textController.clear();
    setState(() {
      _isComposing = false;
    });

    widget.onSendText(message);
  }

  void _handleTextChanged(String text) {
    setState(() {
      _isComposing = text.trim().isNotEmpty;
    });
  }

  void _toggleAttachmentOptions() {
    setState(() {
      _showAttachmentOptions = !_showAttachmentOptions;
    });
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        // ในการใช้งานจริง คุณจะต้องอัพโหลดไฟล์ไปยัง storage และได้ URL กลับมา
        // ตอนนี้จะใช้ path ชั่วคราว
        final imageUrl = 'https://example.com/uploads/${image.name}';
        widget.onSendImage(imageUrl);
        _toggleAttachmentOptions();
      }
    } catch (e) {
      _showErrorDialog('เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e');
    }
  }

  Future<void> _pickCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        // ในการใช้งานจริง คุณจะต้องอัพโหลดไฟล์ไปยัง storage และได้ URL กลับมา
        final imageUrl = 'https://example.com/uploads/${image.name}';
        widget.onSendImage(imageUrl);
        _toggleAttachmentOptions();
      }
    } catch (e) {
      _showErrorDialog('เกิดข้อผิดพลาดในการถ่ายภาพ: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        // ในการใช้งานจริง คุณจะต้องอัพโหลดไฟล์ไปยัง storage และได้ URL กลับมา
        final fileUrl = 'https://example.com/uploads/${file.name}';
        widget.onSendFile(fileUrl, file.name ?? 'file');
        _toggleAttachmentOptions();
      }
    } catch (e) {
      _showErrorDialog('เกิดข้อผิดพลาดในการเลือกไฟล์: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ข้อผิดพลาด'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 8,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Attachment options
          if (_showAttachmentOptions)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.grey[50],
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.photo_library,
                    label: 'รูปภาพ',
                    color: Colors.green,
                    onTap: _pickImage,
                  ),
                  _buildAttachmentOption(
                    icon: Icons.camera_alt,
                    label: 'ถ่ายภาพ',
                    color: Colors.blue,
                    onTap: _pickCamera,
                  ),
                  _buildAttachmentOption(
                    icon: Icons.attach_file,
                    label: 'ไฟล์',
                    color: Colors.orange,
                    onTap: _pickFile,
                  ),
                ],
              ),
            ),

          // Input area
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                // Attachment button
                IconButton(
                  icon: Icon(
                    _showAttachmentOptions ? Icons.close : Icons.add,
                    color: widget.enabled ? Colors.grey[600] : Colors.grey[400],
                  ),
                  onPressed: widget.enabled ? _toggleAttachmentOptions : null,
                ),

                // Text input
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 40,
                      maxHeight: 120,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      style: const TextStyle(color: Colors.black), // ปรับข้อความเป็นสีดำ
                      decoration: const InputDecoration(
                        hintText: 'พิมพ์ข้อความ...',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onChanged: _handleTextChanged,
                      onSubmitted: _handleSubmitted,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Send button
                Container(
                  decoration: BoxDecoration(
                    color: _isComposing && widget.enabled
                        ? Theme.of(context).primaryColor
                        : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _isComposing && widget.enabled
                        ? () => _handleSubmitted(_textController.text)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
