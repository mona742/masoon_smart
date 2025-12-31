import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ استيراد الفايربيز
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../colors.dart';
import '../models/service_model.dart'; // ✅ استيراد الموديل الموحد

class WorkshopAddServiceScreen extends StatefulWidget {
  const WorkshopAddServiceScreen({super.key});

  @override
  State<WorkshopAddServiceScreen> createState() =>
      _WorkshopAddServiceScreenState();
}

class _WorkshopAddServiceScreenState extends State<WorkshopAddServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false; // ✅ حالة التحميل (لإظهار الانتظار)

  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _odometerController = TextEditingController();

  String _selectedServiceType = 'oil';
  final Map<String, String> _dynamicValues = {};

  final List<Map<String, dynamic>> _serviceTypes = [
    {'id': 'oil', 'name': 'تغيير زيت', 'icon': Icons.water_drop},
    {'id': 'tires', 'name': 'تغيير إطارات', 'icon': Icons.tire_repair},
    {'id': 'brakes', 'name': 'صيانة فرامل', 'icon': Icons.car_crash},
    {'id': 'ac', 'name': 'صيانة تكييف', 'icon': Icons.ac_unit},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          "تسجيل خدمة جديدة",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.cardBg,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ) // ✅ إظهار التحميل
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("1. بيانات السيارة"),
                    _buildTextField(
                      controller: _plateController,
                      label: "رقم اللوحة",
                      icon: Icons.directions_car,
                      hint: "أ ب ج 1234",
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: _odometerController,
                      label: "قراءة العداد الحالية (كم)",
                      icon: Icons.speed,
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 30),

                    _buildSectionTitle("2. تفاصيل الخدمة"),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedServiceType,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.arrow_drop_down_circle,
                            color: AppColors.primary,
                          ),
                          items: _serviceTypes.map<DropdownMenuItem<String>>((
                            service,
                          ) {
                            return DropdownMenuItem<String>(
                              value: service['id'] as String,
                              child: Row(
                                children: [
                                  Icon(
                                    service['icon'] as IconData,
                                    color: AppColors.secondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    service['name'] as String,
                                    style: GoogleFonts.cairo(fontSize: 16),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedServiceType = val!;
                              _dynamicValues.clear();
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(children: _buildDynamicFields()),
                    ),

                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed:
                            _saveServiceToFirebase, // ✅ استدعاء دالة الفايربيز
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.cloud_upload),
                        label: Text(
                          "حفظ في قاعدة البيانات",
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _buildDynamicFields() {
    switch (_selectedServiceType) {
      case 'oil':
        return [
          _buildDynamicTextField("نوع الزيت", "مثال: Castrol 10W40"),
          const SizedBox(height: 15),
          _buildDynamicTextField("كمية الزيت (لتر)", "مثال: 4.5"),
          const SizedBox(height: 15),
          _buildDynamicTextField("فلتر الزيت", "مثال: أصلي / تجاري"),
        ];
      case 'tires':
        return [
          _buildDynamicTextField("ماركة الإطارات", "مثال: Hankook"),
          const SizedBox(height: 15),
          _buildDynamicTextField("المقاس", "مثال: 215/55R17"),
          const SizedBox(height: 15),
          _buildDynamicTextField("تاريخ الإنتاج", "مثال: 4022"),
        ];
      case 'brakes':
        return [
          _buildDynamicTextField("نوع الفحمات", "مثال: سيراميك"),
          const SizedBox(height: 15),
          _buildDynamicTextField("حالة الهوبات", "مثال: تم الخرط"),
          const SizedBox(height: 15),
          _buildDynamicTextField("جهة العمل", "مثال: أمامي فقط"),
        ];
      case 'ac':
        return [
          _buildDynamicTextField("نوع الفلتر", "مثال: فحم نشط"),
          const SizedBox(height: 15),
          _buildDynamicTextField("خدمات إضافية", "مثال: تنظيف الثلاجة"),
        ];
      default:
        return [const Text("لا توجد تفاصيل إضافية")];
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textLight,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: (val) => val!.isEmpty ? "هذا الحقل مطلوب" : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
        prefixIcon: icon != null
            ? Icon(icon, color: AppColors.secondary)
            : null,
        filled: true,
        fillColor: AppColors.cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDynamicTextField(String label, String hint) {
    return TextFormField(
      onChanged: (val) => _dynamicValues[label] = val,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }

  // ✅ الدالة الحقيقية للحفظ في Firebase
  Future<void> _saveServiceToFirebase() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true); // بدء التحميل

      try {
        // 1. تجهيز البيانات
        // ملاحظة: نستخدم رقم اللوحة مؤقتاً كمعرف للسيارة للربط
        final serviceData = ServiceModel(
          id: '', // سيتم توليده تلقائياً
          name: _getServiceName(_selectedServiceType),
          type: _selectedServiceType,
          limitKm: _selectedServiceType == 'oil'
              ? 5000
              : 60000, // قيم افتراضية ذكية
          lastChangeKm: double.parse(_odometerController.text),
          lastChangeDate: DateTime.now(),
          details: _dynamicValues,
          workshopId: 'workshop_01', // معرف الورشة (ثابت حالياً)
          carId: _plateController.text, // الربط برقم اللوحة
        );

        // 2. الإرسال إلى Firestore
        await FirebaseFirestore.instance
            .collection('services')
            .add(serviceData.toMap());

        if (!mounted) return;

        // 3. نجاح العملية
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "✅ تم الحفظ في السحابة بنجاح!",
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // العودة
      } catch (e) {
        // 4. معالجة الأخطاء
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ حدث خطأ: $e", style: GoogleFonts.cairo()),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false); // إيقاف التحميل
      }
    }
  }

  String _getServiceName(String type) {
    switch (type) {
      case 'oil':
        return 'زيت المحرك';
      case 'tires':
        return 'الإطارات';
      case 'brakes':
        return 'الفرامل';
      case 'ac':
        return 'فلتر المكيف';
      default:
        return 'خدمة عامة';
    }
  }
}
