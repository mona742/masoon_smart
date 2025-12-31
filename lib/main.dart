import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart'; // ملف الألوان
import 'views/login_screen.dart'; // ✅ استدعاء شاشة الدخول بدلاً من الداشبورد مباشرة

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    print("✅ تم الاتصال بـ Firebase بنجاح!");
  } catch (e) {
    print("❌ خطأ في الاتصال بـ Firebase: $e");
  }

  runApp(const MasoonSmartApp());
}

class MasoonSmartApp extends StatelessWidget {
  const MasoonSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Masoon Smart',

      // إعداد الثيم العام
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          error: AppColors.danger,
          surface: AppColors.cardBg,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.cardBg,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: AppColors.textDark),
          titleTextStyle: TextStyle(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        textTheme: GoogleFonts.cairoTextTheme(Theme.of(context).textTheme),
      ),

      // ✅ جعلنا البداية هي شاشة الدخول لتتمكن من اختيار (ورشة) أو (عميل)
      home: LoginScreen(),
    );
  }
}
