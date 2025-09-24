# Chat–Customer Linking System

This documentอธิบายการ "ผูก" (link) แชทห้อง (Chat Room) กับข้อมูลลูกค้า (Customer) ภายใน Workspace ให้ครบทั้งมุมมอง Product, Data Model, Workflow, Permission, Realtime, Performance และ Edge Cases / Future Improvements.

> TL;DR: ฟิลด์สำคัญคือ `chatroom.customerId` ชี้ไปที่ `/workspaces/{workspaceId}/customers/{customerId}` และเราทำงาน *แบบหลวม (loose coupling)*: ข้อมูลสรุปที่ต้องโชว์เร็ว จะถูกดูดซ้ำ (denormalize) ไว้ใน chatroom เช่น `customerName` (ถ้ามี) แต่ **source of truth** คือเอกสารในคอลเลคชัน `customers`.

---
## 1. Goals / เป้าหมาย
- ให้ Agent เห็น *บริบทลูกค้า* (ประวัติ, Job Cards, เอกสาร, Hashtags, Assignees) ขณะตอบแชท ได้ทันที
- ลดการค้นหา/สร้างข้อมูลซ้ำ – Reuse customer profile เดิม
- เปิดทาง Automation (routing ตาม customer tags, priority ตาม customerType ฯลฯ)
- ใช้โครงสร้างที่ scale ได้ (อ่านน้อยลง, query เร็ว, ง่ายต่อ index)

---
## 2. High-Level Architecture
```
/workspaces/{workspaceId}
  customers/{customerId}
  chatrooms/{chatroomId}
    messages/{messageId}
    comments/{commentId}
  cards/{jobCardId}
  documents/{docId}
```
ความสัมพันธ์หลัก:
- `chatrooms.customerId` -> อ้างอิง Customer (ถ้ามีการ Link แล้ว)
- `cards.customerId`, `documents.customerId` -> ใช้ให้หน้าลูกค้า ย้อนดูประวัติการทำงาน/การเงิน
- (Optional Denormalization) `chatrooms.customerName`, `chatrooms.customerHashtags[]`, `chatrooms.customerAssignees[]` (ถ้าเลือก optimize latency ด้าน UI)

เรา **ยังไม่** บังคับ Firestore reference type (ไม่มีฟิลด์เป็น `DocumentReference`) เพื่อรักษา flexibility และหลีกเลี่ยง security rule ที่ซับซ้อน; ใช้ pure string IDs.

---
## 3. Core Data Model (สำคัญเฉพาะด้าน Linking)
### 3.1 Chat Room (`/workspaces/{ws}/chatrooms/{chatId}`)
ฟิลด์ที่เกี่ยวข้องกับการผูก:
| Field | Type | Purpose |
|-------|------|---------|
| `customerId` | string (optional) | ไอดีลูกค้าที่เชื่อม | 
| `customerName` | string (optional, denormalized) | ชื่อ snapshot ขณะ link (ไม่ใช่ source of truth) |
| `linkedJobCards` | array<RelatedDocInfo> | รายการการ์ดที่เชื่อมภายหลัง (JC, QUO ฯลฯ) |
| `hashtags` | array<string | TagLike> | Hashtag ที่ผูกกับห้อง (แยกจาก customer tags) |
| `assignees` | array<string> | ผู้รับผิดชอบห้อง (อาจต่างจาก customer.assignees) |

### 3.2 Customer (`/workspaces/{ws}/customers/{customerId}`)
Fields สำคัญ:
| Field | Type | จุดใช้เชื่อมกับ Chat |
|-------|------|--------------------|
| `name` | string | แสดงใน panel (ตัวจริง) |
| `assignees` | string[] | ใช้ filter / permission (view assigned only) |
| `hashtags` | Tag[] | Merge กับ chat-level hashtag เพื่อ UI context |
| `relatedDocuments` | array<RelatedDocInfo> | รวมถึง Job Cards, เอกสารขายต่างๆ |
| `phones`, `emails` | ContactInfo[] | (อนาคต) dedupe / enrich chat profile |

