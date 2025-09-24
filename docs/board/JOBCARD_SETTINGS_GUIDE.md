# คู่มือการตั้งค่า Job Card (ต่อบอร์ด)

ควบคุมการ “เปิด/ปิด Section & Field”, กำหนด Required, และจัดลำดับการแสดงผล สำหรับบอร์ดแต่ละอัน พร้อมแนวทางให้ Mobile app นำไปใช้ได้สะดวก


## ภาพรวมสั้นๆ
- การตั้งค่านี้เก็บอยู่ในเอกสาร Board (ต่อบอร์ด) ภายใต้ฟิลด์ `jobCardSettings` และ `customFieldTemplate` (สำหรับ Custom Fields)
- UI ฝั่ง Web จะซ่อน/แสดงและบังคับกรอกตามกติกานี้ รวมถึงซ่อนตัวเลขการเงินในส่วนหัวเมื่อปิด Section “expenses”
- Mobile app สามารถอ่านค่าจากเอกสาร Board เดียวกัน เพื่อนำไปบังคับ UI และ Validation ได้ทันที (แนะนำให้อ่านแบบ realtime subscription)

ตำแหน่งประเภทข้อมูล (อ้างอิง TypeScript):
- ไฟล์ `src/lib/types.ts`
  - `interface Board { jobCardSettings?: JobCardSettings; customFieldTemplate?: Array<... & { required?: boolean }>; }`
  - `interface JobCardSettings { sections?: JobCardSectionRule[]; fields?: JobCardFieldRule[]; allowPerUserOverrides?: boolean; }`
  - `type JobCardSectionId = 'collaborators' | 'watchers' | 'todos' | 'expenses' | 'attachments' | 'notes' | 'history' | 'documents'`
  - `type JobCardFieldId = 'title' | 'description' | 'assignee' | 'customer' | 'dates' | 'customId' | 'priority' | 'hashtags' | 'customFields'`


## โครงสร้างข้อมูลการตั้งค่า

### 1) Section Rules (แท็บ/บล็อกใหญ่ในหน้า Job Card)
- รูปแบบ: `JobCardSectionRule = { id: JobCardSectionId; visible: boolean; order?: number; lockVisibility?: boolean; }`
- ตัวอย่าง Section ที่รองรับ: `collaborators`, `watchers`, `todos`, `expenses`, `attachments`, `notes`, `history`, `documents`
- ความหมาย
  - `visible`: เปิด/ปิดการแสดงผลของ Section นั้นๆ
  - `order`: ลำดับการแสดง (ถ้ามี)
  - `lockVisibility`: ล็อกไม่ให้ผู้ใช้ระดับ View ส่วนตัวเปลี่ยนได้ (เผื่ออนาคต)

### 2) Field Rules (ฟิลด์หลักๆ ในส่วนรายละเอียดของ Job Card)
- รูปแบบ: `JobCardFieldRule = { id: JobCardFieldId; visible?: boolean; required?: boolean; lockVisibility?: boolean; }`
- ตัวอย่าง Field ที่รองรับ: `title`, `description`, `assignee`, `customer`, `dates`, `customId`, `priority`, `hashtags`, `customFields`
- ความหมาย
  - `visible`: ซ่อน/แสดง Field (ถ้าไม่ระบุ ให้ใช้ค่าเริ่มต้นของระบบ)
  - `required`: บังคับกรอก (UI จะแสดงเครื่องหมายและบล็อกการบันทึกเมื่อไม่ครบ)
  - `lockVisibility`: ล็อกไม่ให้เปลี่ยนในมุมมองผู้ใช้รายคน (เผื่ออนาคต)

### 3) Custom Field Template (ต่อบอร์ด)
- รูปแบบ: `Board.customFieldTemplate?: Array<Omit<CustomField, 'id' | 'value'> & { required?: boolean }>`
- ความหมาย
  - กำหนดรายการ Custom Fields ของบอร์ด และสามารถตั้ง `required: true` สำหรับฟิลด์เฉพาะได้
  - ฝั่ง UI จะบังคับกรอกเฉพาะฟิลด์ที่ถูกทำเครื่องหมาย `required`


## ค่าปริยาย (Defaults) และการตีความค่าไม่ระบุ
- ถ้าไม่มี `jobCardSettings` หรือไม่มี Rule สำหรับ Section/Field ใดๆ ให้ใช้ค่าเริ่มต้นของระบบ
- สำหรับการซ่อนสรุปการเงินในส่วนหัว: จะซ่อนเมื่อพบว่า Section `expenses` ถูกตั้ง `visible: false`

