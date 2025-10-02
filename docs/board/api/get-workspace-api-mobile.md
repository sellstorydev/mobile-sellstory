# Mobile Workspace API – `GET /api/mobile/workspaces`

> TL;DR: ดึงรายการ workspace ที่ผู้ใช้มีสิทธิ์ พร้อมข้อมูล board summary, สถานะ subscription และ workspace ที่ผู้ใช้เลือกใช้งานล่าสุด ภายใน call เดียวสำหรับแอปมือถือ

## 🧭 Overview

- **Method**: `GET`
- **Path**: `/api/mobile/workspaces`
- **Auth**: ต้องส่ง Firebase ID Token ผ่าน `Authorization: Bearer <token>`
- **Rate limit**: ไม่มี rate limit พิเศษ (ใช้มาตรฐานของ Firebase/Cloud Run)
- **Caching**: ไม่ได้ตั้ง Header cache-control ให้ client ต้องจัดการ caching เอง

## 🎯 Use Cases

- โหลด dashboard หลักหลังผู้ใช้ล็อกอินบน mobile
- เลือก workspace ที่ต้องการใช้งานและจำค่า `activeWorkspaceId`
- ดึงข้อมูล boards แบบสรุป (จำนวน lane/card, `lastModified`) เพื่อ render รายการเร็ว ๆ ก่อนโหลดรายละเอียดเชิงลึกจาก endpoint อื่น

## 📡 Request

### URL

```
GET /api/mobile/workspaces
```

### Required Headers

| Header | ค่า | บังคับ | หมายเหตุ |
| --- | --- | --- | --- |
| `Authorization` | `Bearer <Firebase ID Token>` | ✅ | ต้องเป็น token สดที่ออกจาก Firebase Auth |
| `Content-Type` | `application/json` | ⛔ | ไม่บังคับ แต่แนะนำเพื่อให้ log อ่านง่าย |

### Query Parameters

- ไม่มี query parameter เพิ่มเติม ณ ตอนนี้

### ตัวอย่างเรียกใช้งาน

```bash
curl -X GET "https://<host>/api/mobile/workspaces" \
	-H "Authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6..."
```

```dart
final response = await http.get(
	Uri.parse('$baseUrl/api/mobile/workspaces'),
	headers: await AuthService.getAuthHeaders(),
);
```

## 📦 Response

### Status Codes

| Status | เงื่อนไข |
| --- | --- |
| `200 OK` | สำเร็จ มีข้อมูล (หรือไม่มี workspace ก็ได้) |
| `401 Unauthorized` | ไม่ส่ง Bearer token หรือ token หมดอายุ/ไม่ถูกต้อง |
| `404 Not Found` | ไม่พบ user document ใน Firestore |
| `500 Internal Server Error` | เกิดข้อผิดพลาดอื่น ๆ (เช่น Firestore ล่ม) |

### Payload Structure

```typescript
interface MobileWorkspacesApiResponse {
	success: boolean;
	data?: {
		workspaces: MobileWorkspaceResponse[];
		activeWorkspaceId?: string; // workspace ล่าสุดที่ user ใช้ (อาจเป็น undefined)
	};
	error?: string; // กรณี success = false
}

interface MobileWorkspaceResponse {
	id: string;
	name: string;
	role: string; // owner | admin | member | viewer ฯลฯ ตามข้อมูลใน users/{uid}.workspaces
	boardCount: number;
	memberCount: number;
	status: "active" | "suspended" | "trial" | "expired" | "view-only";
	packageId: string;
	subscription: {
		status: string;
		currentPeriodEnd: number; // Unix millis
		billingCycle: string; // monthly | yearly | custom
	};
	boards: MobileBoardInfo[];
}

interface MobileBoardInfo {
	id: string;
	name: string;
	description?: string;
	cardCount: number;   // นับเฉพาะการ์ดที่ไม่สถานะ Archived
	laneCount: number;   // จำนวน lane ที่อยู่ใน board นี้
	lastModified: number; // Unix millis (fallback เป็น createdAt หรือ Date.now())
}
```

### รายละเอียดฟิลด์สำคัญ

#### `data.activeWorkspaceId`

- มาจาก `users/{uid}.lastActiveWorkspaceId`
- ใช้เพื่อตั้ง workspace เริ่มต้นเมื่อแอปเปิดครั้งถัดไป
- ถากถางว่า user ยังไม่เคยเลือก workspace จะไม่มีค่าในฟิลด์นี้

