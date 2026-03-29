import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart'; // ✅ 1. استيراد الخدمة

import '../views/client_dashboard.dart';
import '../views/workshop_home_screen.dart';
import '../views/workshop_setup_screen.dart';

class LoginViewModel extends ChangeNotifier {
  bool _isWorkshopOwner = false;
  bool _otpSent = false;
  bool _isLoading = false;

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  bool get isWorkshopOwner => _isWorkshopOwner;
  bool get otpSent => _otpSent;
  bool get isLoading => _isLoading;

  void toggleRole(bool isWorkshop) {
    _isWorkshopOwner = isWorkshop;
    notifyListeners();
  }

  void sendOtp(BuildContext context) async {
    if (phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ يرجى كتابة رقم الجوال أولاً!")),
      );
      return;
    }
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1)); // محاكاة
    _isLoading = false;
    _otpSent = true;
    notifyListeners();
  }

  void verifyOtp(BuildContext context) {
    // ⚠️ في التطبيق الحقيقي يجب التحقق من كود OTP حقيقي
    if (otpController.text == "1234") {
      // ✅ 2. تشغيل خدمة التتبع (GPS) بمجرد نجاح الدخول
      FlutterBackgroundService().startService();
      print("🚀 تم تشغيل خدمة التتبع في الخلفية");

      if (_isWorkshopOwner) {
        _checkUserProfile(context);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ClientDashboard(
              clientPhone: phoneController.text.trim(), // تمرير الرقم
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ الرمز غير صحيح")));
    }
  }

  Future<void> _checkUserProfile(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      final String userId = phoneController.text.trim().replaceAll(' ', '');

      // نبحث عن الورشة بكل الصيغ المحتملة لتجنب التكرار
      String? foundId;
      DocumentSnapshot? foundDoc;

      List<String> possibilities = [
        userId,
        "0$userId",
        userId.startsWith('0') ? userId.substring(1) : userId,
      ];

      for (String id in possibilities) {
        final doc = await FirebaseFirestore.instance
            .collection('workshops')
            .doc(id)
            .get();
        if (doc.exists) {
          foundId = id;
          foundDoc = doc;
          break;
        }
      }

      _isLoading = false;
      notifyListeners();

      if (foundDoc != null && foundId != null) {
        final data = foundDoc.data() as Map<String, dynamic>;
        final name = data['name'] ?? 'مركز الصيانة';

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                WorkshopHomeScreen(workshopName: name, workshopId: foundId!),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => WorkshopSetupScreen(uid: userId)),
        );
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("خطأ: $e")));
    }
  }

  void changePhoneNumber() {
    _otpSent = false;
    otpController.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }
}
