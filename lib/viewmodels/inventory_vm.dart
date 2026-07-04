// lib/viewmodels/inventory_vm.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class InventoryViewModel extends ChangeNotifier {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final discountPriceController = TextEditingController();
  final skuController = TextEditingController();
  final modelInputController = TextEditingController();

  List<String> compatibleModels = [];
  bool isFeatured = false; // ✅ الحقل الجديد لتمييز العرض
  bool isLoading = false;

  void toggleFeatured(bool value) {
    isFeatured = value;
    notifyListeners();
  }

  void addCompatibleModel() {
    String text = modelInputController.text.trim().toUpperCase();
    if (text.isNotEmpty && !compatibleModels.contains(text)) {
      compatibleModels.add(text);
      modelInputController.clear();
      notifyListeners();
    }
  }

  void removeModel(String model) {
    compatibleModels.remove(model);
    notifyListeners();
  }

  Future<void> savePart(BuildContext context, String? workshopId) async {
    if (nameController.text.isEmpty || priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى تعبئة البيانات الأساسية")),
      );
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      await FirebaseFirestore.instance.collection('spare_parts').add({
        'name': nameController.text.trim(),
        'sku': skuController.text.trim(),
        'price': double.parse(priceController.text),
        'discountPrice': double.tryParse(discountPriceController.text) ?? 0.0,
        'compatibleModels': compatibleModels,
        'isFeatured': isFeatured,
        'workshopId': workshopId ?? 'unknown',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ✅ 1. عرض الرسالة أولاً
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ تم حفظ العرض ونشره بنجاح!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2), // الرسالة ستظهر لمدة ثانيتين
        ),
      );

      // ✅ 2. تأخير بسيط جداً ليرى صاحب الورشة الرسالة ثم العودة
      await Future.delayed(const Duration(milliseconds: 1500));

      _clearAll();
      if (context.mounted) Navigator.pop(context); // العودة بأمان
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("خطأ أثناء الحفظ: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  // lib/viewmodels/inventory_vm.dart
  // ... (أبقِ الـ Imports والمتحكمات كما هي)

  // دالة الحذف مع رسالة تأكيد (سنستدعيها من الواجهة)
  Future<void> deletePart(BuildContext context, String partId) async {
    try {
      await FirebaseFirestore.instance
          .collection('spare_parts')
          .doc(partId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ تم حذف القطعة بنجاح"),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("خطأ أثناء الحذف: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // دالة التحديث (تعديل بيانات موجودة)
  Future<void> updatePart(BuildContext context, String partId) async {
    isLoading = true;
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('spare_parts')
          .doc(partId)
          .update({
            'name': nameController.text.trim(),
            'price': double.parse(priceController.text),
            'discountPrice':
                double.tryParse(discountPriceController.text) ?? 0.0,
            'sku': skuController.text.trim(),
            'compatibleModels': compatibleModels,
            'isFeatured': isFeatured,
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ تم تحديث بيانات القطعة"),
          backgroundColor: Colors.green,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      _clearAll();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("خطأ في التحديث: $e")));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // دالة لتعبئة الحقول بالبيانات القديمة عند الرغبة في التعديل
  void prepareForEdit(Map<String, dynamic> data) {
    nameController.text = data['name'] ?? '';
    priceController.text = (data['price'] ?? 0).toString();
    discountPriceController.text = (data['discountPrice'] ?? 0).toString();
    skuController.text = data['sku'] ?? '';
    compatibleModels = List<String>.from(data['compatibleModels'] ?? []);
    isFeatured = data['isFeatured'] ?? false;
    notifyListeners();
  }

  void _clearAll() {
    nameController.clear();
    priceController.clear();
    discountPriceController.clear();
    skuController.clear();
    compatibleModels.clear();
    isFeatured = false;
  }
}
