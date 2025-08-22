import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../../../data/services/upload_service.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSendText;
  final Function(String) onSendImage;
  final Function(String, String) onSendFile;
  final bool enabled;
  final String workspaceId;
  final String chatroomId;

  const ChatInput({
    Key? key,
    required this.onSendText,
    required this.onSendImage,
    required this.onSendFile,
    required this.workspaceId,
    required this.chatroomId,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final UploadService _uploadService = UploadService.to;

  bool _isComposing = false;
  bool _showAttachmentOptions = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';

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
        await _uploadAndSendImage(File(image.path));
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
        await _uploadAndSendImage(File(image.path));
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
        if (file.path != null) {
          await _uploadAndSendFile(File(file.path!), file.name);
          _toggleAttachmentOptions();
        }
      }
    } catch (e) {
      _showErrorDialog('เกิดข้อผิดพลาดในการเลือกไฟล์: $e');
    }
  }

  Future<void> _uploadAndSendImage(File imageFile) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'กำลังอัพโหลดรูปภาพ...';
    });

    try {
      final imageUrl = await _uploadService.uploadImage(
        file: imageFile,
        workspaceId: widget.workspaceId,
        chatroomId: widget.chatroomId,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
            _uploadStatus = 'กำลังอัพโหลดรูปภาพ... ${(progress * 100).toInt()}%';
          });
        },
      );

      setState(() {
        _uploadStatus = 'ส่งรูปภาพ...';
      });

      // ส่งรูปภาพผ่าน API
      widget.onSendImage(imageUrl);

    } catch (e) {
      _showErrorDialog('อัพโหลดรูปภาพไม่สำเร็จ: $e');
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
        _uploadStatus = '';
      });
    }
  }

  Future<void> _uploadAndSendFile(File file, String fileName) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'กำลังอัพโหลดไฟล์...';
    });

    try {
      final fileUrl = await _uploadService.uploadFile(
        file: file,
        workspaceId: widget.workspaceId,
        chatroomId: widget.chatroomId,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
            _uploadStatus = 'กำลังอัพโหลดไฟล์... ${(progress * 100).toInt()}%';
          });
        },
      );

      setState(() {
        _uploadStatus = 'ส่งไฟล์...';
      });

      // ส่งไฟล์ผ่าน API
      widget.onSendFile(fileUrl, fileName);

    } catch (e) {
      _showErrorDialog('อัพโหลดไฟล์ไม่สำเร็จ: $e');
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
        _uploadStatus = '';
      });
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
            offset: const Offset(0, -1),
            blurRadius: 6,
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // แถบสถานะอัปโหลด (คงไว้ตามเดิม)
            if (_isUploading)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.blue.shade50,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _uploadStatus,
                            style: TextStyle(color: Colors.blue.shade700, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                    ),
                  ],
                ),
              ),

            // แถวไอคอนซ้าย + ช่องพิมพ์ (สไตล์ตามภาพ)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              child: Row(
                children: [
                  // ไอคอน 3 อันซ้ายมือ
                  _RoundIcon(
                    icon: Icons.grid_view_rounded,
                    onTap: () async {
                      // เลือกไฟล์เอกสาร (เหมือนปุ่ม “+” เดิม)
                      await _pickFile();
                    },
                  ),
                  _RoundIcon(
                    icon: Icons.photo_camera_outlined,
                    onTap: () async => await _pickCamera(),
                  ),
                  _RoundIcon(
                    icon: Icons.image_outlined,
                    onTap: () async => await _pickImage(),
                  ),

                  // ช่องพิมพ์ “Aa”
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      constraints: const BoxConstraints(minHeight: 44, maxHeight: 120),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F2F4), // เทาอ่อนแบบ LINE
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        enabled: widget.enabled && !_isUploading,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.2),
                        decoration: const InputDecoration(
                          hintText: 'Aa',
                          hintStyle: TextStyle(color: Color(0xFF9E9E9E), fontSize: 16),
                          border: InputBorder.none,
                          isCollapsed: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: _handleTextChanged,
                        onSubmitted: _handleSubmitted,
                      ),
                    ),
                  ),

                  // ปุ่มส่งจะปรากฏเมื่อพิมพ์ข้อความแล้วเท่านั้น
                  const SizedBox(width: 6),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: (_isComposing && widget.enabled && !_isUploading)
                        ? GestureDetector(
                            key: const ValueKey('send-btn'),
                            onTap: () => _handleSubmitted(_textController.text),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Color(0xFFFF6A00),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.send, color: Colors.white, size: 20),
                            ),
                          )
                        : const SizedBox(key: ValueKey('spacer'), width: 4),
                  ) ],
              ),
            ),
          ],
        ),
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



class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIcon({required this.icon, required this.onTap, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 26,
      child: Container(
        width: 40, height: 40,
        alignment: Alignment.center,
        child: Icon(icon, size: 22, color: Colors.grey[800]),
      ),
    );
  }
}
