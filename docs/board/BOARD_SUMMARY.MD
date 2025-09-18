--------------------------------------
2025-01-27
เพิ่ม input fields สำหรับ collaborators และ watchers ในหน้า jobcard add และ edit

การเปลี่ยนแปลง:
1. เพิ่ม variables: _selectedCollaborators และ _selectedWatchers ใน create_card_page.dart และ edit_card_page.dart
2. เพิ่ม UI sections: _buildCollaboratorsSection() และ _buildWatchersSection() ใน create_card_page.dart
3. เพิ่ม Collaborators และ Watchers sections ใน edit_card_page.dart
4. อัปเดต _initializeData() ใน edit_card_page.dart เพื่อโหลดข้อมูล collaborators และ watchers จาก card
5. อัปเดต _saveChanges() ใน edit_card_page.dart เพื่อบันทึก collaborators และ watchers
6. อัปเดต _saveCard() ใน create_card_page.dart เพื่อสร้าง card พร้อม collaborators และ watchers

Features:
- Multi-select dropdown สำหรับเลือก collaborators และ watchers
- แสดง selected users เป็น chips ที่สามารถลบได้
- ใช้ข้อมูลจาก _availableUsers (workspace users) ตาม CARD_EDIT_ADD.md
- บันทึกข้อมูลลง database ใน collaborators[] และ watchers[] arrays
--------------------------------------

--------------------------------------
2025-01-27
แก้ไข const Text errors ใน History/Comment UI

ปัญหา:
- Error: "Not a constant expression" ใน edit_card_page.dart
- const Text() ไม่สามารถใช้กับ Colors.grey.shade600/500 ได้
- Compilation errors ที่บรรทัด 1376, 1380, 1384, 1388, 1405, 1409, 1413, 1417

การแก้ไข:
1. ลบ const keyword ออกจาก Text widgets ใน _buildHistoryContent() และ _buildCommentContent()
2. เปลี่ยนจาก:
   ```dart
   const Text('History', style: TextStyle(color: Colors.grey.shade600))
   ```
   เป็น:
   ```dart
   Text('History', style: TextStyle(color: Colors.grey.shade600))
   ```

3. ไฟล์ที่ต้องแก้ไข:
   - edit_card_page.dart (หลัก)
   - create_card_page.dart 
   - card_detail_page.dart

การแก้ไขที่ต้องทำ:
- ค้นหา "const Text(" และเปลี่ยนเป็น "Text(" ใน methods:
  - _buildHistoryContent()
  - _buildCommentContent()
- เฉพาะที่ใช้ Colors.grey.shade600 หรือ Colors.grey.shade500

หมายเหตุ: Colors.grey.shade ไม่ใช่ compile-time constant ทำให้ไม่สามารถใช้กับ const constructor ได้
--------------------------------------
