# Mobile Send Message API

API สำหรับส่งข้อความจาก Mobile App ไปยัง LINE, Facebook, Instagram

## Endpoint
```
POST /api/mobile/send-message
```

## Request Body
```typescript
{
  workspaceId: string;        // ID ของ Workspace
  chatroomId: string;         // ID ของ Chatroom 
  platform: "line" | "facebook" | "instagram";  // Platform ปลายทาง
  message: {
    type: "text" | "image" | "video" | "audio" | "file" | "sticker";
    text?: string;            // ข้อความ (สำหรับ type: text)
    imageUrl?: string;        // URL รูปภาพ (สำหรับ type: image)
    videoUrl?: string;        // URL วิดีโอ (สำหรับ type: video)
    audioUrl?: string;        // URL เสียง (สำหรับ type: audio)
    fileUrl?: string;         // URL ไฟล์ (สำหรับ type: file)
    fileName?: string;        // ชื่อไฟล์
    stickerId?: string;       // ID สติ๊กเกอร์ (สำหรับ LINE)
    stickerPackageId?: string; // Package ID สติ๊กเกอร์ (สำหรับ LINE)
  };
  sender?: {                  // ข้อมูลผู้ส่ง (ถ้าไม่ระบุจะใช้ Mobile App)
    id: string;
    name: string;
    avatar?: string;
  };
  // (ออปชัน) ส่งแบบ "ตอบกลับ / อ้างถึง" ข้อความเดิม
  // server จะพยายามหา original message ด้วย messageId -> ถ้าไม่เจอจะ fallback หา platformMessageId
  replyTo?: {
    messageId: string;        // Firestore message id หรือ platformMessageId ของข้อความต้นทาง
    quotedMessageId?: string; // (ส่วนมากใส่เหมือน messageId) ใช้คงรูปแบบภายใน
    quoteToken?: string;      // (LINE เท่านั้น) quoteToken จาก event.message.quoteToken ของข้อความต้นทาง
  };
}
```

## Response
```typescript
{
  success: boolean;
  messageId?: string;         // ID ของข้อความที่ส่งสำเร็จ
  error?: string;             // ข้อผิดพลาด (ถ้ามี)
}
```

## ตัวอย่างการใช้งาน

### ส่งข้อความธรรมดา
```javascript
fetch('/api/mobile/send-message', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    workspaceId: "9KTrtUEyUq8rFlkVM3pA",
    chatroomId: "U8fda1378e3b8c7e440b3a68649200cfc",
    platform: "line",
    message: {
      type: "text",
      text: "สวัสดีครับ! มีอะไรให้ช่วยไหมครับ"
    },
    sender: {
      id: "agent001",
      name: "Agent John",
      avatar: "https://example.com/avatar.jpg"
    }
  })
})
```

### ส่งรูปภาพ
```javascript
fetch('/api/mobile/send-message', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    workspaceId: "9KTrtUEyUq8rFlkVM3pA",
    chatroomId: "U8fda1378e3b8c7e440b3a68649200cfc",
    platform: "facebook",
    message: {
      type: "image",
      imageUrl: "https://example.com/product.jpg"
    }
  })
})
```

### ส่งสติ๊กเกอร์ (LINE เท่านั้น)
```javascript
fetch('/api/mobile/send-message', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    workspaceId: "9KTrtUEyUq8rFlkVM3pA",
    chatroomId: "U8fda1378e3b8c7e440b3a68649200cfc",
    platform: "line",
    message: {
      type: "sticker",
      stickerPackageId: "1",
      stickerId: "1"
    }
  })
})
```

