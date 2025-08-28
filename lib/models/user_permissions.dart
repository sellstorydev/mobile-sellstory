// filepath: /Users/sarawutpromdee/Documents/Sellstoory/mobile-sellstory/lib/models/user_permissions.dart
class UserPermissions {
  final String roleId;
  final String roleName;
  final List<String> permissions;

  const UserPermissions({
    required this.roleId,
    required this.roleName,
    required this.permissions,
  });

  factory UserPermissions.fromJson(Map<String, dynamic> json) {
    final perms = (json['permissions'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
    return UserPermissions(
      roleId: json['roleId']?.toString() ?? '',
      roleName: json['roleName']?.toString() ?? '',
      permissions: perms,
    );
  }

  Map<String, dynamic> toJson() => {
        'roleId': roleId,
        'roleName': roleName,
        'permissions': permissions,
      };

  bool get isOwner => roleId == 'owner' || permissions.contains('*');

  bool can(String permission) {
    if (isOwner) return true;
    return permissions.contains(permission);
  }
}

