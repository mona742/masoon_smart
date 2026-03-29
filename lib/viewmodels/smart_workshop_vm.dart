// lib/viewmodels/smart_workshop_vm.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SmartWorkshopViewModel extends ChangeNotifier {
  bool isLoading = false;
  Map<String, dynamic>? currentCar;
  List<Map<String, dynamic>> servicesHistory = [];
  List<String> alerts = [];

  /// جلب بيانات سيارة معينة وسجل صیانتها من الفايربيز
  Future<void> fetchCarDetails(String carId) async {
    isLoading = true;
    notifyListeners();

    try {
      // 1. جلب بيانات السيارة الأساسية
      final carDoc = await FirebaseFirestore.instance
          .collection('cars')
          .doc(carId)
          .get();

      if (carDoc.exists) {
        currentCar = carDoc.data();

        // 2. جلب سجل الخدمات المرتبط بهذه السيارة (مرتبة من الأحدث للأقدم)
        final servicesQuery = await FirebaseFirestore.instance
            .collection('services')
            .where('carId', isEqualTo: carId)
            .orderBy('createdAt', descending: true)
            .get();

        servicesHistory = servicesQuery.docs.map((doc) => doc.data()).toList();

        // 3. حساب التنبيهات الذكية بناءً على البيانات الحقيقية
        _calculateAlerts();
      } else {
        currentCar = null;
        servicesHistory = [];
        alerts = ["⚠️ السيارة غير مسجلة في النظام."];
      }
    } catch (e) {
      print("Error fetching car details: $e");
      alerts = ["❌ حدث خطأ أثناء جلب بيانات السيارة."];
    }

    isLoading = false;
    notifyListeners();
  }

  /// خوارزمية حساب التنبيهات بناءً على الفايربيز
  void _calculateAlerts() {
    alerts.clear();
    if (currentCar == null) return;

    // استخراج الممشى الحالي من بيانات السيارة
    double currentKm =
        double.tryParse(currentCar!['currentKm'].toString()) ?? 0.0;

    // البحث عن آخر خدمة "تغيير زيت" في السجل
    var oilServices = servicesHistory.where((s) => s['type'] == 'oil').toList();

    if (oilServices.isNotEmpty) {
      var lastOil = oilServices.first;
      double limit = double.tryParse(lastOil['limitKm'].toString()) ?? 5000.0;
      double lastKm =
          double.tryParse(lastOil['lastChangeKm'].toString()) ?? 0.0;

      double remaining = (lastKm + limit) - currentKm;

      if (remaining <= 0) {
        alerts.add(
          "⚠️ تنبيه عاجل: تجاوزت السيارة موعد تغيير الزيت بـ ${remaining.abs().toInt()} كم!",
        );
      } else if (remaining <= 1000) {
        alerts.add(
          "🔔 تذكير: باقي ${remaining.toInt()} كم على موعد تغيير الزيت.",
        );
      } else {
        alerts.add("✅ حالة الزيت جيدة (متبقي ${remaining.toInt()} كم).");
      }
    } else {
      alerts.add("ℹ️ لا يوجد سجل سابق لتغيير الزيت لهذه السيارة.");
    }

    // يمكننا لاحقاً إضافة شروط مشابهة للكفرات والمكيف بناءً على lifeSpanMonths
  }

  /// مسح البيانات عند الخروج من الشاشة
  void clearData() {
    currentCar = null;
    servicesHistory.clear();
    alerts.clear();
    notifyListeners();
  }
}
