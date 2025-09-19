# Firebase Chatroom Fields and How to Access Them (Mobile)

This guide documents the key Firestore fields used for chat status, auto-reply (bot), and pinning, plus ready-to-use code examples in Flutter/Dart.

Collection structure:
- workspaces/{workspaceId}/chatrooms/{chatroomId}
- workspaces/{workspaceId}/customers/{customerId}

## Fields

- bot_status: String
  - Y: Auto-reply enabled
  - N: Auto-reply disabled
- chatroom_status: String
  - INPROGRESS: Chat is ongoing
  - DONE: Chat is finished
- chat_pin: String
  - Y: Pinned
  - N: Not pinned
- hashtags (chatroom mirror): List<String>
  - List of display names, typically prefixed with #, mirrored for quick UI rendering
- hashtagIds (chatroom mirror): List<String>
  - Canonical hashtag IDs for filtering and analytics
- customers/{customerId}.hashtags: List<Map<String, dynamic>>
  - Source of truth of customer tags with color:
  - Each item: { id: string, text: string, color: string("#RRGGBB") }

## Quick Read/Write Examples

Init:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
final db = FirebaseFirestore.instance;
```

Read one chatroom:

```dart
Future<Map<String, dynamic>> getChatroomMeta(String wsId, String roomId) async {
  final snap = await db.collection('workspaces').doc(wsId).collection('chatrooms').doc(roomId).get();
  return snap.data() ?? <String, dynamic>{};
}
```

Stream updates:

```dart
Stream<Map<String, dynamic>> watchChatroomMeta(String wsId, String roomId) {
  return db.collection('workspaces').doc(wsId).collection('chatrooms').doc(roomId)
    .snapshots().map((d) => d.data() ?? <String, dynamic>{});
}
```

Toggle bot on/off:

```dart
Future<void> setBotEnabled(String wsId, String roomId, bool enabled) async {
  await db.collection('workspaces').doc(wsId).collection('chatrooms').doc(roomId)
    .set({'bot_status': enabled ? 'Y' : 'N'}, SetOptions(merge: true));
}
```

Set chat status:

```dart
Future<void> setChatroomStatus(String wsId, String roomId, {required bool done}) async {
  await db.collection('workspaces').doc(wsId).collection('chatrooms').doc(roomId)
    .set({'chatroom_status': done ? 'DONE' : 'INPROGRESS'}, SetOptions(merge: true));
}
```

Pin/unpin:

```dart
Future<void> setPinned(String wsId, String roomId, bool pinned) async {
  await db.collection('workspaces').doc(wsId).collection('chatrooms').doc(roomId)
    .set({'chat_pin': pinned ? 'Y' : 'N'}, SetOptions(merge: true));
}
```

Query pinned chats:

```dart
Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> fetchPinnedChats(String wsId) async {
  final qs = await db.collection('workspaces').doc(wsId).collection('chatrooms')
      .where('chat_pin', isEqualTo: 'Y').get();
  return qs.docs;
}
```

Query finished chats:

```dart
Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> fetchDoneChats(String wsId) async {
  final qs = await db.collection('workspaces').doc(wsId).collection('chatrooms')
      .where('chatroom_status', isEqualTo: 'DONE').get();
  return qs.docs;
}
```

Customer hashtags (source of truth):

```dart
Future<List<Map<String, dynamic>>> getCustomerHashtags(String wsId, String customerId) async {
  final snap = await db.collection('workspaces').doc(wsId).collection('customers').doc(customerId).get();
  final raw = (snap.data()?['hashtags'] as List?) ?? const [];
  return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
}

Future<void> setCustomerHashtags(String wsId, String customerId, List<Map<String, dynamic>> tags) async {
  await db.collection('workspaces').doc(wsId).collection('customers').doc(customerId)
    .set({'hashtags': tags}, SetOptions(merge: true));
}
```

Mirroring to chatroom for instant UI:

```dart
Future<void> mirrorHashtagsToChatroom(String wsId, String roomId, List<Map<String, dynamic>> tags) async {
  final ids = tags.map((m) => (m['id'] ?? '').toString()).where((s) => s.isNotEmpty).toList();
  final names = tags.map((m) => (m['text'] ?? '').toString()).where((s) => s.isNotEmpty)
      .map((s) => s.startsWith('#') ? s : '#$s').toList();
  await db.collection('workspaces').doc(wsId).collection('chatrooms').doc(roomId)
    .set({'hashtagIds': ids, 'hashtags': names}, SetOptions(merge: true));
}
```

## Edge Cases

- Missing fields: Always null-check and provide defaults (e.g., assume bot_status = 'N').
- Legacy string vs object arrays: Some datasets may store customer hashtags as strings; normalize when reading.
- Permissions: Ensure Firestore Security Rules allow the read/write paths above for the current user.
- Offline: Wrap operations in try/catch and handle network errors gracefully.

## Where this is used in code

- Chat bottom modal for hashtag creation and selection: `lib/features/chat/widgets/show_bottom_modal.dart`
- Hashtag field widget (selector UI): `lib/core/widgets/hashtag_input_field.dart`
- Repository helpers: `lib/data/repositories/chatroom_repository.dart`