### ส่งข้อความแบบตอบกลับ (Reply / Quoted Message)
```javascript
// สมมติ เรามี originalMessage (ดึงมาก่อนหน้า) ที่มี field ใด field หนึ่งต่อไปนี้:
// - originalMessage.id (Firestore doc id)
// - originalMessage.platformMessageId (LINE / FB / IG provider id)
// - originalMessage.quoteToken (เฉพาะ LINE ถ้าระบบส่งมาด้วย)

fetch('/api/mobile/send-message', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    workspaceId: '9KTrtUEyUq8rFlkVM3pA',
    chatroomId: 'U8fda1378e3b8c7e440b3a68649200cfc',
    platform: 'line',
    message: {
      type: 'text',
      text: 'ตอบกลับข้อความด้านบนครับ'
    },
    replyTo: {
      // ใส่อันใดอันหนึ่งที่มีอยู่ (ถ้ามีทั้งสอง เลือก doc id ก่อน)
      messageId: originalMessage.id || originalMessage.platformMessageId,
      quotedMessageId: originalMessage.id || originalMessage.platformMessageId,
      quoteToken: originalMessage.quoteToken // (ถ้ามี - LINE เท่านั้น)
    },
    sender: { id: 'agent001', name: 'Agent John' }
  })
});
```

หมายเหตุ:
- ถ้าเป็น LINE และต้องการให้ฝั่ง LINE แสดง UI reply ของทาง LINE จริง ๆ ต้องระบุ `quoteToken` ของข้อความต้นฉบับ (ระบบเราเก็บไว้ใน field `quoteToken` ของ message ถ้าขาเข้าเป็น reply)
- ถ้าไม่มี `quoteToken` จะยังคงบันทึกความสัมพันธ์ reply ในระบบ SellStory และ UI ภายในยังแสดงกรอบอ้างอิงได้
- Facebook / Instagram ปัจจุบันบันทึก reply ในระบบ (internal) ผ่าน `replyTo` แต่ยังไม่ได้ยิง API รูปแบบ reply threading พิเศษเพิ่ม (รองรับในอนาคต)

---

## รูปแบบข้อมูล Reply ที่ได้รับ (ฝั่งอ่าน / Fetch Messages)
เมื่อดึงรายการข้อความ จะมีโครงสร้าง (ถ้ามีการตอบกลับ):
```typescript
interface ReplyToInfo {
  messageId: string;          // ไอดีที่ผู้ส่งใส่มา (อาจเป็น doc id หรือ provider id)
  quotedMessageId?: string;   // ปกติจะเท่ากับ messageId ใช้เพื่อความสม่ำเสมอภายใน
  messageText?: string;       // snippet ของข้อความต้นทาง (ระบบจะพยายาม enrich ถ้าเป็น placeholder จะไม่ใส่)
  senderName: string;         // ชื่อผู้ส่งของข้อความต้นทาง (enriched ถ้าหาเจอ)
  quoteToken?: string;        // LINE เท่านั้น
}
```

ข้อความต้นฉบับเอง (ถ้าอยู่ใน list) จะมีฟิลด์:
```typescript
platformMessageId?: string; // ไอดีจากผู้ให้บริการ (LINE message.id / FB / IG / Lazada / WhatsApp)
quoteToken?: string;        // LINE quote token (ถ้าข้อความนั้นถูกคนอื่น reply ได้)
```

---
## วิธีโฟกัส (Focus / Scroll) ไปยังข้อความต้นฉบับในแอปมือถือ

Pseudo-code ด้านล่างแสดงลำดับ fallback ที่ควรทำเวลา user แตะที่กรอบ reply:
```typescript
function focusReply(reply: ReplyToInfo, messages: ChatMessage[], scrollTo: (id: string) => void) {
  if (!reply) return;
  const targetIds = [
    reply.quotedMessageId,
    reply.messageId,
  ].filter(Boolean) as string[];

  // 1) หาตรง ๆ ด้วย doc id หรือ provider id ที่ map อยู่แล้วใน local refs
  for (const id of targetIds) {
    if (hasRef(id)) { // ฟังก์ชันเช็คว่ามี DOM ref หรือ row ref ใน list
      scrollTo(id);
      return;
    }
  }

  // 2) ถ้ายังไม่พบ อาจยังไม่โหลดหน้าที่มีข้อความนั้น → ยิง API เพิ่มเติม
  //    server รองรับส่ง messageId ที่เป็น provider id ได้ (จะ fallback หา platformMessageId ใน DB)
  fetch(`/api/mobile/get-message?workspaceId=...&chatroomId=...&messageId=${encodeURIComponent(reply.messageId)}`)
    .then(r => r.json())
    .then(data => {
      if (data?.message) {
        appendMessageIfMissing(data.message); // ใส่เข้า state
        setTimeout(() => scrollTo(data.message.id), 50);
      }
    });
}
```

