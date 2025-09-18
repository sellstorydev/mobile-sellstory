# Chatroom Deletion (Hide) Guide

Purpose
- Replace destructive deletion with a reversible “Hide” model.
- Hidden chats disappear from the list until a new message arrives, then reappear automatically.

Summary
- Old behavior: mark is_deleted = 'Y' and filter out.
- New behavior: keep is_deleted = 'N'; use is_hidden to hide without losing data.
- Auto-unhide when unreadCount (count) increases due to new incoming messages.

Firestore schema
- Collection: workspaces/{workspaceId}/chatrooms/{chatroomId}
- Fields
  - is_deleted: 'N' | 'Y' (legacy; remains 'N')
  - is_hidden: boolean (new; default false)
  - hidden_at: server timestamp (set when hiding)
  - count: unread count (string or number; code handles both)
  - last_message_info.last_upd or last_upd: used for sorting
  - chat_pin, bot_status, chatroom_status: unchanged

Write flows
- Hide chat (user taps Delete in sheet)
  - Set with merge: { is_hidden: true, hidden_at: FieldValue.serverTimestamp() }
  - Navigates back from ChatScreen.
- Auto-unhide on new incoming
  - Realtime controller checks each chat item; if is_hidden == true and unread > 0, it writes { is_hidden: false } (merge).

Read/list flows
- Realtime list (ChatController.startRealtime)
  - Base query still filters is_deleted == 'N'.
  - Client-side filter: hide items where is_hidden == true AND unread == 0.
  - Items with unread > 0 are shown even if hidden (and then auto-unhidden).
- Non-realtime list (ChatService.getChatroomsForWorkspace)
  - Returns items with is_deleted == 'N'.
  - Applies the same client-side hide filter as above.

UI behavior
- Bottom sheet action “ลบแชท” now hides instead of deleting.
- Hidden chats vanish from the conversations list.
- When new messages arrive (unread > 0), they reappear and are unhidden.

File touchpoints
- Hide action (ChatScreen)
  - lib/features/chat/view/chat_screen.dart
  - Method _deleteChatroom: sets is_hidden + hidden_at
- Realtime list and auto-unhide (ChatController)
  - lib/features/chat/controller/chat_controller.dart
  - startRealtime: maps docs, filters hidden unless unread > 0, and un-hides automatically
- Non-realtime fetch (ChatService)
  - lib/data/services/chat_service.dart
  - getChatroomsForWorkspace: filters hidden unless unread > 0

Edge cases
- Unread as string ('0') vs number: conversion handled defensively.
- Race on auto-unhide: harmless; last write wins to set is_hidden=false.
- Pinned chats: pin status unaffected by hide/unhide.
- Permissions: unchanged; hide action still gated by chat:delete in UI.

Manual unhide (admin/console)
- Set is_hidden = false on the chatroom doc.

Testing checklist
- Hide a chat via bottom sheet; verify it disappears from list.
- Send an inbound message to that chat; verify chat reappears and is_hidden becomes false.
- Mark chat read (count -> 0), hide again; send a new message; verify reappearance again.
- Verify pinned chats remain pinned after hide/unhide.
- Verify no data loss: messages, notes, assignees remain intact.

Migration notes
- No schema migration required; is_hidden defaults to false when absent.
- Legacy chats with is_deleted == 'Y' remain filtered out by existing queries.

Troubleshooting
- Hidden chat not reappearing: ensure count increments on inbound; confirm is_hidden gets reset to false in the chat doc.
- List still shows a hidden chat: verify unread count > 0; if 0 and still visible, check client filter or pin overrides.

