import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

// ✅ 1. استيراد ملف خدمة الموقع الجديد (تأكد أن المسار صحيح)
import 'services/background_location_service.dart';
import 'services/notification_service.dart';
import 'views/login_screen.dart';

// ⚠️ دالة الخلفية للإشعارات (كما هي، لم نلمسها)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. تشغيل الفايربيز
  await Firebase.initializeApp();

  // 2. تفعيل معالج خلفية الإشعارات
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 3. تشغيل خدمة الإشعارات (كودك القديم)
  await NotificationService().init();

  // ✅ 4. تهيئة خدمة التتبع (الجي بي اس) - الإضافة الجديدة
  // ملاحظة: هذا السطر يجهز الخدمة فقط، ولن يبدأ التتبع إلا عندما نعطي أمر Start بعد تسجيل الدخول
  await BackgroundLocationService.initialize();

  // طباعة التوكن (كودك القديم)
  await NotificationService().getToken();

  runApp(const MasoonSmartApp());
}

class MasoonSmartApp extends StatelessWidget {
  const MasoonSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Masoon Smart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Cairo', // الخط العربي
      ),
      // الشاشة الرئيسية هي تسجيل الدخول
      home: const LoginScreen(),
    );
  }
}
