import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/hashtag_input_field.dart';

class HashtagService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper: extract hashtag settings map and update path from workspace doc data
  // Returns a tuple-like map: {'settings': Map<String,dynamic>, 'path': String}
  Map<String, dynamic> _extractSettings(Map<String, dynamic> data) {
    Map<String, dynamic> settings = const {};
    String path = '';
    // Prefer root-level hashtagSettings if present
    final root = data['hashtagSettings'];
    if (root is Map) {
      settings = Map<String, dynamic>.from(root);
      path = 'hashtagSettings';
      return {'settings': settings, 'path': path};
    }
    // Fallback to companyProfile.hashtagSettings
    final cp = data['companyProfile'];
    if (cp is Map) {
      final cpMap = Map<String, dynamic>.from(cp);
      final raw = cpMap['hashtagSettings'];
      if (raw is Map) {
        settings = Map<String, dynamic>.from(raw);
        path = 'companyProfile.hashtagSettings';
        return {'settings': settings, 'path': path};
      }
    }
    // Nothing found
    return {'settings': <String, dynamic>{}, 'path': ''};
  }


  // Helper: pick update path; if none exists, initialize under companyProfile.hashtagSettings
  String _ensureSettingsPath(Map<String, dynamic> data) {
    // If root exists, use it
    if (data['hashtagSettings'] is Map) return 'hashtagSettings';
    // If companyProfile.hashtagSettings exists, use it
    if (data['companyProfile'] is Map && (data['companyProfile'] as Map)['hashtagSettings'] is Map) {
      return 'companyProfile.hashtagSettings';
    }
    // Otherwise, we'll initialize under companyProfile.hashtagSettings
    return 'companyProfile.hashtagSettings';
  }

  /// Fetch hashtags from workspace settings (supports root and companyProfile paths)
  Future<List<HashtagOption>> getWorkspaceHashtags(String workspaceId) async {
    try {
      final doc = await _firestore
          .collection('workspaces')
          .doc(workspaceId)
          .get();

      if (!doc.exists) {
        return [];
      }

      final data = doc.data();
      if (data == null) {
        return [];
      }

      final extracted = _extractSettings(data);
      final hashtagSettings = extracted['settings'] as Map<String, dynamic>;
      if (hashtagSettings.isEmpty) {
        return [];
      }

      final masterList = hashtagSettings['masterList'] as List<dynamic>?;
      if (masterList == null) {
        return [];
      }

      return masterList
          .where((item) => item is Map && (item['enabled'] != false))
          .map((item) => HashtagOption.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (e) {
      print('❌ Error fetching workspace hashtags: $e');
      return [];
    }
  }

  /// Fetch hashtags filtered by scope
  Future<List<HashtagOption>> getHashtagsByScope(
    String workspaceId,
    String scope,
  ) async {
    try {
      final allHashtags = await getWorkspaceHashtags(workspaceId);
      return allHashtags
          .where((hashtag) => hashtag.scopes[scope] == true)
          .toList();
    } catch (e) {
      print('❌ Error fetching hashtags by scope: $e');
      return [];
    }
  }

  /// Update hashtag usage count
  Future<void> incrementHashtagUsage(
    String workspaceId,
    String hashtagId,
    String scope,
  ) async {
    try {
      final docRef = _firestore
          .collection('workspaces')
          .doc(workspaceId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) return;

        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return;

        final extracted = _extractSettings(data);
        Map<String, dynamic> hashtagSettings = extracted['settings'] as Map<String, dynamic>;
        String path = extracted['path'] as String;
        if (path.isEmpty) {
          // Nothing to increment
          return;
        }

        final masterList = (hashtagSettings['masterList'] as List?)?.toList() ?? [];

        for (int i = 0; i < masterList.length; i++) {
          final raw = masterList[i];
          if (raw is! Map) continue;
          final hashtag = Map<String, dynamic>.from(raw);
          if (hashtag['id'] == hashtagId) {
            hashtag['totalUsage'] = (hashtag['totalUsage'] ?? 0) + 1;
            final usage = (hashtag['usage'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0)) ?? <String, int>{};
            usage[scope] = (usage[scope] ?? 0) + 1;
            hashtag['usage'] = usage;
            masterList[i] = hashtag;
            break;
          }
        }

        hashtagSettings['masterList'] = masterList;
        transaction.update(docRef, {
          '$path.masterList': masterList,
        });
      });
    } catch (e) {
      print('❌ Error incrementing hashtag usage: $e');
    }
  }

  /// Create a new hashtag (supports root/companyProfile storage)
  Future<bool> createHashtag(
    String workspaceId,
    String name,
    String color,
    Map<String, bool> scopes,
  ) async {
    try {
      final docRef = _firestore
          .collection('workspaces')
          .doc(workspaceId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) throw Exception('Workspace not found');

        final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};

        // Pick path; initialize if missing
        final path = _ensureSettingsPath(data);

        // Clone current settings or init
        Map<String, dynamic> settings;
        if (path == 'hashtagSettings') {
          settings = (data['hashtagSettings'] is Map)
              ? Map<String, dynamic>.from(data['hashtagSettings'] as Map)
              : <String, dynamic>{};
        } else {
          final cp = (data['companyProfile'] is Map)
              ? Map<String, dynamic>.from(data['companyProfile'] as Map)
              : <String, dynamic>{};
          final raw = (cp['hashtagSettings'] is Map)
              ? Map<String, dynamic>.from(cp['hashtagSettings'] as Map)
              : <String, dynamic>{};
          settings = raw;
        }

        final masterList = (settings['masterList'] as List?)?.map((e) => e is Map ? Map<String, dynamic>.from(e) : {'id': '$e'}).toList() ?? <Map<String, dynamic>>[];

        // Generate unique ID
        final id = _generateHashtagId(name);

        // Fail if hashtag already exists
        final exists = masterList.any((item) => (item['id'] ?? '') == id);
        if (exists) {
          throw Exception('Hashtag already exists');
        }

        // Create new hashtag
        final usage = <String, int>{ for (final key in scopes.keys) key: 0 };
        final newHashtag = {
          'id': id,
          'name': name,
          'color': color,
          'totalUsage': 0,
          'enabled': true,
          'scopes': scopes,
          'usage': usage,
        };

        masterList.add(newHashtag);

        // Persist at path
        settings['masterList'] = masterList;
        if (path == 'hashtagSettings') {
          transaction.update(docRef, {
            'hashtagSettings.masterList': masterList,
          });
        } else {
          // Ensure companyProfile exists
          transaction.update(docRef, {
            'companyProfile.hashtagSettings.masterList': masterList,
          });
        }
      });

      return true;
    } catch (e) {
      print('❌ Error creating hashtag: $e');
      return false;
    }
  }

  /// Update hashtag
  Future<bool> updateHashtag(
    String workspaceId,
    String hashtagId, {
    String? name,
    String? color,
    Map<String, bool>? scopes,
    bool? enabled,
  }) async {
    try {
      final docRef = _firestore
          .collection('workspaces')
          .doc(workspaceId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) return;

        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return;

        final extracted = _extractSettings(data);
        Map<String, dynamic> hashtagSettings = extracted['settings'] as Map<String, dynamic>;
        String path = extracted['path'] as String;
        if (path.isEmpty) return;

        final masterList = (hashtagSettings['masterList'] as List?)?.map((e) => e is Map ? Map<String, dynamic>.from(e) : {'id': '$e'}).toList() ?? <Map<String, dynamic>>[];

        for (int i = 0; i < masterList.length; i++) {
          if ((masterList[i]['id'] ?? '') == hashtagId) {
            if (name != null) masterList[i]['name'] = name;
            if (color != null) masterList[i]['color'] = color;
            if (scopes != null) masterList[i]['scopes'] = scopes;
            if (enabled != null) masterList[i]['enabled'] = enabled;
            break;
          }
        }

        transaction.update(docRef, {
          '$path.masterList': masterList,
        });
      });

      return true;
    } catch (e) {
      print('❌ Error updating hashtag: $e');
      return false;
    }
  }

  /// Delete hashtag
  Future<bool> deleteHashtag(String workspaceId, String hashtagId) async {
    try {
      final docRef = _firestore
          .collection('workspaces')
          .doc(workspaceId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) return;

        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return;

        final extracted = _extractSettings(data);
        Map<String, dynamic> hashtagSettings = extracted['settings'] as Map<String, dynamic>;
        String path = extracted['path'] as String;
        if (path.isEmpty) return;

        final masterList = (hashtagSettings['masterList'] as List?)?.map((e) => e is Map ? Map<String, dynamic>.from(e) : {'id': '$e'}).toList() ?? <Map<String, dynamic>>[];
        masterList.removeWhere((item) => (item['id'] ?? '') == hashtagId);

        transaction.update(docRef, {
          '$path.masterList': masterList,
        });
      });

      return true;
    } catch (e) {
      print('❌ Error deleting hashtag: $e');
      return false;
    }
  }

  /// Generate unique hashtag ID
  String _generateHashtagId(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  /// Convert hashtag IDs to display string
  String hashtagIdsToString(List<String> hashtagIds, List<HashtagOption> availableHashtags) {
    if (hashtagIds.isEmpty) return '';
    
    final hashtagNames = hashtagIds.map((id) {
      final hashtag = availableHashtags.firstWhere(
        (h) => h.id == id,
        orElse: () => HashtagOption(
          id: id,
          name: id,
          color: '#ef4444',
          totalUsage: 0,
          enabled: true,
          scopes: {},
        ),
      );
      return '#${hashtag.name}';
    }).toList();
    
    return hashtagNames.join(' ');
  }

  /// Convert display string to hashtag IDs
  List<String> stringToHashtagIds(String hashtagString, List<HashtagOption> availableHashtags) {
    if (hashtagString.isEmpty) return [];
    
    final hashtagNames = hashtagString
        .split(' ')
        .where((word) => word.startsWith('#'))
        .map((word) => word.substring(1))
        .toList();
    
    return hashtagNames.map((name) {
      final hashtag = availableHashtags.firstWhere(
        (h) => h.name.toLowerCase() == name.toLowerCase(),
        orElse: () => HashtagOption(
          id: name,
          name: name,
          color: '#ef4444',
          totalUsage: 0,
          enabled: true,
          scopes: {},
        ),
      );
      return hashtag.id;
    }).toList();
  }
}
