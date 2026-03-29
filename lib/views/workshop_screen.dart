// lib/views/workshop_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../viewmodels/smart_workshop_vm.dart';
import 'workshop_add_service_screen.dart'; // للانتقال لشاشة إضافة الخدمة

class WorkshopScreen extends StatefulWidget {
  const WorkshopScreen({super.key});

  @override
  State<WorkshopScreen> createState() => _WorkshopScreenState();
}

class _WorkshopScreenState extends State<WorkshopScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // استدعاء الـ ViewModel الحقيقي
    final vm = Provider.of<SmartWorkshopViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "لوحة الفني - بحث المركبات",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === 1. شريط البحث الحقيقي ===
            Text(
              "🔍 ابحث عن سيارة العميل:",
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "أدخل رقم الهيكل (VIN) هنا...",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Colors.blue),
                  onPressed: () {
                    // إغلاق لوحة المفاتيح
                    FocusScope.of(context).unfocus();
                    if (_searchController.text.isNotEmpty) {
                      // استدعاء دالة الفايربيز الحقيقية
                      vm.fetchCarDetails(
                        _searchController.text.trim().toUpperCase(),
                      );
                    }
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onSubmitted: (val) {
                if (val.isNotEmpty)
                  vm.fetchCarDetails(val.trim().toUpperCase());
              },
            ),

            const SizedBox(height: 30),

            // === 2. عرض النتائج أو حالة التحميل ===
            if (vm.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (vm.currentCar != null) ...[
              // بيانات السيارة التي تم العثور عليها
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.directions_car,
                            color: Colors.blueGrey,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "${vm.currentCar!['make']} | اللوحة: ${vm.currentCar!['plate']}",
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20, thickness: 1),
                      Text(
                        "العميل: ${vm.currentCar!['clientName'] ?? 'غير مسجل'}",
                        style: GoogleFonts.cairo(fontSize: 16),
                      ),
                      Text(
                        "الممشى الحالي (GPS): ${vm.currentCar!['currentKm']} كم",
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          color: Colors.blue[800],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // زر الانتقال لتسجيل صيانة حقيقية
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.build),
                          label: Text(
                            "تسجيل خدمة وصيانة",
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                // نمرر الداتا عشان ما يكتبها الفني من جديد
                                builder: (context) => WorkshopAddServiceScreen(
                                  carData: vm.currentCar,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // === 3. التنبيهات الذكية للورشة ===
              Text(
                "📊 حالة السيارة بناءً على سجل الفايربيز:",
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              if (vm.alerts.isEmpty)
                Text(
                  "لا توجد بيانات كافية.",
                  style: GoogleFonts.cairo(color: Colors.grey),
                )
              else
                ...vm.alerts
                    .map(
                      (alert) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: alert.contains("⚠️")
                              ? Colors.red[50]
                              : (alert.contains("✅")
                                    ? Colors.green[50]
                                    : Colors.blue[50]),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: alert.contains("⚠️")
                                ? Colors.red.shade200
                                : (alert.contains("✅")
                                      ? Colors.green.shade200
                                      : Colors.blue.shade200),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                alert,
                                style: GoogleFonts.cairo(
                                  color: alert.contains("⚠️")
                                      ? Colors.red[900]
                                      : Colors.black87,
                                  fontWeight: alert.contains("⚠️")
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
            ] else if (_searchController.text.isNotEmpty)
              Center(
                child: Text(
                  "لم يتم العثور على سيارة بهذا الرقم.",
                  style: GoogleFonts.cairo(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
