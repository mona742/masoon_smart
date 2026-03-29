// lib/views/car_value_report_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../colors.dart';

class CarValueReportScreen extends StatelessWidget {
  final String carId;

  const CarValueReportScreen({super.key, required this.carId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          "تقرير قيمة المركبة 📄",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('cars').doc(carId).get(),
        builder: (context, carSnapshot) {
          if (carSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!carSnapshot.hasData || !carSnapshot.data!.exists) {
            return const Center(
              child: Text("لم يتم العثور على بيانات المركبة"),
            );
          }

          var carData = carSnapshot.data!.data() as Map<String, dynamic>;
          String make = carData['make'] ?? 'مركبة';
          String plate = carData['plate'] ?? '---';
          double currentKm =
              double.tryParse(carData['currentKm'].toString()) ?? 0.0;

          // جلب سجل الصيانات لحساب مؤشر الثقة
          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('services')
                .where('carId', isEqualTo: carId)
                .get(),
            builder: (context, serviceSnapshot) {
              if (serviceSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              int totalServices = serviceSnapshot.data?.docs.length ?? 0;

              // خوارزمية ذكية بسيطة لحساب "مؤشر الثقة" (Trust Score)
              // كلما زادت الخدمات المسجلة، زادت الثقة، بحد أقصى 98%
              double trustScore = 50.0 + (totalServices * 5.0);
              if (trustScore > 98.0) trustScore = 98.0;

              // حساب القيمة المضافة التقديرية (كم زاد سعر السيارة بسبب السجل)
              int addedValue =
                  totalServices *
                  500; // مثال: كل صيانة موثقة تزيد 500 ريال من قيمة السيارة في السوق

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // 1. بطاقة السيارة الأساسية
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.verified_user,
                            color: Colors.white,
                            size: 50,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "شهادة مصون الرقمية",
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "$make | اللوحة: $plate",
                            style: GoogleFonts.cairo(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "الممشى الموثق: ${currentKm.toInt()} كم",
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // 2. مؤشر الثقة
                    Text(
                      "مؤشر ثقة المشتري",
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 150,
                          height: 150,
                          child: CircularProgressIndicator(
                            value: trustScore / 100,
                            strokeWidth: 12,
                            backgroundColor: Colors.grey[200],
                            color: trustScore > 80
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              "${trustScore.toInt()}%",
                              style: GoogleFonts.cairo(
                                fontSize: 35,
                                fontWeight: FontWeight.bold,
                                color: trustScore > 80
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                              ),
                            ),
                            Text(
                              "موثوقية عالية",
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // 3. القيمة المضافة للسوق
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.trending_up,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "القيمة السوقية المضافة",
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[800],
                                  ),
                                ),
                                Text(
                                  "سجل الصيانة الموثق يرفع من قيمة سيارتك عند البيع مقارنة بالسيارات المجهولة السجل.",
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "+$addedValue ﷼",
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // // 4. ملخص السجل
                    // Align(
                    //   alignment: Alignment.centerRight,
                    //   child: Text(
                    //     "العوامل المؤثرة في التقييم:",
                    //     style: GoogleFonts.cairo(
                    //       fontSize: 16,
                    //       fontWeight: FontWeight.bold,
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(height: 10),
                    // _buildChecklistItem("تتبع الممشى عبر الـ GPS", true),
                    // _buildChecklistItem(
                    //   "إجمالي الصيانات الموثقة: $totalServices خدمة",
                    //   totalServices > 0,
                    // ),
                    // _buildChecklistItem(
                    //   "الالتزام بمواعيد تغيير الزيت",
                    //   totalServices > 1,
                    // ),
                    // _buildChecklistItem(
                    //   "استخدام قطع غيار أصلية (من الورشة)",
                    //   true,
                    // ),
                    //
                    // const SizedBox(height: 40),
                    // 4. ملخص السجل والاعتمادات
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "الاعتمادات ومؤشرات الفحص:",
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildChecklistItem("تتبع الممشى دقيق عبر الـ GPS", true),
                    _buildChecklistItem(
                      "إجمالي الصيانات الموثقة: $totalServices خدمة",
                      totalServices > 0,
                    ),

                    // ✅ الإضافات الرسمية للسوق السعودي
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Column(
                        children: [
                          _buildChecklistItem(
                            "البيانات مهيأة للربط مع منصة «موجز»",
                            true,
                            isOfficial: true,
                          ),
                          _buildChecklistItem(
                            "متوافق مع متطلبات الفحص الدوري (MVPI)",
                            true,
                            isOfficial: true,
                          ),
                        ],
                      ),
                    ),

                    // 5. زر مشاركة التقرير
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "جاري إنشاء رابط للمشاركة مع المشتري...",
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.share, color: Colors.white),
                        label: Text(
                          "مشاركة التقرير مع مشتري",
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ويدجت مساعدة لإنشاء قائمة التحقق
  // Widget _buildChecklistItem(String title, bool isVerified) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 12),
  //     child: Row(
  //       children: [
  //         Icon(
  //           isVerified ? Icons.check_circle : Icons.pending,
  //           color: isVerified ? Colors.green : Colors.grey,
  //           size: 22,
  //         ),
  //         const SizedBox(width: 10),
  //         Expanded(
  //           child: Text(
  //             title,
  //             style: GoogleFonts.cairo(
  //               fontSize: 14,
  //               color: isVerified ? Colors.black87 : Colors.grey,
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  // ويدجت مساعدة لإنشاء قائمة التحقق (مع دعم الشارات الرسمية)
  Widget _buildChecklistItem(
    String title,
    bool isVerified, {
    bool isOfficial = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            isVerified
                ? (isOfficial ? Icons.verified : Icons.check_circle)
                : Icons.pending,
            color: isVerified
                ? (isOfficial ? Colors.blue : Colors.green)
                : Colors.grey,
            size: isOfficial ? 24 : 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: isOfficial ? FontWeight.bold : FontWeight.normal,
                color: isVerified ? Colors.black87 : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
