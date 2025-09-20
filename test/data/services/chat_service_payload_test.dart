import 'package:flutter_test/flutter_test.dart';
import 'package:sellstory/data/services/chat_service.dart' as cs;

void main() {
  group('ChatService.buildSendMessagePayload (LINE)', () {
    const wsId = 'W1';
    const chatId = 'C1';
    const platform = 'line';

    test('text reply moves replyTo to top-level and keeps quoteToken', () {
      final message = <String, dynamic>{
        'type': 'text',
        'text': 'ตอบกลับครับ',
        'quoteText': 'เดิม',
        'reply': {
          'id': 'orig123',
          'text': 'เดิม',
          'type': 'text',
        },
        'replyTo': {
          'messageId': 'orig123',
          'quotedMessageId': 'orig123',
          'messageText': 'เดิม',
          'senderName': 'Alice',
          'quoteToken': 'qt_abc',
        },
      };

      final payload = cs.ChatService.buildSendMessagePayload(
        workspaceId: wsId,
        chatroomId: chatId,
        platform: platform,
        message: message,
      );

      expect(payload['workspaceId'], wsId);
      expect(payload['chatroomId'], chatId);
      expect(payload['platform'], platform);

      // replyTo must be moved to top-level
      final top = payload['replyTo'] as Map<String, dynamic>;
      expect(top['messageId'], 'orig123');
      expect(top['quotedMessageId'], 'orig123');
      expect(top['messageText'], 'เดิม');
      expect(top['senderName'], 'Alice');
      expect(top['quoteToken'], 'qt_abc');

      final msg = payload['message'] as Map<String, dynamic>;
      expect(msg['type'], 'text');
      expect(msg['text'], 'ตอบกลับครับ');
      expect(msg['quoteText'], 'เดิม');
      // replyTo must be removed from message
      expect(msg.containsKey('replyTo'), isFalse);
      // keep minimal reply block for UI (optional behavior)
      expect((msg['reply'] as Map)['id'], 'orig123');
    });

    test('video with reply keeps caption and moves replyTo', () {
      final message = <String, dynamic>{
        'type': 'video',
        'videoUrl': 'https://example.com/video.mp4',
        'text': 'แคปชัน',
        'replyTo': {
          'messageId': 'origV1',
          'quotedMessageId': 'origV1',
          'quoteToken': 'qt_v1',
        },
      };

      final payload = cs.ChatService.buildSendMessagePayload(
        workspaceId: wsId,
        chatroomId: chatId,
        platform: platform,
        message: message,
      );

      final top = payload['replyTo'] as Map<String, dynamic>;
      expect(top['messageId'], 'origV1');
      expect(top['quotedMessageId'], 'origV1');
      expect(top['quoteToken'], 'qt_v1');

      final msg = payload['message'] as Map<String, dynamic>;
      expect(msg['type'], 'video');
      expect(msg['videoUrl'], 'https://example.com/video.mp4');
      expect(msg['text'], 'แคปชัน');
      expect(msg.containsKey('replyTo'), isFalse);
    });

    test('no replyTo -> no top-level replyTo', () {
      final message = <String, dynamic>{
        'type': 'video',
        'videoUrl': 'https://example.com/v2.mp4',
      };

      final payload = cs.ChatService.buildSendMessagePayload(
        workspaceId: wsId,
        chatroomId: chatId,
        platform: platform,
        message: message,
      );

      expect(payload.containsKey('replyTo'), isFalse);
      final msg = payload['message'] as Map<String, dynamic>;
      expect(msg['type'], 'video');
      expect(msg['videoUrl'], 'https://example.com/v2.mp4');
    });
  });
}
