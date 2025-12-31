import 'package:flutter/material.dart';

import '../models/app_models.dart';

class ClientStoreViewModel extends ChangeNotifier {
  // السيارة المختارة حالياً للعميل
  final Car userCar;

  // القائمة النهائية التي ستظهر في الشاشة
  List<SparePart> filteredParts = [];

  ClientStoreViewModel(this.userCar) {
    _loadAndFilterParts();
  }

  void _loadAndFilterParts() {
    // 1. قاعدة بيانات القطع (محاكاة لسيرفر الورشة)
    // لاحظي: بعض القطع للكامري، وبعضها للهونداي
    List<SparePart> allInventory = [
      SparePart(
        id: 'p1',
        name: 'فحمات سيراميك أمامية',
        sku: 'BRK-CAM-20',
        price: 250.0,
        stockQuantity: 10,
        compatibleModels: [
          'Toyota Camry 2020',
          'Toyota Camry 2021',
          'Toyota Avalon 2020',
        ],
      ),
      SparePart(
        id: 'p2',
        name: 'فلتر زيت أصلي',
        sku: 'OIL-TYT-GEN',
        price: 45.0,
        stockQuantity: 50,
        compatibleModels: [
          'Toyota Camry 2020',
          'Toyota Corolla 2020',
          'Toyota Yaris 2020',
        ],
      ),
      SparePart(
        id: 'p3',
        name: 'مساعدات خلفية (KYB)',
        sku: 'SUS-ACC-18',
        price: 320.0,
        stockQuantity: 4,
        compatibleModels: [
          'Hyundai Accent 2018',
          'Hyundai Elantra 2019',
        ], // هذه لا يجب أن تظهر للكامري
      ),
      SparePart(
        id: 'p4',
        name: 'بواجي ليزر (طقم 4)',
        sku: 'SPK-NGK-99',
        price: 180.0,
        stockQuantity: 15,
        compatibleModels: ['Toyota Camry 2020', 'Toyota Rav4 2020'],
      ),
    ];

    // 2. الفلترة الذكية (Smart Filtering Logic)
    // نبحث عن اسم السيارة + موديلها + سنتها داخل قائمة الموديلات المتوافقة
    String searchKey =
        "${userCar.make} ${userCar.model} ${userCar.year}"; // مثال: Toyota Camry 2020

    // ملاحظة: في التطبيق الحقيقي البحث يكون أدق، هنا نبحث عن تطابق جزئي للنص
    filteredParts = allInventory.where((part) {
      // هل موديل سيارتي موجود في قائمة الموديلات التي تدعمها القطعة؟
      return part.compatibleModels.any(
        (model) => model.contains(userCar.model),
      );
    }).toList();

    notifyListeners();
  }

  // دالة طلب القطعة
  void orderPart(BuildContext context, SparePart part) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("تأكيد الطلب 🛍️"),
        content: Text(
          "هل تود حجز قطعة (${part.name}) بسعر ${part.price} ريال؟\nسيتم تجهيزها لك في الورشة.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "تم إرسال طلبك للورشة بنجاح! سيتم التواصل معك.",
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[800],
              foregroundColor: Colors.white,
            ),
            child: const Text("تأكيد الحجز"),
          ),
        ],
      ),
    );
  }
}
