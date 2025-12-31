// lib/viewmodels/smart_workshop_vm.dart
import 'package:flutter/material.dart';

import '../models/workshop_models.dart';

class SmartWorkshopViewModel extends ChangeNotifier {
  // بيانات تجريبية (سيارة كامري)
  List<Car> cars = [
    Car(
      id: 'c1',
      vin: 'ABC123456',
      make: 'Toyota',
      model: 'Camry',
      year: 2018,
      currentMileage: 104500,
    ),
  ];

  List<ServiceRecord> servicesHistory = [];
  List<String> alerts = [];

  // دالة الورشة لإضافة خدمة
  void addServiceRecord(
    String carId,
    ServiceType type,
    int currentKm,
    String notes,
  ) {
    // إضافة السجل
    final newRecord = ServiceRecord(
      id: DateTime.now().toString(),
      carId: carId,
      type: type,
      cost: 150.0,
      mileageAtService: currentKm,
      date: DateTime.now(),
      notes: notes,
    );
    servicesHistory.add(newRecord);

    // تحديث عداد السيارة
    final carIndex = cars.indexWhere((c) => c.id == carId);
    if (carIndex != -1) {
      cars[carIndex].currentMileage = currentKm;
      // حساب التنبيهات فوراً
      calculateMaintenanceAlerts(cars[carIndex]);
    }

    notifyListeners(); // تحديث الشاشة
  }

  // خوارزمية حساب التنبيهات
  void calculateMaintenanceAlerts(Car car) {
    alerts.clear();

    // البحث عن آخر تغيير زيت
    var lastOilChange = servicesHistory.lastWhere(
      (s) => s.carId == car.id && s.type == ServiceType.oilChange,
      orElse: () => ServiceRecord(
        id: '0',
        carId: '0',
        type: ServiceType.other,
        cost: 0,
        mileageAtService: 0,
        date: DateTime(2000),
      ),
    );

    if (lastOilChange.id != '0') {
      int nextDue = lastOilChange.expectedNextServiceMileage;
      int remaining = nextDue - car.currentMileage;

      if (remaining <= 0) {
        alerts.add(
          "⚠️ تنبيه عاجل: تجاوزت موعد تغيير الزيت بـ ${remaining.abs()} كم!",
        );
      } else if (remaining <= 500) {
        alerts.add("🔔 تذكير: باقي $remaining كم على الزيت.");
      } else {
        alerts.add("✅ حالة الزيت ممتازة. الموعد القادم بعد $remaining كم.");
      }
    } else {
      alerts.add("ℹ️ لا يوجد سجل سابق لتغيير الزيت.");
    }
  }

  // دالة لتحديث العداد يدوياً (للتجربة)
  void updateMileage(String carId, int newMileage) {
    final car = cars.firstWhere((c) => c.id == carId);
    car.currentMileage = newMileage;
    calculateMaintenanceAlerts(car);
    notifyListeners();
  }
}
