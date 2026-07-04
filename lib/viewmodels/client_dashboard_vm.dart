// lib/viewmodels/client_dashboard_vm.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ هذا هو الكلاس الذي كان يبحث عنه ملف main.dart
class ClientDashboardViewModel extends ChangeNotifier {
  int selectedCarIndex = 0;
  bool isLoading = false;

  void changeCar(int index) {
    selectedCarIndex = index;
    notifyListeners();
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  // أضيفي هذا المتغير والدالة في الـ ViewModel
  double _localPendingKm = 0.0;
  double get localPendingKm => _localPendingKm;

  Future<void> checkLocalTrackingData() async {
    final prefs = await SharedPreferences.getInstance();
    // قراءة القيمة التي تخزنها خدمة الخلفية
    _localPendingKm = prefs.getDouble('pending_distance') ?? 0.0;
    notifyListeners(); // تحديث الواجهة لتري الرقم
  }
}

// ⚠️ ملاحظة: كود ServiceModel الذي أرسلتيه يفضل أن يكون في مجلد models
// سنتركه هنا مؤقتاً لكي لا تتعطل باقي الشاشات إذا كانت تستدعيه من هنا
