# LINE Quota & Rate Limit — Detection, Notifications, and Mobile Contract

This guide explains how we detect LINE Messaging API quota/rate-limit conditions, how to fetch current usage, what gets logged, and how mobile apps should consume this information.

## What we cover

- Proactive quota check (monthly usage/limit)
- Send-time error detection and user-friendly messages
- API contracts (server endpoints) for web/mobile
- Logging and optional notifications

---

## 1) Proactive quota check (current usage)

Endpoint: `POST /api/line/quota`

Purpose: Return the current LINE message quota usage for a given workspace + channel.

Request body:

```json
{
  "workspaceId": "<workspace-id>",
  "channelId": "<line-channel-id>"
}
```

Response shape:

```json
{
  "used": 1234,
  "total": 5000,
  "unlimited": false
}
```

- When the LINE plan is unlimited, `unlimited=true` and `total=null`.
- When limited, `total` is a number; show progress as `used / total`.

Implementation reference:
- File: `src/app/api/line/quota/route.ts`
- Uses LINE endpoints:
  - `GET https://api.line.me/v2/bot/message/quota`
  - `GET https://api.line.me/v2/bot/message/quota/consumption`

Display ideas (mobile):
- If `!unlimited && total > 0`, show a progress bar and soft warning when `used/total >= 0.8`.
- If `used >= total`, block message sends (or show a clear error) until the cycle resets or plan is upgraded.

---

## 2) Send-time error detection (when pushing messages)

When sending LINE messages (push API), the server maps LINE errors into user-friendly, localized messages.

Mapping logic (reference): `translateLineSendError()` in `src/app/chat-actions.ts`.

Patterns we detect:

- Monthly quota reached
  - LINE message often contains: `"you have reached your monthly limit"`
  - We surface (TH): `"ส่งข้อความผ่าน LINE ไม่สำเร็จ: เกินโควตารายเดือนของบัญชีแล้ว"`
  - We surface (EN): `"Failed to send via LINE: Monthly quota has been reached."`

- Temporary rate limit
  - HTTP status `429` or message contains `"limit"`
  - We surface (TH): `"ส่งข้อความผ่าน LINE ไม่สำเร็จ: ระบบถูกจำกัดอัตราการส่งชั่วคราว (Rate limit) โปรดลองใหม่ภายหลัง"`
  - We surface (EN): `"Failed to send via LINE: Rate limited temporarily. Please try again later."`

- Unauthorized / token expired
  - HTTP `401` or message contains `"unauthorized"`
  - Clear reconnect message in TH/EN.

- Invalid parameters
  - HTTP `400` → show parameter validation error.

Server behavior on failure:
- The error is logged via `createLogEntry` with context `SEND_MESSAGE`.
- The send API throws with the friendly message (localized) so clients can display it.

---

## 3) Mobile send API contract

Endpoint: `POST /api/mobile/send-message`

Request body (excerpt):

```json
{
  "workspaceId": "<id>",
  "chatroomId": "<id>",
  "platform": "line",
  "message": {
    "type": "text",
    "text": "Hello",
    "replyTo": {
      "messageId": "<original-message-id>",
      "quotedMessageId": "<optional, same as messageId>",
      "messageText": "<optional short snippet>",
      "senderName": "<optional>",
      "quoteToken": "<LINE-only token if replying>"
    }
  },
  "sender": { "id": "<user-id>", "name": "<user-name>", "avatar": "<optional>" }
}
```

Response:

```json
{ "success": true, "messageId": "..." }
```

On error (including quota/rate limit):

```json
{ "success": false, "error": "ส่งข้อความผ่าน LINE ไม่สำเร็จ: เกินโควตารายเดือนของบัญชีแล้ว" }
```

Notes for mobile UI:
- Treat `error` as a user-facing string (already localized based on server locale setting).
- For retry UI, if `error` contains the rate-limit message, suggest retry after a short delay.
- If the monthly quota message appears, advise plan upgrade or wait for the cycle reset.

Implementation reference:
- Entry point: `src/app/api/mobile/send-message/route.ts` → `sendMessageAction`
- LINE send: `sendMessageAction` in `src/app/chat-actions.ts`

---

## 4) Logging (for audit and debugging)

All sends (success/failure) write logs under Firestore:

`workspaces/{workspaceId}/logs` (collection)

Example log entry on error:

```json
{
  "level": "ERROR",
  "context": "SEND_MESSAGE",
  "message": "Failed to send via LINE: Monthly quota has been reached.",
  "timestamp": 1730000000000,
  "data": { "status": 429, "lineResponse": { /* raw */ } },
  "workspaceId": "<id>",
  "chatroomId": "<id>"
}
```

Reference: `createLogEntry` in `src/lib/firebase-admin.ts`.

---

## 5) Optional notifications (recommended)

We can proactively notify users when usage is high or when the quota has been exhausted.

Building blocks:
- Server function: `createNotificationServer(...)` in `src/lib/notifications-server.ts`
- FCM token collection: `users/{userId}/devices/*`
- Dedupe per-device: enabled via web push `tag` + `renotify: false` and optional `dedupeKey` per notification doc.

Suggested triggers:
- Soft warning (80%): after calling `/api/line/quota` and detecting `!unlimited && used/total >= 0.8`
- Hard stop (100%): when `used >= total` OR when a send fails with the monthly limit message.

Suggested notification payload:

```ts
await createNotificationServer({
  userId,
  workspaceId,
  type: 'line-quota-warning',
  title: 'LINE quota almost reached',
  message: `Used ${used} of ${total} messages this month`,
  link: '/settings/subscription',
  dedupeKey: `line-quota-${workspaceId}-${channelId}-${Math.floor(used/ (total||1)*10)}` // dedupe by 10% buckets
});
```

Note: The above is a recommendation; adopt per your ops policy. Current codebase does not auto-trigger this yet.

---

## 6) Mobile UX recommendations

- Show a non-blocking banner when usage >= 80% (for limited plans).
- Show a blocking dialog on 100% (monthly quota reached) with actions: “Upgrade plan” or “Retry next month”.
- For rate-limit errors (temporary), allow retry with exponential backoff.

---

## 7) Quick checklist

- Read current usage via `POST /api/line/quota`.
- Handle send errors from `POST /api/mobile/send-message` by showing `error` text.
- Track logs in `workspaces/{workspaceId}/logs` when debugging customer issues.
- Optionally, wire notifications to warn stakeholders early.

---

## File references

- `src/app/api/line/quota/route.ts` — quota endpoints to LINE
- `src/app/chat-actions.ts` — LINE send + error translation and logging
- `src/app/api/mobile/send-message/route.ts` — mobile send entry
- `src/lib/notifications-server.ts` — notification building blocks
