## สรุปการแก้ไข JobCard Create Data Mapping

### ปัญหาที่พบ
การสร้าง JobCard ใน Flutter app สร้างข้อมูลที่ไม่ตรงกับ structure ที่ใช้ใน web version:

**ข้อมูลที่ผิดพลาด (Flutter):**
- มี `memberUids` แทน `watchers`
- มี `badges`, `hashtag`, `lanes`, `members`, `name`, `workspaces` ที่ไม่จำเป็น  
- ขาด `customFields`, `expenses`, `notes`, `attachments`, `descriptionMentions`
- `description` และ `todos.title` เป็น plain text แทน HTML format
- `updatedAt` เป็น number แทน Firestore Timestamp object

### การแก้ไขที่ทำ

#### 1. แก้ไข `JobCard.toMap()` method ใน `/lib/domain/entities/job_card.dart`
- ลบ fields ที่ไม่จำเป็น: `name`, `memberUids`, `members`, `lanes`, `workspaces`, `badges`, `hashtag`
- เพิ่ม fields ที่ขาดหาย: `id`, `customFields`, `expenses`, `notes`, `attachments`, `descriptionMentions`, `quotationTemplateId`
- รับประกันว่า `watchers` และ `collaborators` arrays ถูกบันทึกอย่างถูกต้อง
- จัดระเบียบโครงสร้างให้ตรงกับ web version

#### 2. แก้ไข FirestoreRepository ใน `/lib/data/repositories/firestore_repository.dart`
- เพิ่มการแปลง `updatedAt` เป็น Firestore Timestamp object format:
  ```dart
  {
    '_seconds': (updatedAtMs / 1000).floor(),
    '_nanoseconds': ((updatedAtMs % 1000) * 1000000).toInt(),
  }
  ```
- เพิ่ม debug logging สำหรับ `watchers` และ `collaborators`

#### 3. แก้ไข CreateCardPage ใน `/lib/features/board/view/create_card_page.dart`
- แปลง `description` เป็น HTML format: `<p><strong>text</strong></p>`
- แปลง `todos.title` เป็น HTML format with styling
- รับประกันว่า `watchers` และ `collaborators` ได้รับการส่งไปอย่างถูกต้อง

### ผลลัพธ์ที่คาดหวัง

JobCard ที่สร้างจาก Flutter จะมี structure ที่ตรงกับ web version:

```json
{
  "boardId": "string",
  "workspaceId": "string", 
  "title": "string",
  "description": "<p><strong>text</strong></p>",
  "status": "string",
  "assignedTo": "string",
  "customFields": [],
  "hashtags": [...],
  "expenses": [],
  "todos": [...],
  "notes": [],
  "customer": "string",
  "customerId": "string",
  "company": {...},
  "createdAt": number,
  "createdBy": "string",
  "updatedBy": "string", 
  "updatedByDisplayName": "string",
  "attachments": [],
  "quotationTemplateId": "",
  "startDate": number,
  "endDate": number,
  "customerInterest": "string",
  "descriptionMentions": [],
  "customId": "string",
  "order": number,
  "watchers": ["string"],
  "collaborators": ["string"],
  "id": "string",
  "laneId": "string",
  "updatedAt": {
    "_seconds": number,
    "_nanoseconds": number
  }
}
```

### การทดสอบ
- รัน `flutter pub get` สำเร็จ
- ไม่มี compilation errors
- โครงสร้างข้อมูลตรงตาม web version
- watchers และ collaborators ถูกส่งไปอย่างถูกต้อง