#### `workspace.subscription`

- ดึงจาก `workspaces/{id}.subscription`
- `currentPeriodEnd` = millisecond timestamp (UTC)
- ถ้า workspace ยังไม่เคย subscribe ฟิลด์จะ fallback เป็น `status: "active"`, `currentPeriodEnd: 0`, `billingCycle: "monthly"`

#### `boards`

- ระบบดึงเฉพาะ board ที่ user มีสิทธิ์ (`memberUids` มี uid)
- `laneCount` คำนวณจาก collection `workspaces/{id}/lanes`
- `cardCount` รวมการ์ดทุกใบใน lanes ที่สถานะไม่ใช่ `Archived`

### Success Example

```json
{
	"success": true,
	"data": {
		"workspaces": [
			{
				"id": "TQwci4FtpadAGTQJLFd7",
				"name": "Production Workspace",
				"role": "owner",
				"boardCount": 5,
				"memberCount": 8,
				"status": "active",
				"packageId": "premium",
				"subscription": {
					"status": "active",
					"currentPeriodEnd": 1730419200000,
					"billingCycle": "monthly"
				},
				"boards": [
					{
						"id": "8xdVfWrvjlIE4W0hTsNb",
						"name": "Mobile App Development",
						"description": "Flutter mobile app project",
						"cardCount": 23,
						"laneCount": 4,
						"lastModified": 1729929228120
					}
				]
			}
		],
		"activeWorkspaceId": "TQwci4FtpadAGTQJLFd7"
	}
}
```

### Error Examples

```json
{
	"success": false,
	"error": "Missing Bearer token"
}
```

```json
{
	"success": false,
	"error": "User not found"
}
```

เมื่อเกิด error ฝั่ง server (เช่น Firestore timeout) จะได้ `500` พร้อม message จากระบบ: `{ "success": false, "error": "Internal error" }`

## 🛠️ Server Behavior & Notes

- ดึงข้อมูลจาก Firestore ผ่าน service account (admin SDK)
- ลำดับของ workspace ตรงกับ array `users/{uid}.workspaces` (ใช้เป็น implicit ordering ได้)
- ใช้ `console.log` debug บางจุด เมื่อรันใน production ควรตรวจสอบ Logging quota
- หาก board ไม่มี lane ใด ระบบ fallback ไปนับการ์ดด้วย `boardId`
- ไม่ดึง `archived` cards ทำให้ตัวเลขบน mobile สอดคล้องกับ board UI หลัก
- กรณี workspace document หาย จะถูกข้าม (`null` filter)

## 📱 Mobile Integration Checklist

1. **หลัง Sign-In สำเร็จ**: ยิง endpoint นี้ทันทีเพื่อ preload ข้อมูล workspace ทั้งหมด
2. **เก็บ `activeWorkspaceId`**: ถ้ามีให้ตั้งค่า default selection และอัพเดทกลับเมื่อผู้ใช้เปลี่ยน
3. **แคชบนเครื่อง**: แนะนำเก็บ response ไว้ใน local storage/SQLite พร้อม timestamp เพื่อใช้ offline mode และลด cold start
4. **Refresh Strategy**: 
	 - Pull-to-refresh ให้เรียก endpoint นี้อีกรอบ
	 - เมื่อ switch workspace หรือเข้า board หนึ่ง สามารถใช้ข้อมูล board summary ที่มาพร้อม response ก่อนเรียก endpoint รายละเอียดอื่น
5. **Error Handling**: 
	 - `401` → trigger re-auth และ refresh Firebase token
	 - `404` → แสดงข้อความ “ไม่พบข้อมูลผู้ใช้” และแนะนำติดต่อ support
	 - `500` → ให้ผู้ใช้ retry พร้อม log error detail เพื่อส่งทีม backend

## 🔄 Related Endpoints

- `GET /api/mobile/workspaces/{workspaceId}/boards` – รายละเอียดเชิงลึกของ boards (lanes, members, card per lane)
- `GET /api/mobile/cards/{cardId}` (ถ้ามี) – ดึงรายละเอียดการ์ดแต่ละใบเพิ่มเติม

---

อัปเดตล่าสุด: 2025-10-02
