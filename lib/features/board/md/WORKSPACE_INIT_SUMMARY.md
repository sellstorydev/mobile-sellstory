# Workspace Initialization with lastActiveWorkspaceId

## Overview
ปรับปรุงระบบการ init workspace เมื่อเข้ามา application โดยใช้ `lastActiveWorkspaceId` จาก user document แทนการเลือก workspace แรกเสมอ

## Changes Made

### 1. Database Schema Update
- เพิ่มฟิลด์ `lastActiveWorkspaceId: string|null` ใน User document ที่ DTB.md
- ฟิลด์นี้จะเก็บ workspace ID ที่ใช้งานล่าสุด เช่น "xKnLu20t7n6A0IJxl4NN"

### 2. Service Layer Updates

#### FirestoreService
- เพิ่ม `getUserLastActiveWorkspaceId(String userId)` - ดึง lastActiveWorkspaceId จาก user document
- เพิ่ม `updateUserLastActiveWorkspaceId(String userId, String workspaceId)` - อัปเดต lastActiveWorkspaceId

#### FirestoreRepository  
- เพิ่ม `getUserLastActiveWorkspaceId(String userId)` - wrapper สำหรับ FirestoreService
- เพิ่ม `updateUserLastActiveWorkspaceId(String userId, String workspaceId)` - wrapper สำหรับ FirestoreService

#### ChatService
- ปรับปรุง `getUserCurrentWorkspaceId()` ให้ตรวจสอบว่า lastActiveWorkspaceId ยังมีอยู่ใน user's workspaces หรือไม่
- เพิ่ม `updateUserLastActiveWorkspaceId()` สำหรับอัปเดต lastActiveWorkspaceId

### 3. Controller Updates

#### BoardController
- ปรับปรุง `initializeWithUser()` ให้ใช้ lastActiveWorkspaceId เป็นลำดับแรก
- ปรับปรุง `switchWorkspace()` ให้อัปเดต lastActiveWorkspaceId เมื่อเปลี่ยน workspace
- Fallback ไปใช้ workspace แรกถ้า lastActiveWorkspaceId ไม่มีหรือไม่ถูกต้อง

#### CustomersController
- ปรับปรุง `initializeWithUser()` ให้ใช้ lastActiveWorkspaceId
- ปรับปรุง `switchWorkspace()` ให้อัปเดต lastActiveWorkspaceId

#### CalendarController
- ปรับปรุง `_initializeUserAndWorkspace()` ให้ใช้ lastActiveWorkspaceId

#### ProductsController
- ปรับปรุง `_initializeUserAndWorkspace()` ให้ใช้ lastActiveWorkspaceId

#### DocumentCenterController
- ปรับปรุง `_initializeUserAndWorkspace()` ให้ใช้ lastActiveWorkspaceId

#### QuotationsListController
- ปรับปรุง `_initializeUserAndWorkspace()` ให้ใช้ lastActiveWorkspaceId

#### InvoiceListController
- ปรับปรุง `_initializeUserAndWorkspace()` ให้ใช้ lastActiveWorkspaceId

#### ReceiptListController
- ปรับปรุง `_initializeUserAndWorkspace()` ให้ใช้ lastActiveWorkspaceId

#### ChatController
- ปรับปรุง `_getCurrentWorkspaceId()` ให้ตรวจสอบว่า lastActiveWorkspaceId ยังมีอยู่ใน user's workspaces หรือไม่

### 4. Widget Updates

#### CompanyPicker
- ปรับปรุง `_initializeUserAndWorkspace()` ให้ใช้ lastActiveWorkspaceId

## Logic Flow

### Initialization Process
1. ดึง user's workspaces จาก user document
2. ดึง lastActiveWorkspaceId จาก user document
3. ตรวจสอบว่า lastActiveWorkspaceId ยังมีอยู่ใน user's workspaces หรือไม่
4. ถ้ามี → ใช้ lastActiveWorkspaceId
5. ถ้าไม่มี → ใช้ workspace แรก (fallback)
6. อัปเดต current workspace ใน controller

### Workspace Switch Process
1. อัปเดต current workspace ใน controller
2. อัปเดต lastActiveWorkspaceId ใน user document
3. โหลดข้อมูลสำหรับ workspace ใหม่

## Benefits
- ผู้ใช้จะกลับมาที่ workspace เดิมที่ใช้งานล่าสุด
- รองรับการใช้งานข้าม platform (web/mobile)
- Fallback ที่ปลอดภัยถ้า workspace เก่าถูกลบ
- Consistent experience ระหว่าง features ต่างๆ

## Error Handling
- ถ้าไม่สามารถดึง lastActiveWorkspaceId ได้ → ใช้ workspace แรก
- ถ้า lastActiveWorkspaceId ไม่มีอยู่ใน user's workspaces → ใช้ workspace แรก
- ถ้าไม่สามารถอัปเดต lastActiveWorkspaceId ได้ → ไม่ throw error, continue การทำงาน

## Testing Scenarios
1. User เข้า app ครั้งแรก → ใช้ workspace แรก
2. User เปลี่ยน workspace → อัปเดต lastActiveWorkspaceId
3. User เข้า app ใหม่ → ใช้ workspace ที่เลือกล่าสุด
4. User ใช้งานบน web แล้วมา mobile → ใช้ workspace เดียวกัน
5. Workspace เก่าถูกลบ → fallback ไป workspace แรก
