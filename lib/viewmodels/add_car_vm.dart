import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddCarViewModel extends ChangeNotifier {
  // مفتاح النموذج للتحقق من صحة البيانات
  final formKey = GlobalKey<FormState>();

  // --- الحقول النصية ---
  final TextEditingController vinController =
      TextEditingController(); // رقم الهيكل
  final TextEditingController plateController =
      TextEditingController(); // اللوحة
  final TextEditingController modelController =
      TextEditingController(); // الموديل (كامري، أكورد..)
  final TextEditingController kmController =
      TextEditingController(); // الممشى الحالي

  // ✅ الحقل الجديد والمهم جداً: رقم جوال العميل
  final TextEditingController clientPhoneController = TextEditingController();

  // --- القوائم المنسدلة ---
  String? selectedMake;
  int? selectedYear;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // بيانات ثابتة للقوائم
  final List<String> carMakes = [
    'تويوتا',
    'هيونداي',
    'فورد',
    'نيسان',
    'مازدا',
    'هوندا',
    'مرسيدس',
    'بي إم دبليو',
    'شيفروليه',
    'كيا',
  ];

  final List<int> years = List.generate(
    30,
    (index) => DateTime.now().year + 1 - index,
  );

  // دالة محاكاة "مسح الباركود"
  void scanVinCode() {
    vinController.text =
        "SALWA${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";
    notifyListeners();
  }

  // ✅ دالة الحفظ الحقيقية في الفايربيز
  Future<void> saveCar(BuildContext context) async {
    // 1. التحقق من صحة المدخلات
    if (formKey.currentState!.validate()) {
      if (selectedMake == null || selectedYear == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("يرجى اختيار الشركة وسنة الصنع")),
        );
        return;
      }

      _isLoading = true;
      notifyListeners();

      try {
        // 2. تنظيف رقم الجوال (إزالة المسافات لضمان المطابقة)
        String cleanPhone = clientPhoneController.text.trim().replaceAll(
          ' ',
          '',
        );

        // 3. تجهيز البيانات للإرسال
        // ملاحظة: نستخدم رقم الهيكل (VIN) كـ ID للمستند لمنع تكرار نفس السيارة
        final carData = {
          'vin': vinController.text.toUpperCase(),
          'plate': plateController.text,
          'make': selectedMake,
          'model': modelController.text,
          'year': selectedYear,
          'currentKm': int.tryParse(kmController.text) ?? 0,
          'ownerPhone': cleanPhone, // 👈 هذا هو الرابط مع العميل
          'addedByWorkshop': true, // للعلم أن الورشة هي من أضافتها
          'lastServiceDate': FieldValue.serverTimestamp(), // تاريخ الإضافة
          'createdAt': FieldValue.serverTimestamp(),
        };

        // 4. الحفظ في مجموعة 'cars'
        // نستخدم set بدلاً من add لضمان عدم تكرار السيارة بنفس رقم الهيكل
        await FirebaseFirestore.instance
            .collection('cars')
            .doc(vinController.text.toUpperCase())
            .set(carData);

        _isLoading = false;
        notifyListeners();

        // 5. رسالة نجاح والخروج
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ تم إضافة السيارة وربطها بالعميل بنجاح!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // العودة
        }
      } catch (e) {
        _isLoading = false;
        notifyListeners();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("حدث خطأ: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    vinController.dispose();
    plateController.dispose();
    modelController.dispose();
    kmController.dispose();
    clientPhoneController.dispose();
    super.dispose();
  }
}
