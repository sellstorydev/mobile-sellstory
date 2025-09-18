# Board Card View — Toggle & Sort (Display‑only)  
**ไฟล์นี้ใช้สำหรับให้ AI Copilot/Dev แก้ “เฉพาะการแสดงผล” ของ Card View และ Card View Settings เท่านั้น (ห้ามสร้างไฟล์ใหม่ซ้ำ)**  
อัปเดตล่าสุด: 2025-09-05 04:07:05

> ✅ เป้าหมาย: ทำให้การ์ดที่อยู่บน **lane** (หน้า **board view**) สามารถ **เปิด/ปิด** ฟิลด์ที่ต้องการแสดง และ **ลากเรียงลำดับ** ได้ โดยใช้การตั้งค่าจากผู้ใช้ (`users/{{uid}}.viewSettings`) แบบ **ต่อบอร์ด**

---

## เส้นทางไฟล์ที่ต้องแก้ (มีอยู่แล้ว ห้ามสร้างไฟล์ใหม่)
- `lib/features/board/view/card_view_page.dart`
- `lib/features/board/view/card_view_setting_page.dart`
- `lib/features/board/widgets/job_card_tile.dart`

> ถ้าชื่อ/ที่อยู่ไฟล์ไม่ตรงกับโปรเจ็กต์ **ให้ค้นหา** ไฟล์ที่สร้างการ์ดบนบอร์ดและหน้าตั้งค่าการ์ด แล้วแก้ที่เดิม ห้ามสร้างไฟล์ที่ซ้ำกัน

---

## แผนภาพรวมการทำงาน
1. **อ่านค่า settings ต่อบอร์ด** จาก `users/{{uid}}/viewSettings.kanbanCardDisplayFieldsConfig_{{boardId}}`  
   - ถ้าไม่มี ให้ fallback ไปที่ค่า global (`users/{{uid}}/viewSettings`) หรือ default ในโค้ด
2. ใน `card_view_page.dart` โหลด settings แล้ว **ส่งต่อ**เข้า `JobCardTile` ทุกใบ
3. ใน `job_card_tile.dart` แปลง **fields → widgets** ตามลำดับ (`order`) และเงื่อนไขแสดง (`isVisible`)
4. ใน `card_view_setting_page.dart` ทำ UI **เปิด/ปิด + ลากเรียง** แล้ว **บันทึกกลับ**ไปที่ `users/{{uid}}/viewSettings.kanbanCardDisplayFieldsConfig_{{boardId}}`

---

## Mapping ฟิลด์จากเอกสาร (Card)
| UI Field | Firestore Field / Logic |
|---|---|
| **Job ID** | `customId` |
| **Status** | `status` |
| **Date Range** | `startDate` → date, `endDate` → date → แสดงเป็น `dd/MM/yyyy - dd/MM/yyyy` |
| **Created Date** | `createdAt` (epoch ms → date) |
| **Assignee** | `assignedTo` → map ไปที่ `users/{{uid}}.displayName` |
| **Customer Interest** | `customerInterest` |
| **Collaborators** | `collaborators[]` → map `users/{{uid}}.displayName` หลายคน |
| **Customer** | `customer` |
| **Company** | `company.value` |
| **Hashtags** | `hashtags[]` → ใช้ `text` + พื้นหลัง `color` |
| **Grand Total** | อิงสูตรในหัวข้อ “นิยามตัวเลขรวม” (ด้านล่าง) |
| **Net Total** | อิงสูตรในหัวข้อ “นิยามตัวเลขรวม” |
| **Total (before discount)** | อิงสูตรในหัวข้อ “นิยามตัวเลขรวม” |
| **Total (after discount)** | อิงสูตรในหัวข้อ “นิยามตัวเลขรวม” |
| **Total (before VAT)** | อิงสูตรในหัวข้อ “นิยามตัวเลขรวม” |
| **Description** | `description` (HTML → แสดงด้วย widget HTML เดิมของโปรเจกต์) |
| **To‑Do List** | `todos`: แสดงเป็น `incomplete/total` โดย **นับเฉพาะที่ `completed == false`** → เช่น `1/2` |

