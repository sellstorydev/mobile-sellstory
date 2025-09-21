# คู่มือ Linking Job Card สำหรับ Mobile (เฉพาะการลิงก์)

เอกสารฉบับย่อสำหรับ “การลิงก์ Job Card” เท่านั้น เพื่อให้ทีม Mobile ผูกการ์ดงานเข้ากับแชท/ลูกค้าได้อย่างถูกต้องและเป็นระเบียบ

## ขอบเขต (Scope)
- ไม่ครอบคลุมการสร้างการ์ด/โควต้า/AI defaults
- ครอบคลุมเฉพาะการ “ลิงก์” Job Card ไปยังแชท และ (อ็อปชัน) ลิงก์ไปยังลูกค้า

## โมเดลข้อมูลที่ใช้
- RelatedDocInfo
  - โครงสร้าง: `{ id: string; docNo: string; type: 'JC' | 'QT' | 'INV' | 'RT' | 'DEP' }`
  - สำหรับ Job Card ให้ใช้ `type: 'JC'`

## เขียนลิงก์ไว้ที่ไหน
1) แชท: `workspaces/{workspaceId}/chatrooms/{chatroomId}`
  - ฟิลด์: `linkedJobCards: RelatedDocInfo[]`
  - ตัวอย่างค่า:
    ```json
    {
      "linkedJobCards": [
        { "id": "<cardId>", "docNo": "<customId>", "type": "JC" }
      ]
    }
    ```
2) ลูกค้า (อ็อปชัน): `workspaces/{workspaceId}/customers/{customerId}`
  - ฟิลด์: `relatedDocuments: RelatedDocInfo[]`
  - ใช้กรณีที่ต้องการให้ประวัติของลูกค้าเห็นเอกสาร Job Card ที่เกี่ยวข้อง

หมายเหตุ: ควรตั้งค่า `docNo` ให้ “เสถียร” เพื่อป้องกันสำเนาซ้ำเมื่อใช้ `arrayUnion` (แนะนำใช้ `card.customId` หากมี)

## ข้อเสนอ API ทางการ (แนะนำ)

### 1) Link Job Card กับแชท
- Endpoint: `POST /api/chatroom/link-jobcard`
- Auth: `Authorization: Bearer <ID_TOKEN>`
- Body:
  ```json
  {
    "workspaceId": "<wsId>",
    "chatroomId": "<chatId>",
    "cardId": "<cardId>",
    "docNo": "<preferred-doc-no>"  // ถ้าไม่ส่ง ให้เซิร์ฟเวอร์ดึงจาก card.customId หรือ card.title
  }
  ```
- พฤติกรรม:
  1) ตรวจสอบว่า card อยู่ใน workspace เดียวกัน
  2) สร้างอ็อบเจ็กต์ `{ id: cardId, docNo, type: 'JC' }`
  3) อัปเดต chatroom: `linkedJobCards` ด้วย `arrayUnion`
  4) คืน `success: true` และค่า link ที่ถูกเพิ่ม
- Response (ตัวอย่าง):
  ```json
  { "success": true, "link": { "id": "<cardId>", "docNo": "JB-250930-0001", "type": "JC" } }
  ```

### 2) Unlink Job Card ออกจากแชท
- Endpoint: `POST /api/chatroom/unlink-jobcard`
- Auth: `Authorization: Bearer <ID_TOKEN>`
- Body:
  ```json
  {
    "workspaceId": "<wsId>",
    "chatroomId": "<chatId>",
    "cardId": "<cardId>"
  }
  ```
- พฤติกรรม (แนะนำให้ปลอดภัยกับการเปลี่ยน docNo):
  1) อ่าน `linkedJobCards` ปัจจุบัน
  2) กรองออกด้วย `id !== cardId`
  3) เขียนกลับเป็นอาร์เรย์ใหม่ (หลีกเลี่ยง `arrayRemove` ที่ต้องตรงทุกฟิลด์)

### 3) (อ็อปชัน) Link Job Card เข้ากับลูกค้า
- Endpoint: `POST /api/customer/link-jobcard`
- Body:
  ```json
  {
    "workspaceId": "<wsId>",
    "customerId": "<customerId>",
    "cardId": "<cardId>",
    "docNo": "<docNo>"
  }
  ```
- พฤติกรรม: เพิ่ม `{ id, docNo, type: 'JC' }` ลง `customers/{id}.relatedDocuments` ด้วย `arrayUnion`

## ตัวอย่างการเรียก (cURL)
Link กับแชท:
```bash
curl -X POST https://<host>/api/chatroom/link-jobcard \
  -H "Authorization: Bearer $ID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "workspaceId": "<wsId>",
    "chatroomId": "<chatId>",
    "cardId": "<cardId>",
    "docNo": "JB-250930-0001"
  }'
```
Unlink จากแชท:
```bash
curl -X POST https://<host>/api/chatroom/unlink-jobcard \
  -H "Authorization: Bearer $ID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "workspaceId": "<wsId>",
    "chatroomId": "<chatId>",
    "cardId": "<cardId>"
  }'
```
Link ให้ลูกค้า (อ็อปชัน):
```bash
curl -X POST https://<host>/api/customer/link-jobcard \
  -H "Authorization: Bearer $ID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "workspaceId": "<wsId>",
    "customerId": "<customerId>",
    "cardId": "<cardId>",
    "docNo": "JB-250930-0001"
  }'
```

## Idempotency และการกันรายการซ้ำ
- ใช้ `arrayUnion` บน `{ id, docNo, type: 'JC' }` เพื่อลดโอกาสซ้ำ
- Firestore จะถือว่า “ซ้ำ” ก็ต่อเมื่ออ็อบเจ็กต์เท่ากันทุกฟิลด์
  - แนะนำให้กำหนด `docNo` เป็น `card.customId` (คงที่) มากกว่าชื่อเรื่อง เพื่อลดโอกาสเปลี่ยนค่า
- ฝั่ง Unlink แนะนำอ่าน-กรอง-เขียนกลับเพื่อไม่ผูกกับค่า `docNo` เดิม

## ความปลอดภัยและสิทธิ์
- ต้องตรวจสอบสิทธิ์ผู้ใช้ว่าเป็นสมาชิกของ `workspaceId` นั้นก่อนอนุญาตให้ลิงก์/ปลดลิงก์
- ตรวจสอบว่า `cardId` และ `chatroomId` อยู่ใน workspace เดียวกัน
- แนะนำให้ทำงานฝั่งเซิร์ฟเวอร์ (Next.js API + Admin SDK) และรับ `Authorization: Bearer <ID_TOKEN>`

## โค้ดตัวอย่าง (Pseudo, ฝั่งเซิร์ฟเวอร์)
```ts
// POST /api/chatroom/link-jobcard
const { workspaceId, chatroomId, cardId, docNo } = await req.json();
// 1) verify id token & membership
// 2) load card to confirm workspace and get fallback docNo = card.customId || card.title
const link = { id: cardId, docNo: docNo || fallback, type: 'JC' };
await db.collection('workspaces').doc(workspaceId)
  .collection('chatrooms').doc(chatroomId)
  .set({ linkedJobCards: admin.firestore.FieldValue.arrayUnion(link), updatedAt: Date.now() }, { merge: true });
return json({ success: true, link });
```

เพียงเท่านี้ Mobile ก็สามารถ “ลิงก์” Job Card กับแชท/ลูกค้าได้เรียบง่าย ปลอดภัย และไม่ซ้ำซ้อน

