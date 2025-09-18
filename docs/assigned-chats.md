# Assigned Chats (แชทที่ถูก Assign) — เว็บ (วิธีอย่างย่อ)

เอกสารฉบับนี้สรุป “วิธี” สำหรับทำฟีเจอร์ Assigned บนเว็บ โดยยึด Firestore เป็นแหล่งข้อมูลหลัก และไม่ผูกกับโค้ดมือถือ

## TL;DR
- แหล่งเก็บผู้รับผิดชอบหลัก: Customer `workspaces/{wsId}/customers/{customerId}.assignees: string[]` (uid)
- ถ้าแชทยังไม่ผูกลูกค้า: ใช้ Chatroom `workspaces/{wsId}/chatrooms/{chatId}.assignees: string[]`
- หน้าแชทรวม: subscribe ที่ `chatrooms` (is_deleted == 'N', orderBy last_message_info.last_upd desc) -> enrich ผู้รับผิดชอบจาก customer/chatroom -> กรอง Assigned/Unassigned/อื่นๆ ฝั่ง client

---

## โครงสร้างข้อมูลที่ใช้ (Firestore)
- Chatroom: `workspaces/{wsId}/chatrooms/{chatId}`
  - `assignees: string[]` (ใช้เมื่อไม่มี customer)
  - `is_deleted: 'Y'|'N'`, `is_hidden: boolean|'Y'|'N'`, `count` (unread), `last_message_info.last_upd` (เวลา), `chat_pin: 'Y'|'N'`, `chatroom_status`, `is_new: 'Y'|'N'`
  - ความสัมพันธ์ลูกค้า (อย่างน้อยหนึ่ง): `customerId` | `customer_id` | `customer.id`
- Customer: `workspaces/{wsId}/customers/{customerId}`
  - `assignees: string[]` รายชื่อ uid ผู้รับผิดชอบหลัก
- Users: `users/{uid}` (ใช้ดึง `displayName` สำหรับแสดงผล)

---

## วิธีเขียน (Assign ผู้ใช้ให้แชท)
หลักการ: ถ้าแชทมี customer -> เขียนที่ customer; ถ้าไม่มี -> เขียนที่ chatroom

ตัวอย่าง (Firebase Web v9):

```js
import { doc, updateDoc, arrayUnion } from 'firebase/firestore';

// Assign ที่ระดับ Customer
await updateDoc(
  doc(db, 'workspaces', wsId, 'customers', customerId),
  { assignees: arrayUnion(userId) }
);

// หรือ ถ้าไม่มี customer ให้ Assign ที่ Chatroom
await updateDoc(
  doc(db, 'workspaces', wsId, 'chatrooms', chatId),
  { assignees: arrayUnion(userId) }
);
```

---

## วิธีอ่าน (Realtime + เติมข้อมูลผู้รับผิดชอบ)
1) Subscribe รายการห้องแชท
```js
import { collection, query, where, orderBy, onSnapshot } from 'firebase/firestore';

const q = query(
  collection(db, 'workspaces', wsId, 'chatrooms'),
  where('is_deleted', '==', 'N'),
  orderBy('last_message_info.last_upd', 'desc')
);

const unsub = onSnapshot(q, async (snap) => {
  const base = snap.docs.map(d => ({ id: d.id, ...d.data() }));
  // ซ่อน item ที่ถูกซ่อน เว้นแต่มีข้อความใหม่ (unread > 0)
  const visible = base.filter(it => {
    const hiddenRaw = it.is_hidden;
    const hidden = hiddenRaw === true || hiddenRaw === 'Y' || hiddenRaw === 'true' || hiddenRaw === 1;
    const unread = parseInt(String(it.count ?? it.unreadCount ?? 0), 10) || 0;
    return !hidden || unread > 0;
  });

  // เติม assignees
  const enriched = await enrichAssignees(db, wsId, visible);
  render(enriched);
});
```