---

## นิยามตัวเลขรวม (ออกแบบให้ “ตรงตามภาพตัวอย่าง”)
> ภาพแนบของคุณแสดงผลลัพธ์ที่ถูกต้องสำหรับ 5 ฟิลด์ต่อไปนี้: **Grand Total, Net Total, Total (before discount), Total (after discount), Total (before VAT)**  
> เพื่อให้ตัวเลขตรงภาพ เรากำหนดกติกาดังนี้ (เลือกใช้เป็นค่าเริ่มต้น):
- **Total (before discount)** = ผลรวม `quantity * pricePerUnit` ของทุก `expenses` (ยัง **ไม่คิดส่วนลดรายรายการ**)
- **Additional Discount** (`additionalDiscount`) จะถูกใช้กับยอดรวมข้างบน
  - ถ้า `type == 'percentage'` → หักตามเปอร์เซ็นต์
  - ถ้า `type == 'amount'` → หักเป็นจำนวนเงินตรงๆ (ไม่ต่ำกว่า 0)
- **Total (after discount)** = ยอดรวมหลังหัก `additionalDiscount`
- **Total (before VAT)** = **Total (after discount)**
- **VAT (7%)** = ถ้า `isVatEnabled == true` → 7% ของ **Total (before VAT)** มิฉะนั้น 0
- **Grand Total** = **Total (before VAT) + VAT**
- **Net Total** = **Grand Total – (withholdingTaxPercentage% ของ Total (before VAT))**

> หมายเหตุ: ถ้าต้องการให้ “ส่วนลดรายรายการ” (field: `discount` + `discountType`) **มีผล**กับยอดรวมด้วย ให้ตั้งตัวแปร `usePerItemDiscountsInTotals = true` ในฟังก์ชันด้านล่าง (ค่าเริ่มต้น `false` เพื่อให้ตรงภาพแนบของคุณ)

---

## โค้ดที่ต้องเพิ่ม/แก้

### A) `job_card_tile.dart` — สร้างตัวช่วยคำนวณ + เรนเดอร์ตาม settings
> วางฟังก์ชันด้านล่างไว้ใต้ imports (หรือในไฟล์นี้) **ไม่สร้างไฟล์ใหม่**

