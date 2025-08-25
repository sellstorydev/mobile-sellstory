import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/hashtag_input_field.dart';

class HashtagService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch hashtags from workspace settings
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

      final hashtagSettings = data['companyProfile']?['hashtagSettings'];
      if (hashtagSettings == null) {
        return [];
      }

      final masterList = hashtagSettings['masterList'] as List<dynamic>?;
      if (masterList == null) {
        return [];
      }

      return masterList
          .where((item) => item['enabled'] == true)
          .map((item) => HashtagOption.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      print('Error fetching workspace hashtags: $e');
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
      print('Error fetching hashtags by scope: $e');
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

        final data = doc.data();
        if (data == null) return;

        final hashtagSettings = data['companyProfile']?['hashtagSettings'];
        if (hashtagSettings == null) return;

        final masterList = hashtagSettings['masterList'] as List<dynamic>?;
        if (masterList == null) return;

        // Find and update the hashtag
        for (int i = 0; i < masterList.length; i++) {
          final hashtag = masterList[i];
          if (hashtag['id'] == hashtagId) {
            // Update total usage
            masterList[i]['totalUsage'] = (hashtag['totalUsage'] ?? 0) + 1;
            
            // Update scope-specific usage
            final usage = hashtag['usage'] as Map<String, dynamic>? ?? {};
            usage[scope] = (usage[scope] ?? 0) + 1;
            masterList[i]['usage'] = usage;
            
            break;
          }
        }

        // Update the document
        transaction.update(docRef, {
          'companyProfile.hashtagSettings.masterList': masterList,
        });
      });
    } catch (e) {
      print('Error incrementing hashtag usage: $e');
    }
  }

  /// Create a new hashtag
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
        if (!doc.exists) return;

        final data = doc.data();
        if (data == null) return;

        final hashtagSettings = data['companyProfile']?['hashtagSettings'];
        if (hashtagSettings == null) return;

        final masterList = hashtagSettings['masterList'] as List<dynamic>? ?? [];

        // Generate unique ID
        final id = _generateHashtagId(name);
        
        // Check if hashtag already exists
        final exists = masterList.any((item) => item['id'] == id);
        if (exists) {
          throw Exception('Hashtag already exists');
        }

        // Create new hashtag
        final usage = <String, int>{};
        for (final key in scopes.keys) {
          usage[key] = 0;
        }
        
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

        // Update the document
        transaction.update(docRef, {
          'companyProfile.hashtagSettings.masterList': masterList,
        });
      });

      return true;
    } catch (e) {
      print('Error creating hashtag: $e');
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

        final data = doc.data();
        if (data == null) return;

        final hashtagSettings = data['companyProfile']?['hashtagSettings'];
        if (hashtagSettings == null) return;

        final masterList = hashtagSettings['masterList'] as List<dynamic>?;
        if (masterList == null) return;

        // Find and update the hashtag
        for (int i = 0; i < masterList.length; i++) {
          final hashtag = masterList[i];
          if (hashtag['id'] == hashtagId) {
            if (name != null) masterList[i]['name'] = name;
            if (color != null) masterList[i]['color'] = color;
            if (scopes != null) masterList[i]['scopes'] = scopes;
            if (enabled != null) masterList[i]['enabled'] = enabled;
            break;
          }
        }

        // Update the document
        transaction.update(docRef, {
          'companyProfile.hashtagSettings.masterList': masterList,
        });
      });

      return true;
    } catch (e) {
      print('Error updating hashtag: $e');
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

        final data = doc.data();
        if (data == null) return;

        final hashtagSettings = data['companyProfile']?['hashtagSettings'];
        if (hashtagSettings == null) return;

        final masterList = hashtagSettings['masterList'] as List<dynamic>?;
        if (masterList == null) return;

        // Remove the hashtag
        masterList.removeWhere((item) => item['id'] == hashtagId);

        // Update the document
        transaction.update(docRef, {
          'companyProfile.hashtagSettings.masterList': masterList,
        });
      });

      return true;
    } catch (e) {
      print('Error deleting hashtag: $e');
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
