import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../firebase/firebase_bootstrap.dart';

/// Only notification payloads are displayed. Data never drives navigation,
/// profile changes, calculations, logging, or telemetry.
final pushMessengerKey = GlobalKey<ScaffoldMessengerState>();

class PushNotifications {
  static StreamSubscription<RemoteMessage>? _foreground;

  static Future<void> initialize(FirebaseStartupStatus status) async {
    if (status != FirebaseStartupStatus.ready) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final permission = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (permission.authorizationStatus != AuthorizationStatus.authorized &&
          permission.authorizationStatus != AuthorizationStatus.provisional) {
        return;
      }
      // APNs presents foreground alerts on iOS. Android uses an in-app banner.
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      await _foreground?.cancel();
      _foreground = FirebaseMessaging.onMessage.listen((message) {
        if (defaultTargetPlatform !=
            TargetPlatform.android) return;
        final notification = message.notification;
        if (notification == null) return;
        final text = [notification.title, notification.body]
            .whereType<String>()
            .where((value) => value.isNotEmpty)
            .join('\n');
        if (text.isEmpty) return;
        pushMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(text)),
        );
      });
    } catch (_) {
      // Messaging failure never blocks local profiles. Do not report raw errors.
    }
  }
}
