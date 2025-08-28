# สรุปงานที่ทำ: เพิ่มการเช็คสิทธิ์ (Permissions) ในแอป Mobile SellStory

เอกสารนี้สรุปการปรับปรุงระบบสิทธิ์การใช้งาน (RBAC/Permissions) ที่ถูกเพิ่มเข้ามา พร้อมตำแหน่งที่เช็คสิทธิ์ วิธีใช้งาน helper ใหม่ และวิธีตรวจสอบการทำงานอย่างรวดเร็ว

## ไฟล์/โค้ดใหม่
- core/widgets/permission_guard.dart
  - PermissionGuard: วิดเจ็ตสำหรับซ่อน/แสดง UI ตามสิทธิ์
  - guardAction(context, permission, onAllowed): ฟังก์ชันสำหรับบล็อกแอคชันและแสดง snackbar ถ้าไม่มีสิทธิ์

## จุดที่เพิ่มการเช็คสิทธิ์

- ลูกค้า (Customers)
  - features/customers/view/customers_page.dart
    - เช็คสิทธิ์มองเห็นรายการ: `customer:view:all`
    - ปุ่ม “เพิ่มลูกค้า”: `customer:create`
  - features/customers/view/customer_detail_page.dart
    - ปุ่มแก้ไข: `customer:edit:all`
  - features/customers/controller/customers_controller.dart
    - addCustomer: `customer:create`
    - updateCustomer: `customer:edit:all`
    - deleteCustomer: `customer:delete`
  - features/customers/view/add_edit_customer_page.dart
    - ปุ่มบันทึก (Save): ใช้ `guardAction` เช็ค `customer:create` (เพิ่ม) หรือ `customer:edit:all` (แก้ไข)

- สินค้า (Products)
  - features/products/view/products_page.dart
    - เช็คสิทธิ์มองเห็นรายการ: `product:view`
    - ปุ่ม “เพิ่มสินค้า” (AppBar/หัวข้อ/หน้าเปล่า): `product:create`
  - features/products/view/product_detail_page.dart
    - ปุ่มแก้ไข: `product:edit:all`
    - ปุ่มลบ: `product:delete`
  - features/products/controller/products_controller.dart
    - addProduct: `product:create`
    - updateProduct: `product:edit:all`
    - deleteProduct: `product:delete`
  - features/products/view/add_edit_product_page.dart
    - ปุ่มบันทึก (Save): ใช้ `guardAction` เช็ค `product:create` (เพิ่ม) หรือ `product:edit:all` (แก้ไข)

- จ๊อบการ์ด (Jobcard)
  - features/jobcard/view/jobcard_page.dart
    - ปุ่มลอย “+” สร้างการ์ด: `jobcard:create`

- เมนูตั้งค่า (More / Settings)
  - features/more/view/more_page.dart
    - Operation บอร์ด: `settings:board:manage`
    - # Hashtag Center: `settings:catalog:manage`
    - ตั้งค่าบริษัท: `settings:company:manage`

- อ้างอิง Service/Model ที่มีอยู่เดิม
  - data/services/mobile_permissions_service.dart
    - ใช้ `isOwner` และ `can(permission)` สำหรับเช็คสิทธิ์ปัจจุบัน
  - models/user_permissions.dart
    - `isOwner => roleId == 'owner' || permissions.contains('*')`
    - `can(permission) => permissions.contains(permission)`

## วิธีใช้งาน PermissionGuard และ guardAction
- แสดง UI เฉพาะเมื่อมีสิทธิ์
  - `PermissionGuard(permission: 'customer:create', child: YourButton())`
  - หรือหลายสิทธิ์อย่างใดอย่างหนึ่ง: `PermissionGuard(anyOf: ['a', 'b'], child: ...)`
- ปกป้องแอคชัน (เช่น onPressed)
  - `guardAction(context, 'product:delete', () { /* ลบสินค้า */ })`

หมายเหตุ: สิทธิ์ของ Owner หรือผู้ที่มี `*` จะผ่านทุกการเช็คโดยอัตโนมัติ

## สิทธิ์ที่รองรับในรอบนี้
- ลูกค้า: `customer:view:all`, `customer:create`, `customer:edit:all`, `customer:delete`
- สินค้า: `product:view`, `product:create`, `product:edit:all`, `product:delete`
- จ๊อบการ์ด: `jobcard:create`, (มีการใช้งาน `jobcard:move` อยู่ที่หน้า board เดิม)
- ตั้งค่า: `settings:board:manage`, `settings:company:manage`, `settings:catalog:manage`

## วิธีตรวจสอบการทำงานอย่างรวดเร็ว
1) เข้าสู่ระบบในเวิร์กสเปซที่กำหนด และให้ MobilePermissionsService โหลดสิทธิ์ได้สำเร็จ
2) ทดสอบบทบาทตัวอย่าง:
   - Owner: ควรมองเห็นและใช้งานทุกอย่างได้
   - Admin (ตัวอย่าง permissions ตามที่ให้):
     - เห็นและเพิ่ม/แก้ไข/ลบ ลูกค้า/สินค้าได้
     - กด FAB สร้าง Jobcard ได้
     - เห็นเมนูตั้งค่าที่เกี่ยวข้อง (board/company/catalog)
3) ทดสอบผู้ใช้ทั่วไปที่ไม่มีสิทธิ์บางรายการ:
   - ปุ่ม/เมนูที่ไม่มีสิทธิ์ควรถูกซ่อนไว้ หรือกดแล้วมี snackbar แจ้งว่า “คุณไม่มีสิทธิ์ในการทำรายการนี้”

## งานถัดไป/ข้อเสนอแนะ
- เปลี่ยนการใช้ `withOpacity(...)` ที่ Deprecated เป็น `withValues(alpha: ...)` (refactor ภายหลัง)
- เมื่อมีหน้าจอ Company (view/create/edit/delete/import) เพิ่มการเช็คสิทธิ์ตามคีย์ที่ออกแบบไว้
- รวมข้อความ denied/snackbar ไว้ใน i18n ถ้าต้องการรองรับหลายภาษา

---
เอกสารนี้ครอบคลุมเฉพาะการเพิ่มการเช็คสิทธิ์ที่เกี่ยวข้องกับตัวอย่างที่ให้มา หากต้องการขยายไปยังฟีเจอร์อื่น แจ้งระบุหน้าจอ/แอคชันเพิ่มเติมได้
