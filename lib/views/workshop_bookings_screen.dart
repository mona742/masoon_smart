import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../colors.dart';
import '../models/booking_model.dart'; // تأكد من وجود الموديل

class WorkshopBookingsScreen extends StatelessWidget {
  const WorkshopBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          "طلبات الحجز الواردة",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.cardBg,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // نستمع لجدول الحجوزات، ونرتبها حسب تاريخ الإنشاء (الأحدث أولاً)
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 60,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "لا توجد طلبات حجز حالياً",
                    style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final bookings = snapshot.data!.docs.map((doc) {
            return BookingModel.fromFirestore(doc);
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              return _buildBookingCard(context, bookings[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, BookingModel booking) {
    Color statusColor;
    String statusText;

    // تحديد لون وحالة النص بناءً على status
    switch (booking.status) {
      case 'confirmed':
        statusColor = Colors.green;
        statusText = "مقبول ✅";
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = "مرفوض ❌";
        break;
      default:
        statusColor = AppColors.secondary;
        statusText = "قيد الانتظار ⏳";
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            // الرأس: الخدمة والحالة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  booking.serviceName,
                  style: GoogleFonts.tajawal(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 25),

            // التفاصيل
            _buildInfoRow(Icons.person, "العميل", booking.clientName),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.directions_car, "اللوحة", booking.plateNumber),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.access_time,
              "الموعد",
              "${booking.bookingDate.day}/${booking.bookingDate.month} - ${booking.bookingTime}",
            ),

            if (booking.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.note, "ملاحظات", booking.notes),
            ],

            // أزرار التحكم (تظهر فقط إذا كانت الحالة "قيد الانتظار")
            if (booking.status == 'pending') ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateBookingStatus(
                        context,
                        booking.id,
                        'confirmed',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "قبول",
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          _updateBookingStatus(context, booking.id, 'rejected'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade100,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "رفض",
                        style: GoogleFonts.cairo(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  // دالة تحديث الحالة في الفايربيز
  Future<void> _updateBookingStatus(
    BuildContext context,
    String docId,
    String newStatus,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(docId).update(
        {'status': newStatus},
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("تم تحديث الحالة بنجاح 👍", style: GoogleFonts.cairo()),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ: $e", style: GoogleFonts.cairo())),
      );
    }
  }
}
