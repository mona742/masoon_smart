// lib/models/app_models.dart

// 1. المستخدمون (قد يكون عميلاً أو صاحب ورشة)
enum UserRole { customer, workshopOwner, admin }

class AppUser {
  final String id;
  final String email;
  final String? phone;
  final UserRole role;

  AppUser({
    required this.id,
    required this.email,
    this.phone,
    required this.role,
  });
}

// 2. الورشة
class Workshop {
  final String id;
  final String ownerId; // ربط بالمستخدم
  final String name;
  final String address;
  final String phone;
  // يمكن إضافة ساعات العمل هنا

  Workshop({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.address,
    required this.phone,
  });
}

// 3. السيارة (تم تحديثها لتشمل العميل واللون)
class Car {
  final String id;
  final String customerId; // FK
  final String vin; // رقم الهيكل
  final String make; // تويوتا
  final String model; // كامري
  final int year;
  final String plateNumber;
  final String color;
  int currentKm;

  Car({
    required this.id,
    required this.customerId,
    required this.vin,
    required this.make,
    required this.model,
    required this.year,
    required this.plateNumber,
    required this.color,
    required this.currentKm,
  });
}

// 4. أنواع الخدمات (أساس الذكاء في التطبيق)
class ServiceType {
  final String id;
  final String name; // تغيير زيت، فحمات...
  final int recommendedIntervalKm; // كل 5000 كم
  final int recommendedIntervalDays; // أو كل 90 يوم

  ServiceType({
    required this.id,
    required this.name,
    required this.recommendedIntervalKm,
    required this.recommendedIntervalDays,
  });
}

// 5. سجل الخدمة الفعلي (الفاتورة)
class ServiceRecord {
  final String id;
  final String carId;
  final String workshopId;
  final String serviceTypeId; // FK لنوع الخدمة
  final DateTime date;
  final int kmAtService;
  final double totalPrice;
  final String notes;
  final String? invoiceUrl; // صورة الفاتورة

  ServiceRecord({
    required this.id,
    required this.carId,
    required this.workshopId,
    required this.serviceTypeId,
    required this.date,
    required this.kmAtService,
    required this.totalPrice,
    this.notes = '',
    this.invoiceUrl,
  });

  // دالة لحساب موعد الصيانة القادم بناءً على نوع الخدمة
  int getNextDueKm(int interval) {
    return kmAtService + interval;
  }
}

// 6. قطع الغيار (المتجر والمخزون)
class SparePart {
  final String id;
  final String name;
  final String sku; // رمز القطعة
  final double price;
  final double? discountPrice; // ✅ حقل جديد: سعر العرض (اختياري)
  final int stockQuantity;

  // القائمة الذكية: هذه القطعة تركب على أي سيارات؟
  // مثال: ["TOYOTA", "CAMRY", "2022"]
  final List<String> compatibleModels;

  SparePart({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    this.discountPrice, // ✅ سعر العرض
    required this.stockQuantity,
    required this.compatibleModels,
  });

  // ✅ دالة التحقق المطورة: هل تناسب هذه القطعة سيارة معينة؟
  bool isCompatibleWith(Car car) {
    // نحول البيانات لنصوص كبيرة للمقارنة بدقة (Case Insensitive)
    String carInfo = "${car.make} ${car.model} ${car.year}".toUpperCase();

    for (var modelString in compatibleModels) {
      if (carInfo.contains(modelString.toUpperCase())) {
        return true;
      }
    }
    return false;
  }
}

// 7. التنبيهات
enum NotificationType { maintenance, partOffer, appointment }

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });
}
