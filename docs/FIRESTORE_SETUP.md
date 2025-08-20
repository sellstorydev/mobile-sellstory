# Cloud Firestore Setup Guide

## ภาพรวม

Project นี้ได้ติดตั้ง Cloud Firestore เพื่อจัดการข้อมูลแบบ real-time สำหรับ Kanban board application

## โครงสร้างข้อมูล

### Collections

1. **users** - ข้อมูลผู้ใช้
2. **boards** - ข้อมูล Kanban boards
3. **lanes** - ข้อมูล lanes ในแต่ละ board
4. **cards** - ข้อมูล job cards ในแต่ละ lane

### Data Models

#### Board
```dart
{
  id: String,
  title: String,
  userId: String,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

#### Lane
```dart
{
  id: String,
  title: String,
  boardId: String,
  order: int
}
```

#### JobCard
```dart
{
  id: String,
  title: String,
  assignee: String,
  dueDate: Timestamp?,
  badges: List<String>,
  amount: double,
  laneId: String,
  order: int,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

## การใช้งาน

### 1. FirestoreService

Service หลักสำหรับจัดการการเชื่อมต่อกับ Firestore:

```dart
final firestoreService = Get.find<FirestoreService>();

// เพิ่มเอกสาร
final docRef = await firestoreService.addDocument(
  firestoreService.boardsCollection,
  boardData,
);

// อ่านเอกสาร
final data = await firestoreService.getDocument(docRef);

// อัปเดตเอกสาร
await firestoreService.updateDocument(docRef, updatedData);

// ลบเอกสาร
await firestoreService.deleteDocument(docRef);

// Stream ข้อมูลแบบ real-time
firestoreService.getDocumentsStream(collection).listen((snapshot) {
  // จัดการข้อมูลที่เปลี่ยนแปลง
});
```

### 2. FirestoreRepository

Repository สำหรับจัดการข้อมูลเฉพาะ domain:

```dart
final repository = Get.find<FirestoreRepository>();

// สร้าง board ใหม่
final boardId = await repository.createBoard(board);

// ดึง boards ของผู้ใช้
final boardsStream = repository.getBoardsStream(userId);

// สร้าง lane ใหม่
final laneId = await repository.createLane(lane);

// ย้าย card ระหว่าง lanes
await repository.moveCard(cardId, fromLaneId, toLaneId, newOrder);
```

### 3. การใช้งานใน Controller

```dart
class BoardController extends GetxController {
  final FirestoreRepository _repository = Get.find<FirestoreRepository>();
  
  void loadBoard(String boardId) {
    _repository.getLanesStream(boardId).listen((lanes) {
      // อัปเดต UI
    });
  }
  
  Future<void> addCard(JobCard card) async {
    await _repository.createCard(card);
  }
}
```

## Security Rules

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Boards can only be accessed by their owner
    match /boards/{boardId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
    
    // Lanes can only be accessed by board owner
    match /lanes/{laneId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == get(/databases/$(database)/documents/boards/$(resource.data.boardId)).data.userId;
    }
    
    // Cards can only be accessed by board owner
    match /cards/{cardId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == get(/databases/$(database)/documents/boards/$(get(/databases/$(database)/documents/lanes/$(resource.data.laneId)).data.boardId)).data.userId;
    }
  }
}
```

## การทดสอบ

### 1. ทดสอบการเชื่อมต่อ

```dart
void testConnection() async {
  try {
    final firestoreService = Get.find<FirestoreService>();
    final testDoc = await firestoreService.addDocument(
      firestoreService.boardsCollection,
      {'test': true, 'timestamp': DateTime.now()},
    );
    print('Connection successful: ${testDoc.id}');
    
    // Clean up
    await firestoreService.deleteDocument(testDoc);
  } catch (e) {
    print('Connection failed: $e');
  }
}
```

### 2. ทดสอบการทำงานแบบสมบูรณ์

```dart
void runCompleteTest() async {
  final example = FirestoreExample();
  await example.runCompleteExample('test-user-id');
}
```

## การแก้ไขปัญหา

### 1. Permission Denied
- ตรวจสอบ Firestore Security Rules
- ตรวจสอบการ authentication ของผู้ใช้

### 2. Network Error
- ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต
- ตรวจสอบ Firebase configuration

### 3. Data Type Error
- ตรวจสอบ data types ใน toMap() และ fromMap() methods
- ตรวจสอบ Timestamp conversion

## Best Practices

1. **ใช้ Transactions** สำหรับ operations ที่ต้อง atomic
2. **ใช้ Streams** สำหรับ real-time updates
3. **จัดการ Error** อย่างเหมาะสม
4. **ใช้ Batch Operations** สำหรับ operations หลายรายการ
5. **Optimize Queries** โดยใช้ indexes ที่เหมาะสม

## การตั้งค่า Firebase Console

1. เปิด Firebase Console
2. เลือก project ของคุณ
3. ไปที่ Firestore Database
4. สร้าง database ใน production mode หรือ test mode
5. ตั้งค่า Security Rules
6. สร้าง indexes สำหรับ queries ที่ซับซ้อน

## การ Deploy

1. ตรวจสอบ Security Rules
2. สร้าง indexes ที่จำเป็น
3. ทดสอบใน production environment
4. Monitor performance และ usage
