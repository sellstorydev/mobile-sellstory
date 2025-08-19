# 📱 iOS Build & Archive Guide

คู่มือการใช้งาน Script สำหรับการเปลี่ยน Version และ Archive แอป iOS

## 🛠️ Scripts ที่มีให้ใช้งาน

### 1. `check_version.sh` - ตรวจสอบเวอร์ชันปัจจุบัน
### 2. `sync_version.sh` - เปลี่ยนเวอร์ชันและ sync ทุกไฟล์
### 3. `build_ios.sh` - Build และ Archive อัตโนมัติ
### 4. `quick_release.sh` - ทำทุกขั้นตอนในคำสั่งเดียว

---

## 📋 ขั้นตอนการใช้งาน

### **Step 1: ตรวจสอบเวอร์ชันปัจจุบัน**
```bash
./scripts/check_version.sh
```

**ผลลัพธ์ที่ได้:**
```
🔍 Checking current iOS version...

📱 Project.pbxproj versions:
                                MARKETING_VERSION = 1.11.0;

🔢 Project.pbxproj build numbers:
                                CURRENT_PROJECT_VERSION = 9;

📋 Info.plist version:
        <key>CFBundleShortVersionString</key>
        <string>1.11.0</string>

📋 Info.plist build:
        <key>CFBundleVersion</key>
        <string>9</string>
```

---

### **Step 2: เปลี่ยนเวอร์ชัน**
```bash
./scripts/sync_version.sh <version> <build_number>
```

**ตัวอย่าง:**
```bash
# เปลี่ยนเป็นเวอร์ชัน 1.12.0 build 10
./scripts/sync_version.sh 1.12.0 10

# เปลี่ยนเป็นเวอร์ชัน 2.0.0 build 1
./scripts/sync_version.sh 2.0.0 1
```

**สิ่งที่ Script จะทำ:**
- ✅ อัปเดต `project.pbxproj` ทุกจุด
- ✅ อัปเดต `Info.plist`
- ✅ อัปเดต `pubspec.yaml`
- ✅ ล้าง Xcode cache
- ✅ ล้าง build folder

---

### **Step 3: Build และ Archive**
```bash
./scripts/build_ios.sh
```

**หรือทำแบบแยกขั้นตอน:**
```bash
# Clean project
flutter clean

# Get dependencies
flutter pub get

# Build iOS
flutter build ios --release

# Archive ใน Xcode (ต้องทำใน Xcode)
```

---

## 🔄 Workflow แบบเต็ม

### **สำหรับ Release ใหม่:**
```bash
# 1. ตรวจสอบเวอร์ชันปัจจุบัน
./scripts/check_version.sh

# 2. เปลี่ยนเวอร์ชัน
./scripts/sync_version.sh 1.12.0 10

# 3. Build และ Archive
./scripts/build_ios.sh

# 4. Archive ใน Xcode
# เปิด Xcode → Product → Archive
```

### **สำหรับ Bug Fix:**
```bash
# เพิ่มเฉพาะ patch number
./scripts/sync_version.sh 1.11.1 11
./scripts/build_ios.sh
```

### **สำหรับ Feature ใหม่:**
```bash
# เพิ่ม minor version
./scripts/sync_version.sh 1.12.0 12
./scripts/build_ios.sh
```

---

## 📖 Version Numbering Convention

### **Format: `MAJOR.MINOR.PATCH`**
- **MAJOR**: การเปลี่ยนแปลงใหญ่ที่ไม่ compatible กับเวอร์ชันเก่า
- **MINOR**: Feature ใหม่ที่ compatible กับเวอร์ชันเก่า
- **PATCH**: Bug fixes และการปรับปรุงเล็กน้อย

### **Build Number**
- เพิ่มทีละ 1 สำหรับทุก build
- ไม่ควรลดเลขลง (เพื่อ App Store)
- สามารถ reset เป็น 1 เมื่อเปลี่ยน major version

### **ตัวอย่าง:**
| Version | Build | Description |
|---------|-------|-------------|
| 1.11.0 | 9 | เวอร์ชันปัจจุบัน |
| 1.11.1 | 10 | Bug fix |
| 1.12.0 | 11 | Feature ใหม่ |
| 2.0.0 | 1 | Major update |

---

## 🚨 สิ่งที่ต้องระวัง

### **ก่อนเปลี่ยนเวอร์ชัน:**
1. ✅ Commit งานปัจจุบันใน Git
2. ✅ Test แอปให้ทำงานปกติ
3. ✅ ปิด Xcode ทั้งหมด

### **หลังเปลี่ยนเวอร์ชัน:**
1. ✅ เปิด Xcode ใหม่
2. ✅ ตรวจสอบเวอร์ชันใน Xcode UI
3. ✅ Clean Build Folder
4. ✅ Test build ก่อน Archive

### **สำหรับ App Store:**
1. ✅ Build number ต้องเพิ่มขึ้นเสมอ
2. ✅ Version ต้องตรงกับที่ตั้งใน App Store Connect
3. ✅ pubspec.yaml version ต้องตรงกับ iOS version
4. ✅ Test ใน TestFlight ก่อนส่ง Review

---

## 🔧 Troubleshooting

### **ปัญหา: Xcode ไม่เห็นเวอร์ชันใหม่**
```bash
# แก้ไข: ปิด Xcode และล้าง cache
./scripts/sync_version.sh 1.12.0 10
# ปิด Xcode
# เปิด Xcode ใหม่
```

### **ปัญหา: Archive ไม่ได้**
```bash
# แก้ไข: Clean ทั้งหมด
flutter clean
rm -rf ios/build/
# เปิด Xcode → Product → Clean Build Folder
# ลอง Archive ใหม่
```

### **ปัญหา: Build Number ซ้ำ**
```bash
# แก้ไข: เพิ่ม build number
./scripts/sync_version.sh 1.12.0 11  # เพิ่มจาก 10 เป็น 11
```

### **ปัญหา: Script ไม่ทำงาน**
```bash
# แก้ไข: ตรวจสอบ permission
chmod +x scripts/*.sh
./scripts/check_version.sh
```

### **ปัญหา: "Action Required: You must set a build name and number in the pubspec.yaml file"**
```bash
# แก้ไข: ใช้ script sync version
./scripts/sync_version.sh 1.11.0 9
# หรือแก้ไข pubspec.yaml เอง
# version: 1.11.0+9
```

---

## 📞 ติดต่อ & Support

หากมีปัญหาหรือข้อสงสัย:
1. ตรวจสอบ error message จาก script
2. รัน `./scripts/check_version.sh` เพื่อดูสถานะปัจจุบัน
3. ตรวจสอบว่า Xcode เปิดหรือปิดอยู่
4. ลอง clean project และ build ใหม่

---

## 📚 เอกสารอ้างอิง

- [Apple Developer - App Store Connect](https://developer.apple.com/app-store-connect/)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [Xcode Build Settings](https://developer.apple.com/documentation/xcode/build-settings-reference)

---

**อัปเดตล่าสุด:** วันที่สร้างไฟล์นี้  
**เวอร์ชัน:** 1.0.0
