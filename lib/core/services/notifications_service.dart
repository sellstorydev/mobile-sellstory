// filepath: /Users/sarawutpromdee/Documents/Sellstoory/mobile-sellstory/lib/core/services/notifications_service.dart
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../network/api_client.dart';
import '../config/app_config.dart';
import 'logger_service.dart';

class NotificationsService extends GetxService {
  final ApiClient _api;

  NotificationsService(this._api);

  static NotificationsService get to => Get.find<NotificationsService>();

  Future<Map<String, dynamic>?> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? link,
    String? workspaceId,
    String? workspaceName,
    String? boardId,
    String? icon,
    String? createdBy,
    Map<String, dynamic>? data,
  }) async {
    try {
      final secret = AppConfig.mobileBackendSecret;
      final headers = <String, dynamic>{
        'Content-Type': 'application/json',
      };
      if (secret.isNotEmpty) {
        headers['x-mobile-secret'] = secret;
      }

      final res = await _api.post<Map<String, dynamic>>(
        '/api/notifications/create',
        data: {
          'userId': userId,
          'type': type,
          'title': title,
          'message': message,
          if (link != null) 'link': link,
          if (workspaceId != null) 'workspaceId': workspaceId,
          if (workspaceName != null) 'workspaceName': workspaceName,
          if (boardId != null) 'boardId': boardId,
          if (icon != null) 'icon': icon,
          if (createdBy != null) 'createdBy': createdBy,
          if (data != null) 'data': data,
        },
        options: Options(headers: headers),
      );
      LoggerService.to.business('Notification API success: ${res.data}');
      return res.data;
    } catch (e) {
      LoggerService.to.error('Notification API failed', e);
      return null;
    }
  }

  Future<void> notifyCardAssignment({
    required String assigneeId,
    required String assignerName,
    required String cardId,
    required String boardId,
    String? workspaceId,
    String? workspaceName,
    String? createdBy,
  }) async {
    final link = '/?cardId=$cardId&boardId=$boardId';
    await createNotification(
      userId: assigneeId,
      type: 'onCardAssignment',
      title: 'New Assignment',
      message: '$assignerName assigned you a job card',
      link: link,
      workspaceId: workspaceId,
      workspaceName: workspaceName,
      boardId: boardId,
      createdBy: createdBy,
      data: {
        'cardId': cardId,
        'boardId': boardId,
        'assignerName': assignerName,
      },
    );
  }

  Future<void> notifyStatusChange({
    required List<String> userIds,
    required String cardId,
    required String boardId,
    required String oldStatus,
    required String newStatus,
    String? workspaceId,
    String? workspaceName,
    String? createdBy,
  }) async {
    final link = '/?cardId=$cardId&boardId=$boardId';
    for (final uid in userIds.toSet()) {
      await createNotification(
        userId: uid,
        type: 'onStatusChange',
        title: 'Card moved',
        message: 'Status changed: $oldStatus → $newStatus',
        link: link,
        workspaceId: workspaceId,
        workspaceName: workspaceName,
        boardId: boardId,
        createdBy: createdBy,
        data: {
          'cardId': cardId,
          'boardId': boardId,
          'oldStatus': oldStatus,
          'newStatus': newStatus,
        },
      );
    }
  }

  Future<void> notifyComment({
    required List<String> userIds,
    required String commenterName,
    required String cardId,
    required String boardId,
    String? workspaceId,
    String? workspaceName,
    String? createdBy,
  }) async {
    final link = '/?cardId=$cardId&boardId=$boardId';
    for (final uid in userIds.toSet()) {
      await createNotification(
        userId: uid,
        type: 'onComment',
        title: 'New Comment',
        message: '$commenterName commented on a card',
        link: link,
        workspaceId: workspaceId,
        workspaceName: workspaceName,
        boardId: boardId,
        createdBy: createdBy,
        data: {
          'cardId': cardId,
          'boardId': boardId,
          'commenterName': commenterName,
        },
      );
    }
  }

  Future<void> notifyTagged({
    required List<String> taggedUserIds,
    required String cardId,
    required String boardId,
    required String contextType, // 'description' | 'comment' | 'todo'
    String? workspaceId,
    String? workspaceName,
    String? createdBy,
  }) async {
    if (taggedUserIds.isEmpty) return;
    final link = '/?cardId=$cardId&boardId=$boardId';
    for (final uid in taggedUserIds.toSet()) {
      await createNotification(
        userId: uid,
        type: 'onTagged',
        title: 'You were mentioned',
        message: 'You were mentioned in a $contextType',
        link: link,
        workspaceId: workspaceId,
        workspaceName: workspaceName,
        boardId: boardId,
        createdBy: createdBy,
        data: {
          'cardId': cardId,
          'boardId': boardId,
          'contextType': contextType,
        },
      );
    }
  }
}

