import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';

import 'logger_service.dart';
import '../../data/services/firebase_auth_service.dart';

class FcmService extends GetxService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _isInitialized = false.obs;
  String? _cachedToken;
  String? _cachedDeviceId;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _deviceWatcher;

  Future<void> _awaitApnsToken({Duration timeout = const Duration(seconds: 8)}) async {
    if (!Platform.isIOS) return;
    final start = DateTime.now();
    while (true) {
      try {
        final apns = await _messaging.getAPNSToken();
        if (apns != null && apns.isNotEmpty) {
          LoggerService.to.firebase('APNs token ready');
          LoggerService.to.firebase('APNs token: $apns');
          LoggerService.to.addFcmLog('apns_ready', data: {'apnsToken': apns});
          break;
        }
      } catch (_) {}
      if (DateTime.now().difference(start) > timeout) {
        LoggerService.to.warning('APNs token not ready within timeout; proceeding');
        LoggerService.to.addFcmLog('apns_timeout');
        break;
      }
      await Future.delayed(const Duration(milliseconds: 250));
    }
  }


  Future<FcmService> init() async {
    if (_isInitialized.value) return this;

    // iOS: request permissions
    await _requestPermission();

    // Ensure FCM auto-init is enabled
    try { await _messaging.setAutoInitEnabled(true); } catch (_) {}

    // Ensure APNs token for iOS before getting FCM token
    await _awaitApnsToken();

    // iOS foreground presentation options
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get token (may be null before permission/APNs on iOS)
    try {
      _cachedToken = await _messaging.getToken();
      LoggerService.to.firebase('FCM initial token: ${_cachedToken ?? '-'}');
      LoggerService.to.addFcmLog('token_initial', data: {'token': _cachedToken});
    } catch (e) {
      LoggerService.to.failure('FCM getToken failed', e);
      LoggerService.to.addFcmLog('token_error', message: 'getToken failed', data: {'error': e.toString()});
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      LoggerService.to.firebase('FCM token refreshed: $newToken');
      LoggerService.to.addFcmLog('token_refreshed', data: {'token': newToken});
      _cachedToken = newToken;
      try {
        await _saveTokenToFirestore();
      } catch (e) {
        LoggerService.to.failure('Failed to update token on refresh', e);
        LoggerService.to.addFcmLog('token_refresh_save_error', data: {'error': e.toString()});
      }
    });

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // LoggerService.to.firebase('FCM onMessage: ${message.messageId} data=${message.data}');
      LoggerService.to.addFcmLog('onMessage', data: {
        'id': message.messageId,
        'title': message.notification?.title,
        'body': message.notification?.body,
        'data': message.data,
      });
      final title = message.notification?.title ?? 'New Notification';
      final body = message.notification?.body ?? '';
      if (Get.isRegistered<LoggerService>()) {
        // Also show a non-intrusive in-app banner
        // Get.snackbar(title, body, snackPosition: SnackPosition.TOP);
      }
    });

    // App opened from a notification (background -> foreground)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      LoggerService.to.firebase('FCM onMessageOpenedApp: ${message.messageId} data=${message.data}');
      LoggerService.to.addFcmLog('onMessageOpenedApp', data: {
        'id': message.messageId,
        'title': message.notification?.title,
        'body': message.notification?.body,
        'data': message.data,
      });
      // TODO: Deep link to a page based on message.data if needed
    });

    // App launched by tapping a notification (terminated state)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      LoggerService.to.firebase('FCM getInitialMessage: ${initialMessage.messageId} data=${initialMessage.data}');
      LoggerService.to.addFcmLog('getInitialMessage', data: {
        'id': initialMessage.messageId,
        'title': initialMessage.notification?.title,
        'body': initialMessage.notification?.body,
        'data': initialMessage.data,
      });
      // TODO: Handle deep link on cold start
    }

    _isInitialized.value = true;
    LoggerService.to.addFcmLog('fcm_initialized');

    // Start device guard for current session
    if (_auth.currentUser != null) {
      await _ensureDeviceId();
      _startDeviceWatcher();
    }
    return this;
  }

  Future<void> registerDeviceForPush() async {
    if (!_isInitialized.value) {
      await init();
    }
    LoggerService.to.addFcmLog('register_device_start');
    // Ensure APNs ready on iOS before saving
    await _awaitApnsToken();
    await _ensureDeviceId();
    try {
      await _saveTokenToFirestore();
      LoggerService.to.addFcmLog('register_device_success', data: {'deviceId': _cachedDeviceId});
    } catch (e) {
      LoggerService.to.warning('registerDeviceForPush: token save skipped due to transient error: $e');
      LoggerService.to.addFcmLog('register_device_error', data: {'error': e.toString()});
    }
    await _enforceMaxActiveDevices(2);
    _startDeviceWatcher();
  }

  void _startDeviceWatcher() {
    final uid = _auth.currentUser?.uid;
    if (uid == null || _cachedDeviceId == null || _cachedDeviceId!.isNotEmpty == false) return;

    // Cancel previous watcher
    _deviceWatcher?.cancel();

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(_cachedDeviceId);

    _deviceWatcher = docRef.snapshots().listen((snap) async {
      if (!snap.exists) return;
      final data = snap.data() ?? {};
      final isActive = data['isActive'] != false; // default true if missing
      final forceSignOut = data['forceSignOut'] == true;
      if (!isActive || forceSignOut) {
        LoggerService.to.addFcmLog('device_signout_trigger', data: {
          'deviceId': _cachedDeviceId,
          'reason': !isActive ? 'inactive' : 'forceSignOut',
        });
        // Prevent loops by stopping watcher before sign out
        await _deviceWatcher?.cancel();
        _deviceWatcher = null;
        try {
          // Immediate logout via central auth service (handles Google + Firebase)
          await Get.find<FirebaseAuthService>().signOut();
        } catch (e) {
          LoggerService.to.failure('Auto sign-out failed', e);
          // Fallback to raw Firebase signOut if service not available
          try { await FirebaseAuth.instance.signOut(); } catch (_) {}
        }
      }
    });
  }

  Future<void> _enforceMaxActiveDevices(int maxActive) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final devicesCol = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('devices');
      // Order by updatedAt (oldest first); filter actives client-side to avoid composite index
      final q = await devicesCol
          .orderBy('updatedAt')
          .get();
      final docs = q.docs;
      // Collect active devices in order
      final active = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      for (final d in docs) {
        final data = d.data();
        final isActive = data['isActive'] != false;
        if (isActive) active.add(d);
      }
      if (active.length <= maxActive) return;

      int needDisable = active.length - maxActive;
      int disabled = 0;
      for (final d in active) {
        if (disabled >= needDisable) break;
        if (d.id == _cachedDeviceId) {
          // Skip current device; pick next oldest
          continue;
        }
        await d.reference.set({
          'isActive': false,
          'forceSignOut': true,
          'kickAt': FieldValue.serverTimestamp(),
          'kickByDevice': _cachedDeviceId,
          'kickReason': 'exceeded_limit',
        }, SetOptions(merge: true));
        disabled++;
      }
      if (disabled > 0) {
        LoggerService.to.addFcmLog('enforce_max_devices', data: {'disabled': disabled});
      }
    } catch (e) {
      LoggerService.to.failure('Failed to enforce max active devices', e);
    }
  }

  Future<void> _requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      LoggerService.to.firebase('Notification permission: ${settings.authorizationStatus}');
      LoggerService.to.addFcmLog('permission', data: {
        'status': settings.authorizationStatus.toString(),
        'alert': settings.alert,
        'badge': settings.badge,
        'sound': settings.sound,
      });
    } catch (e) {
      LoggerService.to.failure('Requesting notification permission failed', e);
      LoggerService.to.addFcmLog('permission_error', data: {'error': e.toString()});
    }
  }

  Future<void> _ensureDeviceId() async {
    if (_cachedDeviceId != null && _cachedDeviceId!.isNotEmpty) return;
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        _cachedDeviceId = info.id;
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        _cachedDeviceId = info.identifierForVendor;
      } else if (Platform.isMacOS) {
        final info = await deviceInfo.macOsInfo;
        _cachedDeviceId = info.systemGUID;
      } else if (Platform.isWindows) {
        final info = await deviceInfo.windowsInfo;
        _cachedDeviceId = info.deviceId;
      } else if (Platform.isLinux) {
        final info = await deviceInfo.linuxInfo;
        _cachedDeviceId = info.machineId;
      }
    } catch (e) {
      LoggerService.to.failure('Failed to get device id', e);
    }

    // Fallbacks
    _cachedDeviceId ??= _cachedToken; // fallback to token
    _cachedDeviceId ??= DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<void> _saveTokenToFirestore() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      LoggerService.to.warning('Skipping FCM token save: no authenticated user');
      LoggerService.to.addFcmLog('token_save_skipped', message: 'No user');
      return;
    }

    // Retry fetch if token is missing (common on iOS)
    try {
      _cachedToken ??= await _messaging.getToken();
    } catch (e) {
      LoggerService.to.warning('getToken threw before APNs ready: $e');
      _cachedToken = null;
    }
    if (_cachedToken == null || _cachedToken!.isEmpty) {
      await _awaitApnsToken();
      try {
        _cachedToken = await _messaging.getToken();
      } catch (e) {
        LoggerService.to.warning('getToken retry threw after waiting APNs: $e');
        _cachedToken = null;
      }
    }
    if (_cachedToken == null || _cachedToken!.isEmpty) {
      LoggerService.to.warning('Skipping FCM token save: token is null/empty');
      LoggerService.to.addFcmLog('token_missing');
      return;
    }

    await _ensureDeviceId();

    final devicesCol = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('devices');

    final deviceDoc = devicesCol.doc(_cachedDeviceId);

    final now = FieldValue.serverTimestamp();

    // Basic device metadata
    Map<String, dynamic> meta = {
      'token': _cachedToken,
      'platform': Platform.operatingSystem,
      'updatedAt': now,
      'isActive': true,
      'forceSignOut': false,
    };



    try {
      await deviceDoc.set(meta, SetOptions(merge: true));
      LoggerService.to.firebase('Saved FCM token for device $_cachedDeviceId');
      LoggerService.to.addFcmLog('token_saved_device', data: {'deviceId': _cachedDeviceId});

      // Also update token at user root document for simple lookups
      final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
      await userDoc.set({
        'fcmToken': _cachedToken,
        'fcmTokenUpdatedAt': now,
        'lastDeviceId': _cachedDeviceId,
        'lastPlatform': Platform.operatingSystem,
      }, SetOptions(merge: true));
      LoggerService.to.firebase('Saved FCM token at /users/$uid');
      LoggerService.to.addFcmLog('token_saved_user', data: {'userId': uid});
    } catch (e) {
      LoggerService.to.failure('Failed to save FCM token to Firestore', e);
      LoggerService.to.addFcmLog('token_save_error', data: {'error': e.toString()});
    }
  }
}
