import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    //
  }

  // متغير لتخزين معرف السيارة
  String? currentCarId;

  // الاستماع لحدث تعيين السيارة من التطبيق الأمامي
  service.on('setCarId').listen((event) {
    if (event != null && event['carId'] != null) {
      currentCarId = event['carId'] as String;
      print("✅ الخدمة استلمت معرف السيارة: $currentCarId");
    }
  });

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // متغيرات التتبع
  Position? _lastPosition;
  double _totalDistance = 0.0;

  // إعدادات الـ GPS
  final LocationSettings locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,
  );

  Geolocator.getPositionStream(locationSettings: locationSettings).listen((
    Position position,
  ) async {
    if (_lastPosition != null) {
      double distanceInMeters = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      // إذا تحرك أكثر من 20 متر
      if (distanceInMeters > 20) {
        double distanceInKm = distanceInMeters / 1000;
        _totalDistance += distanceInKm;

        // 🚀 تحديث الفايربيز فوراً
        if (currentCarId != null) {
          try {
            await FirebaseFirestore.instance
                .collection('cars')
                .doc(currentCarId)
                .update({
                  // نستخدم increment لزيادة العداد بأمان
                  'currentKm': FieldValue.increment(distanceInKm),
                  'lastUpdated': FieldValue.serverTimestamp(),
                });
            print("📡 تم تحديث العداد في الفايربيز بزيادة: $distanceInKm كم");
          } catch (e) {
            print("❌ فشل تحديث الفايربيز: $e");
          }
        }

        // تحديث الإشعار
        if (service is AndroidServiceInstance) {
          if (await service.isForegroundService()) {
            final FlutterLocalNotificationsPlugin
            flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
            flutterLocalNotificationsPlugin.show(
              888,
              'مصون يتتبع مركبتك 🚗',
              'المسافة المقطوعة: ${_totalDistance.toStringAsFixed(2)} كم',
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'masoon_tracking_channel',
                  'تتبع المسافة',
                  icon: '@mipmap/ic_launcher',
                  ongoing: true,
                  importance: Importance.low,
                  onlyAlertOnce: true, // عشان ما يزعجك بالصوت كل ثانية
                ),
              ),
            );
          }
        }
      }
    }

    _lastPosition = position;

    service.invoke('update', {
      "lat": position.latitude,
      "lng": position.longitude,
      "distance": _totalDistance,
    });
  });
}

class BackgroundLocationService {
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'masoon_tracking_channel',
      'تتبع المسافة',
      description: 'تتبع حركة السيارة لحساب استهلاك الزيت',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'masoon_tracking_channel',
        initialNotificationTitle: 'مصون',
        initialNotificationContent: 'جاري تهيئة الخدمة...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onServiceBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onServiceBackground(ServiceInstance service) async {
    return true;
  }
}
