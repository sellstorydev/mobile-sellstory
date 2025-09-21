# แนวทางสมัครสมาชิกด้วย Social Login (Web + Mobile + API)

เอกสารนี้อธิบาย Flow การสมัคร/เข้าสู่ระบบด้วย Social (เช่น Google/Apple) ให้ได้ผลลัพธ์เหมือนการสมัครครั้งแรกด้วยอีเมล-รหัสผ่าน คือมีการสร้างข้อมูลพื้นฐานผู้ใช้และ Workspace ให้พร้อมใช้งาน โดยออกแบบให้สามารถใช้ซ้ำได้กับ Mobile และ/หรือทำเป็น API กลางได้

---

## เป้าหมาย
- ผู้ใช้ที่เข้าสู่ระบบครั้งแรกผ่าน Social จะได้ข้อมูลพื้นฐาน (Firestore user profile) และ Workspace เริ่มต้นเหมือนกับ Sign up ปกติ
- รองรับการ “ลิงก์บัญชี” กรณีอีเมลเดียวกันมีการสมัครไว้กับวิธีอื่นอยู่แล้ว
- สามารถแยกเป็น API ตอนหลัง เพื่อให้ Mobile ใช้งานได้เหมือน Web

---

## คำจำกัดความและ Collection ที่เกี่ยวข้อง
- Firestore
  - `users/{uid}`: โปรไฟล์ของผู้ใช้แอป (AppUser) ที่ซิงก์กับ Firebase Auth user
    - ฟิลด์หลักที่ใช้ในระบบปัจจุบัน
      - `uid: string`
      - `email: string | null`
      - `displayName: string | null`
      - `photoURL?: string | null`
      - `language: 'en' | 'th'` (ค่าเริ่มต้น 'en')
      - `workspaces?: Array<{ id: string; name: string; role: 'owner' | 'admin' | 'member' }>`
      - `lastActiveWorkspaceId?: string`
  - `workspaces/{workspaceId}`: เอกสารของ Workspace พร้อมข้อมูลแพ็กเกจและ companyProfile
    - สร้างจาก helper `createWorkspace(name, owner)` ซึ่งภายในจะ
      - เซ็ตสมาชิกเริ่มต้น (owner)
      - ปั๊ม board/lane ตั้งต้น
      - โคลนเอกสาร template เริ่มต้น (quotation/invoice/receipt) เข้าสู่ workspace ใหม่
      - ประทับค่า subscription/package/quota พื้นฐาน
  - Subcollections ภายใต้ workspace เช่น `boards`, `lanes`, `quotationTemplates` ฯลฯ จะถูกสร้างอัตโนมัติจาก `createWorkspace`

- Firebase Auth
  - จัดเก็บตัวตนผู้ใช้และวิธีเข้าสู่ระบบ (email+password, google.com, apple.com เป็นต้น)

---

## ภาพรวม Flow (Web)
1. ผู้ใช้กด Sign in with Google (หรือ Social อื่น)
2. เรียก `signInWithPopup` (หรือบน Mobile ใช้ SDK ตามแพลตฟอร์ม)
3. สำเร็จแล้ว เรียก `ensureBaseData()` เพื่อตรวจสอบ/สร้างข้อมูลพื้นฐาน
   - ถ้ายังไม่มี `users/{uid}` -> `createUserProfile({ uid, email, displayName, photoURL })`
   - ถ้ายังไม่มี workspace ใน `users/{uid}.workspaces` -> `createWorkspace('My Workspace', owner)` แล้วอัปเดต `lastActiveWorkspaceId`
4. นำผู้ใช้เข้าหน้า Dashboard

หมายเหตุ: ในโค้ดเว็บปัจจุบันได้เพิ่ม `ensureBaseData()` แล้วใน `src/app/login/page.tsx` หลัง `signInWithPopup` และหลังการลิงก์บัญชีสำเร็จ

---

