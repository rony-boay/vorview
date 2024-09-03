import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vorviewadmin/main.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static void notificationTapBackgroundHandler(NotificationResponse response) {
    if (response.payload != null) {
      print('Notification payload in background: ${response.payload}');
      _handleNotificationTap(response.payload!);
    }
  }

  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Karachi'));

    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iOSInitializationSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
      iOS: iOSInitializationSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          _handleNotificationTap(response.payload!);
        }
      },
      onDidReceiveBackgroundNotificationResponse:
          notificationTapBackgroundHandler,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  static Future<void> showInstantNotification(
      String title, String body, String productId,
      {String? category}) async {
    if (!await _areNotificationsEnabled()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _saveNotificationToFirestore(user.uid, title, body, productId);
    }

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails(
        _getChannelIdForCategory(category),
        _getChannelNameForCategory(category),
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        styleInformation: DefaultStyleInformation(true, true),
        groupKey: 'com.yourcompany.productNotifications', // Grouping key
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: category ?? 'default',
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      _generateSafeNotificationId(),
      title,
      body,
      platformChannelSpecifics,
      payload: productId,
    );
  }

  static Future<void> scheduleLoopingNotifications(
    List<Map<String, dynamic>> products,
    int intervalSeconds,
  ) async {
    if (!await _areNotificationsEnabled()) {
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    int notificationIndex = 0;
    final user = FirebaseAuth.instance.currentUser;

    while (true) {
      final product = products[notificationIndex % products.length];

      if (user != null) {
        _saveNotificationToFirestore(
          user.uid,
          product['name'],
          product['description'],
          product['productId'],
        );
      }

      await flutterLocalNotificationsPlugin.zonedSchedule(
        _generateSafeNotificationId(),
        product['name'],
        product['description'],
        now.add(Duration(seconds: intervalSeconds * (notificationIndex + 1))),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'recurring_notification_channel_id',
            'Recurring Notifications',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            groupKey: 'com.yourcompany.productNotifications', // Grouping key
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: product['productId'],
      );

      notificationIndex++;
      await Future.delayed(Duration(seconds: intervalSeconds));
    }
  }

  static Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  static Future<void> _saveNotificationToFirestore(
    String userId,
    String title,
    String body,
    String productId,
  ) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'title': title,
      'body': body,
      'productId': productId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Future<bool> _areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notificationsEnabled') ?? true;
  }

  static int _generateSafeNotificationId() {
    return DateTime.now().millisecondsSinceEpoch.remainder(100000);
  }

  static void _handleNotificationTap(String payload) {
    print('Notification tapped with payload: $payload');
    final productId = payload;

    final context = navigatorKey.currentContext;

    if (context != null) {
      Navigator.pushNamed(
        context,
        '/productDetail',
        arguments: productId,
      );
    } else {
      print('Error: No valid context for navigation');
    }
  }

  // Additional methods to support new features

  static String _getChannelIdForCategory(String? category) {
    switch (category) {
      case 'sales':
        return 'sales_notification_channel_id';
      case 'new_arrivals':
        return 'new_arrivals_notification_channel_id';
      default:
        return 'general_notification_channel_id';
    }
  }

  static String _getChannelNameForCategory(String? category) {
    switch (category) {
      case 'sales':
        return 'Sales Notifications';
      case 'new_arrivals':
        return 'New Arrivals Notifications';
      default:
        return 'General Notifications';
    }
  }
}
