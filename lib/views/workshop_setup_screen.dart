import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';

import '../viewmodels/workshop_profile_vm.dart';

class WorkshopSetupScreen extends StatelessWidget {
  // ✅ استقبال المعرف من الصفحة السابقة
  final String uid;

  const WorkshopSetupScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WorkshopProfileViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "إعداد ملف الورشة",
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Consumer<WorkshopProfileViewModel>(
          builder: (context, vm, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(
                    Icons.storefront,
                    size: 80,
                    color: Colors.blueGrey,
                  ),
                  const SizedBox(height: 20),

                  // اسم الورشة
                  TextField(
                    controller: vm.nameController,
                    decoration: const InputDecoration(
                      labelText: "اسم الورشة",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // التخصص
                  DropdownButtonFormField<String>(
                    value: vm.selectedSpecialty,
                    hint: const Text("التخصص"),
                    items: vm.specialties
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: vm.setSpecialty,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // المنطقة
                  DropdownButtonFormField<int>(
                    value: vm.selectedRegionId,
                    hint: const Text("المنطقة"),
                    items: vm.regionsList
                        .map(
                          (e) => DropdownMenuItem<int>(
                            value: e['id'],
                            child: Text(e['name']),
                          ),
                        )
                        .toList(),
                    onChanged: vm.setRegion,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // المدينة
                  DropdownButtonFormField<String>(
                    value: vm.selectedCity,
                    hint: const Text("المدينة"),
                    items: vm.filteredCities
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: vm.filteredCities.isEmpty ? null : vm.setCity,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // الحي (يدوي)
                  TextField(
                    controller: vm.districtController,
                    decoration: const InputDecoration(
                      labelText: "اسم الحي",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // رقم التواصل (للعرض)
                  IntlPhoneField(
                    decoration: const InputDecoration(
                      labelText: 'رقم الهاتف للتواصل',
                      border: OutlineInputBorder(),
                    ),
                    initialCountryCode: 'SA',
                    languageCode: "ar",
                    onChanged: (phone) {
                      try {
                        vm.updatePhone(
                          phone.completeNumber,
                          phone.isValidNumber(),
                        );
                      } catch (e) {}
                    },
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton(
                      // ✅ نمرر الـ uid هنا لدالة الحفظ
                      onPressed: vm.isLoading
                          ? null
                          : () => vm.saveWorkshopData(context, uid),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey[800],
                        foregroundColor: Colors.white,
                      ),
                      child: vm.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "حفظ وبدء العمل",
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
