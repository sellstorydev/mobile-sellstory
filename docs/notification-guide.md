# App Notification Trigger Guide

This document outlines the key events within the SellStory application that trigger push notifications to users. Each notification includes a `type` field that your mobile application can use to handle the alert appropriately, such as navigating to the correct screen.

## 1. User & Account Notifications

### a. Added to Workspace
- **Trigger**: An admin invites a user to join a workspace.
- **`type`**: `onAddedToWorkspace`
- **Data includes**: `workspaceId`, `workspaceName`
- **Default Link**: `/` (Dashboard)
- **Relevant File**: `src/lib/firebase.ts`

---

## 2. Job Card Notifications

### a. Card Assignment
- **Trigger**: A user is assigned to a Job Card.
- **`type`**: `onCardAssignment`
- **Data includes**: `cardId`, `boardId`, `assignerName`
- **Default Link**: `/?cardId={cardId}&boardId={boardId}`
- **Relevant File**: `src/components/board/card-detail-modal.tsx`

### b. Mentioned ("Tagged")
- **Trigger**: A user is `@mentioned` in a card's description, a comment, or a to-do item.
- **`type`**: `onTagged`
- **Data includes**: `cardId`, `boardId`, `contextType` ('description', 'comment', or 'todo')
- **Default Link**: `/?cardId={cardId}&boardId={boardId}`
- **Relevant Files**: `src/components/board/card-detail/notes-section.tsx`, `src/components/board/card-detail-modal.tsx`

### c. New Comment
- **Trigger**: A new comment is posted on a card that the user is watching or collaborating on.
- **`type`**: `onComment`
- **Data includes**: `cardId`, `boardId`, `commenterName`
- **Default Link**: `/?cardId={cardId}&boardId={boardId}`
- **Relevant File**: `src/components/board/card-detail/notes-section.tsx`

### d. Status/Lane Change
- **Trigger**: A card the user is watching is moved to a new lane.
- **`type`**: `onStatusChange`
- **Data includes**: `cardId`, `boardId`, `newStatus`, `oldStatus`
- **Default Link**: `/?cardId={cardId}&boardId={boardId}`
- **Relevant File**: `src/components/board/kanban-board.tsx`

### e. Due Date Reminder
- **Trigger**: A card's due date is today. This is typically run by a scheduled daily task.
- **`type`**: `onDueDateReminder`
- **Data includes**: `cardId`, `boardId`, `customerName`
- **Default Link**: `/?cardId={cardId}&boardId={boardId}`
- **Relevant File**: `src/app/api/tasks/send-reminders/route.ts`

### f. To-Do Item Reminder
- **Trigger**: A to-do item on a card is due soon (based on user settings). This is run by a scheduled task.
- **`type`**: `onTodoReminder`
- **Data includes**: `cardId`, `boardId`, `todoTitle`
- **Default Link**: `/?cardId={cardId}&boardId={boardId}`
- **Relevant File**: `src/app/api/tasks/send-reminders/route.ts`

---

## 3. Document Approval Notifications

### a. Approval Requested
- **Trigger**: A quotation is submitted for approval, and the user is one of the required approvers.
- **`type`**: `onApprovalRequest`
- **Data includes**: `documentId`, `docNo`, `sellerName`
- **Default Link**: `/approvals?quoteId={documentId}`
- **Relevant File**: `src/lib/approvals.ts`

### b. Approval Decision
- **Trigger**: A quotation submitted by the user is either approved or rejected.
- **`type`**: `onApprovalDecision`
- **Data includes**: `documentId`, `decision` ('approved' or 'rejected')
- **Default Link**: `/sales-docs/quotations/{documentId}`
- **Relevant File**: `src/lib/approvals.ts`

---

## 4. Chat Center Notifications

### a. New Unassigned Chat
- **Trigger**: A new message arrives from any connected channel, and the chat has no assigned salesperson.
- **`type`**: `onNewChatReceived`
- **Data includes**: `chatroomId`, `customerName`
- **Default Link**: `/live-chat?chatId={chatroomId}`
- **Relevant File**: `src/lib/chat-shared.ts`

### b. New Message in Assigned Chat
- **Trigger**: A message arrives in a chat that is specifically assigned to the user.
- **`type`**: `onAssignedChatMessage`
- **Data includes**: `chatroomId`, `customerName`
- **Default Link**: `/live-chat?chatId={chatroomId}`
- **Relevant File**: `src/lib/chat-shared.ts`

### c. Assigned to Chat
- **Trigger**: An admin or another user assigns a chat to the user.
- **`type`**: `onChatAssigned`
- **Data includes**: `chatroomId`, `assignerName`
- **Default Link**: `/live-chat?chatId={chatroomId}`
- **Relevant File**: `src/lib/chat.ts`

