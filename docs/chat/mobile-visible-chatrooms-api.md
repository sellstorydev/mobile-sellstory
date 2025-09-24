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

### 1. Channel / Connection Gating
Each provider connection may optionally restrict visibility by `allowedUserIds`:
- Empty / missing list → visible to all workspace members
- Non-empty list → visible only to those users (or owner)

If a non-owner user ends up with zero allowed connections across all providers, the API returns an empty list early.

### 2. Permission Precedence (Strict)
Applied in this order (first match wins):
1. `owner` or `chat:view:all` → All channel-allowed chatrooms
2. `chat:view:assigned` (WITHOUT `chat:view:all`) → Only chatrooms assigned to the user (strict mode; unassigned chats are NOT included even if role has `chat:view:unassigned`)
3. `chat:view:unassigned` only → Only strictly unassigned chatrooms
4. Otherwise → No chatrooms

### 3. Assigned Resolution
A chatroom counts as assigned to the current user if ANY is true:
- User UID in `chat.assignees`
- User UID equals legacy `chat.salespersonId`
- Linked customer exists AND user UID in `customer.assignees`

### 4. Strict Unassigned Definition
Used only under precedence rule #3:
- No `chat.assignees`
- No legacy `salespersonId`
- If a customer is linked, `customer.assignees` is empty or missing

### 5. Hidden Chats
`is_hidden === true` excluded unless `includeHidden=true`.

### 6. Provider ID Mapping (`source_type` → provider id field)
- line → `botId`
- facebook / messenger → `pageId` (both queried)
- instagram → `igUserId`
- whatsapp → connection `id`
- lazada → `sellerId`

### 7. Legacy Normalization
`messenger` is normalized internally to `facebook` for downstream logic.

### 8. Rationale
Strict assigned mode prevents information leakage of unassigned or other users' chatrooms and mirrors the web `live-chat` implementation for consistency.

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
- 2025-09-24 — Added strict assigned-only precedence, customer assignee enrichment, refined unassigned definition, clarified channel gating.