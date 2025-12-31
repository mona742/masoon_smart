import 'package:flutter/material.dart';

class NotificationService {
  // دالة لإظهار إشعار محلي بسيط
  void showLocalNotification(String title, String body) {
    debugPrint("🔔 إشعار: $title - $body");
  }

  // الدالة التي كانت مفقودة سابقاً: إشعار فوري
  Future<void> showInstantNotification(String title, String body) async {
    // محاكاة الإشعار بطباعة النص في لوحة التحكم (Console)
    debugPrint("🚀 إشعار فوري جديد: $title \n $body");
  }

  // الدالة التي كانت مفقودة سابقاً: جدولة إشعار
  Future<void> scheduleOilNotification(int seconds, String carName) async {
    debugPrint("⏰ تم ضبط منبه لتغيير زيت سيارة $carName بعد $seconds ثواني.");
  }

  // دالة لعرض رسالة منبثقة (SnackBar)
  void showSnackBar(BuildContext context, String message) {
    debugPrint("💬 عرض رسالة للمستخدم: $message"); // للتأكد من وصول الأمر

    // التحقق من أن السياق (Context) لا يزال صالحاً
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.blueAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
