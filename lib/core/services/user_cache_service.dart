import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../data/services/firestore_service.dart';

/// UserCacheService provides in-memory caching and batched fetches
/// to minimize Firestore reads for user profiles (names, avatar, email).
class UserCacheService extends GetxService {
  static UserCacheService get to {
    if (Get.isRegistered<UserCacheService>()) return Get.find<UserCacheService>();
    return Get.put(UserCacheService(), permanent: true);
  }

  final Map<String, Map<String, dynamic>> _userCache = {};
  final Map<String, String> _nameCache = {};

  CollectionReference<Map<String, dynamic>> get _users => FirestoreService.to.usersCollection;

  /// Get display names for a list of UIDs. Returns uid->displayName map.
  /// Performs batched whereIn queries (chunks of 10) for missing UIDs.
  Future<Map<String, String>> getDisplayNames(List<String> uids) async {
    final out = <String, String>{};
    final missing = <String>[];

    for (final uid in uids) {
      if (uid.trim().isEmpty) continue;
      final cached = _nameCache[uid];
      if (cached != null && cached.isNotEmpty) {
        out[uid] = cached;
      } else {
        missing.add(uid);
      }
    }

    if (missing.isNotEmpty) {
      final chunks = _chunk(missing, 10);
      for (final chunk in chunks) {
        if (chunk.isEmpty) continue;
        final qs = await _users
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final doc in qs.docs) {
          final data = doc.data();
          _userCache[doc.id] = data;
          final dn = ((data['displayName'] ?? data['name'] ?? '').toString()).trim();
          final resolved = dn.isNotEmpty ? dn : doc.id;
          _nameCache[doc.id] = resolved;
          out[doc.id] = resolved;
        }
        // Any UID not returned by Firestore -> fallback to UID itself
        for (final uid in chunk) {
          if (!out.containsKey(uid)) {
            _nameCache[uid] = uid;
            out[uid] = uid;
          }
        }
      }
    }

    return out;
  }

  Future<String> getDisplayName(String uid) async {
    if (uid.trim().isEmpty) return '';
    final cached = _nameCache[uid];
    if (cached != null) return cached;
    final map = await getDisplayNames([uid]);
    return map[uid] ?? uid;
  }

  /// Get raw user data for list of UIDs. Returns uid->data map.
  Future<Map<String, Map<String, dynamic>>> getUsersData(List<String> uids) async {
    final out = <String, Map<String, dynamic>>{};
    final missing = <String>[];

    for (final uid in uids) {
      if (uid.trim().isEmpty) continue;
      final cached = _userCache[uid];
      if (cached != null) {
        out[uid] = cached;
      } else {
        missing.add(uid);
      }
    }

    if (missing.isNotEmpty) {
      final chunks = _chunk(missing, 10);
      for (final chunk in chunks) {
        if (chunk.isEmpty) continue;
        final qs = await _users
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final doc in qs.docs) {
          final data = doc.data();
          _userCache[doc.id] = data;
          out[doc.id] = data;
          // Also seed name cache
          final dn = ((data['displayName'] ?? data['name'] ?? '').toString()).trim();
          _nameCache[doc.id] = dn.isNotEmpty ? dn : doc.id;
        }
        for (final uid in chunk) {
          out.putIfAbsent(uid, () => <String, dynamic>{});
        }
      }
    }

    return out;
  }

  List<List<T>> _chunk<T>(List<T> list, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(list.sublist(i, i + size > list.length ? list.length : i + size));
    }
    return chunks;
  }
}
