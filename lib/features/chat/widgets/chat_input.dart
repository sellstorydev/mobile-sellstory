import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:get/get.dart';
import '../../../data/services/upload_service.dart';
import 'canned_responses_sheet.dart';


class ChatInput extends StatefulWidget {
  final Function(String) onSendText;
  final Function(String) onSendImage;
  final Function(String, String) onSendFile;
  final Function(String) onSendVideo; // NEW: send video URL
  final bool enabled;
  final String workspaceId;
  final String chatroomId;
  final String? replyPreview; // preview text for quote reply
  final String? replyToMessageId; // id of original message for focusing
  final VoidCallback? onCancelReply; // cancel quote reply
  final VoidCallback? onTapReplyPreview; // tap to focus original

  const ChatInput({
    Key? key,
    required this.onSendText,
    required this.onSendImage,
    required this.onSendFile,
    required this.onSendVideo,
    required this.workspaceId,
    required this.chatroomId,
    this.enabled = true,
    this.replyPreview,
    this.replyToMessageId,
    this.onCancelReply,
    this.onTapReplyPreview,
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
  bool _isPicking = false; // show loading while opening gallery/camera

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

  Future<void> _openAttachmentModal() async {
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.video_library_outlined),
                title: Text('pick_video_from_gallery'.tr),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickVideo();
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text('pick_document_file'.tr),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickFile();
                },
              ),

              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.quickreply_outlined),
                title: Text('canned_responses_menu'.tr),
                onTap: () async {
                  Navigator.pop(ctx);
                  // Open canned responses manager in another bottom sheet
                  if (!mounted) return;
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (_) => CannedResponsesSheet(
                      workspaceId: widget.workspaceId,
                      onSendText: widget.onSendText,
                      onSendImage: widget.onSendImage,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }


  // New helper for selecting multiple images from gallery
  Future<void> _pickImages() async {
    try {
      if (mounted) setState(() => _isPicking = true);
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (images.isEmpty) return; // user canceled

      if (images.length == 1) {
        // Fallback to single existing flow
        await _uploadAndSendImage(File(images.first.path));
      } else {
        await _uploadAndSendMultipleImages(images.map((x) => File(x.path)).toList());
      }
      _toggleAttachmentOptions();
    } catch (e) {
      _showErrorDialog('error_picking_images'.trParams({'error': '$e'}));
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  // Sequential multi-image upload with aggregated progress
  Future<void> _uploadAndSendMultipleImages(List<File> files) async {
    if (files.isEmpty) return;
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'uploading_images_start'.trParams({'total': '${files.length}'});
    });

    try {
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        double lastInnerProgress = 0.0;
        final imageUrl = await _uploadService.uploadImage(
          file: file,
          workspaceId: widget.workspaceId,
            chatroomId: widget.chatroomId,
          onProgress: (p) {
            // overall progress: (completedFiles + currentProgress)/total
            lastInnerProgress = p;
            final overall = (i + p) / files.length;
            if (mounted) {
              setState(() {
                _uploadProgress = overall;
                _uploadStatus = 'uploading_images_progress'.trParams({
                  'current': '${i + 1}',
                  'total': '${files.length}',
                  'percent': '${((overall * 100).clamp(0, 100)).toInt()}',
                });
              });
            }
          },
        );
        // Ensure status shows finished for this file if inner progress didn't reach 1.0 due to rounding
        if (lastInnerProgress < 0.999 && mounted) {
          setState(() {
            _uploadProgress = (i + 1) / files.length;
          });
        }
        // Send after each successful upload
        widget.onSendImage(imageUrl);
      }
    } catch (e) {
      _showErrorDialog('อัพโหลดรูปภาพไม่สำเร็จ: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
          _uploadStatus = '';
        });
      }
    }
  }

  Future<void> _pickImage() async { // legacy single-image picker kept for compatibility (camera uses separate method)
    try {
      if (mounted) setState(() => _isPicking = true);
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
      _showErrorDialog('error_picking_image'.trParams({'error': '$e'}));
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _pickCamera() async {
    try {
      if (mounted) setState(() => _isPicking = true);
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
      _showErrorDialog('error_taking_photo'.trParams({'error': '$e'}));
    } finally {
      if (mounted) setState(() => _isPicking = false);
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
      _showErrorDialog('error_picking_file'.trParams({'error': '$e'}));
    }
  }

  Future<void> _uploadAndSendImage(File imageFile) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'uploading_image'.tr;
    });

    try {
      final imageUrl = await _uploadService.uploadImage(
        file: imageFile,
        workspaceId: widget.workspaceId,
        chatroomId: widget.chatroomId,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
            _uploadStatus = 'uploading_image_percent'.trParams({'percent': '${(progress * 100).toInt()}'});
          });
        },
      );

      setState(() {
        _uploadStatus = 'sending_image'.tr;
      });

      // ส่งรูปภาพผ่าน API
      widget.onSendImage(imageUrl);

    } catch (e) {
      _showErrorDialog('upload_image_failed_details'.trParams({'error': '$e'}));
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
      _uploadStatus = 'uploading_file'.tr;
    });

    try {
      final fileUrl = await _uploadService.uploadFile(
        file: file,
        workspaceId: widget.workspaceId,
        chatroomId: widget.chatroomId,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
            _uploadStatus = 'uploading_file_percent'.trParams({'percent': '${(progress * 100).toInt()}'});
          });
        },
      );

      setState(() {
        _uploadStatus = 'sending_file'.tr;
      });

      // ส่งไฟล์ผ่าน API
      widget.onSendFile(fileUrl, fileName);

    } catch (e) {
      _showErrorDialog('upload_file_failed_details'.trParams({'error': '$e'}));
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
        _uploadStatus = '';
      });
    }
  }

  Future<void> _pickVideo() async {
    try {
      if (mounted) setState(() => _isPicking = true);
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
      if (video == null) return; // user canceled
      await _uploadAndSendVideo(File(video.path));
      _toggleAttachmentOptions();
    } catch (e) {
      _showErrorDialog('pick_video_failed'.trParams({'error': '$e'}));
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _uploadAndSendVideo(File file) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'uploading_video'.tr;
    });

    try {
      final videoUrl = await _uploadService.uploadVideo(
        file: file,
        workspaceId: widget.workspaceId,
        chatroomId: widget.chatroomId,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
            _uploadStatus = 'uploading_video_percent'.trParams({'percent': '${(progress * 100).toInt()}'});
          });
        },
      );
      setState(() { _uploadStatus = 'sending_video'.tr; });
      widget.onSendVideo(videoUrl);
    } catch (e) {
      _showErrorDialog('upload_video_failed_details'.trParams({'error': '$e'}));
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
        title: Text('error'.tr),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ok'.tr),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
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
                // Reply preview bar
                if (widget.replyPreview != null && widget.replyPreview!.isNotEmpty)
                  GestureDetector(
                    onTap: widget.onTapReplyPreview,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.only(top: 6, left: 8, right: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0), // light orange
                        border: Border(
                          left: BorderSide(color: const Color(0xFFFF7A00), width: 3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.reply, size: 18, color: Color(0xFFFF7A00)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('reply'.tr, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                Text(
                                  widget.replyPreview!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: widget.onCancelReply,
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.close, size: 18, color: Colors.black45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

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
                          await _openAttachmentModal();
                        },
                      ),
                      _RoundIcon(
                        icon: Icons.photo_camera_outlined,
                        onTap: () async => await _pickCamera(),
                      ),
                      _RoundIcon(
                        icon: Icons.image_outlined,
                        onTap: () async => await _pickImages(), // updated to multi-image picker
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
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none, isCollapsed: true,
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
        ),
        if (_isPicking)
          PositionedFillOverlay(maskColor: Colors.black, alpha: 0.25, child: const _PickingOverlay())
      ],
    );
  }

  // Helper overlay widget to avoid repeating withValues every time
}

class PositionedFillOverlay extends StatelessWidget {
  final Widget child;
  final Color maskColor;
  final double alpha;
  const PositionedFillOverlay({super.key, required this.child, required this.maskColor, required this.alpha});
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: Container(
          color: maskColor.withOpacity(alpha),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

class _PickingOverlay extends StatelessWidget {
  const _PickingOverlay();
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
        const SizedBox(height: 10),
        Text('preparing_images'.tr, style: const TextStyle(color: Colors.white)),
      ],
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
