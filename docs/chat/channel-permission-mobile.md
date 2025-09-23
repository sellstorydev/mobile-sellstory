# คู่มือใช้งาน: โครงสร้าง Database สำหรับ Channel Permission (Mobile)

เอกสารนี้สรุปโครงสร้างข้อมูลบน Firestore ที่เกี่ยวข้องกับ "สิทธิ์การเข้าถึงช่องทางแชทต่อผู้ใช้ (Channel Permission)" เพื่อให้ทีม Mobile นำไปใช้กรองห้องแชท/ข้อความที่ผู้ใช้แต่ละคนมีสิทธิ์เห็น และแมปข้อมูลการเชื่อมต่อแต่ละแพลตฟอร์ม (LINE, Facebook, Instagram, WhatsApp, Lazada)

## ภาพรวมข้อมูลที่เกี่ยวข้อง

- เอกสาร Workspace: `workspaces/{workspaceId}`
  - ฟิลด์สมาชิกและบทบาท: `members: { [uid]: roleId }`
  - โปรไฟล์บริษัท: `companyProfile`
    - การเชื่อมต่อช่องทาง: `companyProfile.connections`
      - `line: LineConnection[]`
      - `facebook: FacebookConnection[]`
      - `instagram: InstagramConnection[]`
      - `whatsapp: WhatsAppConnection[]`
      - `lazada: LazadaConnection[]`

- คอลเลกชันห้องแชท: `workspaces/{workspaceId}/chatrooms/{chatroomId}`
  - ฟิลด์ที่ใช้ระบุช่องทาง/ตัวตนช่องทางของห้อง:
    - `source_type`: หนึ่งใน `"line" | "facebook" | "instagram" | "whatsapp" | "lazada"`
    - `provider_id`: รหัสตัวตนของช่องทาง (เชื่อมกับแต่ละ connection)
  - ฟิลด์อื่นที่อาจใช้ในการแสดงผล/กรอง:
    - `last_message_info.msg_timestamp` (string of epoch millis)
    - `chatroom_status`, `salespersonId`, `hashtags` ฯลฯ

> หมายเหตุ: Firestore rules ปัจจุบันอนุญาตสมาชิก workspace อ่าน `chatrooms` ได้ แต่การจำกัดสิทธิ์ตามช่องทางทำที่ฝั่งแอปโดยกรองตามรายการ allowedUserIds ของ connection

## โครงสร้างอ็อบเจ็กต์ Connection และการแมป provider_id

ทุก connection จะมีฟิลด์ optional `allowedUserIds?: string[]` ถ้าไม่กำหนดหรืออาร์เรย์ว่าง หมายถึง "ทุกคนใน workspace เห็นได้" ถ้ามีค่า หมายถึง "เห็นได้เฉพาะผู้ใช้ที่ uid อยู่ในลิสต์นี้"

- LINE (LineConnection)
  - คีย์อ้างอิง: `channelId`
  - ฟิลด์สำคัญ: `displayName`, `pictureUrl`, `connectedAt`, `quota`, `allowedUserIds?: string[]`
  - แมปกับ chatroom: `provider_id === channelId`

- Facebook (FacebookConnection)
  - คีย์อ้างอิง: `pageId`
  - ฟิลด์สำคัญ: `pageName`, `pageImageUrl`, `connectedAt`, `alias?`, `allowedUserIds?: string[]`
  - แมปกับ chatroom: `provider_id === pageId`

- Instagram (InstagramConnection)
  - คีย์อ้างอิง: `igUserId`
  - ฟิลด์สำคัญ: `igUsername`, `pageId`, `pageName`, `profilePictureUrl?`, `connectedAt`, `alias?`, `allowedUserIds?: string[]`
  - แมปกับ chatroom: `provider_id === igUserId`

- WhatsApp (WhatsAppConnection)
  - คีย์อ้างอิง: `id`
  - ฟิลด์สำคัญ: `name`, `phoneNumbers[]`, `connectedAt`, `featureType?`, `alias?`, `allowedUserIds?: string[]`
  - แมปกับ chatroom: `provider_id === id`

