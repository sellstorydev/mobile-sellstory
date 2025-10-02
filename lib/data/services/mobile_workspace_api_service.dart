import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../core/network/mobile_api.dart';
import '../services/firebase_auth_service.dart';
import '../../domain/entities/board.dart';

/// Response models matching the API specification

/// Mobile Board Info from API
class MobileBoardInfo {
  final String id;
  final String name;
  final String? description;
  final int cardCount;
  final int laneCount;
  final int lastModified;

  MobileBoardInfo({
    required this.id,
    required this.name,
    this.description,
    required this.cardCount,
    required this.laneCount,
    required this.lastModified,
  });

  factory MobileBoardInfo.fromJson(Map<String, dynamic> json) {
    return MobileBoardInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      cardCount: json['cardCount'] as int,
      laneCount: json['laneCount'] as int,
      lastModified: json['lastModified'] as int,
    );
  }

  /// Convert to Board entity for compatibility with existing code
  /// Note: workspaceId, createdBy, members must be filled in by caller
  Board toBoard({
    required String workspaceId,
    String? createdBy,
  }) {
    return Board(
      id: id,
      name: name,
      workspaceId: workspaceId,
      createdBy: createdBy ?? '',
      members: [], // Not included in summary API
      memberUids: [], // Not included in summary API
      lanes: [], // Not included in summary API
      createdAt: DateTime.fromMillisecondsSinceEpoch(lastModified),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(lastModified),
    );
  }
}

/// Mobile Workspace Response from API
class MobileWorkspaceResponse {
  final String id;
  final String name;
  final String role;
  final int boardCount;
  final int memberCount;
  final String status;
  final String packageId;
  final Map<String, dynamic> subscription;
  final List<MobileBoardInfo> boards;

  MobileWorkspaceResponse({
    required this.id,
    required this.name,
    required this.role,
    required this.boardCount,
    required this.memberCount,
    required this.status,
    required this.packageId,
    required this.subscription,
    required this.boards,
  });

  factory MobileWorkspaceResponse.fromJson(Map<String, dynamic> json) {
    return MobileWorkspaceResponse(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      boardCount: json['boardCount'] as int,
      memberCount: json['memberCount'] as int,
      status: json['status'] as String,
      packageId: json['packageId'] as String,
      subscription: json['subscription'] as Map<String, dynamic>,
      boards: (json['boards'] as List<dynamic>)
          .map((b) => MobileBoardInfo.fromJson(b as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Convert to workspace map for compatibility with existing code
  Map<String, dynamic> toWorkspaceMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
    };
  }
}

/// Mobile Workspaces API Response
class MobileWorkspacesApiResponse {
  final bool success;
  final MobileWorkspacesData? data;
  final String? error;

  MobileWorkspacesApiResponse({
    required this.success,
    this.data,
    this.error,
  });

  factory MobileWorkspacesApiResponse.fromJson(Map<String, dynamic> json) {
    return MobileWorkspacesApiResponse(
      success: json['success'] as bool,
      data: json['data'] != null
          ? MobileWorkspacesData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      error: json['error'] as String?,
    );
  }
}

class MobileWorkspacesData {
  final List<MobileWorkspaceResponse> workspaces;
  final String? activeWorkspaceId;

  MobileWorkspacesData({
    required this.workspaces,
    this.activeWorkspaceId,
  });

  factory MobileWorkspacesData.fromJson(Map<String, dynamic> json) {
    return MobileWorkspacesData(
      workspaces: (json['workspaces'] as List<dynamic>)
          .map((w) => MobileWorkspaceResponse.fromJson(w as Map<String, dynamic>))
          .toList(),
      activeWorkspaceId: json['activeWorkspaceId'] as String?,
    );
  }
}

/// Service for calling Mobile Workspace API
class MobileWorkspaceApiService extends GetxService {
  final Dio _dio = Dio();
  final FirebaseAuthService _authService = Get.find<FirebaseAuthService>();

  /// Get all workspaces and boards for current user
  /// Calls GET /api/mobile/workspaces
  Future<MobileWorkspacesApiResponse> getWorkspaces() async {
    try {
      print('🔄 Fetching workspaces from API...');
      
      // Get Firebase ID token
      final token = await MobileApiAuth.getIdTokenOrThrow(_authService);
      
      // Call API
      final response = await _dio.get(
        '${MobileApiConfig.baseUrl}/api/mobile/workspaces',
        options: MobileApiAuth.authHeaderOptions(token),
      );

      print('✅ Workspaces API response received');
      
      // Parse response
      final apiResponse = MobileWorkspacesApiResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      if (!apiResponse.success) {
        throw Exception(apiResponse.error ?? 'Failed to fetch workspaces');
      }

      print('✅ Successfully parsed ${apiResponse.data?.workspaces.length ?? 0} workspaces');
      
      return apiResponse;
    } on DioException catch (e) {
      print('❌ Dio error fetching workspaces: ${e.message}');
      if (e.response != null) {
        print('❌ Response status: ${e.response?.statusCode}');
        print('❌ Response data: ${e.response?.data}');
      }
      rethrow;
    } catch (e) {
      print('❌ Error fetching workspaces from API: $e');
      rethrow;
    }
  }

  /// Get boards for a specific workspace from cached API data
  /// Returns empty list if workspace not found
  List<Board> getBoardsForWorkspaceFromCache(
    String workspaceId,
    List<MobileWorkspaceResponse> cachedWorkspaces,
  ) {
    try {
      final workspace = cachedWorkspaces.firstWhereOrNull(
        (w) => w.id == workspaceId,
      );
      
      if (workspace == null) {
        print('⚠️ Workspace $workspaceId not found in cache');
        return [];
      }

      return workspace.boards
          .map((b) => b.toBoard(workspaceId: workspaceId))
          .toList();
    } catch (e) {
      print('❌ Error getting boards from cache: $e');
      return [];
    }
  }
}
