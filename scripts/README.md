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

## 📋 Scripts ทั้งหมด

| Script | คำอธิบาย | ตัวอย่าง |
|--------|----------|----------|
| `check_version.sh` | ตรวจสอบเวอร์ชันปัจจุบัน | `./scripts/check_version.sh` |
| `sync_version.sh` | เปลี่ยนเวอร์ชันและ sync ทุกไฟล์ | `./scripts/sync_version.sh 1.12.0 10` |
| `build_ios.sh` | Build iOS | `./scripts/build_ios.sh --archive` |
| `quick_release.sh` | ทำทุกขั้นตอนในคำสั่งเดียว | `./scripts/quick_release.sh 1.12.0 10` |

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

## 📖 คู่มือฉบับเต็ม

ดูรายละเอียดเพิ่มเติมได้ที่: [../docs/IOS_BUILD_GUIDE.md](../docs/IOS_BUILD_GUIDE.md)
