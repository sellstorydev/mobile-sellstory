// filepath: /Users/sarawutpromdee/Documents/Sellstoory/mobile-sellstory/lib/core/widgets/permission_guard.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/mobile_permissions_service.dart';

/// A simple widget to show [child] only if the user has the required permission.
/// If not allowed, it shows [fallback] or nothing (when [hideIfUnauthorized] is true).
class PermissionGuard extends StatelessWidget {
  final String? permission;
  final List<String>? anyOf;
  final Widget child;
  final Widget? fallback;
  final bool hideIfUnauthorized;

  PermissionGuard({
    super.key,
    this.permission,
    this.anyOf,
    required this.child,
    this.fallback,
    this.hideIfUnauthorized = true,
  });

  bool _isAllowed(MobilePermissionsService svc) {
    if (svc.isOwner) return true;
    if (anyOf != null && anyOf!.isNotEmpty) {
      return anyOf!.any((p) => svc.can(p));
    }
    if (permission != null) {
      return svc.can(permission!);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final svc = MobilePermissionsService.to;
      final allowed = _isAllowed(svc);
      if (allowed) return child;
      if (fallback != null) return fallback!;
      if (hideIfUnauthorized) return const SizedBox.shrink();
      // Disabled state fallback (basic)
      return IgnorePointer(
        child: Opacity(opacity: 0.4, child: child),
      );
    });
  }
}

/// Guard an action by permission; executes [onAllowed] if permitted,
/// otherwise shows a snack bar with a friendly message.
void guardAction(BuildContext context, String permission, VoidCallback onAllowed,
    {String? deniedMessage}) {
  final svc = MobilePermissionsService.to;
  if (svc.isOwner || svc.can(permission)) {
    onAllowed();
  } else {
    final msg = deniedMessage ?? 'คุณไม่มีสิทธิ์ในการทำรายการนี้';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}