2) เติมผู้รับผิดชอบจาก Customer/Chatroom (พร้อม map ชื่อผู้ใช้)
```js
import { doc, getDoc } from 'firebase/firestore';

const userNameCache = new Map(); // uid -> displayName
const customerAssignCache = new Map(); // customerId -> string[] uids

async function getUserName(db, uid) {
  if (!uid) return '';
  if (userNameCache.has(uid)) return userNameCache.get(uid);
  const snap = await getDoc(doc(db, 'users', uid));
  const name = (snap.data()?.displayName || snap.data()?.name || '') + '';
  userNameCache.set(uid, name);
  return name;
}

async function getCustomerAssignees(db, wsId, customerId) {
  if (customerAssignCache.has(customerId)) return customerAssignCache.get(customerId);
  const snap = await getDoc(doc(db, 'workspaces', wsId, 'customers', customerId));
  const uids = (snap.data()?.assignees ?? []).map(String);
  customerAssignCache.set(customerId, uids);
  return uids;
}

async function enrichAssignees(db, wsId, items) {
  return Promise.all(items.map(async it => {
    const customerId = String(it.customerId || it.customer_id || it.customer?.id || '');
    let assigneeIds = [];

    if (customerId) {
      assigneeIds = await getCustomerAssignees(db, wsId, customerId);
    } else if (Array.isArray(it.assignees)) {
      assigneeIds = it.assignees.map(String);
    }

    const assigneeNames = await Promise.all(assigneeIds.map(uid => getUserName(db, uid)));
    return { ...it, assigneeIds, assigneeNames, assigneesKnown: true };
  }));
}
```

---

## วิธีกรอง (Assigned/Unassigned และอื่นๆ ฝั่งเว็บ)
- Assigned to me: กรองรายการที่ `assigneeIds` มี `myUid`
- Unassigned: กรองรายการที่ `assigneesKnown == true` และ `assigneeIds.length == 0`
- ฟิลเตอร์อื่นๆ (ถ้ามี)
  - แพลตฟอร์ม: จาก `source_type` หรือ connection ที่ผูก (เช่น facebook/instagram/line)
  - สถานะ: ใช้ `is_new`, `chatroom_status` (เช่น NEW/DONE/IN_PROGRESS)
  - Hashtag: ใช้ `hashtagIds`/`hashtags` ตามที่แอปจัดเก็บ
  - Sales (คนเดียว): เลือก uid เดียวแล้วกรองให้ `assigneeIds` มี uid นั้น

หมายเหตุเรื่องสิทธิ์: แนวคิดทั่วไปคือ
- ผู้มีสิทธิ์รวม (เช่น `chat:view:all`) เห็นทั้งหมด
- ผู้มีสิทธิ์เฉพาะ `chat:view:assigned` เห็นเฉพาะที่ตัวเองถูก assign
- ผู้มีสิทธิ์ `chat:view:unassigned` เห็นเฉพาะที่ยังไม่ถูก assign
การบังคับใช้สิทธิ์ทำฝั่งเว็บ (UI/logic และ/หรือ Security Rules) ตามนโยบายของระบบคุณ

---

## ตัวอย่างข้อมูล (อ้างอิง)
- Customer (assign ให้ผู้ใช้ A, B)
```json
{
  "assignees": ["uidA", "uidB"],
  "hashtags": ["tag123", {"id": "tag999", "text": "VIP", "color": "#FF5555"}]
}
```
- Chatroom (ยังไม่ผูก Customer แต่ assign ให้ C)
```json
{
  "assignees": ["uidC"],
  "is_deleted": "N",
  "is_hidden": false,
  "count": "2",
  "last_message_info": {"last_upd": "2025-09-18T10:11:12.000Z"}
}
```

---

## เช็กลิสต์ทดสอบแบบเร็ว
- Assign:
  - มี customer -> `customers/{customerId}.assignees` มี uid เพิ่ม
  - ไม่มี customer -> `chatrooms/{chatId}.assignees` มี uid เพิ่ม
- UI:
  - ชื่อผู้รับผิดชอบแสดงถูกต้อง (fallback เป็น uid ถ้าไม่มี displayName)
  - ฟิลเตอร์ Assigned/Unassigned/Sales ตรงตามคาด
- Realtime:
  - แชทที่ซ่อน (is_hidden) จะไม่ขึ้น ยกเว้นมี unread > 0 และจะปรากฏเมื่อมีข้อความใหม่

---

## ข้อควรระวัง
- `assigneesKnown` อาจยังเป็น false ระหว่างดึงข้อมูล ทำให้ Unassigned ยังไม่ขึ้นจนดึงเสร็จ
- ถ้ามี customer ให้ถือ customer เป็น source of truth ของ assignees แทน chatroom
- การดึงชื่อผู้ใช้แบบครั้งละหลาย uid ให้พิจารณาแคช/กลุ่มคำขอ (ข้อจำกัด Where-In สูงสุด 10 ค่า)
- ตรวจสอบ Firestore Security Rules ให้สอดคล้องกับนโยบาย assign ของระบบ
