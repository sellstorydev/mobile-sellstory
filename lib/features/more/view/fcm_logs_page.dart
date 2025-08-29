// filepath: lib/features/more/view/fcm_logs_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/logger_service.dart';

class FcmLogsPage extends StatelessWidget {
  const FcmLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final logger = LoggerService.to;
    return Scaffold(
      appBar: AppBar(
        title: const Text('FCM Logs'),
        actions: [
          IconButton(
            tooltip: 'Clear logs',
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              logger.clearFcmLogs();
              Get.snackbar('Cleared', 'FCM logs cleared', snackPosition: SnackPosition.BOTTOM);
            },
          ),
        ],
      ),
      body: Obx(() {
        final logs = List<Map<String, dynamic>>.from(logger.fcmLogs);
        if (logs.isEmpty) {
          return const Center(
            child: Text('No FCM logs yet'),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: logs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = logs[index];
            final ts = (item['ts'] ?? '').toString();
            final event = (item['event'] ?? '').toString();
            final message = (item['message'] ?? '').toString();
            final data = item['data'];

            String? title;
            String? body;
            if (data is Map) {
              title = (data['title'] ?? data['notification']?['title'] ?? '').toString();
              body = (data['body'] ?? data['notification']?['body'] ?? '').toString();
            }

            return Material(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                title: Row(
                  children: [
                    const Icon(Icons.notifications_active_outlined, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.isEmpty ? 'event' : event, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(
                            title?.isNotEmpty == true ? title! : (message.isNotEmpty ? message : '(no title)'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade800),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(ts.split('T').join(' ').split('.').first, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
                subtitle: (body != null && body!.isNotEmpty)
                    ? Padding(
                        padding: const EdgeInsets.only(left: 32, top: 4),
                        child: Text(
                          body!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      )
                    : null,
                children: [
                  if (message.isNotEmpty) ...[
                    const Text('Message', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    SelectableText(message),
                    const SizedBox(height: 8),
                  ],
                  if (data is Map && data.isNotEmpty) ...[
                    const Text('Data', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    SelectableText(_prettyJson(data)),
                  ],
                ],
              ),
            );
          },
        );
      }),
    );
  }
}

String _prettyJson(Map data) {
  try {
    // Keep it simple; avoid jsonEncode to keep dependencies minimal
    final entries = data.entries.map((e) => '  ${e.key}: ${e.value}').join('\n');
    return '{\n$entries\n}';
  } catch (_) {
    return data.toString();
  }
}

