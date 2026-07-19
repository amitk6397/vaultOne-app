import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _fcmTokenStorageKey = 'fcm_token';

const _channel = AndroidNotificationChannel(
  'vaultone_notifications',
  'VaultOne notifications',
  description: 'Security, expiry, renewal, and account alerts.',
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _notificationEvents = StreamController<void>.broadcast();
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  Future<void> Function(String token)? _tokenSyncHandler;

  void setTokenSyncHandler(Future<void> Function(String token) handler) {
    _tokenSyncHandler = handler;
  }

  Stream<void> get notificationEvents => _notificationEvents.stream;

  Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await _foregroundSubscription?.cancel();
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _showForegroundNotification,
    );
    await _openedSubscription?.cancel();
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((_) {
      _notificationEvents.add(null);
    });

    final token = await FirebaseMessaging.instance.getToken();
    await _storeAndVerifyToken(token);

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh
        .listen(
          (refreshedToken) => _storeAndVerifyToken(refreshedToken),
          onError: (Object error) {
            debugPrint('FCM token refresh error: $error');
          },
        );
  }

  Future<String?> getStoredToken() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_fcmTokenStorageKey);
  }

  Future<void> _storeAndVerifyToken(String? token) async {
    if (token == null || token.isEmpty) {
      debugPrint('FCM token unavailable; nothing was stored.');
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(_fcmTokenStorageKey, token);
    await preferences.reload();
    final storedToken = preferences.getString(_fcmTokenStorageKey);
    final isVerified = saved && storedToken == token;

    debugPrint('FCM token stored: $isVerified');
    if (isVerified && _tokenSyncHandler != null) {
      try {
        await _tokenSyncHandler!(token);
      } catch (error) {
        debugPrint('FCM token sync failed: $error');
      }
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    _notificationEvents.add(null);
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      id: message.messageId?.hashCode ?? notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'vaultone_notifications',
          'VaultOne notifications',
          channelDescription: 'Security, expiry, renewal, and account alerts.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data['route']?.toString(),
    );
  }
}
