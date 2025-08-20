# 📱 Logging Guide for Dart DevTools

คู่มือการใช้งาน logging ใน SellStory App เพื่อดู log ผ่าน Dart DevTools

## 🎯 วัตถุประสงค์

- ดู log แบบ real-time ใน Dart DevTools
- Debug ปัญหาการทำงานของแอพ
- ติดตามการทำงานของ dependencies และ state management
- วิเคราะห์ performance และ memory usage

## 🛠️ การตั้งค่า

### 1. เปิด Dart DevTools

```bash
# วิธีที่ 1: ใช้ Flutter Inspector ใน VS Code
# กด F5 หรือ Run > Start Debugging

# วิธีที่ 2: ใช้ command line
flutter run --debug

# วิธีที่ 3: เปิด DevTools ใน browser
flutter pub global activate devtools
flutter pub global run devtools
```

### 2. เชื่อมต่อกับแอพ

1. เปิดแอพใน debug mode
2. เปิด Dart DevTools
3. เลือกแอพ SellStory จากรายการ
4. ไปที่แท็บ **Console** เพื่อดู log

## 📊 ประเภทของ Log

### 🛠️ DevTools Logs
```dart
LoggerService.to.devTools('Message', {
  'key': 'value',
  'timestamp': DateTime.now().toIso8601String(),
});
```

### 📱 Console Logs
```dart
LoggerService.to.console('Message', data);
```

### 🔍 Debug Logs
```dart
LoggerService.to.debugStructured('Operation', {
  'param1': 'value1',
  'param2': 'value2',
});
```

### ⏱️ Performance Logs
```dart
LoggerService.to.profile('Operation', duration, {
  'context': 'additional info',
});
```

### 💾 Memory Logs
```dart
LoggerService.to.memoryProfile('Component', currentBytes, peakBytes);
```

## 🔄 Log Flow ในแอพ

### 1. App Startup
```
🛠️ DevTools: SellStory App Starting
🛠️ DevTools: Setting up dependencies...
🛠️ DevTools: Locator.setup() called
🛠️ DevTools: Dependencies setup completed
```

### 2. User Login
```
🛠️ DevTools: User initialization started
📱 Console: Fetching user workspaces...
🛠️ DevTools: User workspaces loaded
🛠️ DevTools: Workspace selected
```

### 3. Board Loading
```
🛠️ DevTools: Loading board data
🛠️ DevTools: Board data loaded successfully
🛠️ DevTools: Board state rendered
```

### 4. User Actions
```
🛠️ DevTools: Card moved
🛠️ DevTools: Lane created
🛠️ DevTools: Workspace switched
```

### 5. Logout/Login Cycle
```
🛠️ DevTools: Locator.resetDependencies() called
🛠️ DevTools: Dependencies cleared
🛠️ DevTools: Dependencies reset completed
```

## 🎨 การใช้งานใน DevTools

### Console Tab
- ดู log ทั้งหมดแบบ real-time
- Filter log ตาม level (debug, info, warning, error)
- Search log ตาม keyword

### Logging Tab
- ดู log แบบ structured
- Export log เป็นไฟล์
- Filter และ search ขั้นสูง

### Performance Tab
- ดู performance metrics
- Memory usage
- Network requests

## 🔧 การปรับแต่ง Log Level

```dart
// เปลี่ยน log level
LoggerService.to.setLevel(Level.debug);  // เห็น log ทั้งหมด
LoggerService.to.setLevel(Level.info);   // เห็น info ขึ้นไป
LoggerService.to.setLevel(Level.warning); // เห็น warning ขึ้นไป
LoggerService.to.setLevel(Level.error);  // เห็น error เท่านั้น

// ปิด/เปิด logging
LoggerService.to.enableLogging(true);   // เปิด logging
LoggerService.to.enableLogging(false);  // ปิด logging
```

## 📝 ตัวอย่างการใช้งาน

### ใน Controller
```dart
class MyController extends GetxController {
  final LoggerService _logger = Get.find<LoggerService>();
  
  @override
  void onInit() {
    super.onInit();
    _logger.devTools('Controller initialized', {
      'controllerId': hashCode.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  Future<void> loadData() async {
    _logger.methodEntry('loadData');
    _logger.devTools('Loading data...');
    
    try {
      // ... load data logic
      _logger.devTools('Data loaded successfully', {
        'dataCount': data.length,
      });
    } catch (e) {
      _logger.error('Failed to load data', e);
      _logger.devTools('Data loading failed', {
        'error': e.toString(),
      });
    }
    
    _logger.methodExit('loadData');
  }
}
```

### ใน Repository
```dart
class MyRepository {
  final LoggerService _logger = Get.find<LoggerService>();
  
  Future<List<Data>> fetchData() async {
    _logger.methodEntry('fetchData');
    _logger.database('Fetching data from Firestore');
    
    try {
      final result = await _firestore.collection('data').get();
      _logger.database('Data fetched successfully', {
        'documentsCount': result.docs.length,
      });
      return result.docs.map((doc) => Data.fromMap(doc.data())).toList();
    } catch (e) {
      _logger.error('Database error', e);
      rethrow;
    }
  }
}
```

## 🚀 Tips & Tricks

### 1. ใช้ Structured Data
```dart
// ✅ ดี - ใช้ structured data
_logger.devTools('User action', {
  'action': 'card_move',
  'cardId': cardId,
  'fromLane': fromLaneId,
  'toLane': toLaneId,
  'timestamp': DateTime.now().toIso8601String(),
});

// ❌ ไม่ดี - ใช้ string ธรรมดา
_logger.devTools('User moved card $cardId from $fromLane to $toLane');
```

### 2. ใช้ Context ใน Error Logs
```dart
_logger.errorWithContext('Failed to load data', 'BoardController.loadData', e);
```

### 3. ใช้ Performance Logging
```dart
final stopwatch = Stopwatch()..start();
// ... operation
stopwatch.stop();
_logger.profile('Data loading', stopwatch.elapsed, {
  'dataSize': data.length,
});
```

### 4. ใช้ Memory Profiling
```dart
_logger.memoryProfile('BoardController', currentMemoryUsage, peakMemoryUsage);
```

## 🔍 การ Debug ปัญหา

### 1. Dependency Issues
```dart
// ดู log เมื่อ dependency ไม่พบ
🛠️ DevTools: Locator.resetDependencies() called
🛠️ DevTools: Dependencies cleared
🛠️ DevTools: Dependencies reset completed
```

### 2. State Management Issues
```dart
// ดู log เมื่อ state เปลี่ยน
🛠️ DevTools: Board state rendered
🔄 State: State updated
```

### 3. Network Issues
```dart
// ดู log เมื่อ network มีปัญหา
🌐 API: Request failed
❌ Error: Network timeout
```

### 4. Performance Issues
```dart
// ดู log เมื่อ performance มีปัญหา
⏱️ Profile: Data loading took 5000ms
💾 Memory: High memory usage detected
```

## 📚 เพิ่มเติม

- [Dart DevTools Documentation](https://docs.flutter.dev/tools/devtools)
- [Logger Package Documentation](https://pub.dev/packages/logger)
- [GetX Documentation](https://pub.dev/packages/get)

---

**หมายเหตุ**: Log ทั้งหมดจะปรากฏใน Dart DevTools Console และสามารถ export เป็นไฟล์เพื่อวิเคราะห์เพิ่มเติมได้