- Lazada (LazadaConnection)
  - คีย์อ้างอิง: `id`
  - ฟิลด์สำคัญ: `sellerId`, `sellerName`, `storeName?`, `connectedAt`, `alias?`, `allowedUserIds?: string[]`
  - แมปกับ chatroom/คำสั่งซื้อ: `provider_id === id`

## ขั้นตอนฝั่ง Mobile: สร้างรายการ provider ที่ผู้ใช้เห็นได้

อินพุต: `workspaceId`, `currentUser.uid`

เอาต์พุต: อาร์เรย์ `allowedProviderIds: string[]` ซึ่งรวม `channelId/pageId/igUserId/id` ของทุก connection ที่อนุญาตให้ผู้ใช้เห็น

ขั้นตอน (สรุป):

1) อ่านเอกสาร workspace: `workspaces/{workspaceId}` เพื่อดึง `companyProfile.connections`
2) สำหรับ connection แต่ละแพลตฟอร์ม ให้รวมรายการตามเงื่อนไขต่อไปนี้:
   - ถ้า `allowedUserIds` เป็น `undefined` หรือความยาว 0: อนุญาตทุกคน → เพิ่ม id ลงในผลลัพธ์
   - ถ้ามีค่าอาร์เรย์: เพิ่ม id เมื่อ `currentUser.uid` อยู่ใน `allowedUserIds`
3) ได้ `allowedProviderIds` เป็นลิสต์รวมทั้งหมดของทุกแพลตฟอร์ม

ตัวอย่างโค้ดเชิงตรรกะ (pseudo):

```
const cons = workspace.companyProfile?.connections || {};
const me = currentUser.uid;
const pick = (arr, key) => (arr || [])
  .filter(c => !Array.isArray(c.allowedUserIds) || c.allowedUserIds.length === 0 || c.allowedUserIds.includes(me))
  .map(c => String(c[key]));

const allowedProviderIds = [
  ...pick(cons.line, 'channelId'),
  ...pick(cons.facebook, 'pageId'),
  ...pick(cons.instagram, 'igUserId'),
  ...pick(cons.whatsapp, 'id'),
  ...pick(cons.lazada, 'id'),
];
```

## การนำไปใช้ตอนอ่าน Chatrooms (Client-side filtering)

รูปแบบ 1: กรองข้อมูลหลังดึง
- ดึง `chatrooms` ชุดเวลาหนึ่งช่วงหรือเงื่อนไขที่ต้องการ แล้วกรองในแอปด้วย `provider_id` ที่อยู่ใน `allowedProviderIds`
- ใช้เมื่อจำนวนห้องไม่มาก หรือมีตัวกรองอื่นช่วยลดจำนวนเอกสารอยู่แล้ว

รูปแบบ 2: กรองที่ query ด้วย `where('provider_id', 'in', [...])`
- Firestore จำกัด `in` สูงสุด 10 ค่า/เงื่อนไข
- ถ้า `allowedProviderIds` ยาวกว่า 10 ให้ทำการแบ่งเป็นกลุ่มละ ≤10 แล้วรวมผลลัพธ์

ตัวอย่างการแบ่งกลุ่ม (pseudo):
```
function chunk(arr, size) {
  const out = []; for (let i=0;i<arr.length;i+=size) out.push(arr.slice(i,i+size));
  return out;
}
const chunks = chunk(allowedProviderIds, 10);
const snapshots = await Promise.all(chunks.map(ids =>
  getDocs(query(chatroomsColRef, where('provider_id', 'in', ids)))
));
const rooms = snapshots.flatMap(s => s.docs.map(d => ({ id: d.id, ...d.data() })));
```

คำแนะนำเพิ่มเติม:
- ควรรวมเงื่อนไขช่วงเวลาโดยใช้ `where('last_message_info.msg_timestamp', '>=', from)` และ `<= to` เพื่อจำกัดขอบเขตข้อมูล
- ใช้ `orderBy('last_message_info.msg_timestamp', 'desc')` + `limit(n)` ร่วมด้วยสำหรับหน้าแรก/เลื่อนเพิ่ม

### สิทธิ์ระดับบทบาท (Role-based visibility)

แม้ผู้ใช้จะผ่านเงื่อนไขตามช่องทางแล้ว ยังควรกรองตามสิทธิ์บทบาทในระบบ (ในเว็บใช้รูปแบบ `chat:view:*`) ด้วยตรรกะต่อไปนี้:

