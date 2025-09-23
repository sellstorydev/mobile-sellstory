# Mobile API: Visible Chatrooms

This document describes the mobile API that returns the list of chatrooms a user is allowed to see in a given workspace. The API enforces both role-based visibility and per-connection channel permissions.

- Route file: `src/app/api/mobile/chatrooms/visible/route.ts`
- Data type reference: `src/lib/types.ts` (see `ChatRoom`)

## Endpoint

- Method: GET
- Path: `/api/mobile/chatrooms/visible`

## Authentication

- Header: `Authorization: Bearer <Firebase ID Token>`
- If missing or invalid: HTTP 401

## Query Parameters

Required:
- `workspaceId` (string) — Workspace ID

Optional:
- `limit` (number, 1–100) — Page size (default 20)
- `after` (string) — Cursor for pagination; use `last_message_info.msg_timestamp` from the last row of the previous page
- `status` (string) — Filter by status. Supported values:
  - Normalized: `INPROGRESS`, `DONE`, `NEW`
  - Legacy stored values (also accepted): `processing`, `completed`, `new`
- `includeHidden` (boolean) — If `true`, includes chats with `is_hidden === true`; default is to exclude hidden

Notes:
- The API automatically includes both `facebook` and legacy `messenger` `source_type` when fetching FB-related rooms.

## Visibility Rules

- Role-based permissions (from the user role in `companyProfile.roles`):
  - `chat:view:all` — See all chatrooms (subject to channel access below)
  - `chat:view:assigned` — See only rooms assigned to the current user
  - `chat:view:unassigned` — See rooms with no assignees
  - Owner (`roleId = owner`) has `*` (all permissions)
- Per-connection channel access (`companyProfile.connections.*[].allowedUserIds`):
  - If `allowedUserIds` is empty or missing → visible to all workspace members
  - If present and non-empty → visible only to those user IDs
  - Owner bypasses this restriction (sees all connections)

Provider ID mapping per source_type:
- LINE → `botId`
- Facebook → `pageId` (also fetches legacy `messenger`)
- Instagram → `igUserId`
- WhatsApp → connection `id`
- Lazada → `sellerId`

Assignee detection:
- Uses `chat.assignees` (array) when available
- Fallback to legacy `salespersonId` when `assignees` is missing

## Sorting and Pagination

- Sorted by `last_message_info.msg_timestamp` descending (newest first)
- Pagination cursor: pass the last item’s `last_message_info.msg_timestamp` as `after` for the next page

## Response Shape

- 200 OK
  - `success` (boolean)
  - `rooms` (ChatRoom[]) — Filtered, deduplicated, and paginated list of chatrooms
  - `total` (number) — Items in the current page
  - `nextCursor` (string | null) — Use as `after` for the next page; `null` when there are no more pages

- Errors
  - 400 — Missing required parameters (e.g., `workspaceId`)
  - 401 — Unauthorized (missing/invalid token)
  - 403 — User is not a member of the workspace
  - 404 — User profile or workspace not found
  - 500 — Internal server error

## Example Requests (optional)

Fetch first page (default limit 20):
```bash
curl -G \
  -H "Authorization: Bearer <ID_TOKEN>" \
  --data-urlencode "workspaceId=<WORKSPACE_ID>" \
  https://<BASE_URL>/api/mobile/chatrooms/visible
```

Fetch with status filter (in-progress only):
```bash
curl -G \
  -H "Authorization: Bearer <ID_TOKEN>" \
  --data-urlencode "workspaceId=<WORKSPACE_ID>" \
  --data-urlencode "status=INPROGRESS" \
  https://<BASE_URL>/api/mobile/chatrooms/visible
```

Fetch next page using cursor:
```bash
curl -G \
  -H "Authorization: Bearer <ID_TOKEN>" \
  --data-urlencode "workspaceId=<WORKSPACE_ID>" \
  --data-urlencode "limit=20" \
  --data-urlencode "after=<LAST_msg_timestamp_FROM_PREVIOUS_PAGE>" \
  https://<BASE_URL>/api/mobile/chatrooms/visible
```

Include hidden chats:
```bash
curl -G \
  -H "Authorization: Bearer <ID_TOKEN>" \
  --data-urlencode "workspaceId=<WORKSPACE_ID>" \
  --data-urlencode "includeHidden=true" \
  https://<BASE_URL>/api/mobile/chatrooms/visible
```

## Implementation Notes

- Status mapping:
  - `INPROGRESS` → `processing`
  - `DONE` → `completed`
  - `NEW` → `new`
- Soft-hide:
  - By default, chats with `is_hidden === true` are filtered out in-memory
  - Set `includeHidden=true` to include them
- Indexes:
  - Firestore may prompt composite indexes, e.g.:
    - `source_type ==`, `provider_id in`, `orderBy last_message_info.msg_timestamp desc`
    - `source_type ==`, `chatroom_status ==`, `orderBy last_message_info.msg_timestamp desc`
    - `source_type ==`, `last_message_info.msg_timestamp <`, `orderBy last_message_info.msg_timestamp desc`
- Legacy `source_type` support:
  - `messenger` is queried alongside `facebook`

## Changelog

- 2025-09-23 — Initial version