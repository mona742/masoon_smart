import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../colors.dart';
import '../models/booking_model.dart';

class BookingScreen extends StatefulWidget {
  final String serviceName;
  final String clientName; // ✅ نستقبل الاسم الحقيقي
  final String plateNumber; // ✅ نستقبل اللوحة الحقيقية
  final String workshopId; // ✅ نستقبل الورشة المقصودة

  const BookingScreen({
    super.key,
    required this.serviceName,
    required this.clientName,
    required this.plateNumber,
    required this.workshopId,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = false;

  // القائمة الكاملة للأوقات المتاحة
  final List<String> _allTimeSlots = [
    "09:00 AM",
    "10:00 AM",
    "11:00 AM",
    "04:00 PM",
    "05:00 PM",
    "06:00 PM",
    "07:00 PM",
  ];

  // ✅ دالة ذكية تفلتر الأوقات (تخفي الأوقات التي مضت إذا كان الحجز لليوم)
  List<String> get _availableTimeSlots {
    if (_selectedDate.day != DateTime.now().day ||
        _selectedDate.month != DateTime.now().month) {
      return _allTimeSlots; // إذا كان الحجز في يوم قادم، أظهر كل الأوقات
    }

    // إذا كان الحجز اليوم، نقوم بفلترة الأوقات التي مضت
    return _allTimeSlots.where((timeString) {
      DateTime parsedTime = DateFormat("hh:mm a").parse(timeString);
      DateTime slotDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        parsedTime.hour,
        parsedTime.minute,
      );
      // أضفنا ساعة سماحية (لا يمكنك حجز موعد إلا إذا كان باقٍ عليه ساعة على الأقل)
      return slotDateTime.isAfter(
        DateTime.now().add(const Duration(minutes: 30)),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    List<String> currentSlots = _availableTimeSlots;

    // إذا اختار العميل وقتاً ثم غير اليوم وأصبح الوقت غير متاح، نمسح التحديد
    if (_selectedTime != null && !currentSlots.contains(_selectedTime)) {
      _selectedTime = null;
    }

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
                    // ملخص الخدمة والسيارة
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.build_circle,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "الخدمة: ",
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
                          const Divider(height: 20),
                          Row(
                            children: [
                              const Icon(
                                Icons.directions_car,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "المركبة: ",
                                style: GoogleFonts.cairo(
                                  color: AppColors.textLight,
                                ),
                              ),
                              Text(
                                widget.plateNumber,
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // اختيار التاريخ
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

                    // اختيار الوقت (بعد الفلترة)
                    Text(
                      "اختر الوقت المناسب",
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    currentSlots.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "عذراً، لا توجد مواعيد متاحة بقية هذا اليوم، يرجى اختيار يوم آخر.",
                              style: GoogleFonts.cairo(color: Colors.red),
                            ),
                          )
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  childAspectRatio: 2.5,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                            itemCount: currentSlots.length,
                            itemBuilder: (context, index) {
                              bool isSelected =
                                  _selectedTime == currentSlots[index];
                              return GestureDetector(
                                onTap: () => setState(
                                  () => _selectedTime = currentSlots[index],
                                ),
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
                                      // استبدال AM/PM بعربي للعرض
                                      currentSlots[index]
                                          .replaceAll('AM', 'ص')
                                          .replaceAll('PM', 'م'),
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

                    // الملاحظات
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

                    // زر التأكيد
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
      setState(() => _selectedDate = picked);
    }
  }

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

    setState(() => _isLoading = true);

    try {
      // ✅ 1. استخدام البيانات الحقيقية القادمة من المتغيرات
      final booking = BookingModel(
        id: '',
        serviceName: widget.serviceName,
        clientName: widget.clientName, // الديناميكي
        plateNumber: widget.plateNumber, // الديناميكي
        workshopId: widget.workshopId, // ✅ الديناميكي والمهم جداً
        bookingDate: _selectedDate,
        bookingTime: _selectedTime!.replaceAll('AM', 'ص').replaceAll('PM', 'م'),
        notes: _noteController.text,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      // 2. الإرسال إلى الفايربيز
      await FirebaseFirestore.instance
          .collection('bookings')
          .add(booking.toMap());

      if (!mounted) return;

      // 3. نجاح
      showDialog(
        context: context,
        barrierDismissible: false,
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
                Navigator.pop(ctx);
                Navigator.pop(context); // العودة للشاشة السابقة
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
