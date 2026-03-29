import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart'; // ✅ المكتبة المهمة
import 'package:provider/provider.dart';

import '../viewmodels/add_car_vm.dart';

class AddCarScreen extends StatelessWidget {
  const AddCarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddCarViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "إضافة سيارة عميل",
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        backgroundColor: Colors.grey[50],
        body: Consumer<AddCarViewModel>(
          builder: (context, vm, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: vm.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === قسم 1: بيانات العميل (الرابط الأساسي) ===
                    const Text(
                      "بيانات العميل (لمن تتبع السيارة؟)",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ✅ حقل رقم جوال العميل
                    IntlPhoneField(
                      controller: vm.clientPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'رقم جوال العميل',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                      initialCountryCode: 'SA', // السعودية افتراضي
                      languageCode: "ar",
                      disableLengthCheck: false,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(
                          9,
                        ), // 9 أرقام (5xxxxxxxx)
                      ],
                      onChanged: (phone) {
                        // هنا ممكن نضيف تحقق إضافي لو احتجنا
                      },
                    ),

                    const Divider(height: 30, thickness: 1),

                    // === قسم 2: بيانات المركبة ===
                    const Text(
                      "بيانات المركبة",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // رقم الهيكل مع زر المسح
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: vm.vinController,
                            decoration: InputDecoration(
                              labelText: "رقم الهيكل (VIN)",
                              hintText: "موجود على الاستمارة",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              prefixIcon: const Icon(
                                Icons.confirmation_number_outlined,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.length < 5)
                                return 'رقم الهيكل قصير جداً';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: vm.scanVinCode,
                          child: Container(
                            height: 55,
                            width: 55,
                            decoration: BoxDecoration(
                              color: Colors.blueGrey[800],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "يمكنك استخدام الزر الجانبي لمسح الباركود 📷",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),

                    const SizedBox(height: 20),

                    // الشركة والموديل
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: vm.selectedMake,
                            decoration: InputDecoration(
                              labelText: "الشركة",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items: vm.carMakes
                                .map(
                                  (make) => DropdownMenuItem(
                                    value: make,
                                    child: Text(make),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) => vm.selectedMake = val,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: TextFormField(
                            controller: vm.modelController,
                            decoration: InputDecoration(
                              labelText: "الموديل (مثال: كامري)",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator: (val) => val!.isEmpty ? 'مطلوب' : null,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // السنة ورقم اللوحة
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<int>(
                            value: vm.selectedYear,
                            decoration: InputDecoration(
                              labelText: "السنة",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items: vm.years
                                .map(
                                  (year) => DropdownMenuItem(
                                    value: year,
                                    child: Text(year.toString()),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) => vm.selectedYear = val,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: vm.plateController,
                            decoration: InputDecoration(
                              labelText: "رقم اللوحة",
                              prefixIcon: const Icon(Icons.abc),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // العداد الحالي
                    TextFormField(
                      controller: vm.kmController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "قراءة العداد الحالية (كم)",
                        suffixText: "كم",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.speed),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                      validator: (val) =>
                          val!.isEmpty ? 'يرجى إدخال العداد' : null,
                    ),

                    const SizedBox(height: 40),

                    // زر الحفظ
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        // ✅ ربط الزر بحالة التحميل
                        onPressed: vm.isLoading
                            ? null
                            : () => vm.saveCar(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                        ),
                        child: vm.isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                "حفظ السيارة",
                                style: GoogleFonts.cairo(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
