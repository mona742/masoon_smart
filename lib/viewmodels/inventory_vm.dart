import 'package:flutter/material.dart';

import '../models/app_models.dart';

class InventoryViewModel extends ChangeNotifier {
  // للتحكم في الحقول
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final skuController = TextEditingController();
  final modelInputController = TextEditingController();

  // قائمة الموديلات المتوافقة (التي أضافها المستخدم)
  List<String> compatibleModels = [];

  // دالة لإضافة موديل للقائمة (مثل نظام التاقات)
  void addCompatibleModel() {
    if (modelInputController.text.isNotEmpty) {
      compatibleModels.add(modelInputController.text);
      modelInputController.clear();
      notifyListeners();
    }
  }

  // دالة لحذف موديل من القائمة
  void removeModel(String model) {
    compatibleModels.remove(model);
    notifyListeners();
  }

  // دالة الحفظ النهائية
  void saveSparePart(BuildContext context) {
    if (nameController.text.isEmpty || priceController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("يرجى تعبئة البيانات الأساسية")));
      return;
    }

    // هنا يتم إنشاء الكائن وإرساله للداتابيس
    final newPart = SparePart(
      id: DateTime.now().toString(),
      name: nameController.text,
      sku: skuController.text,
      price: double.parse(priceController.text),
      stockQuantity: 10, // افتراضي
      compatibleModels: List.from(compatibleModels),
    );

    // طباعة للتجربة
    print(
      "تم حفظ القطعة: ${newPart.name} - متوافقة مع: ${newPart.compatibleModels}",
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("تم إضافة القطعة وإرسال التنبيهات للعملاء المتطابقين!"),
      ),
    );
    // تفريغ الحقول
    nameController.clear();
    priceController.clear();
    compatibleModels.clear();
    notifyListeners();
  }
}
