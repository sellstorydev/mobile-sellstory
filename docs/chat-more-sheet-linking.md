
ไฟล์นี้อธิบาย “แต่ละจุดที่เชื่อมต่อ/ผูก” ในหน้าเมนูเพิ่มเติมของห้องแชท ว่าทำงานอย่างไร เขียนข้อมูลลงที่ไหน และต้องมีสิทธิ์อะไรบ้าง

## สารบัญ
- [สรุปภาพรวม (Overview)](#สรุปภาพรวม-overview)
- [1) โน้ต (Notes)](#1-โน้ต-notes)
- [2) เพิ่ม/เปลี่ยนลูกค้า (Link/Change Customer)](#2-เพิ่มเปลี่ยนลูกค้า-linkchange-customer)
- [3) ยกเลิกเชื่อมต่อลูกค้า (Unlink Customer)](#3-ยกเลิกเชื่อมต่อลูกค้า-unlink-customer)
- [4) แฮชแท็กของลูกค้า (Customer Hashtags)](#4-แฮชแท็กของลูกค้า-customer-hashtags)
- [5) ผูก/เปลี่ยน/เปิด Job Card](#5-ผูกเปลี่ยนเปิด-job-card)
- [6) เพิ่ม/ลบเซล (Assignees)](#6-เพิ่มลบเซล-assignees)
- [7) สถานะแชท / ปักหมุด / บอท](#7-สถานะแชท--ปักหมุด--บอท)
- [สรุปสิทธิ์ (Permissions Quick Ref)](#สรุปสิทธิ์-permissions-quick-ref)
- [กรณีขอบ (Edge Cases) และหมายเหตุ](#กรณีขอบ-edge-cases-และหมายเหตุ)
- [จุดต่อยอด (Next)](#จุดต่อยอด-next)
- [ตำแหน่งฟิลด์ (Cheat Sheet)](#ตำแหน่งฟิลด์-cheat-sheet)

---

## สรุปภาพรวม (Overview)
- หน้านี้เปิดด้วย: `ShowBottomModal.open(context, ...)`
- ทำงานด้วยเอกสาร Firestore หลัก ๆ:
  - `workspaces/{workspaceId}/chatrooms/{chatroomId}`
  - `workspaces/{workspaceId}/customers/{customerId}` (หากมีการเชื่อมลูกค้า)
  - `workspaces/{workspaceId}/cards/{cardId}` (เมื่อเชื่อม/เปิด Job Card)
- เมนูสำคัญ: โน้ต (Notes), เพิ่ม/เปลี่ยนลูกค้า, ยกเลิกเชื่อมต่อลูกค้า, ผูก Job Card, เพิ่ม/ลบเซล (Assignees), แฮชแท็กของลูกค้า, สถานะแชท/ปักหมุด/บอท

---

## 1) โน้ต (Notes)

- ปุ่ม: ไอคอน `sticky_note_2_outlined` ข้อความ “โน้ต”
- พฤติกรรม:
  - ถ้า “ยังไม่เชื่อมลูกค้า”: เปิดโน้ตแบบระดับห้องแชท (Chatroom-level Notes)
  - ถ้า “เชื่อมลูกค้าแล้ว”: เปิดโน้ตแบบระดับลูกค้า (Customer-level Notes)
- สิทธิ์ที่ใช้เปิด:
  - ถ้า “ไม่มีลูกค้า”: ต้องมีอย่างน้อยหนึ่งใน `chat:manage`, `chat:assign`, `chat:send` หรือเป็น Owner
  - ถ้า “มีลูกค้า”: ต้องมีอย่างน้อยหนึ่งใน `customer:edit:all`, `customer:edit:assigned` หรือเป็น Owner
- การบันทึกข้อมูล:
  - ระดับห้องแชท: `workspaces/{ws}/chatrooms/{chatroomId}.notes` (List<Map>)
  - ระดับลูกค้า: `workspaces/{ws}/customers/{customerId}.notes` (List<Map>)
- การย้าย/รวมโน้ตอัตโนมัติ:
  - เมื่อ “เชื่อมลูกค้า”: ระบบรวมโน้ตจากห้องแชทเข้าลูกค้า (Dedup + Newest Wins) และเคลียร์โน้ตในแชทเพื่อไม่ให้ซ้ำ
  - เมื่อ “ยกเลิกเชื่อมต่อลูกค้า”: ระบบคัดลอกโน้ตของลูกค้ามายังห้องแชท (Dedup + Newest Wins) โดยไม่ลบของลูกค้า
- กุญแจสำหรับ Dedup:
  - ใช้ลำดับ `storagePath > url > id > timestamp+title` เป็นคีย์จัดกลุ่มและเลือกตัวใหม่กว่าชนะ

> หมายเหตุ: การจัดเก็บไฟล์แนบ/รูปในโน้ตจะอ้างพาธตามระดับ (chatrooms/customers) ตามที่ NotesSheet กำหนดไว้ในโปรเจกต์

---

## 2) เพิ่ม/เปลี่ยนลูกค้า (Link/Change Customer)

- ปุ่ม: ไอคอน `supervised_user_circle_outlined` ข้อความ “เพิ่มลูกค้า” (ใช้เพื่อเลือก/เปลี่ยนลูกค้า)
- สิทธิ์: ต้องมี `chat:assign` หรือเป็น Owner เพื่อเชื่อมลูกค้ากับห้องแชท
- การเขียนข้อมูลไปที่แชท:
  - `workspaces/{ws}/chatrooms/{chatroomId}`
    - `customerId`: string (ID ของลูกค้า)
    - `customerName`: string (ชื่อ/แสดงผลของลูกค้า)
- หลังเชื่อมลูกค้าแล้ว ระบบจะทำเพิ่มเติม:
  - รวมโน้ตจากแชทเข้าลูกค้า (ดูหัวข้อโน้ต)
  - โหลด Assignees จากลูกค้า แทนที่การแสดงผลจากแชท
  - แสดง/โหลด “แฮชแท็กของลูกค้า”
  - พยายาม “Auto-link Job Card ล่าสุด” ของลูกค้านั้น (ถ้ามี)

---

## 3) ยกเลิกเชื่อมต่อลูกค้า (Unlink Customer)

- ปุ่ม: ไอคอน `link_off` ข้อความ “ยกเลิกเชื่อมต่อลูกค้า” (แสดงเมื่อมีลูกค้าถูกเชื่อมอยู่)
- สิทธิ์: ต้องมี `chat:assign` หรือเป็น Owner
- พฤติกรรมเมื่อยืนยัน:
  - คัดลอกโน้ตของลูกค้ามายังห้องแชท (Dedup + Newest Wins) โดยไม่ลบโน้ตเดิมของลูกค้า
  - เคลียร์ฟิลด์การเชื่อมลูกค้าในแชท:
    - ลบ `customerId`, ลบ `customerName`
  - รีโหลด Assignees จากแชท (เพราะไม่มีลูกค้าผูกแล้ว)
- หมายเหตุ:
  - เวอร์ชันปัจจุบัน “ยังไม่ย้ายแฮชแท็ก/Assignees ของลูกค้าไปแชท” อัตโนมัติ หากต้องการสามารถพัฒนาต่อได้

---

## 4) แฮชแท็กของลูกค้า (Customer Hashtags)

- แสดงเฉพาะเมื่อเชื่อมลูกค้าแล้ว
- แหล่งข้อมูล Hashtag ทั้งหมดของ Workspace มาจาก Service กลาง (มีการ Filter scope `customer: true` และเรียงตามการใช้งาน/ชื่อ)
- การบันทึกข้อมูล:
  - ลูกค้า (แหล่งจริง): `workspaces/{ws}/customers/{customerId}.hashtags` เป็น List ของ Object
    - แต่ละรายการ: `{ id: string, text: string, color: string }`
  - แชท (สำหรับแสดงผลทันที): `workspaces/{ws}/chatrooms/{chatroomId}`
    - `hashtagIds`: List<string>
    - `hashtags`: List<string> (ชื่อพร้อม # เพื่อโชว์ทันที)
- สิทธิ์แก้ไข/เพิ่ม:
  - ต้องมีอย่างน้อยหนึ่งใน `customer:edit:all`, `customer:edit:assigned` หรือเป็น Owner
- เวิร์กโฟลว์ UI:
  - เปลี่ยนค่าในอินพุต → ปุ่มบันทึกจะเปิดเมื่อมีการแก้ไขจริง (dirty)
  - สามารถ “เพิ่มแฮชแท็กใหม่” (สร้างที่ระดับ Workspace) ได้ เมื่อมีสิทธิ์ด้านลูกค้า

---

## 5) ผูก/เปลี่ยน/เปิด Job Card

- ปุ่มผูก: ไอคอน `card_travel_outlined` ข้อความ “ผูก Job Card”
- ปุ่มเปิดเมื่อมีการผูกแล้ว: การ์ดแสดงรายละเอียด + ปุ่ม “เปลี่ยน”
- สิทธิ์:
  - ดู/เลือก: `jobcard:view:all` หรือ `jobcard:view:assigned` หรือ Owner (เปิด Picker/เปิดรายละเอียด)
  - เชื่อมกับแชท: ต้องมี `chat:assign` หรือ Owner
- การบันทึกข้อมูลลงแชท:
  - `workspaces/{ws}/chatrooms/{chatroomId}`
    - `jobCardId`: string
    - `jobCardTitle`: string
- กรณี “เลือก Job Card แต่แชทยังไม่ผูกลูกค้า”:
  - ระบบพยายามอ่าน `customerId` จากการ์ด แล้ว “เชื่อมลูกค้ากับแชทให้” พร้อมรวมโน้ต (ดูหัวข้อโน้ต)

---

## 6) เพิ่ม/ลบเซล (Assignees)

- ปุ่มเพิ่ม: ไอคอน `badge_outlined` ข้อความ “เพิ่มเซล” → เปิด User Picker
- สิทธิ์: ต้องมี `chat:assign` หรือ Owner
- แหล่งข้อมูลแสดงผล:
  - ถ้าผูกลูกค้าอยู่: อ่านจาก `workspaces/{ws}/customers/{customerId}.assignees` (List<string>)
  - ถ้าไม่ผูกลูกค้า: อ่านจาก `workspaces/{ws}/chatrooms/{chatroomId}.assignees` (List<string>)
- การเพิ่ม/ลบ:
  - ถ้าผูกลูกค้า: เพิ่ม/ลบใน doc ของลูกค้า
  - ถ้าไม่ผูกลูกค้า: เพิ่ม/ลบใน doc ของแชท

---

## 7) สถานะแชท / ปักหมุด / บอท

- ปุ่มสถานะ (กำลังดำเนินการ / สำเร็จ), ปักหมุด, เปิด/ปิดบอท
- สิทธิ์: `chat:assign` หรือ Owner
- ฟิลด์ใน `workspaces/{ws}/chatrooms/{chatroomId}`:
  - `chatroom_status`: 'INPROGRESS' | 'DONE' (ในโค้ด Normalize เป็น in progress/done)
  - `chat_pin`: 'Y'|'N'
  - `bot_status`: 'Y'|'N'

---

## สรุปสิทธิ์ (Permissions Quick Ref)

- เปิดโน้ต (ไม่มีลูกค้า): `chat:manage` | `chat:assign` | `chat:send` | Owner
- เปิดโน้ต (มีลูกค้า): `customer:edit:all` | `customer:edit:assigned` | Owner
- เชื่อม/ยกเลิกเชื่อมลูกค้า, เปลี่ยนสถานะ/ปักหมุด/บอท, มอบหมาย/ลบผู้ดูแล: `chat:assign` | Owner
- ดู/เชื่อม Job Card: `jobcard:view:all` | `jobcard:view:assigned` | Owner (ดู/picker); เชื่อมต้อง `chat:assign` | Owner
- จัดการแฮชแท็กลูกค้า: `customer:edit:all` | `customer:edit:assigned` | Owner

ดูรายละเอียดเพิ่มเติมที่ [chat-center-permissions.md](./chat-center-permissions.md)

---

## กรณีขอบ (Edge Cases) และหมายเหตุ

- การรวมโน้ต (Merge) ใช้วิธี Dedup ตามคีย์ที่อธิบายไว้ ป้องกันรายการซ้ำซ้อนเมื่อย้ายไป-กลับ
- การยกเลิกเชื่อมต่อลูกค้า “คัดลอกโน้ตฝั่งลูกค้า” กลับมาที่แชท แต่ “ไม่ลบของเดิมฝั่งลูกค้า”
- เมื่อเชื่อมลูกค้าแล้ว การแสดงผล Assignees จะอ้างอิงจากลูกค้าเสมอ
- ความแตกต่างของ Workspace: อาจมีนโยบายแฮชแท็ก/สี Default ต่างกัน → ใช้ Service กลางกำหนด

---

## จุดต่อยอด (Next)

- รองรับการย้าย/ซิงก์ แฮชแท็ก/Assignees แบบ Two-way ระหว่างลูกค้า ↔ แชท ตอนเชื่อม/ยกเลิกเชื่อม
- เพิ่ม Badge แสดงจำนวนโน้ตในรายการแชท
- เพิ่ม Logs/Analytics เมื่อเกิดการเชื่อม/ยกเลิก

---

## ตำแหน่งฟิลด์ (Cheat Sheet)

- Chatroom: `workspaces/{ws}/chatrooms/{chatroomId}`
  - `customerId`, `customerName`
  - `notes` (List<Map>) — ใช้เมื่อไม่มีลูกค้า
  - `hashtagIds` (List<string>), `hashtags` (List<string> with #)
  - `jobCardId`, `jobCardTitle`
  - `assignees` (List<string>) — ใช้เมื่อไม่มีลูกค้า
  - `chat_pin` ('Y'|'N'), `bot_status` ('Y'|'N'), `chatroom_status`

- Customer: `workspaces/{ws}/customers/{customerId}`
  - `notes` (List<Map>) — ใช้เมื่อมีลูกค้า
  - `hashtags` (List<{id,text,color}>)
  - `assignees` (List<string>)

- Job Card: `workspaces/{ws}/cards/{cardId}`
  - `customerId` (หรือ `customer.id`)
  - `title`/`name`
