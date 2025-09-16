import 'package:cloud_firestore/cloud_firestore.dart';

/// Canonical quota keys
const List<String> quotaKeys = [
  'users',
  'boards',
  'pages',
  'storageGB',
  'customers',
  'products',
];

/// Aliases for quota keys
const Map<String, String> quotaAliases = {
  'storage': 'storageGB',
  'chatPages': 'pages',
};

/// Normalized quota usage type
typedef UsageMap = Map<String, Map<String, int>>;

class QuotaService {
  /// Normalize the quota map from Firestore, handling aliases and missing keys.
  static UsageMap normalizeQuota(Map<String, dynamic>? quota) {
    final result = <String, Map<String, int>>{};
    quota ??= {};
    for (final key in quotaKeys) {
      final alias = quotaAliases.entries.firstWhere(
        (e) => e.value == key,
        orElse: () => const MapEntry('', ''),
      ).key;
      final raw = quota[key] ?? (alias.isNotEmpty ? quota[alias] : null);
      int used = 0;
      int limit = -1;
      if (raw is Map) {
        used = (raw['used'] ?? 0) is int ? raw['used'] ?? 0 : int.tryParse(raw['used'].toString()) ?? 0;
        limit = (raw['limit'] ?? raw['max'] ?? -1) is int ? (raw['limit'] ?? raw['max'] ?? -1) : int.tryParse((raw['limit'] ?? raw['max'] ?? -1).toString()) ?? -1;
      } else if (raw is int) {
        limit = raw;
      }
      result[key] = {'used': used, 'limit': limit};
    }
    return result;
  }

  /// Check if a quota is exceeded (returns true if used > limit and limit is not unlimited)
  static bool isQuotaExceeded(Map<String, int> quota) {
    final used = quota['used'] ?? 0;
    final limit = quota['limit'] ?? -1;
    return limit != -1 && used > limit;
  }

  /// Fetch quota for a workspace from Firestore and normalize it
  static Future<UsageMap> fetchAndNormalizeQuota(String workspaceId) async {
    final doc = await FirebaseFirestore.instance.collection('workspaces').doc(workspaceId).get();
    final data = doc.data();
    return normalizeQuota(data?['quota'] as Map<String, dynamic>?);
  }
}

