import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../colors.dart';
import '../models/booking_model.dart';

// ✅ جعلنا الشاشة تستقبل معرف الورشة لتجلب طلباتها فقط!
class WorkshopBookingsScreen extends StatelessWidget {
  final String workshopId;

  const WorkshopBookingsScreen({super.key, required this.workshopId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // عدد التبويبات
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            "إدارة الحجوزات",
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: AppColors.cardBg,
          foregroundColor: AppColors.textDark,
          elevation: 0,
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "الطلبات الجديدة 🔔"),
              Tab(text: "الأرشيف السجل 📁"),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          // ✅ الفلترة السحرية: اجلب فقط الحجوزات الخاصة بهذه الورشة!
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('workshopId', isEqualTo: workshopId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState();
            }

            // تحويل البيانات ثم ترتيبها محلياً (الأحدث أولاً) لتجنب أخطاء فهارس الفايربيز
            List<BookingModel> allBookings = snapshot.data!.docs
                .map((doc) => BookingModel.fromFirestore(doc))
                .toList();
            allBookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            // تقسيم الحجوزات إلى قائمتين
            List<BookingModel> pendingBookings = allBookings
                .where((b) => b.status == 'pending')
                .toList();
            List<BookingModel> historyBookings = allBookings
                .where((b) => b.status != 'pending')
                .toList();

            return TabBarView(
              children: [
                // التبويب 1: الطلبات المعلقة
                pendingBookings.isEmpty
                    ? _buildEmptyState("لا توجد طلبات جديدة")
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: pendingBookings.length,
                        itemBuilder: (context, index) => _buildBookingCard(
                          context,
                          pendingBookings[index],
                          isPending: true,
                        ),
                      ),

                // التبويب 2: الأرشيف (سجل الحجوزات المقبولة والمرفوضة)
                historyBookings.isEmpty
                    ? _buildEmptyState("سجل الحجوزات فارغ")
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: historyBookings.length,
                        itemBuilder: (context, index) => _buildBookingCard(
                          context,
                          historyBookings[index],
                          isPending: false,
                        ),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }

  // رسالة الحالة الفارغة
  Widget _buildEmptyState([String msg = "لا توجد طلبات حجز حالياً"]) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 15),
          Text(msg, style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  // تصميم الكارت المحدث (أنيق، بحدود متناسقة، وبدون تشوه)
  Widget _buildBookingCard(
    BuildContext context,
    BookingModel booking, {
    required bool isPending,
  }) {
    Color statusColor;
    String statusText;

    switch (booking.status) {
      case 'confirmed':
        statusColor = Colors.green;
        statusText = "تم القبول ✅";
        break;
      case 'rejected':
      case 'rejected_notified': // كلاهما يعامل كمرفوض في واجهة الورشة
        statusColor = Colors.red;
        statusText = "مرفوض ❌";
        break;
      default:
        statusColor = Colors.orange;
        statusText = "قيد الانتظار ⏳";
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade200), // حدود متناسقة وناعمة
      ),
      elevation: 2,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    booking.serviceName,
                    style: GoogleFonts.tajawal(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, thickness: 1),
            ),
            _buildInfoRow(Icons.person, "العميل", booking.clientName),
            const SizedBox(height: 10),
            _buildInfoRow(Icons.directions_car, "اللوحة", booking.plateNumber),
            const SizedBox(height: 10),
            _buildInfoRow(
              Icons.access_time,
              "الموعد",
              "${booking.bookingDate.day}/${booking.bookingDate.month} - ${booking.bookingTime}",
            ),

            if (booking.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildInfoRow(Icons.note, "ملاحظات", booking.notes),
              ),
            ],

            // الأزرار تظهر فقط في تبويب الطلبات المعلقة
            if (isPending) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateBookingStatus(
                        context,
                        booking.id,
                        'confirmed',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(
                        "قبول",
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _updateBookingStatus(context, booking.id, 'rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.close, size: 18),
                      label: Text(
                        "رفض",
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey),
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
          content: Text(
            newStatus == 'confirmed'
                ? "تم قبول الموعد بنجاح ✅"
                : "تم رفض الموعد ❌",
            style: GoogleFonts.cairo(),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ: $e", style: GoogleFonts.cairo())),
      );
    }
  }
}
