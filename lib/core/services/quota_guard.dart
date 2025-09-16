import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// QuotaGuard: lightweight, on-demand quota checking + popup alert.
/// Use before creating resources (boards, customers, products, etc.)
/// Example:
///   final ok = await QuotaGuard.ensureCanCreate(context, workspaceId, 'boards');
///   if(!ok) return; // already showed dialog
class QuotaGuard {
  static const Map<String, String> _resourceLabelsTh = {
    'boards': 'บอร์ด',
    'users': 'ผู้ใช้',
    'customers': 'ลูกค้า',
    'products': 'สินค้า',
    'pages': 'เพจ',
    'storageGB': 'พื้นที่จัดเก็บ',
  };

  static int _asInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static String _canonKey(String key) {
    // Canonical keys per docs
    if (key == 'chatPages') return 'pages';
    if (key == 'storage') return 'storageGB';
    return key;
  }

  static Map<String, int> _extractUsage(Map<String, dynamic> quota, String rawKey) {
    final key = _canonKey(rawKey);
    // Aliases in quota document
    String primary = key;
    String? alias;
    if (key == 'pages') alias = 'chatPages';
    if (key == 'storageGB') alias = 'storage';

    int used = 0;
    int limit = -1; // default unlimited

    dynamic entry = quota[primary];
    if (entry == null && alias != null) entry = quota[alias];

    if (entry is Map) {
      used = _asInt(entry['used']);
      final rawLimit = entry['limit'] ?? entry['max'];
      limit = rawLimit == null ? -1 : _asInt(rawLimit, fallback: -1);
    } else if (entry is int || entry is double || entry is String) {
      limit = _asInt(entry, fallback: -1);
    }

    final usedContainer = quota['used'];
    if (usedContainer is Map) {
      dynamic u = usedContainer[primary];
      if (u == null && alias != null) u = usedContainer[alias];
      if (u != null) used = _asInt(u, fallback: used);
    }

    if (used < 0) used = 0;
    return {'used': used, 'limit': limit};
  }

  static Future<bool> ensureCanCreate(BuildContext context, String workspaceId, String quotaKey) async {
    if (workspaceId.isEmpty) return true; // nothing to check
    try {
      final wsDoc = await FirebaseFirestore.instance.collection('workspaces').doc(workspaceId).get();
      if (!wsDoc.exists) return true;
      final data = wsDoc.data() ?? {};
      final quota = (data['quota'] ?? {}) as Map<String, dynamic>;

      print("------------");
      print(quota);
      print("------------");
      final usage = _extractUsage(quota, quotaKey);
      final used = usage['used'] ?? 0;
      final limit = usage['limit'] ?? -1;

      if (limit == -1) return true; // unlimited
      if (limit <= 0) return true; // unknown -> fail-open
      if (used >= limit) {
        _showQuotaFullDialog(context, _canonKey(quotaKey), used, limit);
        return false;
      }
      return true;
    } catch (_) {
      // On error allow to proceed (fail-open) to not block user unexpectedly
      return true;
    }
  }

  static void handleQuotaException(BuildContext context, Object error) {
    final msg = error.toString();
    final match = RegExp(r'quota_exceeded:([a-zA-Z0-9_]+)').firstMatch(msg);
    if (match != null) {
      final key = _canonKey(match.group(1)!);
      _showQuotaFullDialog(context, key, null, null);
    } else {
      Get.snackbar('Error', msg, snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  static void _showQuotaFullDialog(BuildContext context, String quotaKey, int? used, int? limit) {
    final label = _resourceLabelsTh[quotaKey] ?? quotaKey;
    final detail = (used != null && limit != null) ? '($used / $limit)' : '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ถึงขีดจำกัดโควต้า'),
        content: Text('ไม่สามารถสร้าง ${label} เพิ่มได้ โควต้าเต็มแล้ว $detail\nกรุณาลบรายการเก่าหรืออัปเกรดแพ็กเกจ'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }
}