```dart
// ===== Helpers for money/date =====
import 'package:intl/intl.dart';

final _thb = NumberFormat.currency(locale: 'th_TH', symbol: '฿');
String fmt(num v) => _thb.format((v * 100).round() / 100); // ปัด 2 ตำแหน่ง

String fmtDateRange(int? startMs, int? endMs) {
  if (startMs == null || endMs == null) return '-';
  final d1 = DateTime.fromMillisecondsSinceEpoch(startMs);
  final d2 = DateTime.fromMillisecondsSinceEpoch(endMs);
  final dd = DateFormat('dd/MM/yyyy');
  return '${dd.format(d1)} - ${dd.format(d2)}';
}

class MoneyTotals {
  final double totalBeforeDiscount;
  final double totalAfterDiscount;
  final double totalBeforeVat;
  final double vatAmount;
  final double grandTotal;
  final double netTotal;
  const MoneyTotals({required this.totalBeforeDiscount, required this.totalAfterDiscount, required this.totalBeforeVat, required this.vatAmount, required this.grandTotal, required this.netTotal});
}

double _round2(num v) => (v * 100).round() / 100.0;

MoneyTotals computeTotals({
  required List<Map<String, dynamic>> expenses,
  required bool isVatEnabled,
  required Map<String, dynamic>? additionalDiscount,
  required num withholdingTaxPercentage,
  bool usePerItemDiscountsInTotals = false, // false = ตรงภาพตัวอย่าง
}) {
  // 1) ยอดก่อนส่วนลด
  double totalBeforeDiscount = 0;
  double afterItemDiscount = 0;

  for (final e in expenses) {
    final q = (e['quantity'] ?? 0).toDouble();
    final p = (e['pricePerUnit'] ?? 0).toDouble();
    final base = q * p;
    totalBeforeDiscount += base;

    // คิดส่วนลดรายรายการ (เผื่อเปิดใช้งานในอนาคต)
    final disc = (e['discount'] ?? 0).toDouble();
    final type = (e['discountType'] ?? 'amount') as String;
    double line = base;
    if (disc > 0) {
      if (type == 'percentage') {
        line -= base * (disc / 100.0);
      } else {
        line -= disc;
      }
    }
    afterItemDiscount += line.clamp(0, double.infinity);
  }

  // 2) ส่วนลดเพิ่มเติม (ทั้งบิล)
  double baseForAdditional = usePerItemDiscountsInTotals ? afterItemDiscount : totalBeforeDiscount;
  double totalAfterDiscount = baseForAdditional;

  if (additionalDiscount != null && (additionalDiscount['value'] ?? 0) != 0) {
    final v = (additionalDiscount['value'] ?? 0).toDouble();
    final t = (additionalDiscount['type'] ?? 'amount') as String?;
    if (t == 'percentage') {
      totalAfterDiscount = baseForAdditional * (1 - (v / 100.0));
    } else {
      totalAfterDiscount = baseForAdditional - v;
    }
  }

  totalAfterDiscount = _round2(totalAfterDiscount.clamp(0, double.infinity));

  // 3) ก่อน VAT และ VAT
  final totalBeforeVat = totalAfterDiscount;
  final vatAmount = isVatEnabled ? _round2(totalBeforeVat * 0.07) : 0.0;

  // 4) Grand Total & Net
  final grandTotal = _round2(totalBeforeVat + vatAmount);
  final wht = _round2(totalBeforeVat * ((withholdingTaxPercentage ?? 0) / 100.0));
  final netTotal = _round2(grandTotal - wht);

  return MoneyTotals(
    totalBeforeDiscount: _round2(totalBeforeDiscount),
    totalAfterDiscount: totalAfterDiscount,
    totalBeforeVat: totalBeforeVat,
    vatAmount: vatAmount,
    grandTotal: grandTotal,
    netTotal: netTotal,
  );
}
```

> ใช้งานใน `build()` ของการ์ด: สร้าง `MoneyTotals` จาก `card.expenses`, `card.isVatEnabled`, `card.additionalDiscount`, `card.withholdingTaxPercentage` แล้วเลือกแสดงเฉพาะฟิลด์ที่ `isVisible == true` ตามลำดับ `order` จาก settings

ตัวอย่างการเรนเดอร์ฟิลด์ตาม settings:

```dart
// สมมติได้ settings ต่อบอร์ดเป็น Map<String, dynamic> fieldCfg
// ตัวอย่าง keys ที่รองรับ (ต้องตรงกัน): 
// customId, status, dateRange, createdAt, assignee, customerInterest, collaborators, customer, company,
// hashtags, grandTotal, netTotal, totalAmountBeforeDiscount, totalAmountAfterDiscount, totalAmountBeforeVat,
// description, todos

List<_FieldEntry> buildFieldEntries(CardModel card, MoneyTotals totals, Map<String, dynamic> fieldCfg, Map<String, String> userNameCache) {
  String? nameOf(String uid) => userNameCache[uid];

  final entries = <_FieldEntry>[
    _FieldEntry('customId', card.customId ?? '-'),
    _FieldEntry('status', card.status ?? '-'),
    _FieldEntry('dateRange', fmtDateRange(card.startDate, card.endDate)),
    _FieldEntry('createdAt', DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(card.createdAt ?? 0))),
    _FieldEntry('assignee', nameOf(card.assignedTo ?? '') ?? '-'),
    _FieldEntry('customerInterest', card.customerInterest ?? '-'),
    _FieldEntry('collaborators', (card.collaborators ?? []).map((e) => nameOf(e) ?? e).join(', ')),
    _FieldEntry('customer', card.customer ?? '-'),
    _FieldEntry('company', card.company?.value ?? '-'),
    _FieldEntry('hashtags', ''), // วาดเป็น chips แยก
    _FieldEntry('grandTotal', fmt(totals.grandTotal)),
    _FieldEntry('netTotal', fmt(totals.netTotal)),
    _FieldEntry('totalAmountBeforeDiscount', fmt(totals.totalBeforeDiscount)),
    _FieldEntry('totalAmountAfterDiscount', fmt(totals.totalAfterDiscount)),
    _FieldEntry('totalAmountBeforeVat', fmt(totals.totalBeforeVat)),
    _FieldEntry('description', ''), // เรนเดอร์ HTML แยก
    _FieldEntry('todos', '${(card.todos ?? []).where((t) => !(t.completed ?? false)).length}/${(card.todos ?? []).length}'),
  ];

  // กรองตาม isVisible และเรียงตาม order
  entries.retainWhere((e) => (fieldCfg[e.key]?['isVisible'] ?? true) == true);
  entries.sort((a, b) => (fieldCfg[a.key]?['order'] ?? 999).compareTo(fieldCfg[b.key]?['order'] ?? 999));

  return entries;
}

class _FieldEntry {
  final String key;
  final String value;
  _FieldEntry(this.key, this.value);
}
```

