import 'package:logger/logger.dart';
import 'package:get/get.dart';

class LoggerService extends GetxService {
  static LoggerService get to => Get.find();
  
  late Logger _logger;
  
  // Keep a rolling buffer of recent FCM logs for in-app viewing
  final RxList<Map<String, dynamic>> fcmLogs = <Map<String, dynamic>>[].obs;
  final int _maxFcmLogs = 200;

  @override
  void onInit() {
    super.onInit();
    _initializeLogger();
  }
  
  void _initializeLogger() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 3, // เพิ่ม method count เพื่อให้เห็น stack trace มากขึ้น
        errorMethodCount: 10, // เพิ่ม error method count
        lineLength: 150, // เพิ่ม line length
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      level: Level.debug, // ตั้งเป็น debug level เพื่อให้เห็น log ทั้งหมด
      output: ConsoleOutput(), // ใช้ ConsoleOutput เพื่อให้ log ปรากฏใน DevTools
    );
  }
  
  // Debug level logging
  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }
  
  // Info level logging
  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }
  
  // Warning level logging
  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }
  
  // Error level logging
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
  
  // Fatal level logging
  void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
  
  // Trace level logging (replaces verbose)
  void trace(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.t(message, error: error, stackTrace: stackTrace);
  }
  
  // Success logging (custom)
  void success(String message) {
    _logger.i('✅ $message');
  }
  
  // Failure logging (custom)
  void failure(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e('❌ $message', error: error, stackTrace: stackTrace);
  }
  
  // Firebase specific logging
  void firebase(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i('🔥 Firebase: $message', error: error, stackTrace: stackTrace);
    // Also store to in-memory FCM logs for UI visibility
    addFcmLog('firebase', message: message);
  }

  // Add a structured FCM log entry
  void addFcmLog(String event, {String? message, Map<String, dynamic>? data}) {
    final entry = <String, dynamic>{
      'ts': DateTime.now().toIso8601String(),
      'event': event,
      if (message != null && message.isNotEmpty) 'message': message,
      if (data != null && data.isNotEmpty) 'data': data,
    };
    fcmLogs.add(entry);
    // Enforce rolling buffer size
    if (fcmLogs.length > _maxFcmLogs) {
      final overflow = fcmLogs.length - _maxFcmLogs;
      fcmLogs.removeRange(0, overflow);
    }
  }

  // Clear FCM logs
  void clearFcmLogs() {
    fcmLogs.clear();
  }
  
  // API specific logging
  void api(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i('🌐 API: $message', error: error, stackTrace: stackTrace);
  }
  
  // UI specific logging
  void ui(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i('🎨 UI: $message', error: error, stackTrace: stackTrace);
  }
  
  // Database specific logging
  void database(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i('💾 Database: $message', error: error, stackTrace: stackTrace);
  }
  
  // Authentication specific logging
  void auth(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i('🔐 Auth: $message', error: error, stackTrace: stackTrace);
  }
  
  // Performance logging
  void performance(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i('⚡ Performance: $message', error: error, stackTrace: stackTrace);
  }
  
  // Navigation logging
  void navigation(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i('🧭 Navigation: $message', error: error, stackTrace: stackTrace);
  }
  
  // State management logging
  void state(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i('🔄 State: $message', error: error, stackTrace: stackTrace);
  }
  
  // Business logic logging
  void business(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i('💼 Business: $message', error: error, stackTrace: stackTrace);
  }
  
  // Security logging
  void security(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w('🔒 Security: $message', error: error, stackTrace: stackTrace);
  }
  
  // Network logging
  void network(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i('📡 Network: $message', error: error, stackTrace: stackTrace);
  }
  
  // Cache logging
  void cache(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i('💿 Cache: $message', error: error, stackTrace: stackTrace);
  }
  
  // File logging
  void file(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i('📁 File: $message', error: error, stackTrace: stackTrace);
  }
  
  // Device logging
  void device(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i('📱 Device: $message', error: error, stackTrace: stackTrace);
  }
  
  // Configuration logging
  void config(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i('⚙️ Config: $message', error: error, stackTrace: stackTrace);
  }
  
  // Dependency injection logging
  void di(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i('🔧 DI: $message', error: error, stackTrace: stackTrace);
  }
  
  // Testing logging
  void test(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i('🧪 Test: $message', error: error, stackTrace: stackTrace);
  }
  
  // Development logging
  void dev(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d('🛠️ Dev: $message', error: error, stackTrace: stackTrace);
  }
  
  // Production logging
  void prod(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i('🚀 Prod: $message', error: error, stackTrace: stackTrace);
  }
  
  // Custom tag logging
  void tag(String tag, String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i('🏷️ [$tag]: $message', error: error, stackTrace: stackTrace);
  }
  
  // Log method entry
  void methodEntry(String methodName, [Map<String, dynamic>? parameters]) {
    final params = parameters != null ? ' with params: $parameters' : '';
    _logger.d('➡️ Entering: $methodName$params');
  }
  
  // Log method exit
  void methodExit(String methodName, [dynamic result]) {
    final resultStr = result != null ? ' with result: $result' : '';
    _logger.d('⬅️ Exiting: $methodName$resultStr');
  }
  
  // Log method execution time
  void methodTime(String methodName, Duration duration) {
    _logger.i('⏱️ $methodName took ${duration.inMilliseconds}ms');
  }
  
  // Log object creation
  void objectCreated(String className, [Map<String, dynamic>? properties]) {
    final props = properties != null ? ' with properties: $properties' : '';
    _logger.d('🏗️ Created: $className$props');
  }
  
  // Log object destruction
  void objectDestroyed(String className) {
    _logger.d('🗑️ Destroyed: $className');
  }
  
  // Log lifecycle events
  void lifecycle(String component, String event) {
    _logger.i('🔄 $component: $event');
  }
  
  // Log user actions
  void userAction(String action, [Map<String, dynamic>? context]) {
    final ctx = context != null ? ' with context: $context' : '';
    _logger.i('👤 User Action: $action$ctx');
  }
  
  // Log system events
  void systemEvent(String event, [Map<String, dynamic>? data]) {
    final eventData = data != null ? ' with data: $data' : '';
    _logger.i('⚙️ System Event: $event$eventData');
  }
  
  // Log external service calls
  void externalService(String service, String operation, [dynamic result, dynamic error]) {
    if (error != null) {
      _logger.e('🌍 External Service [$service]: $operation failed', error: error);
    } else {
      _logger.i('🌍 External Service [$service]: $operation completed${result != null ? ' with result: $result' : ''}');
    }
  }
  
  // Log data flow
  void dataFlow(String from, String to, String dataType, [dynamic data]) {
    final dataStr = data != null ? ' with data: $data' : '';
    _logger.i('📊 Data Flow: $from → $to ($dataType)$dataStr');
  }
  
  // Log memory usage
  void memoryUsage(String component, int bytes) {
    final mb = (bytes / 1024 / 1024).toStringAsFixed(2);
    _logger.i('💾 Memory Usage [$component]: ${mb}MB');
  }
  
  // Log performance metrics
  void performanceMetric(String metric, dynamic value, [String? unit]) {
    final unitStr = unit != null ? ' $unit' : '';
    _logger.i('📈 Performance [$metric]: $value$unitStr');
  }
  
  // Log error with context
  void errorWithContext(String message, String context, [dynamic error, StackTrace? stackTrace]) {
    _logger.e('❌ Error in $context: $message', error: error, stackTrace: stackTrace);
  }
  
  // Log warning with context
  void warningWithContext(String message, String context, [dynamic error, StackTrace? stackTrace]) {
    _logger.w('⚠️ Warning in $context: $message', error: error, stackTrace: stackTrace);
  }
  
  // Log info with context
  void infoWithContext(String message, String context, [dynamic error, StackTrace? stackTrace]) {
    _logger.i('ℹ️ Info in $context: $message', error: error, stackTrace: stackTrace);
  }
  
  // Log debug with context
  void debugWithContext(String message, String context, [dynamic error, StackTrace? stackTrace]) {
    _logger.d('🔍 Debug in $context: $message', error: error, stackTrace: stackTrace);
  }
  
  // Get the underlying logger instance
  Logger get logger => _logger;
  
  // Set log level
  void setLevel(Level level) {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 3,
        errorMethodCount: 10,
        lineLength: 150,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      level: level,
      output: ConsoleOutput(),
    );
  }
  
  // DevTools specific logging methods
  void devTools(String message, [Map<String, dynamic>? data]) {
    final dataStr = data != null ? ' | Data: $data' : '';
    _logger.i('🛠️ DevTools: $message$dataStr');
  }
  
  // Log for Dart DevTools Console
  void console(String message, [dynamic data]) {
    final dataStr = data != null ? ' | $data' : '';
    _logger.d('📱 Console: $message$dataStr');
  }
  
  // Log for debugging with structured data
  void debugStructured(String message, Map<String, dynamic> data) {
    _logger.d('🔍 Debug [$message]: $data');
  }
  
  // Log for performance profiling
  void profile(String operation, Duration duration, [Map<String, dynamic>? context]) {
    final ctx = context != null ? ' | Context: $context' : '';
    _logger.i('⏱️ Profile [$operation]: ${duration.inMilliseconds}ms$ctx');
  }
  
  // Log for memory profiling
  void memoryProfile(String component, int currentBytes, int peakBytes) {
    final currentMB = (currentBytes / 1024 / 1024).toStringAsFixed(2);
    final peakMB = (peakBytes / 1024 / 1024).toStringAsFixed(2);
    _logger.i('💾 Memory [$component]: Current: ${currentMB}MB, Peak: ${peakMB}MB');
  }
  
  // Enable/disable logging
  void enableLogging(bool enabled) {
    if (enabled) {
      setLevel(Level.debug);
    } else {
      setLevel(Level.off);
    }
  }
}
