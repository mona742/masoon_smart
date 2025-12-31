import 'package:cloud_firestore/cloud_firestore.dart'; // استيراد الفايربيز
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../colors.dart';
import '../models/booking_model.dart'; // استيراد موديل الحجز

class BookingScreen extends StatefulWidget {
  final String serviceName;

  const BookingScreen({super.key, required this.serviceName});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = false; // حالة التحميل

  final List<String> _timeSlots = [
    "09:00 ص",
    "10:00 ص",
    "11:00 ص",
    "04:00 م",
    "05:00 م",
    "06:00 م",
    "07:00 م",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          "حجز موعد جديد",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.cardBg,
        foregroundColor: AppColors.textDark,
        centerTitle: true,
        elevation: 0,
      ),
      // إذا كان يحمل، نعرض دائرة التحميل، وإلا نعرض المحتوى
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. ملخص الخدمة
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bookmarks, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Text(
                            "الخدمة المطلوبة: ",
                            style: GoogleFonts.cairo(
                              color: AppColors.textLight,
                            ),
                          ),
                          Text(
                            widget.serviceName,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // 2. اختيار التاريخ
                    Text(
                      "اختر التاريخ",
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                              style: GoogleFonts.tajawal(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(
                              Icons.calendar_today,
                              color: AppColors.secondary,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // 3. اختيار الوقت
                    Text(
                      "اختر الوقت المناسب",
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 2.5,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemCount: _timeSlots.length,
                      itemBuilder: (context, index) {
                        bool isSelected = _selectedTime == _timeSlots[index];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTime = _timeSlots[index];
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.cardBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _timeSlots[index],
                                style: GoogleFonts.tajawal(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textDark,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 25),

                    // 4. الملاحظات
                    Text(
                      "ملاحظات (اختياري)",
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "مثال: أريد فحص الفرامل الخلفية أيضاً...",
                        hintStyle: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        filled: true,
                        fillColor: AppColors.cardBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // 5. زر التأكيد الحقيقي
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _confirmBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          "تأكيد الحجز",
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // ✅ دالة الحجز المتصلة بالفايربيز
  Future<void> _confirmBooking() async {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "يرجى اختيار الوقت المناسب 🕒",
            style: GoogleFonts.cairo(),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true); // بدء التحميل

    try {
      // 1. تجهيز بيانات الحجز
      // ملاحظة: نستخدم بيانات ثابتة للعميل واللوحة مؤقتاً (نفس المستخدمة في الداشبورد)
      final booking = BookingModel(
        id: '', // تلقائي
        serviceName: widget.serviceName,
        clientName: "أحمد محمد",
        plateNumber: "1234 س ح ط ", // يجب أن يطابق رقم الداشبورد
        bookingDate: _selectedDate,
        bookingTime: _selectedTime!,
        notes: _noteController.text,
        status: 'pending', // الحالة الافتراضية: قيد الانتظار
        createdAt: DateTime.now(),
      );

      // 2. الإرسال إلى Firestore (جدول bookings)
      await FirebaseFirestore.instance
          .collection('bookings')
          .add(booking.toMap());

      if (!mounted) return;

      // 3. نجاح
      showDialog(
        context: context,
        barrierDismissible: false, // منع الإغلاق بالضغط خارج الصندوق
        builder: (ctx) => AlertDialog(
          title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "تم إرسال الطلب بنجاح!",
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "حالة الطلب الآن: قيد الانتظار.\nسيتم إشعارك عند موافقة الورشة.",
                style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx); // إغلاق الديالوج
                Navigator.pop(context); // العودة للرئيسية
              },
              child: Text(
                "حسناً",
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("حدث خطأ: $e", style: GoogleFonts.cairo())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