สำหรับ **Hashtags** ให้ใช้ `Wrap` + `Container` ตามสี:

```dart
Widget buildHashtags(List<dynamic>? tags) {
  final list = (tags ?? []);
  if (list.isEmpty) return const SizedBox.shrink();
  return Wrap(
    spacing: 6, runSpacing: 6,
    children: list.map<Widget>((t) {
      final text = t['text'] ?? '';
      final color = t['color'] ?? '#eeeeee';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _hexToColor(color).withOpacity(0.18),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _hexToColor(color)),
        ),
        child: Text('$text'),
      );
    }).toList(),
  );
}

Color _hexToColor(String hex) {
  final buffer = StringBuffer();
  if (hex.length == 6 || hex.length == 7) buffer.write('ff');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}
```

> **Description (HTML)**: ใช้ widget HTML เดิมของโปรเจกต์ (เช่น `flutter_widget_from_html` หรือ `flutter_html`) **ห้ามเพิ่มแพคเกจใหม่ถ้าโปรเจกต์มีอยู่แล้ว**

---

### B) `card_view_page.dart` — โหลด settings แล้วส่งเข้า `JobCardTile`
- อ่าน `users/{{uid}}` → `viewSettings.kanbanCardDisplayFieldsConfig_{{boardId}}`  
- ถ้าไม่มี ให้สร้าง **in‑memory default** (อย่าบันทึกอัตโนมัติ) เพื่อกันค่าว่าง
- สร้าง cache `uid → displayName` สำหรับ **assignedTo/collaborators**

ตัวอย่างโค้ด (ย่อหน้าเดียวสำหรับแนวทาง):

```dart
final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUid).get();
final cfg = (userDoc.data()?['viewSettings'] ?? {})['kanbanCardDisplayFieldsConfig_${boardId}'] ?? {};

// โหลดชื่อผู้ใช้ล่วงหน้า (แคช)
Future<Map<String, String>> loadUserNames(Set<String> uids) async {
  if (uids.isEmpty) return {};
  final snaps = await FirebaseFirestore.instance.collection('users').where(FieldPath.documentId, whereIn: uids.toList()).get();
  return {for (final d in snaps.docs) d.id: (d.data()['displayName'] ?? '')};
}
```

---

### C) `card_view_setting_page.dart` — เปิด/ปิด + ลากเรียง แล้วบันทึก
ทำรายการฟิลด์ตาม keys ต่อไปนี้ (ต้องตรงกับฝั่งแสดงผล):

```
customId, status, dateRange, createdAt, assignee, customerInterest, collaborators, customer, company,
hashtags, grandTotal, netTotal, totalAmountBeforeDiscount, totalAmountAfterDiscount, totalAmountBeforeVat,
description, todos
```

