import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final String currentUserId;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final messageType = message['type'] ?? 'text';
    final messageText = message['text'] ?? message['message'] ?? '';
    final sender = message['sender'] as Map<String, dynamic>? ?? {};
    final senderType = sender['type'] ?? 'user';
    final senderId = sender['id'] ?? '';
    final senderName = sender['name'] ?? 'Unknown';
    final senderAvatar = sender['avatar'];

    final isFromCurrentUser = senderId == currentUserId || senderType == 'admin';
    final timestamp = _parseTimestamp(message['timestamp']);

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

          // Message bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isFromCurrentUser
                    ? Colors.blue.shade500
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isFromCurrentUser ? 16 : 4),
                  bottomRight: Radius.circular(isFromCurrentUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sender name (for non-current users)
                  if (!isFromCurrentUser && senderName.isNotEmpty) ...[
                    Text(
                      senderName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],

                  // Message content based on type
                  _buildMessageContent(messageType, isFromCurrentUser),

                  // Timestamp
                  if (timestamp != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      timeago.format(timestamp, locale: 'th'),
                      style: TextStyle(
                        fontSize: 11,
                        color: isFromCurrentUser
                            ? Colors.white.withOpacity(0.7)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (isFromCurrentUser) ...[
            const SizedBox(width: 8),
            // Status indicator for current user messages
            Icon(
              Icons.check,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(String messageType, bool isFromCurrentUser) {
    switch (messageType.toLowerCase()) {
      case 'image':
        return _buildImageMessage(isFromCurrentUser);
      case 'video':
        return _buildVideoMessage(isFromCurrentUser);
      case 'file':
        return _buildFileMessage(isFromCurrentUser);
      case 'text':
      default:
        return _buildTextMessage(isFromCurrentUser);
    }
  }

  Widget _buildTextMessage(bool isFromCurrentUser) {
    final messageText = message['text'] ?? message['message'] ?? '';
    return Text(
      messageText,
      style: TextStyle(
        fontSize: 16,
        color: isFromCurrentUser ? Colors.white : Colors.black87,
        height: 1.3,
      ),
    );
  }

  Widget _buildImageMessage(bool isFromCurrentUser) {
    final imageUrl = message['imageUrl'] ?? message['url'] ?? message['file_url'];
    final text = message['text'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageUrl != null) ...[
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
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.broken_image, size: 50),
                );
              },
            ),
          ),
          if (text.isNotEmpty) const SizedBox(height: 8),
        ],
        if (text.isNotEmpty)
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: isFromCurrentUser ? Colors.white : Colors.black87,
              height: 1.3,
            ),
          ),
      ],
    );
  }

  Widget _buildVideoMessage(bool isFromCurrentUser) {
    final videoUrl = message['videoUrl'] ?? message['url'] ?? message['file_url'];
    final thumbnailUrl = message['thumbnailUrl'] ?? message['thumbnail'];
    final text = message['text'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (videoUrl != null) ...[
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: thumbnailUrl != null
                    ? Image.network(
                        thumbnailUrl,
                        width: 200,
                        height: 150,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 200,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.videocam, size: 50),
                      ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
            ],
          ),
          if (text.isNotEmpty) const SizedBox(height: 8),
        ],
        if (text.isNotEmpty)
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: isFromCurrentUser ? Colors.white : Colors.black87,
              height: 1.3,
            ),
          ),
      ],
    );
  }

  Widget _buildFileMessage(bool isFromCurrentUser) {
    final fileName = message['fileName'] ?? message['name'] ?? 'Unknown file';
    final fileSize = message['fileSize'] ?? message['size'];
    final fileUrl = message['fileUrl'] ?? message['url'] ?? message['file_url'];
    final text = message['text'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isFromCurrentUser
                ? Colors.white.withOpacity(0.2)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getFileIcon(fileName),
                color: isFromCurrentUser ? Colors.white : Colors.grey.shade600,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isFromCurrentUser ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (fileSize != null)
                      Text(
                        _formatFileSize(fileSize),
                        style: TextStyle(
                          fontSize: 12,
                          color: isFromCurrentUser
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.download,
                color: isFromCurrentUser ? Colors.white : Colors.grey.shade600,
                size: 20,
              ),
            ],
          ),
        ),
        if (text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: isFromCurrentUser ? Colors.white : Colors.black87,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }

  DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;

    try {
      if (timestamp is int) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else if (timestamp is String) {
        return DateTime.parse(timestamp);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(dynamic size) {
    if (size == null) return '';

    int bytes;
    if (size is String) {
      bytes = int.tryParse(size) ?? 0;
    } else if (size is int) {
      bytes = size;
    } else {
      return size.toString();
    }

    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
    }
    return (parts[0].isNotEmpty ? parts[0][0] : '') +
           (parts[1].isNotEmpty ? parts[1][0] : '');
  }
}
