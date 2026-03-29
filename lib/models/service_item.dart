import 'package:flutter/material.dart';

// هذا الموديل مخصص لواجهة عرض تفاصيل الخدمة (أيقونات، ألوان، نصوص)
class ServiceItem {
  final String name; // اسم الخدمة
  final IconData icon; // الأيقونة
  final Color color; // لون التمييز
  final String description; // وصف مختصر

  // الحقول الإضافية المطلوبة لشاشة التفاصيل
  final double lastChangeKm; // عداد آخر تغيير
  final double limitKm; // العمر الافتراضي (كم)
  final String lastChangeDate; // تاريخ آخر تغيير
  final Map<String, String> detailsMap; // تفاصيل فنية إضافية

  ServiceItem({
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
    this.lastChangeKm = 0.0, // قيمة افتراضية
    this.limitKm = 5000.0, // قيمة افتراضية
    this.lastChangeDate = '---', // قيمة افتراضية
    this.detailsMap = const {}, // قيمة افتراضية
  });
}
