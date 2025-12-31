import 'package:flutter/material.dart';

class AddCarViewModel extends ChangeNotifier {
  // مفتاح النموذج للتحقق من صحة البيانات
  final formKey = GlobalKey<FormState>();

  // الحقول النصية
  final vinController = TextEditingController();
  final plateController = TextEditingController();
  final modelController = TextEditingController();
  final kmController = TextEditingController();

  // القوائم المنسدلة (Dropdowns)
  String? selectedMake;
  int? selectedYear;

  // بيانات ثابتة للقوائم (لاحقاً تأتي من قاعدة البيانات)
  final List<String> carMakes = [
    'تويوتا',
    'هيونداي',
    'فورد',
    'نيسان',
    'مازدا',
    'هوندا',
    'مرسيدس',
    'بي إم دبليو',
  ];
  final List<int> years = List.generate(
    30,
    (index) => DateTime.now().year - index + 1,
  ); // من السنة القادمة وتنازلياً

  // دالة محاكاة "مسح الباركود" لرقم الهيكل
  void scanVinCode() {
    // هنا سنضع كود الكاميرا لاحقاً، حالياً سنضع قيمة وهمية للتجربة
    vinController.text = "SALWA2548H123456";
    notifyListeners();
  }

  // دالة الحفظ
  void saveCar(BuildContext context) {
    if (formKey.currentState!.validate()) {
      if (selectedMake == null || selectedYear == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("يرجى اختيار الشركة وسنة الصنع")),
        );
        return;
      }

      // محاكاة الإرسال للسيرفر
      // final car = Car(.....)

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("تم إضافة السيارة بنجاح! 🚗"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context); // الرجوع للشاشة السابقة
    }
  }

  // تنظيف الحقول عند الخروج
  @override
  void dispose() {
    vinController.dispose();
    plateController.dispose();
    modelController.dispose();
    kmController.dispose();
    super.dispose();
  }
}