ตัวอย่าง UI (ย่อหน้าแนวทาง):

```dart
class CardViewSettingPage extends StatefulWidget {
  final String boardId;
  const CardViewSettingPage({super.key, required this.boardId});
  @override State<CardViewSettingPage> createState() => _CVSState();
}

class _CVSState extends State<CardViewSettingPage> {
  late List<String> order;
  late Map<String, bool> visible;

  @override void initState() {
    super.initState();
    // TODO: โหลดจาก users/{{uid}}/viewSettings.kanbanCardDisplayFieldsConfig_${widget.boardId}
    // แล้ว setState ให้ order & visible สอดคล้องกัน
  }

  void save() async {
    final cfg = <String, dynamic>{};
    for (var i = 0; i < order.length; i++) {
      cfg[order[i]] = {'order': i, 'isVisible': visible[order[i]] ?? true, 'style': {}};
    }
    await FirebaseFirestore.instance.collection('users').doc(currentUid).update({
      'viewSettings.kanbanCardDisplayFieldsConfig_${widget.boardId}': cfg,
    });
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Card View Settings'), actions: [
        TextButton(onPressed: save, child: const Text('Save'))
      ]),
      body: ReorderableListView(
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex--;
            final item = order.removeAt(oldIndex);
            order.insert(newIndex, item);
          });
        },
        children: [
          for (final key in order)
            SwitchListTile(
              key: ValueKey(key),
              title: Text(key),
              value: visible[key] ?? true,
              onChanged: (v) => setState(() => visible[key] = v),
              secondary: const Icon(Icons.drag_handle),
            ),
        ],
      ),
    );
  }
}
```

> การตั้งค่าที่บันทึกจะอยู่ใน `users/{{uid}}/viewSettings.kanbanCardDisplayFieldsConfig_{{boardId}}` เท่านั้น ไม่แตะส่วนอื่น

---

## ค่าทดสอบจากข้อมูลตัวอย่างของคุณ (คาดหวังให้ “ตรงภาพ”)
- Subtotal / **Total (before discount)** = **11,274,578.00**
- Additional Discount = **97%**
- **Total (after discount)** = **338,237.34**
- **Total (before VAT)** = **338,237.34**
- VAT 7% = **23,676.61**
- **Grand Total** = **361,913.95**
- หัก ณ ที่จ่าย 3% คิดจาก **ก่อน VAT** = **10,147.12**
- **Net Total** = **351,766.83**

---

## ข้อควรระวัง
- ห้ามสร้างไฟล์ใหม่ซ้ำ ให้ **ค้นหาและแก้ไฟล์เดิม** ตาม path ที่กำหนด
- ไม่แก้ไขโครงสร้างฐานข้อมูล มีเพียงอ่าน/เขียนเฉพาะ `viewSettings.kanbanCardDisplayFieldsConfig_{{boardId}}`
- ถ้าโปรเจกต์ยังไม่มี `intl` ให้เพิ่มใน `pubspec.yaml` (ถ้ามีอยู่แล้วให้ใช้ตัวเดิม)  
  ```yaml
  dependencies:
    intl: ^0.19.0
  ```
- ถ้าต้องการให้ส่วนลดรายรายการร่วมคำนวณยอดรวม ให้ตั้ง `usePerItemDiscountsInTotals = true` ใน `computeTotals()`

---

## Definition ของ Keys (ต้องตรงกันทั้งสองหน้า)
```
customId, status, dateRange, createdAt, assignee, customerInterest, collaborators,
customer, company, hashtags, grandTotal, netTotal,
totalAmountBeforeDiscount, totalAmountAfterDiscount, totalAmountBeforeVat,
description, todos
```

---

## Done
เมื่อทำครบ การ์ดบน lane จะเปิด/ปิดฟิลด์ได้และลากเรียงได้ โดยตัวเลข 5 ฟิลด์สำคัญจะตรงกับภาพแนบครับ
