import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🔴 الكلاس الرئيسي لتهيئة الخدمة (يُستدعى من ملف main.dart)
class BackgroundLocationService {
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    // إعداد التهيئة الأساسية للخدمة
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart, // الدالة التي ستعمل في الخلفية
        autoStart: false, // لا تبدأ تلقائياً، ننتظر تسجيل الدخول أولاً
        isForegroundMode:
            true, // 🔴 إجباري لكي يعمل التطبيق في الخلفية دون أن يقتله نظام الأندرويد
        notificationChannelId: 'masoon_tracking_channel',
        initialNotificationTitle: 'مصون', // العنوان الافتراضي قبل بدء التتبع
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

// 🔴 الدالة الفعلية التي تعمل في الخلفية (Isolate منفصل عن واجهة التطبيق)
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // 1. تهيئة بيئة العمل في الخلفية (لأننا في مساحة منعزلة عن التطبيق الأمامي)
  DartPluginRegistrant.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("خطأ في تهيئة الفايربيز: $e");
  }

  // 2. التحقق من صلاحيات الموقع لتجنب انهيار التطبيق (Crash)
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  LocationPermission permission = await Geolocator.checkPermission();

  // إذا لم يكن هناك صلاحية، نغير الإشعار لتنبيه المستخدم ونوقف التتبع
  if (!serviceEnabled ||
      permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'مصون - تنبيه ⚠️',
        content: 'يرجى تفعيل صلاحيات الموقع (دائماً) لعمل التتبع',
      );
    }
    return; // إيقاف الكود هنا حتى يمنح المستخدم الصلاحية
  }

  String? currentCarId;
  final prefs = await SharedPreferences.getInstance();

  // 3. جلب المسافات المحفوظة
  // المسافة المعلقة للرفع (تُصفر بعد الرفع الناجح للفايربيز)
  double _pendingDistance = prefs.getDouble('pending_distance') ?? 0.0;
  // إجمالي المسافة المقطوعة (لحساب موعد تغيير الزيت وعرضها في الإشعار)
  double _totalDistance = prefs.getDouble('total_distance') ?? 0.0;

  // الاستماع لحدث تعيين السيارة من واجهة التطبيق
  service.on('setCarId').listen((event) {
    if (event != null && event['carId'] != null) {
      currentCarId = event['carId'] as String;
    }
  });

  // الاستماع لحدث إيقاف الخدمة (عند تسجيل الخروج)
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  Position? _lastPosition;

  // 4. بدء الاستماع لحركة الـ GPS بشكل مستمر
  Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high, // دقة عالية للحساب الصحيح
      distanceFilter: 10, // تحديث الموقع كلما تحركت السيارة 10 أمتار على الأقل
    ),
  ).listen((Position position) async {
    if (_lastPosition != null) {
      double distanceInMeters = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      // 5. إذا تحركت السيارة أكثر من 20 متر، نقوم بتحديث البيانات
      if (distanceInMeters > 20) {
        double distanceInKm = distanceInMeters / 1000;
        _pendingDistance += distanceInKm;
        _totalDistance += distanceInKm;

        // 🔴 حفظ محلي فوراً (لضمان عدم ضياع المسافة لو انقطع الإنترنت في الطريق)
        await prefs.setDouble('pending_distance', _pendingDistance);
        await prefs.setDouble('total_distance', _totalDistance);

        // 🔴 محاولة المزامنة مع الفايربيز
        if (currentCarId != null) {
          try {
            await FirebaseFirestore.instance
                .collection('cars')
                .doc(currentCarId)
                .update({
                  'currentKm': FieldValue.increment(
                    _pendingDistance,
                  ), // زيادة العداد السحابي
                  'lastUpdated': FieldValue.serverTimestamp(),
                });

            // إذا نجح الرفع، نصفر العداد "المعلق" فقط، ونحتفظ بالإجمالي
            _pendingDistance = 0.0;
            await prefs.setDouble('pending_distance', 0.0);
          } catch (e) {
            print("الإنترنت ضعيف، البيانات محفوظة محلياً ولن تضيع.");
          }
        }

        // 🔴 6. التحديث الذكي للإشعار (بديل مكتبة الإشعارات السابقة التي سببت التعارض)
        if (service is AndroidServiceInstance) {
          String notificationTitle = 'مصون يحمي مركبتك 🛡️';
          String notificationContent =
              'تم قطع: ${_totalDistance.toStringAsFixed(2)} كم';

          // 🔔 التنبيه الذكي لتغيير الزيت
          if (_totalDistance >= 5000.0) {
            notificationTitle = '⚠️ حان وقت الصيانة!';
            notificationContent =
                'تجاوزت 5000 كم، احجز موعداً لتغيير الزيت الآن.';
          }

          // هذا السطر يحدّث الإشعار الثابت بسلاسة ودون انهيار التطبيق
          service.setForegroundNotificationInfo(
            title: notificationTitle,
            content: notificationContent,
          );
        }
      }
    }
    _lastPosition = position;
  });
}
