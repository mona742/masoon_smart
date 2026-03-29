import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../colors.dart';
import 'booking_screen.dart';

class ServiceDetailsScreen extends StatelessWidget {
  // نستقبل بيانات الخدمة (الثابتة) ومعرف السيارة (لمراقبة العداد المتغير)
  final Map<String, dynamic> serviceData;
  final String carId;

  const ServiceDetailsScreen({
    super.key,
    required this.serviceData,
    required this.carId,
  });

  @override
  Widget build(BuildContext context) {
    // 1. استخراج بيانات الخدمة الأساسية
    double lastChangeKm =
        double.tryParse(serviceData['lastChangeKm'].toString()) ?? 0.0;
    double limitKm =
        double.tryParse(serviceData['limitKm'].toString()) ?? 5000.0;
    String serviceName = serviceData['name'] ?? 'خدمة';
    String serviceType = serviceData['type'] ?? 'other';

    // تنسيق التاريخ
    String lastDateStr = "---";
    if (serviceData['lastChangeDate'] != null) {
      lastDateStr = DateFormat(
        'yyyy-MM-dd',
      ).format((serviceData['lastChangeDate'] as Timestamp).toDate());
    }

    // تفاصيل إضافية (مثل نوع الزيت)
    Map<String, dynamic> details = serviceData['details'] ?? {};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          serviceName,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      // 📡 2. StreamBuilder: يراقب عداد السيارة الحي من الفايربيز
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('cars')
            .doc(carId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("خطأ: السيارة غير موجودة"));
          }

          // ✅ جلب العداد الحي (الذي سيحدثه الـ GPS لاحقاً أو الورشة)
          var carData = snapshot.data!.data() as Map<String, dynamic>;
          double currentOdometer =
              double.tryParse(carData['currentKm'].toString()) ?? 0.0;

          // 🧮 3. الحسابات الذكية الحية
          double drivenDistance = currentOdometer - lastChangeKm;
          if (drivenDistance < 0)
            drivenDistance = 0; // حماية من الأرقام السالبة

          double remainingKm = limitKm - drivenDistance;
          double progress = (drivenDistance / limitKm).clamp(
            0.0,
            1.0,
          ); // نسبة من 0 إلى 1

          // تحديد الحالة والألوان
          bool isUrgent = remainingKm <= 0;
          Color statusColor = isUrgent
              ? AppColors.danger
              : (progress > 0.8 ? Colors.orange : AppColors.primary);

          String statusMessage = isUrgent
              ? "⚠️ تجاوزت الحد المسموح! يجب الصيانة فوراً."
              : (progress > 0.8
                    ? "⚠️ اقترب موعد الصيانة!"
                    : "✅ الحالة ممتازة، الطريق أمامك.");

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. رأس الصفحة (العداد الحي الدائري) ---
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 160,
                          height: 160,
                          child: CircularProgressIndicator(
                            value: 1.0 - progress, // نعرض المتبقي
                            strokeWidth: 12,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              statusColor,
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            Icon(
                              _getIcon(serviceType),
                              size: 40,
                              color: statusColor,
                            ),
                            const SizedBox(height: 5),
                            // النسبة المئوية المتبقية
                            Text(
                              "${((1.0 - progress) * 100).toInt()}%",
                              style: GoogleFonts.tajawal(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                            Text(
                              "متبقي من العمر",
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // رسالة الحالة
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      statusMessage,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- 2. المواصفات الفنية والتفاصيل ---
                  Text(
                    "تفاصيل الخدمة",
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          Icons.calendar_today,
                          "تاريخ التغيير",
                          lastDateStr,
                        ),
                        const Divider(height: 25),
                        _buildDetailRow(
                          Icons.speed,
                          "العداد عند التغيير",
                          "${lastChangeKm.toInt()} كم",
                        ),
                        const Divider(height: 25),
                        // هذا الرقم يتحدث تلقائياً
                        _buildDetailRow(
                          Icons.speed,
                          "العداد الحالي (Live)",
                          "${currentOdometer.toInt()} كم",
                          isLive: true,
                        ),
                        const Divider(height: 25),
                        _buildDetailRow(
                          Icons.timeline,
                          "المسافة المقطوعة",
                          "${drivenDistance.toInt()} كم",
                        ),

                        // التفاصيل الديناميكية (نوع الزيت، الماركة...)
                        if (details.isNotEmpty) ...[
                          const Divider(height: 25),
                          ...details.entries.map(
                            (e) => Column(
                              children: [
                                _buildDetailRow(
                                  Icons.info_outline,
                                  e.key,
                                  e.value.toString(),
                                ),
                                const SizedBox(height: 15),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- 3. زر الحجز ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // الانتقال لحجز موعد جديد لنفس الخدمة
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                BookingScreen(serviceName: serviceName),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isUrgent
                            ? AppColors.danger
                            : AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        "حجز موعد صيانة",
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // صف عرض المعلومات
  Widget _buildDetailRow(
    IconData icon,
    String title,
    String value, {
    bool isLive = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: isLive ? Colors.green : AppColors.textLight,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textLight),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isLive ? Colors.green : AppColors.textDark,
          ),
        ),
        if (isLive) ...[
          const SizedBox(width: 5),
          const Icon(
            Icons.radio_button_checked,
            size: 12,
            color: Colors.green,
          ), // إشارة Live
        ],
      ],
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'oil':
        return Icons.water_drop;
      case 'tires':
        return Icons.tire_repair;
      case 'brakes':
        return Icons.car_crash;
      case 'ac':
        return Icons.ac_unit;
      default:
        return Icons.build;
    }
  }
}