> หมายเหตุ: ค่าเริ่มต้นของระบบอาจปรับได้ในอนาคต ควรเขียนโค้ด Mobile ให้ “ทนต่อค่าไม่ระบุ” โดยให้ Fallback เป็นค่าปลอดภัย เช่นแสดงฟิลด์ทั่วไป และบังคับกรอกเฉพาะที่ประกาศชัดเจนว่า `required: true` เท่านั้น


## ตัวอย่าง JSON ที่บันทึกในเอกสาร Board
```json
{
  "jobCardSettings": {
    "sections": [
      { "id": "todos", "visible": true, "order": 1 },
      { "id": "expenses", "visible": false, "order": 2 },
      { "id": "attachments", "visible": true, "order": 3 }
    ],
    "fields": [
      { "id": "title", "visible": true, "required": true },
      { "id": "assignee", "visible": true },
      { "id": "customer", "visible": true },
      { "id": "dates", "visible": true },
      { "id": "customFields", "visible": true }
    ],
    "allowPerUserOverrides": true
  },
  "customFieldTemplate": [
    { "name": "PO Number", "type": "text", "required": true },
    { "name": "Budget Code", "type": "text" },
    { "name": "Target Go-Live", "type": "date" }
  ]
}
```

ผลลัพธ์ที่ UI ควรทำตามจากตัวอย่าง:
- ส่วนหัวของ Dashboard จะ “ไม่แสดง” คำว่า `(Grand Total)` และตัวเลขรวม เพราะ `expenses.visible` ถูกตั้งเป็น `false` (ซ่อนข้อมูลการเงินทั้งหมดในหัว)
- ฟิลด์ `title` ต้องกรอก (required)
- ในแท็บ Custom Fields, `PO Number` ต้องกรอก (required) ส่วน `Budget Code`, `Target Go-Live` ไม่บังคับ


## พฤติกรรมใน Dashboard Header (ซ่อน Grand Total/จำนวนเงิน)
- Web Dashboard ส่งพร็อพ `hideFinancials` ไปที่ Header เมื่อพบว่า Section `expenses` ถูกซ่อน (`visible === false`)
- เมื่อ `hideFinancials = true`
  - จะไม่แสดงคำว่า `(Grand Total)`
  - จะไม่แสดงตัวเลขรวมทั้งหมดบนการ์ดสถานะต่างๆ

ตรรกะย่อ:
```ts
const expensesRule = board.jobCardSettings?.sections?.find(s => s.id === 'expenses');
const hideFinancials = expensesRule ? expensesRule.visible === false : false;
```


## วิธีนำไปใช้ใน Mobile App ให้สะดวก

### A) อ่านค่าจาก Firestore โดยตรง (แนะนำสำหรับ Realtime)
1. อ่านเอกสาร Board ที่ใช้งาน (เช่น `boards/{boardId}`) เอาฟิลด์ `jobCardSettings` และ `customFieldTemplate`
2. รวมค่าเข้ากับ Defaults เพื่อสร้าง “Effective Rules”
3. ใช้กติกานี้กับ UI Mobile:
   - ซ่อน/แสดง Section และ Field ตาม `visible`
   - บังคับกรอก Field ที่ `required: true`
   - ถ้า `expenses.visible === false` ให้ซ่อนข้อความ `(Grand Total)` และตัวเลขรวมทุกที่ที่มีการสรุปการเงิน
4. สมัคร `onSnapshot` (หรือเทียบเท่า) เพื่ออัปเดต UI อัตโนมัติเมื่อผู้ดูแลเปลี่ยนการตั้งค่าบอร์ด

โค้ดตัวอย่าง (แนวคิด TypeScript/Pseudo):
```ts
type SectionId = 'collaborators' | 'watchers' | 'todos' | 'expenses' | 'attachments' | 'notes' | 'history' | 'documents';
type FieldId   = 'title' | 'description' | 'assignee' | 'customer' | 'dates' | 'customId' | 'priority' | 'hashtags' | 'customFields';

interface JobCardSectionRule { id: SectionId; visible: boolean; order?: number; }
interface JobCardFieldRule   { id: FieldId; visible?: boolean; required?: boolean; }

interface BoardDoc {
  jobCardSettings?: {
    sections?: JobCardSectionRule[];
    fields?: JobCardFieldRule[];
  };
  customFieldTemplate?: Array<{ name: string; type: string; required?: boolean; options?: string[] }>;
}

function buildEffectiveConfig(board: BoardDoc) {
  const sectionDefaults: Record<SectionId, { visible: boolean; order?: number }> = {
    collaborators: { visible: true },
    watchers:      { visible: true },
    todos:         { visible: true },
    expenses:      { visible: true },
    attachments:   { visible: true },
    notes:         { visible: true },
    history:       { visible: true },
    documents:     { visible: true },
  };

  const fieldDefaults: Record<FieldId, { visible: boolean; required: boolean }> = {
    title:        { visible: true,  required: true  },
    description:  { visible: true,  required: false },
    assignee:     { visible: true,  required: false },
    customer:     { visible: true,  required: false },
    dates:        { visible: true,  required: false },
    customId:     { visible: true,  required: false },
    priority:     { visible: true,  required: false },
    hashtags:     { visible: true,  required: false },
    customFields: { visible: true,  required: false },
  };

  const sections = { ...sectionDefaults };
  const fields   = { ...fieldDefaults };

  for (const r of board.jobCardSettings?.sections || []) {
    sections[r.id] = { ...sections[r.id], ...r };
  }
  for (const r of board.jobCardSettings?.fields || []) {
    fields[r.id] = { ...fields[r.id], ...r } as any;
  }

  const hideFinancials = sections.expenses?.visible === false;

  const customFieldRequiredByName: Record<string, boolean> = {};
  for (const cf of board.customFieldTemplate || []) {
    customFieldRequiredByName[cf.name] = !!cf.required;
  }

  return { sections, fields, hideFinancials, customFieldRequiredByName };
}
```