### 3.3 Job Card / Document
มี `customerId`, `customer` (ซ้ำชื่อ) เพื่อ lookup และแสดงเร็วใน list; เมื่อ link Job Card จาก Chat จะ update ทั้ง `cards` และ `chatrooms.linkedJobCards` + `customers.relatedDocuments`.

### 3.4 RelatedDocInfo Shape (สรุป)
```ts
interface RelatedDocInfo {
  id: string;      // doc id (job card, quotation ฯลฯ)
  docNo: string;   // friendly number (customId / title)
  type: 'JC' | 'QUO' | 'INV' | 'REC' | string; // extensible
}
```

---
## 4. Linking Flows / ลำดับการทำงาน
### 4.1 Link Existing Customer
1. Agent เปิดแชท → คลิก "Link Customer"
2. UI เปิด dialog ค้นหา (ค้นจาก `customers` ที่โหลดแบบ onSnapshot (จำกัด 500) หรือ server search เพิ่ม)
3. เลือก customer → call server action: `updateChatRoom(wsId, chatId, { customerId, customerName: customer.name })`
4. (Optional) Trigger background refresh ให้ chatroom sync customer hashtags, assignees (หรือทำแบบ lazy เมื่อ render panel)

### 4.2 Create + Link (New Customer From Chat)
1. Agent กรอกฟอร์ม → `createCustomer(wsId, payload)`
2. เมื่อสร้างสำเร็จ ได้ `newCustomerId`
3. Chain call `updateChatRoom(..., { customerId: newCustomerId, customerName: payload.name })`
4. UI แจ้งสำเร็จ & panel reload customer detail

### 4.3 Unlink Customer
(กรณีผิดคน หรือแชทเป็น multi-user) – ขณะนี้มักจะ set `customerId = null` และ **เก็บประวัติการ unlink? (ยังไม่ implement)**
Suggested pattern:
- `updateChatRoom(..., { customerId: FieldValue.delete(), customerName: FieldValue.delete() })`
- Optionally เพิ่ม collection audit: `/workspaces/{ws}/chatrooms/{chatId}/link_audit/{eventId}` with `{ type: 'unlink', by, ts, prevCustomerId }`

### 4.4 Relink (Switch Customer)
- ทำเหมือน unlink + link ใหม่ ภายใน transaction ถ้าต้องการกัน race (เช่น สอง agent แข่งกัน)

### 4.5 Link Job Card (จาก Chat Panel)
1. เปิด sheet → เลือก/สร้าง Job Card
2. Update Card: `cards/{id}` เติม `customerId`, `customer`
3. Update ChatRoom: push `{ id, docNo, type: 'JC' }` เข้า `linkedJobCards` (arrayUnion)
4. Update Customer: push related doc เข้า `relatedDocuments`
5. Optimistic UI merge (ดูโค้ด `handleLinkJobCard` ใน `live-chat/page.tsx`)

### 4.6 Background Sync (Optional Strategy)
- เมื่อเปิดแชท ถ้า `customerId` มี → fetch latest customer doc
- ถ้า `customer.name` เปลี่ยน แต่ `chatroom.customerName` ต่าง → สามารถ schedule soft update เพื่อ UI consistency

---
## 5. Permission Model
| Action | Required Permission | Notes |
|--------|---------------------|-------|
| View chat list | `chat:view:all` หรือ `chat:view:assigned` (จำกัด) | Filter layer ทำงานร่วมกับ customer.assignees (ดู code ใน `filteredChats`) |
| Link / Unlink customer | `chat:edit` หรือ `chat:manage` | ป้องกัน user ธรรมดาแก้ link |
| Create customer from chat | `customer:create` (หรือ role ที่ครอบคลุม) | ตรวจสอบผ่าน server action / API route |
| View customer panel | ต้องเห็นแชท + ผ่าน rule ดู customer (ปกติทุก agent ที่เห็นแชท) | ถ้าอนาคตมี customer:view:restricted ค่อยเพิ่ม gate |
| Link Job Card | `jobcard:edit` + สิทธิ์เห็นแชท | รวมหลาย domain permission |

