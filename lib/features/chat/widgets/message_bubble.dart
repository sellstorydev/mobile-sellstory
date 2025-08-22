import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

class MessageBubble extends StatelessWidget {
  final String messageId;
  final Map<String, dynamic> messageData;
  final bool isFromCurrentUser;

  const MessageBubble({
    Key? key,
    required this.messageId,
    required this.messageData,
    required this.isFromCurrentUser,
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
      child: Row(
        mainAxisAlignment: isFromCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isFromCurrentUser) ...[
            // Avatar for other users
            CircleAvatar(
              radius: 16,
              backgroundImage: senderAvatar != null
                  ? NetworkImage(senderAvatar)
                  : null,
              child: senderAvatar == null
                  ? Text(
                      _getInitials(senderName),
                      style: const TextStyle(fontSize: 12),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],

          // Message content
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
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isFromCurrentUser
                        ? Theme.of(context).primaryColor
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomLeft: isFromCurrentUser
                          ? const Radius.circular(16)
                          : const Radius.circular(4),
                      bottomRight: isFromCurrentUser
                          ? const Radius.circular(4)
                          : const Radius.circular(16),
                    ),
                  ),
                  child: _buildMessageContent(messageType),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
                  child: Text(
                    timestamp != null ? timeago.format(timestamp) : '',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (isFromCurrentUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                _getInitials(senderName),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(String messageType) {
    switch (messageType) {
      case 'text':
        return _buildTextMessage();
      case 'image':
        return _buildImageMessage();
      case 'video':
        return _buildVideoMessage();
      case 'file':
        return _buildFileMessage();
      case 'audio':
        return _buildAudioMessage();
      case 'sticker':
        return _buildStickerMessage();
      default:
        return _buildTextMessage();
    }
  }

  Widget _buildTextMessage() {
    final text = messageData['text'] ?? messageData['message'] ?? '';
    return Text(
      text,
      style: TextStyle(
        color: isFromCurrentUser ? Colors.white : Colors.black87,
        fontSize: 16,
      ),
    );
  }

  Widget _buildImageMessage() {
    final imageUrl = messageData['imageUrl'] ?? messageData['url'] ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: 200,
              height: 150,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 200,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.broken_image,
                    size: 48,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
        if (messageData['text'] != null && messageData['text'].isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              messageData['text'],
              style: TextStyle(
                color: isFromCurrentUser ? Colors.white : Colors.black87,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVideoMessage() {
    final videoUrl = messageData['videoUrl'] ?? messageData['url'] ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 200,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.video_library,
                size: 48,
                color: Colors.grey,
              ),
              if (videoUrl.isNotEmpty)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _launchUrl(videoUrl),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (messageData['text'] != null && messageData['text'].isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              messageData['text'],
              style: TextStyle(
                color: isFromCurrentUser ? Colors.white : Colors.black87,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFileMessage() {
    final fileUrl = messageData['fileUrl'] ?? messageData['url'] ?? '';
    final fileName = messageData['fileName'] ?? 'ไฟล์';

    return GestureDetector(
      onTap: () => _launchUrl(fileUrl),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isFromCurrentUser ? Colors.white54 : Colors.grey[400]!,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file,
              color: isFromCurrentUser ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                fileName,
                style: TextStyle(
                  color: isFromCurrentUser ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioMessage() {
    final audioUrl = messageData['audioUrl'] ?? messageData['url'] ?? '';

    return GestureDetector(
      onTap: () => _launchUrl(audioUrl),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isFromCurrentUser ? Colors.white54 : Colors.grey[400]!,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.audiotrack,
              color: isFromCurrentUser ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              'ข้อความเสียง',
              style: TextStyle(
                color: isFromCurrentUser ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickerMessage() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.emoji_emotions,
        size: 80,
        color: Colors.orange,
      ),
    );
  }

  DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;

    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }

    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        // Try parsing as milliseconds
        final ms = int.tryParse(timestamp);
        if (ms != null) {
          return DateTime.fromMillisecondsSinceEpoch(ms);
        }
      }
    }

    return null;
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }
    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      print('Error launching URL: $e');
    }
  }
}