## กรณี “บัญชีมีอยู่ด้วยวิธีอื่น” (Account Linking)
- ถ้า Auth ส่ง error: `auth/account-exists-with-different-credential`
  - ดึง `fetchSignInMethodsForEmail(email)` เพื่อให้ผู้ใช้เลือกวิธีเดิม
  - ลิงก์ด้วยรหัสผ่าน (ถ้าบัญชีเดิมเป็น email+password) หรือ popup provider อื่น
  - หลังลิงก์สำเร็จ เรียก `ensureBaseData()` เช่นเดียวกัน

---

## สัญญา (Contract) ของ Helper สำคัญ
- `createUserProfile(user: { uid, email, displayName, photoURL }) => Promise<void>`
  - งาน: สร้าง `users/{uid}` หากยังไม่มี โดยตั้งค่า `language='en'` และ `workspaces=[]` เป็นค่าเริ่มต้น
- `createWorkspace(name: string, owner: { uid, email, displayName, photoURL }) => Promise<Workspace>`
  - งาน: สร้างเอกสาร `workspaces/{id}` พร้อม stamping package/quota, companyProfile, default board/lanes, โคลน default templates
  - อัปเดต `users/{uid}.workspaces += { id, name, role: 'owner' }`
- `updateUser(uid, { lastActiveWorkspaceId })`
  - งาน: เซ็ต workspace ปัจจุบัน (ช่วยให้ UI เลือก workspace ถูกต้องตั้งแต่โหลดครั้งแรก)

Edge cases ที่ต้องคำนึง
- popup ถูกบล็อก -> ใช้ redirect แทน
- ผู้ใช้ยกเลิกกลางคัน -> ไม่ควรสร้างข้อมูลใดๆ จนกว่าจะได้ user จาก Auth
- ลิงก์บัญชีไม่สำเร็จ -> แจ้งผู้ใช้และคงสถานะเดิม
- เรียก `ensureBaseData` ซ้ำ: ปลอดภัย (ตรวจสอบก่อนสร้าง)

---

## ออกแบบ API สำหรับ Mobile
เพื่อให้ Mobile ใช้ Flow เดียวกับ Web เสนอให้ทำ API ขั้นตอนหลังจาก mobile sign-in เสร็จแล้ว (mobile จะถือ Firebase ID Token มาแลก)

### Endpoint: POST `/api/auth/bootstrap`
- Auth: ต้องแนบ Bearer ID Token (Firebase)
- Request: ไม่มี body (หรือ body ว่าง) แค่ยืนยันตัวตน
- Response: โปรไฟล์ผู้ใช้ + สรุป workspace ปัจจุบัน

ตัวอย่าง Response
```json
{
  "user": {
    "uid": "...",
    "email": "user@example.com",
    "displayName": "John Doe",
    "photoURL": "https://...",
    "language": "en",
    "workspaces": [
      { "id": "ws_123", "name": "My Workspace", "role": "owner" }
    ],
    "lastActiveWorkspaceId": "ws_123"
  },
  "activeWorkspace": {
    "id": "ws_123",
    "name": "My Workspace"
  }
}
```

ตรรกะฝั่งเซิร์ฟเวอร์ (Pseudo-code)
```ts
import { withAdmin } from '@/lib/firebase/admin/withAdmin';
import { getFirestore } from 'firebase-admin/firestore';

export const POST = withAdmin(async (req) => {
  const uid = req.user.uid; // มาจากการ verify ID Token แล้ว
  const db = getFirestore();

  const userRef = db.doc(`users/${uid}`);
  const snap = await userRef.get();

  if (!snap.exists) {
    await userRef.set({
      uid,
      email: req.user.email || null,
      displayName: req.user.name || null,
      photoURL: req.user.picture || null,
      language: 'en',
      workspaces: [],
    }, { merge: true });
  }

  const userDoc = (await userRef.get()).data()!;
  const workspaces = userDoc.workspaces || [];

  if (!workspaces.length) {
    // สร้าง workspace ใหม่ (ส่วนนี้ทำฝั่ง admin SDK ให้ครบเหมือน createWorkspace ฝั่ง client)
    const wsRef = db.collection('workspaces').doc();
    const now = Date.now();

    // TODO: เติม stamping subscription/package/quota ให้เหมือน client
    await wsRef.set({
      name: 'My Workspace',
      ownerId: uid,
      members: { [uid]: 'owner' },
      createdAt: now,
      // ...companyProfile, subscription, quota, templates clone ฯลฯ
    });

    await userRef.set({
      workspaces: [...workspaces, { id: wsRef.id, name: 'My Workspace', role: 'owner' }],
      lastActiveWorkspaceId: wsRef.id,
    }, { merge: true });

    // เพิ่ม board/lanes เริ่มต้น และโคลน templates ตามที่ใช้อยู่ใน client
    // หมายเหตุ: สามารถย้าย logic จาก createWorkspace ฝั่ง client มาเป็นฟังก์ชัน server reuse ได้
  }

  const finalUser = (await userRef.get()).data()!;
  const activeId = finalUser.lastActiveWorkspaceId || finalUser.workspaces?.[0]?.id || null;

  return Response.json({
    user: finalUser,
    activeWorkspace: activeId ? { id: activeId, name: finalUser.workspaces.find((w: any) => w.id === activeId)?.name } : null,
  });
});
```

