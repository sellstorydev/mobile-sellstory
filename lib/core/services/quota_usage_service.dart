import 'package:cloud_firestore/cloud_firestore.dart';

/// QuotaUsageService: safe increment/decrement of workspace quota.used values.
/// - Updates workspaces/{id}.quota.used.<key>
/// - Reads current used from either quota.used.<key> or quota.<key>.used
/// - Clamps result to >= 0 to avoid negative usage
class QuotaUsageService {
  static final FirebaseFirestore _fs = FirebaseFirestore.instance;

  static int _asInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  /// Increment usage by [delta] (can be negative). Result is clamped to >= 0.
  static Future<void> incrementUsed(String workspaceId, String quotaKey, {int delta = 1}) async {
    if (workspaceId.isEmpty || quotaKey.isEmpty || delta == 0) return;
    final ref = _fs.collection('workspaces').doc(workspaceId);

    await _fs.runTransaction((txn) async {
      final snap = await txn.get(ref);
      final data = (snap.data() ?? {}) as Map<String, dynamic>;
      final quota = (data['quota'] ?? {}) as Map<String, dynamic>;

      int current = 0;
      final usedContainer = quota['used'];
      if (usedContainer is Map) {
        final v = usedContainer[quotaKey];
        if (v != null) current = _asInt(v);
      }
      if (current == 0) {
        final entry = quota[quotaKey];
        if (entry is Map && entry['used'] != null) {
          current = _asInt(entry['used']);
        }
      }

      final next = current + delta;
      final clamped = next < 0 ? 0 : next;

      if (snap.exists) {
        // Update dotted path when doc exists
        txn.update(ref, {'quota.used.$quotaKey': clamped});
      } else {
        // Create nested structure with merge
        txn.set(ref, {
          'quota': {
            'used': {quotaKey: clamped},
          }
        }, SetOptions(merge: true));
      }
    });
  }

  static Future<void> decrementUsed(String workspaceId, String quotaKey, {int delta = 1}) async {
    await incrementUsed(workspaceId, quotaKey, delta: -delta);
  }
}