---

## 5. Mobile: Direct Create Notification API

สำหรับฝั่ง Mobile ที่ต้องการสร้าง Notification แบบ Manual (เช่น กรณี Action บางอย่างเกิดใน Mobile ก่อน Web จะ Sync) มี API ใหม่ดังนี้

### Endpoint
`POST /api/notifications/create`

### Auth
ใส่ Header `x-mobile-secret: <SECRET>` (ตั้งค่าที่ Server เป็น ENV `MOBILE_BACKEND_SECRET`) ถ้าไม่ตั้งค่า ENV นี้ API จะไม่ตรวจ Secret

### Request Body (JSON)
```json
{
	"userId": "<targetUserUid>",
	"type": "onComment",
	"title": "New Comment",
	"message": "John commented on your card",
	"link": "/?cardId=abc&boardId=def", 
	"workspaceId": "workspace_123",
	"workspaceName": "Main Workspace",
	"boardId": "board_456",
	"icon": "message-circle",
	"createdBy": "creatorUserUid",
	"data": { "cardId": "abc", "extra": "..." }
}
```
Required fields: `userId`, `type`, `title`, `message`

`type` ต้องอยู่ในชุดที่ระบบรองรับ:
`onComment`, `onStatusChange`, `onDueDateReminder`, `onTodoReminder`, `onApprovalRequest`, `onApprovalDecision`, `onAddedToWorkspace`, `onChatAssigned`, `onCardAssignment`, `onTagged`, `onNewChatReceived`, `onAssignedChatMessage`, `test`

### Response (Success)
```json
{
	"success": true,
	"notificationId": "abc123",
	"fcm": { "sent": 1, "failed": 0, "success": true, "tokens": 1 }
}
```

### Response (Error Examples)
| Status | Body | หมายเหตุ |
|--------|------|----------|
| 400 | {"success":false,"error":"userId, type, title, message are required"} | ขาดฟิลด์จำเป็น |
| 400 | {"success":false,"error":"Invalid notification type"} | type ไม่ถูกต้อง |
| 401 | {"success":false,"error":"Unauthorized"} | Secret ไม่ตรง |
| 500 | {"success":false,"error":"Failed to create notification"} | create ล้มเหลวทั่วไป |

### หมายเหตุการทำงานภายใน
- ใช้ `createNotificationServer` ที่มี logic เช็ค quiet hours + user settings แล้ว
- บันทึกเอกสารที่ `users/{userId}/notifications/{notificationId}`
- พยายามส่ง FCM ไปยัง tokens ใน `users/{userId}/devices` (collection) ถ้าไม่มี token ก็จะเก็บแค่ใน Firestore
- ฟิลด์ `link` ส่งไปใน FCM `data` เพื่อ mobile นำไป deep link ได้

### ตัวอย่าง cURL
```bash
curl -X POST https://<domain>/api/notifications/create \
	-H "Content-Type: application/json" \
	-H "x-mobile-secret: $MOBILE_BACKEND_SECRET" \
	-d '{
		"userId":"USER_UID",
		"type":"onComment",
		"title":"New Comment",
		"message":"Someone commented",
		"link":"/?cardId=abc&boardId=def",
		"workspaceId":"workspace_123"
	}'
```

### ตัวอย่างโค้ด (React Native / fetch)
```ts
async function createNotification(input: {
	userId: string;
	type: string;
	title: string;
	message: string;
	link?: string;
	workspaceId?: string;
	workspaceName?: string;
	boardId?: string;
	icon?: string;
	createdBy?: string;
	data?: Record<string, any>;
}) {
	const res = await fetch(BASE_URL + '/api/notifications/create', {
		method: 'POST',
		headers: {
			'Content-Type': 'application/json',
			'x-mobile-secret': MOBILE_BACKEND_SECRET,
		},
		body: JSON.stringify(input),
	});
	return res.json();
}
```

### ข้อเสนอปรับปรุงภายหลัง
1. เปลี่ยนจาก shared secret → ใช้ OAuth2 / Firebase Auth (ID Token) ตรวจสิทธิ์
2. รองรับการส่ง `titleKey` + `messageKey` เพื่อให้ server แปลภาษาอัตโนมัติ (ปัจจุบัน endpoint รับเฉพาะ title/message ตรง)
3. เพิ่ม rate limit ต่อ IP / userId
4. เพิ่ม validation เชิงลึกต่อฟิลด์ `data`
5. Log แยก channel (mobile manual vs system auto)