> NOTE: ตอน filter แบบ "assigned only" ระบบใช้ทั้ง chat.assignees + customer.assignees รวมกัน (loose OR union) เพื่อไม่ซ่อนงานของ user

---
## 6. Realtime Listeners & UI Data Flow
(อ้างอิงจากโค้ด `live-chat/page.tsx` ช่วงกลางไฟล์)

| Listener | Query Scope | Optimization |
|----------|-------------|--------------|
| Customers (allCustomers) | `/customers` limit(500) | ลด read บน workspace ใหญ่; เพียงพอสำหรับ quick pick dialog |
| Active Chatroom core | doc(`/chatrooms/{id}`) | แยกเน้น status fields เพื่อไม่ re-render หนัก |
| Messages | `/chatrooms/{id}/messages` paginated | ใช้ `lastMessageDoc` cursor + backfill button |
| Comments (FB/IG) | `/comments` where sender.id==userId limit(100) | ต้องมี composite index (timestamp desc) |
| Typing indicators | `/typing` sub-collection or ephemeral store | TTL cleanup (not shown) |

การดึง customer detail: เมื่อ `activeChat.customerId` เปลี่ยน → onSnapshot ไปยัง doc customer

---
## 7. Performance & Scaling Considerations
| Concern | Current Mitigation | Next Improvement |
|---------|--------------------|------------------|
| Large customer base >500 | Hard limit 500 ใน listener | เพิ่ม paginated server search หรือ Firestore full-text index (Composite + trigram) |
| Chatroom list reads | Paginate + stable realtime for NEW/MODIFIED only | เพิ่ม materialized summary collection (daily) สำหรับ analytics |
| Denormalized `customerName` staleness | Manual sync (ยัง) | Cloud Function trigger on customer update to push name -> affected chatrooms |
| Linking hot path latency | Direct update single chatroom doc | Batch / transaction only ถ้าต้องการ atomicity กับ audit log |
| Job card linking multiple writes | Sequential 3 updates | ใช้ batched write หรือ server action unify |

---
## 8. Edge Cases
| Scenario | Handling / Behavior |
|----------|---------------------|
| Customer deleted แต่ chatroom ยังมี `customerId` | UI ตรวจสอบ snapshot customer = null → แสดง badge "Unlinked (deleted)" และให้ relink | 
| สร้าง customer ชื่อซ้ำ | อนุญาต (business allowed) – อาจเพิ่ม warning UI | 
| Agent เปลี่ยนชื่อ customer แล้วเปิดหลาย tab | Realtime customer snapshot sync ทำงาน (chatroom.customerName ยังไม่อัพเดททันที) | 
| Race: สอง agent ลิงก์คนละ customer พร้อมกัน | อันสุดท้ายชนะ; ถ้าต้องการ strict ให้ใช้ transaction หรือ optimistic check previous value | 
| Unlink แล้ว relink เร็ว ๆ | OK; ประวัติหายเพราะไม่มี audit collection ตอนนี้ | 
| Job Card ลิงก์ customer A → เปลี่ยน chatroom ไป customer B | ตอนนี้ไม่ rewire อัตโนมัติ; เอกสาร job card & relatedDocuments ยังผูก A | 
| Customer hashtags เปลี่ยน | UI จะเห็นเพราะ listener customer doc; ถ้าใช้ caching ต้อง refresh | 

---
## 9. Future Improvements (Backlog)
- [ ] Cloud Function: onCustomerUpdate → propagate name/hashtags to linked chatrooms (denormal sync)
- [ ] Audit trail collection (`link_audit`) สำหรับ track link/unlink/relink events
- [ ] Server search endpoint (prefix + trigram) สำหรับ customer picker >500 ราย
- [ ] Cleanup script หา chatrooms.customerId ที่ชี้ไป customer ที่ลบแล้ว
- [ ] Batch linking (select หลาย chatrooms → link ลูกค้าคนเดียว) ลด manual work
- [ ] Analytics: ระยะเวลาจาก first message → linked customer (conversion metric)
- [ ] Pre-compute customer engagement score (messages count, last contact) แปะใน panel

