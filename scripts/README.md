# 📱 iOS Build Scripts

ชุดคำสั่งสำหรับจัดการ Version และ Build iOS แบบอัตโนมัติ

## 🚀 Quick Start

### ตรวจสอบเวอร์ชันปัจจุบัน
```bash
./scripts/check_version.sh
```

### เปลี่ยนเวอร์ชันและ Build ทันที
```bash
./scripts/quick_release.sh 1.12.0 10
```

### อัปเดตเวอร์ชัน iOS เท่านั้น
```bash
./scripts/update_version.sh 1.10.8 10
```

## 📋 Scripts ทั้งหมด

| Script | คำอธิบาย | ตัวอย่าง |
|--------|----------|----------|
| `check_version.sh` | ตรวจสอบเวอร์ชันปัจจุบัน | `./scripts/check_version.sh` |
| `update_version.sh` | อัปเดตเวอร์ชัน iOS ใน Xcode project | `./scripts/update_version.sh 1.10.8 10` |
| `sync_version.sh` | เปลี่ยนเวอร์ชันและ sync ทุกไฟล์ | `./scripts/sync_version.sh 1.12.0 10` |
| `force_sync_version.sh` | บังคับ sync เวอร์ชันทั้งหมด | `./scripts/force_sync_version.sh 1.12.0 10` |
| `fix_archive_version.sh` | แก้ไขเวอร์ชันใน archive | `./scripts/fix_archive_version.sh 1.12.0 10` |
| `build_ios.sh` | Build iOS | `./scripts/build_ios.sh --archive` |
| `quick_release.sh` | ทำทุกขั้นตอนในคำสั่งเดียว | `./scripts/quick_release.sh 1.12.0 10` |
| `run_debug.sh` | รัน app ใน debug mode | `./scripts/run_debug.sh` |
| `open_devtools.sh` | เปิด Flutter DevTools | `./scripts/open_devtools.sh` |

## 💡 การใช้งานแบบต่างๆ

### 🔄 Workflow ปกติ
```bash
# 1. ตรวจสอบเวอร์ชันปัจจุบัน
./scripts/check_version.sh

# 2. เปลี่ยนเวอร์ชัน
./scripts/sync_version.sh 1.12.0 10

# 3. Build และ Archive
./scripts/build_ios.sh --archive
```

### 🔧 อัปเดตเวอร์ชัน iOS แบบเฉพาะ
```bash
# อัปเดตเฉพาะ iOS version และ build number
./scripts/update_version.sh 1.10.8 10

# ตรวจสอบผลลัพธ์
./scripts/check_version.sh
```

### ⚡ Quick Release (แนะนำ)
```bash
# ทำทุกขั้นตอนในคำสั่งเดียว
./scripts/quick_release.sh 1.12.0 10
```

### 🐛 Bug Fix Release
```bash
# เพิ่มเฉพาะ patch version
./scripts/quick_release.sh 1.11.1 11
```

### 🆕 Feature Release
```bash
# เพิ่ม minor version
./scripts/quick_release.sh 1.12.0 12
```

### 🚨 Major Release
```bash
# Major version update
./scripts/quick_release.sh 2.0.0 1
```

### 🛠️ Development Tools
```bash
# รัน app ใน debug mode
./scripts/run_debug.sh

# เปิด Flutter DevTools
./scripts/open_devtools.sh
```

### 🔧 แก้ไขปัญหาเวอร์ชัน
```bash
# บังคับ sync เวอร์ชันทั้งหมด
./scripts/force_sync_version.sh 1.12.0 10

# แก้ไขเวอร์ชันใน archive
./scripts/fix_archive_version.sh 1.12.0 10
```

## 📖 คู่มือฉบับเต็ม

ดูรายละเอียดเพิ่มเติมได้ที่: [../docs/IOS_BUILD_GUIDE.md](../docs/IOS_BUILD_GUIDE.md)

## 🔍 รายละเอียด Scripts

### `update_version.sh`
- **วัตถุประสงค์**: อัปเดตเฉพาะ iOS version และ build number
- **ไฟล์ที่อัปเดต**: 
  - `ios/Runner.xcodeproj/project.pbxproj`
  - `ios/Runner/Info.plist`
- **เหมาะสำหรับ**: เมื่อต้องการอัปเดตเฉพาะ iOS โดยไม่กระทบส่วนอื่น

### `sync_version.sh`
- **วัตถุประสงค์**: อัปเดตเวอร์ชันในทุกไฟล์ที่เกี่ยวข้อง
- **ไฟล์ที่อัปเดต**: pubspec.yaml, iOS, Android, และไฟล์อื่นๆ
- **เหมาะสำหรับ**: การอัปเดตเวอร์ชันแบบสมบูรณ์

### `force_sync_version.sh`
- **วัตถุประสงค์**: บังคับ sync เวอร์ชันทั้งหมดแม้จะมีปัญหา
- **เหมาะสำหรับ**: เมื่อ sync_version.sh ไม่ทำงาน
