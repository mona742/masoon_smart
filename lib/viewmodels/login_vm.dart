import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart'; // مكتبة التخزين المحلي (للاحتفاظ بتسجيل الدخول)

import '../views/client_dashboard.dart';
import '../views/workshop_home_screen.dart';
import '../views/workshop_setup_screen.dart';

class LoginViewModel extends ChangeNotifier {
  // المتغيرات التي تتحكم في حالة الشاشة
  bool _isWorkshopOwner = false; // هل المستخدم صاحب ورشة؟
  bool _otpSent = false; // هل تم إرسال الرمز؟
  bool _isLoading = false; // هل التطبيق في حالة تحميل (دوران المؤشر)؟

  // وحدات التحكم في الحقول النصية (لجلب النص الذي يكتبه المستخدم)
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  // دوال الـ Getters لقراءة المتغيرات من واجهة المستخدم
  bool get isWorkshopOwner => _isWorkshopOwner;
  bool get otpSent => _otpSent;
  bool get isLoading => _isLoading;

  // دالة للتبديل بين دور العميل ودور صاحب الورشة
  void toggleRole(bool isWorkshop) {
    _isWorkshopOwner = isWorkshop;
    notifyListeners(); // تنبيه الواجهة لتحديث الألوان والنصوص
  }

  // 🔴 الدالة المسؤولة عن إرسال رمز التحقق (والتحقق من صحة الرقم)
  void sendOtp(BuildContext context) async {
    String phone = phoneController.text.trim(); // جلب الرقم وإزالة المسافات

    // 1. التحقق من أن الحقل ليس فارغاً
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ يرجى كتابة رقم الجوال أولاً!")),
      );
      return; // إيقاف الدالة هنا وعدم الإكمال
    }

    // 2. التحقق الصارم (الـ Validation) اللي طلبناه:
    // يجب أن يبدأ بـ 05 وطوله 10 أرقام بالضبط.
    if (!phone.startsWith('05') || phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "⚠️ رقم الجوال غير صحيح! يجب أن يبدأ بـ 05 ويتكون من 10 أرقام.",
          ),
        ),
      );
      return; // إيقاف الدالة لمنع إرسال طلبات خاطئة للفايربيز
    }

    // إذا كان الرقم صحيحاً، نظهر مؤشر التحميل
    _isLoading = true;
    notifyListeners();

    // محاكاة انتظار إرسال الرمز (ثانية واحدة)
    await Future.delayed(const Duration(seconds: 1));

    // إخفاء مؤشر التحميل وإظهار حقل إدخال الرمز
    _isLoading = false;
    _otpSent = true;
    notifyListeners();
  }

  // 🔴 الدالة المسؤولة عن التحقق من الرمز المدخل وحفظ الجلسة
  // لا تنسي إضافة هذا الاستيراد أعلى الملف إذا لم يكن موجوداً
  // import 'package:geolocator/geolocator.dart';

  void verifyOtp(BuildContext context) async {
    if (otpController.text == "1234") {
      final String phone = phoneController.text.trim();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userPhone', phone);
      await prefs.setString(
        'userRole',
        _isWorkshopOwner ? 'workshop' : 'customer',
      );

      // ✅ طلب صلاحية الموقع من المستخدم قبل تشغيل الخدمة
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // تشغيل الخدمة فقط إذا وافق المستخدم
      if (permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever) {
        FlutterBackgroundService().startService();
        print("🚀 تم تفعيل خدمة التتبع المستمر");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠️ تم رفض صلاحية الموقع، التتبع لن يعمل."),
          ),
        );
      }

      if (_isWorkshopOwner) {
        _checkUserProfile(context);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ClientDashboard(clientPhone: phone),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ الرمز غير صحيح")));
    }
  }

  // دالة للبحث عن ملف الورشة في الفايربيز
  Future<void> _checkUserProfile(BuildContext context) async {
    _isLoading = true;
    notifyListeners();
    try {
      final String userId = phoneController.text.trim().replaceAll(' ', '');
      String? foundId;
      DocumentSnapshot? foundDoc;

      // تجربة عدة صيغ للرقم لتفادي أخطاء الإدخال القديمة
      List<String> possibilities = [
        userId,
        "0$userId",
        userId.startsWith('0') ? userId.substring(1) : userId,
      ];

      // البحث في الفايربيز
      for (String id in possibilities) {
        final doc = await FirebaseFirestore.instance
            .collection('workshops')
            .doc(id)
            .get();
        if (doc.exists) {
          foundId = id;
          foundDoc = doc;
          break; // التوقف بمجرد إيجاد الورشة
        }
      }

      _isLoading = false;
      notifyListeners();

      if (foundDoc != null && foundId != null) {
        // الورشة موجودة -> الذهاب للرئيسية
        final data = foundDoc.data() as Map<String, dynamic>;
        final name = data['name'] ?? 'مركز الصيانة';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('workshopId', foundId);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                WorkshopHomeScreen(workshopName: name, workshopId: foundId!),
          ),
        );
      } else {
        // الورشة غير موجودة -> الذهاب لشاشة إعداد الورشة الجديدة
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

  // دالة للتراجع وتغيير رقم الجوال
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

  // 🔴 دالة تسجيل الخروج ومسح الجلسة وإيقاف التتبع
  Future<void> logout(BuildContext context) async {
    try {
      // 1. إيقاف خدمة التتبع في الخلفية لكي لا تستهلك البطارية بعد الخروج
      final service = FlutterBackgroundService();
      var isRunning = await service.isRunning();
      if (isRunning) {
        service.invoke("stopService");
      }

      // 2. مسح كل البيانات المحفوظة في الهاتف (تسجيل الدخول، الدور، الخ)
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // 3. العودة لشاشة تسجيل الدخول ومسح الشاشات السابقة من الذاكرة
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }

      print("✅ تم تسجيل الخروج بنجاح");
    } catch (e) {
      print("❌ خطأ أثناء تسجيل الخروج: $e");
    }
  }
}