- ถ้ามีสิทธิ์ `chat:view:all` ให้เห็นทั้งหมด (ภายใน allowedProviderIds)
- ถ้ามีสิทธิ์ `chat:view:assigned` ให้เห็นเฉพาะห้องที่ผู้ใช้อยู่ใน `assignees` หรือ (fallback) `salespersonId === uid`
- ถ้ามีสิทธิ์ `chat:view:unassigned` ให้เห็นเฉพาะห้องที่ไม่มีผู้รับผิดชอบ (`assignees` ว่าง และไม่มี `salespersonId`)

หมายเหตุ: ในเอกสารบางตัว `assignees` อาจไม่มี ให้ fallback ไปใช้ `salespersonId` แบบเดียวกับฝั่งเว็บ

ตัวอย่างตรรกะย่อ (pseudo):

```
function getAssignees(chat) {
  return Array.isArray(chat.assignees) ? chat.assignees.filter(Boolean)
       : chat.salespersonId ? [chat.salespersonId] : [];
}

let base = allChats.filter(c => allowedSetByType[c.source_type]?.has(c.provider_id));

if (!canViewAll) {
  base = base.filter(c => {
    const asg = getAssignees(c);
    const assignedToMe = asg.includes(currentUser.uid);
    const unassigned = asg.length === 0;
    if (canViewAssigned && canViewUnassigned) return assignedToMe || unassigned;
    if (canViewAssigned) return assignedToMe;
    if (canViewUnassigned) return unassigned;
    return false;
  });
}
```

### การ Normalize ค่า source_type (ตัวอย่าง Messenger)

ในบางข้อมูลเก่า อาจพบ `source_type = "messenger"` ซึ่งเทียบเท่ากับ Facebook Messenger ของเพจ แนะนำให้ normalize เป็น `"facebook"` เพื่อให้ตรวจสอบกับชุดอนุญาตได้ถูกต้องสม่ำเสมอ:

```
const normalizeType = (t) => t === 'messenger' ? 'facebook' : t;
const type = normalizeType(chat.source_type);
```

### Soft-hide (ซ่อนชั่วคราว) ของห้องแชท

- ถ้าห้องมี `is_hidden = true` และ `count` (จำนวน unread) = 0 ให้ซ่อนไม่แสดงในรายการ
- ถ้า `is_hidden = true` แต่มีข้อความใหม่ (unread > 0) ควร “โผล่กลับมา” ให้ผู้ใช้เห็นอีกครั้ง
- ระหว่างการค้นหาข้อความ (full-text ในแอพ): ถ้าห้องตรงกับผลการค้นหา ควรให้แสดงแม้จะถูกซ่อนไว้

### กลยุทธ์การ Query ที่แนะนำ (แยกตามแพลตฟอร์ม)

เพื่อเลี่ยงการชนกันของค่า `provider_id` ข้ามแพลตฟอร์ม และได้ประสิทธิภาพที่ดี แนะนำให้ query แยกตาม `source_type` แล้ว chunk รายการ id ทีละ ≤10:

```
// allowedSets = { line:Set, facebook:Set, instagram:Set, whatsapp:Set, lazada:Set }
const types = Object.keys(allowedSets);
const allResults = [];
for (const type of types) {
  const ids = Array.from(allowedSets[type]);
  const chunks = chunk(ids, 10);
  for (const part of chunks) {
    const q = query(chatroomsColRef,
      where('source_type', '==', type),
      where('provider_id', 'in', part),
      where('last_message_info.msg_timestamp', '>=', from),
      where('last_message_info.msg_timestamp', '<=', to),
      orderBy('last_message_info.msg_timestamp', 'desc'),
      limit(50)
    );
    const snap = await getDocs(q);
    allResults.push(...snap.docs.map(d => ({ id: d.id, ...d.data() })));
  }
}
// รวม-ลบซ้ำด้วย id
const rooms = uniqBy(allResults, r => r.id);
```

เคส `allowedProviderIds` ว่าง: ให้ short-circuit กลับผลลัพธ์ว่าง/ข้ามการยิง query เพื่อลดต้นทุนเครือข่าย

### ด้าน Index ของ Firestore

