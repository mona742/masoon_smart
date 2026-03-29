// lib/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart'; // ✅ أضفنا هذا السطر ليتعرف على الألوان (Color)
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Singleton Pattern لجعل الخدمة متاحة في كامل التطبيق
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // دالة التهيئة (يتم استدعاؤها في main)
  Future<void> init() async {
    // 1. طلب الأذونات (مهم جداً للأندرويد 13+ والآيفون)
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // 2. إعداد قناة التنبيهات (للأندرويد)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    // 3. إنشاء القناة
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // 4. إعدادات الأيقونة (تأكدي أن لديك أيقونة باسم ic_launcher)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // إعدادات iOS
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    // تهيئة الإضافة
    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // هنا الكود الذي يعمل عند الضغط على الإشعار
        print("🔔 تم الضغط على الإشعار: ${details.payload}");
      },
    );

    // 5. الاستماع للرسائل والتطبيق مفتوح (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // عرض الإشعار محلياً إذا كان التطبيق مفتوحاً
      if (notification != null && android != null) {
        _localNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }

  // طباعة التوكن للتجربة
  Future<String?> getToken() async {
    String? token = await _firebaseMessaging.getToken();
    print("\n========================================");
    print("🔔 FCM TOKEN: $token");
    print("========================================\n");
    return token;
  }

  // ✅ 🚀 الدالة الجديدة: لعرض تنبيه الصيانة الذكي من داخل التطبيق (بدون إنترنت)
  Future<void> showWarningNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'masoon_warning_channel',
          'تنبيهات الصيانة',
          channelDescription: 'تنبيهات عند اقتراب موعد الصيانة لتجنب الضرر',
          importance: Importance.max,
          priority: Priority.high,
          color: Color(0xFFE53935), // لون أحمر للتنبيه
          icon: '@mipmap/ic_launcher',
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _localNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }
}
