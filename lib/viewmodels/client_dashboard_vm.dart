import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// هذا الكلاس يمثل "خدمة واحدة" (زيت، كفرات، فرامل...)
// سيتم استخدامه في تطبيق العميل للعرض، وفي تطبيق الورشة للإضافة والتعديل.

class ServiceModel {
  final String id; // المعرف في قاعدة البيانات (مثل: oil_123)
  final String name; // الاسم الظاهر (زيت المحرك)
  final String type; // النوع البرمجي (oil, tires, brakes, ac)
  final double limitKm; // العمر الافتراضي بالكيلومتر
  final double lastChangeKm; // قراءة العداد عند آخر تغيير
  final DateTime lastChangeDate; // تاريخ التغيير
  final Map<String, String> details; // التفاصيل الفنية (نوع الزيت، الماركة...)
  final String workshopId; // من هي الورشة التي قامت بالعمل؟
  final String carId; // تابعة لأي سيارة؟ (مهم جداً للربط)

  ServiceModel({
    required this.id,
    required this.name,
    required this.type,
    required this.limitKm,
    required this.lastChangeKm,
    required this.lastChangeDate,
    required this.details,
    required this.workshopId,
    required this.carId,
  });

  // 1. تحويل من Firebase (JSON) إلى كائن في التطبيق
  factory ServiceModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ServiceModel(
      id: doc.id,
      name: data['name'] ?? 'خدمة غير معروفة',
      type: data['type'] ?? 'other',
      limitKm: (data['limitKm'] ?? 0).toDouble(),
      lastChangeKm: (data['lastChangeKm'] ?? 0).toDouble(),
      lastChangeDate: (data['lastChangeDate'] as Timestamp).toDate(),
      details: Map<String, String>.from(data['details'] ?? {}),
      workshopId: data['workshopId'] ?? '',
      carId: data['carId'] ?? '',
    );
  }

  // 2. تحويل من التطبيق إلى Firebase (للحفظ)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'limitKm': limitKm,
      'lastChangeKm': lastChangeKm,
      'lastChangeDate': Timestamp.fromDate(lastChangeDate),
      'details': details,
      'workshopId': workshopId,
      'carId': carId,
    };
  }

  // دالة مساعدة للأيقونات (تستخدم في الـ View)
  IconData getIcon() {
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