การใช้งานในหน้าฟอร์ม Mobile:
- ก่อนเรนเดอร์: `const cfg = buildEffectiveConfig(boardDoc)`
- ซ่อน Section/Field ที่ `cfg.sections[sec].visible === false` หรือ `cfg.fields[f].visible === false`
- ตอนกดบันทึก: ตรวจ `required`
  - ฟิลด์มาตรฐาน: เช็ก `cfg.fields[f].required === true`
  - Custom Field: เช็กจาก `cfg.customFieldRequiredByName[name] === true`
- ส่วนหัว/สรุปการเงิน: ถ้า `cfg.hideFinancials` เป็น `true` ให้ซ่อนยอดรวมทั้งหมด

> หมายเหตุ: ตัวอย่างโค้ดใช้ Defaults กลางเพื่อให้โค้ดปลอดภัยเมื่อค่าใน Firestore ไม่ครบถ้วน คุณสามารถปรับ Defaults ให้ตรงกับนโยบายของทีมได้


### B) ถ้าต้องการผ่าน REST/HTTP เดียว (ทางเลือก)
- จัดทำ Endpoint ที่คืน "Effective Config" ตาม Board Id เพื่อให้ Mobile เรียกครั้งเดียวแล้วได้ผลลัพธ์พร้อมใช้ เช่น:

ตัวอย่าง Response (ย่อ):
```json
{
  "sections": { "todos": { "visible": true }, "expenses": { "visible": false } },
  "fields":   { "title": { "visible": true, "required": true } },
  "hideFinancials": true,
  "customFieldRequiredByName": { "PO Number": true }
}
```

ข้อดี:
- รวม Default + Overrides ให้เรียบร้อย ลดลงฝั่ง Mobile
- สามารถแทรก Versioning/ETag เพื่อแคชได้สะดวก


### คำแนะนำเพิ่มเติมสำหรับ Mobile
- แคช/ซิงก์: ใช้ onSnapshot หรือดึงซ้ำเมื่อโฟกัสหน้า เพื่อให้การตั้งค่าอัปเดตทันทีที่ผู้ดูแลเปลี่ยน
- Fallback เมื่อออฟไลน์: ใช้ค่าจากแคชล่าสุด และยังคงบังคับเฉพาะฟิลด์ที่ประกาศ `required`
- Validation ฝั่งไคลเอนต์: ทำก่อนบันทึกทุกครั้งเพื่อลดรอบเครือข่าย และลดโอกาสข้อมูลไม่ครบ


## จุดที่เกี่ยวข้องในโค้ด Web (สำหรับอ้างอิง)
- `src/components/board/dashboard-header.tsx` – รองรับพร็อพ `hideFinancials` เพื่อซ่อนคำว่า `(Grand Total)` และตัวเลขรวม
- `src/components/kanban-flow-dashboard.tsx` – คำนวณ `hideFinancials` จาก `board.jobCardSettings.sections` และส่งไปที่ Header
- `src/components/board/card-detail-modal.tsx` – บังคับ Required ทั้งฟิลด์มาตรฐานและ Custom Fields ตามกติกาบอร์ด


## สรุป
- เก็บการตั้งค่าต่อบอร์ดไว้ใน `Board.jobCardSettings` และ `Board.customFieldTemplate`
- ซ่อนสรุปการเงินในหัวอัตโนมัติเมื่อ `expenses.visible === false`
- Mobile app สามารถอ่านค่าจากเอกสาร Board เดียวกันแล้วบังคับ UI/Validation ได้ทันที โดยแนะนำให้อ่านแบบ realtime และมี Fallback ที่ปลอดภัย
