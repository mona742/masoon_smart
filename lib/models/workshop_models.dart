// lib/models/workshop_models.dart

// أنواع الخدمات المتاحة
enum ServiceType {
  oilChange,
  brakeInspection,
  periodicCheck,
  acMaintenance,
  other,
}

// كلاس السيارة
class Car {
  final String id;
  final String vin;
  final String make;
  final String model;
  final int year;
  int currentMileage;

  Car({
    required this.id,
    required this.vin,
    required this.make,
    required this.model,
    required this.year,
    required this.currentMileage,
  });
}

// كلاس سجل الخدمة
class ServiceRecord {
  final String id;
  final String carId;
  final ServiceType type;
  final double cost;
  final int mileageAtService;
  final DateTime date;
  final String notes;

  // خاصية ذكية لحساب موعد الانتهاء
  int get expectedNextServiceMileage {
    switch (type) {
      case ServiceType.oilChange:
        return mileageAtService + 5000; // مثال: الزيت كل 5000
      case ServiceType.brakeInspection:
        return mileageAtService + 10000;
      default:
        return mileageAtService + 5000;
    }
  }

  ServiceRecord({
    required this.id,
    required this.carId,
    required this.type,
    required this.cost,
    required this.mileageAtService,
    required this.date,
    this.notes = '',
  });
}