หมายเหตุสำคัญ
- ถ้าอยากใช้ logic เดียวกับ `createWorkspace` ฝั่ง client ให้ย้าย/แยกส่วนที่ไม่ขึ้นกับ Browser ไปไว้ในโมดูลที่ใช้ได้ทั้ง client/server แล้วเรียกจาก API เพื่อไม่ให้เกิด divergence

---

## ลำดับเหตุการณ์ (Mobile)
1. Mobile ใช้ SDK ของ Firebase ทำ Social sign-in, ได้ ID Token (และ refresh token)
2. ส่ง ID Token ไปที่ API `/api/auth/bootstrap`
3. API ตรวจสอบ/สร้าง `users/{uid}` และ workspace เหมือน Web แล้วส่งข้อมูลกลับ
4. แอปเก็บ activeWorkspaceId ไว้ใน storage และดึงข้อมูลต่อ เช่น dashboard, customers ฯลฯ

---

## Security & Best Practices
- ตรวจสอบ ID Token ทุกครั้งฝั่ง API ด้วย Firebase Admin
- จำกัดสิทธิ์ Cloud Firestore Security Rules ให้สอดคล้องกับโครงสร้าง (เช่น ผู้ใช้ต้องเป็นสมาชิก workspace ถึงจะอ่าน/เขียนได้)
- ออกแบบให้ `ensureBaseData`/`bootstrap` เป็น idempotent เรียกซ้ำได้โดยไม่สร้างข้อมูลซ้ำซ้อน
- Log กรณีสร้าง workspace/โคลน template เพื่อ debug ได้

---

## การขยายในอนาคต
- รองรับการตั้งค่าเริ่มต้นอื่นๆ ต่อ เช่น ภาษา (`language`) เป็น 'th' ตาม Geo/IP หรือระบบ UI
- ลิงก์ผู้ให้บริการอื่นเพิ่ม (Apple/Facebook) ใช้ flow เดียวกันทั้งหมด
- แยกแพ็กเกจ stamping logic ออกมาเป็นโมดูลกลาง ใช้ได้ทั้ง client และ server

---

## อ้างอิงไฟล์ในโปรเจกต์
- `src/app/login/page.tsx` – เรียก `ensureBaseData()` หลัง Google sign-in และหลัง linking
- `src/lib/firebase.ts`
  - `createUserProfile(user)` – สร้างโปรไฟล์ผู้ใช้ใน `users/{uid}`
  - `createWorkspace(name, owner)` – สร้าง workspace พร้อม board/lanes/templates และอัปเดต `users/{uid}.workspaces`
  - `inviteUserToWorkspace(...)` – เส้นทางเชิญผู้ใช้เข้าร่วม workspace ที่มีอยู่

เอกสารนี้สามารถใช้เป็นสเปคเพื่อทำ Mobile ต่อหรือสร้าง API `/api/auth/bootstrap` ให้ทุกแพลตฟอร์มใช้ flow เดียวกันได้