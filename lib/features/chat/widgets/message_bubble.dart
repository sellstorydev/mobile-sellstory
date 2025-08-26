import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import 'viewers/image_viewer_page.dart';
import 'viewers/video_viewer_page.dart';
import 'viewers/audio_viewer_page.dart';
import 'viewers/pdf_viewer_page.dart';
import 'video_cover.dart';

class MessageBubble extends StatelessWidget {
  final String messageId;
  final Map<String, dynamic> messageData;
  final bool isFromCurrentUser;
  final bool highlight;
  final String? highlightQuery;
  final bool focused; // emphasize currently focused match
  final VoidCallback? onLongPress; // for actions like Quote Reply

  const MessageBubble({
    Key? key,
    required this.messageId,
    required this.messageData,
    required this.isFromCurrentUser,
    this.highlight = false,
    this.highlightQuery,
    this.focused = false,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final messageType = messageData['type'] ?? 'text';
    final sender = messageData['sender'] as Map<String, dynamic>? ?? {};
    final senderName = sender['name'] ?? 'Unknown';
    final senderAvatar = sender['avatar'];
    final timestamp = _parseTimestamp(messageData['timestamp']);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onLongPress: onLongPress,
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisAlignment: isFromCurrentUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isFromCurrentUser) ...[
              CircleAvatar(
                radius: 16,
                backgroundImage: senderAvatar != null ? NetworkImage(senderAvatar) : null,
                child: senderAvatar == null
                    ? Text(_getInitials(senderName), style: const TextStyle(fontSize: 12))
                    : null,
              ),
              const SizedBox(width: 8),
            ],

            Flexible(
              child: Column(
                crossAxisAlignment: isFromCurrentUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!isFromCurrentUser)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 8),
                      child: Text(
                        senderName,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                      ),
                    ),
                  Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isFromCurrentUser ? const Color(0xFFFF7A00) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomLeft: isFromCurrentUser ? const Radius.circular(16) : const Radius.circular(4),
                        bottomRight: isFromCurrentUser ? const Radius.circular(4) : const Radius.circular(16),
                      ),
                      boxShadow: highlight
                          ? [
                              BoxShadow(
                                color: Colors.yellow.withValues(alpha: 0.45),
                                blurRadius: focused ? 16 : 10,
                                spreadRadius: focused ? 2 : 1,
                              ),
                            ]
                          : null,
                    ),
                    child: _buildMessageContent(context, messageType),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
                    child: Text(
                      timestamp != null ? timeago.format(timestamp) : '',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ),
                ],
              ),
            ),

            if (isFromCurrentUser) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFFFF7A00),
                child: Text(_getInitials(senderName), style: const TextStyle(fontSize: 12, color: Colors.white)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, String messageType) {
    switch (messageType) {
      case 'text':
        return _buildTextMessage();
      case 'image':
        return _buildImageMessage(context);
      case 'video':
        return _buildVideoMessage(context);
      case 'file':
        return _buildFileMessage(context);
      case 'audio':
        return _buildAudioMessage(context);
      case 'sticker':
        return _buildStickerMessage();
      default:
        return _buildTextMessage();
    }
  }

  Widget _buildTextMessage() {
    final text = (messageData['text'] ?? messageData['message'] ?? '').toString();
    if (text.isEmpty) return const SizedBox();

    if (highlight && (highlightQuery?.isNotEmpty ?? false)) {
      return _buildHighlightedText(text, highlightQuery!, isFromCurrentUser);
    }

    return Text(
      text,
      style: TextStyle(
        color: isFromCurrentUser ? Colors.white : Colors.black87,
        fontSize: 16,
      ),
    );
  }

  Widget _buildHighlightedText(String text, String query, bool onPrimary) {
    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    while (true) {
      final index = lower.indexOf(q, start);
      if (index < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (index > start) spans.add(TextSpan(text: text.substring(start, index)));
      spans.add(TextSpan(
        text: text.substring(index, index + q.length),
        style: TextStyle(
          backgroundColor: Colors.yellow.withValues(alpha: onPrimary ? 0.35 : 0.7),
          fontWeight: FontWeight.w700,
          color: onPrimary ? Colors.white : Colors.black,
        ),
      ));
      start = index + q.length;
    }
    return RichText(
      text: TextSpan(
        style: TextStyle(color: onPrimary ? Colors.white : Colors.black87, fontSize: 16),
        children: spans,
      ),
    );
  }

  Widget _buildImageMessage(BuildContext context) {
    final imageUrl = messageData['imageUrl'] ?? messageData['url'] ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageUrl.isNotEmpty)
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ImageViewerPage(url: imageUrl, title: 'รูปภาพ'),
                ),
              );
            },
            child: Container(
              constraints: const BoxConstraints(maxWidth: 280, maxHeight: 300),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    width: 280,
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),
        if ((messageData['text'] ?? '').toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: highlight && (highlightQuery?.isNotEmpty ?? false)
                ? _buildHighlightedText(messageData['text'], highlightQuery!, isFromCurrentUser)
                : Text(
                    messageData['text'],
                    style: TextStyle(color: isFromCurrentUser ? Colors.white : Colors.black87, fontSize: 14),
                  ),
          ),
      ],
    );
  }

  Widget _buildVideoMessage(BuildContext context) {
    final videoUrl = messageData['videoUrl'] ?? messageData['url'] ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            if (videoUrl.toString().isEmpty) return;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => VideoViewerPage(url: videoUrl, title: 'วิดีโอ'),
              ),
            );
          },
          child: VideoCover(
            url: videoUrl,
            width: 200,
            height: 120,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        if ((messageData['text'] ?? '').toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: highlight && (highlightQuery?.isNotEmpty ?? false)
                ? _buildHighlightedText(messageData['text'], highlightQuery!, isFromCurrentUser)
                : Text(
                    messageData['text'],
                    style: TextStyle(color: isFromCurrentUser ? Colors.white : Colors.black87),
                  ),
          ),
      ],
    );
  }

  Widget _buildFileMessage(BuildContext context) {
    final fileUrl = messageData['fileUrl'] ?? messageData['url'] ?? '';
    final fileName = (messageData['fileName'] ?? 'ไฟล์').toString();
    final lower = fileName.toLowerCase();
    return GestureDetector(
      onTap: () {
        if (lower.endsWith('.pdf')) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PdfViewerPage(url: fileUrl, title: fileName),
            ),
          );
        } else if (lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.gif') || lower.endsWith('.webp')) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ImageViewerPage(url: fileUrl, title: fileName),
            ),
          );
        } else {
          _launchUrl(fileUrl);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: isFromCurrentUser ? Colors.white54 : Colors.grey[400]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file, color: isFromCurrentUser ? Colors.white : Colors.grey[600]),
            const SizedBox(width: 8),
            Flexible(
              child: highlight && (highlightQuery?.isNotEmpty ?? false)
                  ? _buildHighlightedText(fileName, highlightQuery!, isFromCurrentUser)
                  : Text(
                      fileName,
                      style: TextStyle(color: isFromCurrentUser ? Colors.white : Colors.black87, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioMessage(BuildContext context) {
    final audioUrl = messageData['audioUrl'] ?? messageData['fileUrl'] ?? messageData['url'] ?? '';
    final fileName = (messageData['fileName'] ?? (messageData['text'] ?? 'ข้อความเสียง')).toString();
    return GestureDetector
      (
      onTap: () {
        if (audioUrl.toString().isEmpty) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AudioViewerPage(url: audioUrl, title: fileName.isNotEmpty ? fileName : 'เสียง'),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: isFromCurrentUser ? Colors.white54 : Colors.grey[400]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_fill, color: isFromCurrentUser ? Colors.white : Colors.grey[700], size: 28),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                fileName.isNotEmpty ? fileName : 'ข้อความเสียง',
                style: TextStyle(color: isFromCurrentUser ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickerMessage() {
    return const Icon(Icons.emoji_emotions, size: 80, color: Colors.orange);
  }

  DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is int) return DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (_) {
        final ms = int.tryParse(timestamp);
        if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
      }
    }
    return null;
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final words = name.trim().split(' ');
    if (words.length == 1) return words[0].substring(0, 1).toUpperCase();
    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }
}