หลักการสำคัญ:
- ให้ map DOM ref (หรือ virtual list key) ทั้ง `message.id` และ `message.platformMessageId` (ถ้ามี) ตอน render
- เวลา focus ลองทั้งสองค่าที่มาจาก reply
- ถ้าไม่เจอ ให้ดึงจาก backend เฉพาะตัวเดียว (lazy load) แทนการย้อนโหลดทั้งเพจ

---
## สรุป Flow Reply
1. ผู้ใช้เลือกข้อความ A → ได้ข้อมูล (id, platformMessageId, quoteToken?)
2. ส่งข้อความ B พร้อม `replyTo.messageId = A.id || A.platformMessageId` และถ้า LINE มี `quoteToken`
3. Server บันทึกและ enrich (เติม senderName + messageText ถ้าหาได้)
4. Client ดึงข้อความ B → render กรอบ reply พร้อมกดเพื่อโฟกัส A
5. ถ้า A ยังไม่อยู่ใน buffer → เรียก API get by id (รองรับ fallback platformMessageId)

---

## FAQ (Reply)
**Q: ต้องส่งทั้ง messageId และ quotedMessageId ไหม?**  
ไม่จำเป็น ใส่ตัวเดียวให้ระบบก็ได้ แต่ถ้าใส่ทั้งคู่ให้เหมือนกันเพื่อความชัดเจน

**Q: ถ้า original เป็นรูป / สติ๊กเกอร์ ทำไมไม่มี messageText?**  
ระบบจะไม่สร้าง snippet เทียมจาก placeholder อย่าง [Image] เว้นแต่ข้อความจริง

**Q: ถ้าผมมีแค่ provider id (เช่น LINE message.id) จะใช้ได้ไหม?**  
ได้ ใส่ใน `replyTo.messageId` ได้เลย Server จะลองค้นหาเป็น doc id ก่อน ถ้าไม่เจอค่อยเทียบ `platformMessageId`

**Q: จะรู้ quoteToken ของ LINE ได้อย่างไร?**  
อยู่ในฟิลด์ `quoteToken` ของ message ที่ถูก reply (ขาเข้า) — เก็บไว้ใช้ตอนส่ง push reply ที่แท้จริงใน LINE


## HTTP Status Codes
- `200 OK` - ส่งข้อความสำเร็จ
- `400 Bad Request` - ข้อมูลที่ส่งมาไม่ถูกต้อง
- `500 Internal Server Error` - เกิดข้อผิดพลาดภายในระบบ

## ข้อกำหนดเพิ่มเติม

### LINE Platform
- รองรับ: text, image, video, audio, sticker
- ต้องมี LINE Connection ที่ active ใน workspace
- สำหรับ sticker ต้องระบุ `stickerPackageId` และ `stickerId`

### Facebook Platform  
- รองรับ: text, image, video, audio, file
- ต้องมี Facebook Connection ที่ active ใน workspace
- ใช้ Facebook Messenger API

### Instagram Platform
- รองรับ: text, image, video (จำกัด)
- ต้องมี Instagram Connection ที่ active ใน workspace
- ใช้ Instagram Messaging API

## Error Handling
API จะ return error message ใน response body หากเกิดข้อผิดพลาด:
```javascript
{
  success: false,
  error: "No LINE connection found"
}
```

## Testing
ใช้ GET method สำหรับดู API documentation:
```
GET /api/mobile/send-message
```
