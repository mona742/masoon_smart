import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String serviceName;
  final String clientName;
  final String plateNumber;
  final String workshopId; // ✅ أضفنا معرف الورشة لكي تستلم الطلب
  final DateTime bookingDate;
  final String bookingTime;
  final String notes;
  final String status;
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.serviceName,
    required this.clientName,
    required this.plateNumber,
    required this.workshopId, // ✅ إجباري
    required this.bookingDate,
    required this.bookingTime,
    required this.notes,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'serviceName': serviceName,
      'clientName': clientName,
      'plateNumber': plateNumber,
      'workshopId': workshopId, // ✅ للحفظ في الداتا بيز
      'bookingDate': Timestamp.fromDate(bookingDate),
      'bookingTime': bookingTime,
      'notes': notes,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      serviceName: data['serviceName'] ?? '',
      clientName: data['clientName'] ?? '',
      plateNumber: data['plateNumber'] ?? '',
      workshopId: data['workshopId'] ?? '', // ✅ للقراءة
      bookingDate: (data['bookingDate'] as Timestamp).toDate(),
      bookingTime: data['bookingTime'] ?? '',
      notes: data['notes'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