---
## 10. Example Firestore Documents
### 10.1 Chatroom (linked)
```json
{
  "id": "fb_12345_67890",
  "source_type": "facebook",
  "provider_id": "12345",
  "contactId": "67890",
  "customerId": "cust_abc123",
  "customerName": "บริษัท สมายล์ เทรดดิ้ง",
  "assignees": ["uidA", "uidB"],
  "hashtags": ["vip", "hotlead"],
  "linkedJobCards": [
    { "id": "JC1001", "docNo": "JC1001", "type": "JC" }
  ],
  "last_message_info": { "message": "สวัสดีค่ะ", "msg_timestamp": 1727169012000, "who_name": "Customer" }
}
```

### 10.2 Customer
```json
{
  "id": "cust_abc123",
  "name": "บริษัท สมายล์ เทรดดิ้ง",
  "customerType": "Customer",
  "assignees": ["uidA"],
  "hashtags": [ { "id": "vip", "text": "VIP", "color": "#f59e0b" } ],
  "relatedDocuments": [
    { "id": "JC1001", "docNo": "JC1001", "type": "JC" }
  ],
  "phones": [ { "id": "p1", "label": "mobile", "value": "+66 81 234 5678" } ]
}
```

### 10.3 Job Card Linked
```json
{
  "id": "JC1001",
  "title": "ติดตั้งระบบ POS",
  "customerId": "cust_abc123",
  "customer": "บริษัท สมายล์ เทรดดิ้ง",
  "status": "IN_PROGRESS"
}
```

---
## 11. Implementation Notes (อ้างอิงโค้ดปัจจุบัน)
- Listener โหลด customers: ดูใน `live-chat/page.tsx` (limit 500) – ถ้า workspace โตเกิน ต้องย้ายเป็น server search
- ฟังก์ชันลิงก์ Job Card: `handleLinkJobCard` ทำ sequential writes 3 จุด (Card, Chatroom, Customer) → สามารถ refactor เป็น server action เดียว + batch
- Filtering permission: ดู block `filteredChats` ใช้ customer.assignees + chat.assignees กรองกรณี user มีสิทธิ์ `chat:view:assigned`
- Search message → แล้วกดเข้าแชท: customer panel จะ onSnapshot ตาม `chatroom.customerId`
- UI แสดง hashtags รวม: ถ้า customer.hashtags มี → ใช้อันนั้นแทน chat.hashtags

---
## 12. Testing Checklist (ย่อ)
| Case | Expect |
|------|--------|
| Link existing customer | `chatroom.customerId` ตั้ง, panel preload customer detail |
| Create + link | Customer doc สร้าง + chatroom อัพเดท |
| Unlink | ฟิลด์ customerId/customerName หาย, panel reset |
| Relink different customer | Panel แสดงข้อมูลใหม่, ไม่เหลือค่าเก่า |
| Link job card | Card.customerId ตั้ง + chatroom.linkedJobCards เพิ่ม + customer.relatedDocuments เพิ่ม |
| Customer rename | Panel แสดงชื่อใหม่; chatroom.customerName ยังชื่อเก่า (stale) จน refresh / sync |
| Delete customer | Panel แจ้งสถานะ unlinked (null snapshot) |

---
## 13. Summary
ระบบผูกข้อมูลลูกค้าในแชท ใช้หลักการ single source of truth (customer doc) + denormalization บางส่วนเพื่อความเร็ว UI. การออกแบบนี้เปิดให้ scale, audit, และ automation ต่อไป (routing, scoring, analytics). Improvements ถัดไปคือ sync อัตโนมัติ, audit trail, และ search ที่รองรับฐานลูกค้าขนาดใหญ่.
