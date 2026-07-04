// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
// ✅ استيراد الخدمات بناءً على الهيكلة الجديدة
import 'package:masoon_smart/services/background_location_service.dart';
import 'package:masoon_smart/services/notification_service.dart';
import 'package:masoon_smart/viewmodels/client_dashboard_vm.dart';
// ✅ استيراد الـ ViewModels
import 'package:masoon_smart/viewmodels/inventory_vm.dart';
import 'package:masoon_smart/viewmodels/login_vm.dart';
import 'package:masoon_smart/views/client_dashboard.dart';
// ✅ استيراد الشاشات (Views)
import 'package:masoon_smart/views/login_screen.dart';
import 'package:masoon_smart/views/workshop_home_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. تهيئة الفايربيز
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 2. تشغيل الخدمات
  await NotificationService().init();
  await BackgroundLocationService.initialize();

  // 3. استرجاع بيانات الجلسة
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final String userRole = prefs.getString('userRole') ?? 'customer';
  final String userPhone = prefs.getString('userPhone') ?? '';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InventoryViewModel()),
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => ClientDashboardViewModel()),
      ],
      child: MasoonSmartApp(
        isLoggedIn: isLoggedIn,
        userRole: userRole,
        userPhone: userPhone,
      ),
    ),
  );
}

class MasoonSmartApp extends StatelessWidget {
  final bool isLoggedIn;
  final String userRole;
  final String userPhone;

  const MasoonSmartApp({
    super.key,
    required this.isLoggedIn,
    required this.userRole,
    required this.userPhone,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Masoon Smart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Cairo', // الخط المفضل لديكِ لتناسق الواجهات
      ),
      home: isLoggedIn
          ? (userRole == 'workshop'
                ? WorkshopHomeScreen(workshopId: userPhone)
                : ClientDashboard(clientPhone: userPhone))
          : const LoginScreen(),
    );
  }
}
