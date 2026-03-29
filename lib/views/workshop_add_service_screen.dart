import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import '../colors.dart';

class WorkshopAddServiceScreen extends StatefulWidget {
  final Map<String, dynamic>? carData;
  final String? workshopId;

  const WorkshopAddServiceScreen({super.key, this.carData, this.workshopId});

  @override
  State<WorkshopAddServiceScreen> createState() =>
      _WorkshopAddServiceScreenState();
}

class _WorkshopAddServiceScreenState extends State<WorkshopAddServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // الحقول الأساسية
  final TextEditingController _vinController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _odometerController = TextEditingController();
  final TextEditingController _makeController = TextEditingController();

  // ✅ الحقول الجديدة
  final TextEditingController _clientNameController =
      TextEditingController(); // اسم العميل
  final TextEditingController _priceController =
      TextEditingController(); // السعر

  String _fullPhoneNumber = "";
  String _selectedServiceType = 'oil';
  bool _isPreFilled = false;
  final Map<String, String> _dynamicValues = {};

  final List<Map<String, dynamic>> _serviceTypes = [
    {'id': 'oil', 'name': 'تغيير زيت', 'icon': Icons.water_drop},
    {'id': 'tires', 'name': 'تغيير إطارات', 'icon': Icons.tire_repair},
    {'id': 'brakes', 'name': 'صيانة فرامل', 'icon': Icons.car_crash},
    {'id': 'ac', 'name': 'صيانة تكييف', 'icon': Icons.ac_unit},
    {'id': 'check', 'name': 'فحص شامل', 'icon': Icons.checklist},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.carData != null) {
      _isPreFilled = true;
      _vinController.text = widget.carData!['vin'] ?? '';
      _plateController.text = widget.carData!['plate'] ?? '';
      _makeController.text = widget.carData!['make'] ?? '';
      _fullPhoneNumber = widget.carData!['ownerPhone'] ?? '';

      // ✅ جلب اسم العميل إذا كان مسجلاً سابقاً
      _clientNameController.text = widget.carData!['clientName'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          "تسجيل خدمة وصيانة",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isPreFilled)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "تم جلب بيانات السيارة للعميل بنجاح",
                                style: GoogleFonts.cairo(
                                  color: Colors.green[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    _buildSectionTitle("1. بيانات العميل"),

                    // رقم الجوال
                    _isPreFilled
                        ? _buildReadOnlyField(
                            "رقم الجوال",
                            _fullPhoneNumber,
                            Icons.phone,
                          )
                        : IntlPhoneField(
                            decoration: const InputDecoration(
                              labelText: 'رقم جوال العميل',
                              border: OutlineInputBorder(),
                            ),
                            initialCountryCode: 'SA',
                            languageCode: "ar",
                            onChanged: (phone) {
                              _fullPhoneNumber = phone.completeNumber
                                  .trim()
                                  .replaceAll(' ', '');
                            },
                          ),
                    const SizedBox(height: 15),

                    // ✅ حقل اسم العميل
                    TextFormField(
                      controller: _clientNameController,
                      decoration: InputDecoration(
                        labelText: "اسم العميل",
                        hintText: "الاسم الكريم",
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (val) =>
                          val!.isEmpty ? "اسم العميل مطلوب" : null,
                    ),

                    const SizedBox(height: 25),
                    _buildSectionTitle("2. بيانات المركبة"),

                    TextFormField(
                      controller: _vinController,
                      readOnly: _isPreFilled,
                      decoration: InputDecoration(
                        labelText: "رقم الهيكل (VIN)",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: _isPreFilled,
                        fillColor: _isPreFilled ? Colors.grey[200] : null,
                        suffixIcon: _isPreFilled
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.qr_code_scanner),
                                onPressed: () {
                                  setState(() {
                                    _vinController.text =
                                        "VIN${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";
                                  });
                                },
                              ),
                      ),
                      validator: (val) => val!.isEmpty ? "مطلوب" : null,
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: _makeController,
                      readOnly: _isPreFilled,
                      decoration: InputDecoration(
                        labelText: "نوع السيارة",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: _isPreFilled,
                        fillColor: _isPreFilled ? Colors.grey[200] : null,
                      ),
                      validator: (val) => val!.isEmpty ? "مطلوب" : null,
                    ),
                    const SizedBox(height: 15),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _plateController,
                            label: "اللوحة",
                            icon: Icons.tag,
                            isReadOnly: _isPreFilled,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField(
                            controller: _odometerController,
                            label: "العداد (كم)",
                            icon: Icons.speed,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                    const Divider(thickness: 1),
                    const SizedBox(height: 10),

                    _buildSectionTitle("3. تفاصيل الخدمة"),

                    DropdownButtonFormField<String>(
                      value: _selectedServiceType,
                      decoration: InputDecoration(
                        labelText: "نوع الخدمة",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.miscellaneous_services),
                      ),
                      items: _serviceTypes
                          .map(
                            (e) => DropdownMenuItem(
                              value: e['id'] as String,
                              child: Text(e['name']),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedServiceType = val!;
                          _dynamicValues.clear();
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(children: _buildDynamicFields()),
                    ),

                    const SizedBox(height: 20),

                    // ✅✅✅ حقل السعر (تم تحديث الأيقونة لتكون ﷼)
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "تكلفة الخدمة",
                        // استخدام رمز الريال المدمج
                        suffixText: "﷼",
                        suffixStyle: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                        /*prefixIcon: const Icon(
                          Icons.monetization_on_outlined,
                          color: Colors.green,
                        ),*/
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        fillColor: Colors.green.withOpacity(0.05),
                        filled: true,
                      ),
                      validator: (val) =>
                          val!.isEmpty ? "يرجى تحديد السعر" : null,
                    ),

                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _saveToFirebase,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                        ),
                        label: Text(
                          "حفظ الفاتورة والخدمة",
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[200],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    bool isReadOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: isReadOnly,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: isReadOnly,
        fillColor: isReadOnly ? Colors.grey[200] : null,
      ),
      validator: (val) => val!.isEmpty ? "مطلوب" : null,
    );
  }

  List<Widget> _buildDynamicFields() {
    switch (_selectedServiceType) {
      case 'oil':
        return [
          _buildDynamicField("نوع الزيت", "مثال: 10W40"),
          const SizedBox(height: 10),
          _buildDynamicField("عدد اللترات", "مثال: 4.5"),
          const SizedBox(height: 10),
          _buildDynamicField("فلتر الزيت", "أصلي / تجاري"),
        ];
      case 'tires':
        return [
          _buildDynamicField("المقاس", "مثال: 215/60/17"),
          const SizedBox(height: 10),
          _buildDynamicField("النوع", "مثال: يابانى"),
        ];
      default:
        return [_buildDynamicField("ملاحظات", "تفاصيل الخدمة")];
    }
  }

  Widget _buildDynamicField(String label, String hint) {
    return TextFormField(
      onChanged: (val) => _dynamicValues[label] = val,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // Future<void> _saveToFirebase() async {
  //   if (!_formKey.currentState!.validate()) return;
  //   if (_fullPhoneNumber.isEmpty) {
  //     if (_isPreFilled && widget.carData != null) {
  //       _fullPhoneNumber = widget.carData!['ownerPhone'] ?? '';
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text("يرجى التأكد من رقم الجوال")),
  //       );
  //       return;
  //     }
  //   }
  //
  //   setState(() => _isLoading = true);
  //
  //   try {
  //     // ✅✅✅ توحيد حالة الأحرف (Uppercase) للبحث
  //     final String carId = _vinController.text.trim().toUpperCase();
  //     final double currentKm = double.parse(_odometerController.text);
  //
  //     final carDocRef = FirebaseFirestore.instance
  //         .collection('cars')
  //         .doc(carId);
  //
  //     // تحديث أو إنشاء السيارة
  //     await carDocRef.set({
  //       'vin': carId,
  //       'plate': _plateController.text,
  //       'ownerPhone': _fullPhoneNumber,
  //       'clientName': _clientNameController.text,
  //       'currentKm': currentKm,
  //       'make': _makeController.text,
  //       'lastServiceDate': FieldValue.serverTimestamp(),
  //     }, SetOptions(merge: true));
  //
  //     // تسجيل الخدمة
  //     final serviceData = ServiceModel(
  //       id: '',
  //       name: _getServiceName(_selectedServiceType),
  //       type: _selectedServiceType,
  //       limitKm: 5000,
  //       lastChangeKm: currentKm,
  //       lastChangeDate: DateTime.now(),
  //       details: _dynamicValues,
  //       workshopId: widget.workshopId ?? 'unknown',
  //       carId: carId, // سيتم حفظه Uppercase
  //     );
  //
  //     var serviceMap = serviceData.toMap();
  //     serviceMap['price'] = double.tryParse(_priceController.text) ?? 0.0;
  //     serviceMap['clientName'] = _clientNameController.text;
  //
  //     await FirebaseFirestore.instance.collection('services').add(serviceMap);
  //
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text("✅ تم حفظ الخدمة والفاتورة!"),
  //         backgroundColor: Colors.green,
  //       ),
  //     );
  //
  //     Navigator.pop(context);
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("خطأ: $e"), backgroundColor: Colors.red),
  //     );
  //   } finally {
  //     if (mounted) setState(() => _isLoading = false);
  //   }
  // }
  Future<void> _saveToFirebase() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fullPhoneNumber.isEmpty) {
      if (_isPreFilled && widget.carData != null) {
        _fullPhoneNumber = widget.carData!['ownerPhone'] ?? '';
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("يرجى التأكد من رقم الجوال")),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      // ✅ 1. تجهيز البيانات الأساسية
      final String carId = _vinController.text.trim().toUpperCase();
      final double currentKm = double.parse(_odometerController.text);
      final double servicePrice = double.tryParse(_priceController.text) ?? 0.0;

      // ✅ 2. تحديث بيانات السيارة (الممشى وتاريخ آخر صيانة)
      final carDocRef = FirebaseFirestore.instance
          .collection('cars')
          .doc(carId);

      await carDocRef.set({
        'vin': carId,
        'plate': _plateController.text,
        'ownerPhone': _fullPhoneNumber,
        'clientName': _clientNameController.text,
        'currentKm': currentKm, // ⚠️ تحديث الممشى الحالي
        'make': _makeController.text,
        'lastServiceDate':
            FieldValue.serverTimestamp(), // ⚠️ تحديث تاريخ آخر خدمة
      }, SetOptions(merge: true));

      // ✅ 3. تجهيز بيانات الخدمة الجديدة
      // نحدد العمر الافتراضي بناءً على نوع الخدمة (مهم جداً للعدادات الزمنية والمسافات)
      double limitKm = 0;
      int lifeSpanMonths = 0;

      if (_selectedServiceType == 'oil') {
        limitKm = 5000; // الافتراضي للزيت
        // إذا كان الفني أدخل قيمة معينة في التفاصيل، يمكننا استخدامها
        if (_dynamicValues.containsKey('نوع الزيت') &&
            _dynamicValues['نوع الزيت']!.contains('10000')) {
          limitKm = 10000;
        }
      } else if (_selectedServiceType == 'tires') {
        limitKm = 60000;
        lifeSpanMonths = 24;
      } else if (_selectedServiceType == 'brakes') {
        limitKm = 40000;
        lifeSpanMonths = 24;
      } else if (_selectedServiceType == 'ac') {
        lifeSpanMonths = 12;
      }

      // ✅ 4. حفظ الخدمة في الفايربيز
      Map<String, dynamic> serviceMap = {
        'name': _getServiceName(_selectedServiceType),
        'type': _selectedServiceType,
        'limitKm': limitKm,
        'lifeSpanMonths': lifeSpanMonths, // للعدادات الزمنية
        'lastChangeKm':
            currentKm, // ⚠️⚠️⚠️ هذه هي النقطة التي تصفر عداد الزيت للعميل!
        'lastChangeDate': FieldValue.serverTimestamp(), // لتصفير العداد الزمني
        'details': _dynamicValues,
        'workshopId': widget.workshopId ?? 'unknown',
        'carId': carId,
        'price': servicePrice,
        'clientName': _clientNameController.text,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('services').add(serviceMap);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ تم حفظ الخدمة وتحديث عدادات العميل!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      case 'check':
        return 'فحص شامل';
      default:
        return 'خدمة عامة';
    }
  }
}
