import 'package:cloud_firestore/cloud_firestore.dart';

class WorkspaceMember {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final String permission; // owner, admin, member

  WorkspaceMember({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    required this.permission,
  });

  factory WorkspaceMember.fromMap(Map<String, dynamic> map) {
    return WorkspaceMember(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoURL: map['photoURL'],
      permission: map['permission'] ?? 'member',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'permission': permission,
    };
  }
}

class WorkspaceMembersService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all members of a workspace with their full user data
  Future<List<WorkspaceMember>> getWorkspaceMembers(String workspaceId) async {
    try {
      // Get workspace document to access members
      final workspaceDoc = await _firestore.collection('workspaces').doc(workspaceId).get();
      
      if (!workspaceDoc.exists) {
        print('❌ Workspace not found: $workspaceId');
        return [];
      }

      final workspaceData = workspaceDoc.data()!;
      final members = workspaceData['members'] as Map<String, dynamic>? ?? {};
      
      print('📋 Found ${members.length} members in workspace');
      
      // Get full user data for each member
      final List<WorkspaceMember> workspaceMembers = [];
      
      for (final entry in members.entries) {
        final memberUid = entry.key;
        final permission = entry.value as String? ?? 'member';
        
        try {
          // Get user data from users collection
          final userDoc = await _firestore.collection('users').doc(memberUid).get();
          
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            final member = WorkspaceMember(
              uid: memberUid,
              email: userData['email'] ?? '',
              displayName: userData['displayName'] ?? '',
              photoURL: userData['photoURL'],
              permission: permission,
            );
            workspaceMembers.add(member);
            print('✅ Added member: ${member.displayName} (${member.permission})');
          } else {
            print('⚠️ User not found: $memberUid');
          }
        } catch (e) {
          print('❌ Error fetching user data for $memberUid: $e');
        }
      }
      
      print('📋 Total workspace members loaded: ${workspaceMembers.length}');
      return workspaceMembers;
    } catch (e) {
      print('❌ Error getting workspace members: $e');
      return [];
    }
  }

  /// Get workspace members filtered by permission
  Future<List<WorkspaceMember>> getWorkspaceMembersByPermission(
    String workspaceId, 
    List<String>? permissions
  ) async {
    final allMembers = await getWorkspaceMembers(workspaceId);
    if (permissions == null) {
      return allMembers;
    }
    return allMembers.where((member) => permissions.contains(member.permission)).toList();
  }

  /// Get only assignable members (admin and member, not owner)
  Future<List<WorkspaceMember>> getAssignableMembers(String workspaceId) async {
    return getWorkspaceMembersByPermission(workspaceId, null);
  }
}
