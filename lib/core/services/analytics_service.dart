import 'package:get/get.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService extends GetxService {
  static AnalyticsService get to => Get.find();

  late final FirebaseAnalytics _analytics;

  @override
  void onInit() {
    super.onInit();
    _analytics = FirebaseAnalytics.instance;
  }

  Future<void> setUserId(String? uid) async {
    if (uid == null || uid.isEmpty) return;
    await _analytics.setUserId(id: uid);
  }

  Future<void> logLogin({required String method}) async {
    await _analytics.logLogin(loginMethod: method);
  }

  // Clean nullable-valued map to non-null values for FirebaseAnalytics API
  Map<String, Object>? _cleanParams(Map<String, Object?>? params) {
    if (params == null) return null;
    final cleaned = <String, Object>{};
    params.forEach((key, value) {
      if (value != null) cleaned[key] = value;
    });
    return cleaned;
  }

  Future<void> logEvent(String name, {Map<String, Object?>? parameters}) async {
    await _analytics.logEvent(name: name, parameters: _cleanParams(parameters));
  }
}