- เมื่อใช้ `where(field, 'in', ...)` ร่วมกับ `where(range)` และ `orderBy` อาจต้องสร้าง Composite Index ในคอนโซล Firestore ตามที่ระบบแจ้ง
- โครง index ทั่วไปสำหรับตัวอย่างด้านบน: `(source_type ASC, provider_id ASC, last_message_info.msg_timestamp DESC)`

## ตัวอย่างสคีมา JSON (ย่อ) ของ connections

```
companyProfile: {
  connections: {
    line: [
      {
        channelId: "165xxxxxxx",
        displayName: "My OA",
        pictureUrl: "https://...",
        connectedAt: 1710000000000,
        allowedUserIds: ["uidA", "uidB"]
      }
    ],
    facebook: [
      {
        pageId: "1234567890",
        pageName: "My Page",
        connectedAt: "2024-09-01T10:00:00.000Z",
        alias: "เพจหลัก",
        allowedUserIds: []
      }
    ],
    instagram: [
      {
        igUserId: "1784xxxxx",
        igUsername: "my_ig",
        connectedAt: "2024-09-02T12:00:00.000Z"
      }
    ],
    whatsapp: [
      {
        id: "wa_abc123",
        name: "WA Support",
        connectedAt: "2024-09-05T08:00:00.000Z",
        allowedUserIds: ["uidA"]
      }
    ],
    lazada: [
      {
        id: "lz_abc123",
        sellerId: "seller_001",
        sellerName: "My Shop",
        connectedAt: 1725000000000,
        allowedUserIds: []
      }
    ]
  }
}
```

## ข้อควรระวังและเคสขอบ

- ถ้า connection เดียวกันซ้ำซ้อน ให้พิจารณาคัดกรองรายการซ้ำด้วยคีย์อ้างอิงหลัก (ตัวเว็บทำ unique ด้วย Set ก่อนโชว์)
- ถ้า `allowedUserIds` ไม่มีหรือเป็นอาร์เรย์ว่าง ให้ตีความว่า "เปิดสาธารณะภายใน workspace"
- `last_message_info.msg_timestamp` เก็บเป็นสตริงเลข millis ควรแปลงเป็น number ก่อนใช้เปรียบเทียบ
- จำกัด `where('in', ...)` ≤ 10 รายการต่อ query เสมอ และรวมผลลัพธ์เองเมื่อเกิน
- ตัวตนช่องทางกับ `provider_id` ต้องแมปให้ถูกต้องตามแพลตฟอร์มด้านบน
- ถ้าใช้วิธี query เดียวด้วย `provider_id in [...]` รวมทุกแพลตฟอร์ม อาจเกิดการชนกันของ id ได้ในเชิงทฤษฎี ควรพิจารณาแยกเป็น per-`source_type` (แนะนำ)
- การค้นหาข้อความข้ามห้อง (ถ้าทำใน Mobile) ไม่ได้ถูกจำกัดด้วย allowedUserIds ของ connection เพิ่มเติม เพราะสิทธิ์ได้ถูกบังคับที่ระดับ “รายการห้อง” แล้ว; ให้ reuse รายการห้องที่ผ่าน gate นี้เป็นฐาน

## อ้างอิงโค้ดในโปรเจกต์

- Type definitions: `src/lib/types.ts` (เช่น `LineConnection`, `FacebookConnection`, `InstagramConnection`, `WhatsAppConnection`, `LazadaConnection`, `ChatRoom`)
- หน้าตั้งค่าการเชื่อมต่อ: `src/app/(app)/settings/connections/page.tsx` (ตัวอย่างการบันทึก `allowedUserIds` และ alias)
- การสรุปแดชบอร์ดแชทที่รองรับ `allowedProviderIds`: `src/services/chatDashboardApi.ts`
- Firestore security rules: `firestore.rules`

---
เอกสารนี้ตั้งใจให้ทีม Mobile นำไปใช้สร้างเลเยอร์กรองข้อมูลก่อน/ระหว่าง query และสอดคล้องกับโครงสร้างจริงในระบบ หากต้องการตัวอย่างโค้ดภาษาเฉพาะแพลตฟอร์ม (Kotlin/Swift/Flutter) แจ้งเพิ่มเติมได้ครับ