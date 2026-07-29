import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    await _requestPermission();
    await _fetchAndLogToken();
    _registerForegroundHandler();
    _registerBackgroundTapHandler();
  }

  Future<void> _requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      _log('Permission status: ${settings.authorizationStatus}');
    } catch (e) {
      _log('Permission request failed: $e');
    }
  }

  Future<void> _fetchAndLogToken() async {
    try {
      final token = await _messaging.getToken();
      _log('Device token: $token');
    } catch (e) {
      _log('Token fetch failed: $e');
    }
  }

  void _registerForegroundHandler() {
    try {
      FirebaseMessaging.onMessage.listen(
            (RemoteMessage message) {
          _log('Foreground message: ${message.notification?.title}');
          _log('Body: ${message.notification?.body}');
          // TODO: show in-app notification banner
        },
        onError: (e) => _log('Foreground listener error: $e'),
      );
    } catch (e) {
      _log('Failed to register foreground handler: $e');
    }
  }

  void _registerBackgroundTapHandler() {
    try {
      FirebaseMessaging.onMessageOpenedApp.listen(
            (RemoteMessage message) {
          _log('Opened from background: ${message.data}');
          // TODO: navigate based on message.data['type']
        },
        onError: (e) => _log('Background tap listener error: $e'),
      );
    } catch (e) {
      _log('Failed to register background tap handler: $e');
    }
  }

  /// Returns null silently on any failure.
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      _log('getToken failed: $e');
      return null;
    }
  }

  Future<void> subscribeToCircle(String circleId) async {
    try {
      await _messaging.subscribeToTopic('circle_$circleId');
      _log('Subscribed to circle_$circleId');
    } catch (e) {
      _log('subscribeToCircle failed for $circleId: $e');
    }
  }

  Future<void> unsubscribeFromCircle(String circleId) async {
    try {
      await _messaging.unsubscribeFromTopic('circle_$circleId');
      _log('Unsubscribed from circle_$circleId');
    } catch (e) {
      _log('unsubscribeFromCircle failed for $circleId: $e');
    }
  }

  /// Only prints in debug mode. No-ops in release.
  void _log(String message) {
    if (kDebugMode) debugPrint('[FCM] $message');
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (kDebugMode) {
      debugPrint('[FCM] Background message: ${message.messageId}');
    }
  } catch (_) {}
}