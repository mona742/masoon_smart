import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../colors.dart'; // لاستيراد الألوان
import 'booking_screen.dart';
import 'client_dashboard.dart'; // لاستيراد الموديل ServiceItem

class ServiceDetailsScreen extends StatelessWidget {
  final ServiceItem service;

  const ServiceDetailsScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    // 1. حسابات العرض (الذكاء)
    // نفترض أن العميل يمشي متوسط 100 كم يومياً
    double dailyUsageKm = 100.0;

    // ملاحظة: هنا يجب تمرير العداد الحالي الحقيقي من الصفحة السابقة في المستقبل
    double currentOdometer = 50000.0;

    double drivenDistance = currentOdometer - service.lastChangeKm;
    double remainingKm = service.limitKm - drivenDistance;
    int remainingDays = (remainingKm / dailyUsageKm).ceil();
    double progress = (drivenDistance / service.limitKm).clamp(0.0, 1.0);

    // تحديد حالة الخدمة
    bool isUrgent = remainingKm <= 0;
    Color statusColor = isUrgent
        ? AppColors.danger
        : (progress > 0.8 ? AppColors.secondary : AppColors.primary);
    String statusMessage = isUrgent
        ? "تجاوزت الحد المسموح! يرجى الصيانة فوراً."
        : "حالتك ممتازة، متبقى لك حوالي $remainingDays يوم.";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          service.name,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.cardBg,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. رأس الصفحة (الأيقونة والعداد) ---
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(service.icon, size: 50, color: statusColor),
                ),
              ),
              const SizedBox(height: 15),
              Center(
                child: Column(
                  children: [
                    Text(
                      "${drivenDistance.toInt()} / ${service.limitKm.toInt()} كم",
                      style: GoogleFonts.tajawal(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      "المسافة المستهلكة",
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // --- شريط التقدم ---
              LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: Colors.grey[200],
                color: statusColor,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 10),
              Text(
                statusMessage,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),

              const SizedBox(height: 30),

              // --- 2. بطاقة التفاصيل الفنية (الديناميكية) ---
              Text(
                "المواصفات الفنية",
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
                  color: AppColors.cardBg,
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
                    // هذه البيانات ثابتة لكل الخدمات
                    _buildDetailRow(
                      Icons.calendar_today,
                      "تاريخ آخر تغيير",
                      service.lastChangeDate,
                    ),
                    const Divider(height: 25),
                    _buildDetailRow(
                      Icons.speed,
                      "عداد عند التغيير",
                      "${service.lastChangeKm.toInt()} كم",
                    ),
                    const Divider(height: 25),

                    // --- هنا السحر: توليد التفاصيل بناءً على نوع الخدمة ---
                    // هذا الكود يقرأ الـ Map (مثل تفاصيل الفرامل) ويعرضها سطراً سطراً
                    ...service.detailsMap.entries.map((entry) {
                      return Column(
                        children: [
                          _buildDetailRow(
                            Icons.info_outline,
                            entry.key,
                            entry.value,
                          ),
                          const Divider(height: 25),
                        ],
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- 3. زر الإجراء ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // ✅ الانتقال لشاشة الحجز وتمرير اسم الخدمة
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            BookingScreen(serviceName: service.name),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.calendar_month),
                  label: Text(
                    "حجز موعد صيانة",
                    style: GoogleFonts.cairo(
                      fontSize: 15,
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

  // دالة مساعدة لبناء الصفوف
  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textLight, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textLight),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
