import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id; // معرف الحجز
  final String serviceName; // اسم الخدمة (زيت، فرامل..)
  final String clientName; // اسم العميل
  final String plateNumber; // رقم اللوحة (للربط)
  final DateTime bookingDate; // تاريخ الموعد المختار
  final String bookingTime; // الوقت المختار (مثلاً 09:00 ص)
  final String notes; // ملاحظات العميل
  final String status; // حالة الطلب (pending, confirmed, completed, cancelled)
  final DateTime createdAt; // متى تم إنشاء الطلب

  BookingModel({
    required this.id,
    required this.serviceName,
    required this.clientName,
    required this.plateNumber,
    required this.bookingDate,
    required this.bookingTime,
    required this.notes,
    required this.status,
    required this.createdAt,
  });

  // تحويل البيانات إلى خريطة لإرسالها للفايربيز
  Map<String, dynamic> toMap() {
    return {
      'serviceName': serviceName,
      'clientName': clientName,
      'plateNumber': plateNumber,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'bookingTime': bookingTime,
      'notes': notes,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // قراءة البيانات من الفايربيز (سنحتاجها لاحقاً للورشة)
  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      serviceName: data['serviceName'] ?? '',
      clientName: data['clientName'] ?? '',
      plateNumber: data['plateNumber'] ?? '',
      bookingDate: (data['bookingDate'] as Timestamp).toDate(),
      bookingTime: data['bookingTime'] ?? '',
      notes: data['notes'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
