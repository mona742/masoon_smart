// lib/views/client_dashboard.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../colors.dart';
import '../services/notification_service.dart';
import 'add_car_screen.dart';
import 'booking_screen.dart';
import 'car_value_report_screen.dart';
import 'client_bookings_screen.dart';
import 'client_service_history_screen.dart';
import 'client_store_screen.dart';
import 'login_screen.dart';
import 'service_details_screen.dart';

class ClientDashboard extends StatefulWidget {
  final String clientPhone;

  const ClientDashboard({super.key, required this.clientPhone});

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> {
  String? _resolvedPhone;
  bool _isLoading = true;
  int _selectedCarIndex = 0;

  StreamSubscription<QuerySnapshot>? _bookingsSub;
  List<String> _currentPlates = [];

  @override
  void initState() {
    super.initState();
    _findCorrectPhoneNumber();
  }

  @override
  void dispose() {
    _bookingsSub?.cancel();
    super.dispose();
  }

  Future<void> _findCorrectPhoneNumber() async {
    String input = widget.clientPhone.trim().replaceAll(' ', '');
    String cleanNumber = input;

    if (cleanNumber.startsWith('0')) cleanNumber = cleanNumber.substring(1);
    if (cleanNumber.startsWith('+966'))
      cleanNumber = cleanNumber.substring(4);
    else if (cleanNumber.startsWith('966'))
      cleanNumber = cleanNumber.substring(3);

    List<String> possibilities = [
      cleanNumber,
      "0$cleanNumber",
      "+966$cleanNumber",
      "00966$cleanNumber",
    ];

    for (String phone in possibilities) {
      final snapshot = await FirebaseFirestore.instance
          .collection('cars')
          .where('ownerPhone', isEqualTo: phone)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        var carDoc = snapshot.docs.first;
        String carId = carDoc.id;

        FlutterBackgroundService().invoke("setCarId", {"carId": carId});

        if (mounted) {
          setState(() {
            _resolvedPhone = phone;
            _isLoading = false;
          });
        }
        return;
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _updateBookingsListener(List<String> plates) {
    if (plates.isEmpty) return;
    bool same =
        plates.length == _currentPlates.length &&
        plates.every((p) => _currentPlates.contains(p));
    if (same) return;

    _currentPlates = plates;
    _bookingsSub?.cancel();

    _bookingsSub = FirebaseFirestore.instance
        .collection('bookings')
        .where('plateNumber', whereIn: plates.take(10).toList())
        .snapshots()
        .listen((snapshot) {
          for (var doc in snapshot.docs) {
            var data = doc.data() as Map<String, dynamic>;
            String status = data['status'] ?? '';
            bool isClientNotified = data['isClientNotified'] ?? false;
            String serviceName = data['serviceName'] ?? 'خدمة';
            String id = doc.id;

            if (!isClientNotified &&
                (status == 'confirmed' || status == 'rejected')) {
              FirebaseFirestore.instance.collection('bookings').doc(id).update({
                'isClientNotified': true,
              });

              if (status == 'confirmed') {
                _showBookingAlert(
                  id,
                  'تم قبول موعدك! ✅',
                  'وافقت الورشة على موعد خدمة ($serviceName). نحن بانتظارك!',
                  Colors.green,
                  Icons.check_circle,
                );
              } else if (status == 'rejected') {
                _showBookingAlert(
                  id,
                  'نعتذر منك ❌',
                  'الورشة غير متاحة لتقديم خدمة ($serviceName) في الوقت المحدد. يرجى حجز موعد آخر.',
                  Colors.red,
                  Icons.cancel,
                );
              }
            }
          }
        });
  }

  void _showBookingAlert(
    String docId,
    String title,
    String msg,
    Color color,
    IconData icon,
  ) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                title,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        content: Text(msg, style: GoogleFonts.cairo(fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "حسناً",
              style: GoogleFonts.cairo(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          "لوحة العميل",
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () {
              FlutterBackgroundService().invoke("stopService");
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _resolvedPhone == null
          ? _buildNoCarsFound()
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('cars')
                  .where('ownerPhone', isEqualTo: _resolvedPhone)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildNoCarsFound();
                }

                var cars = snapshot.data!.docs.where((doc) {
                  var d = doc.data() as Map<String, dynamic>;
                  return d['plate'] != null && d['plate'].toString().length > 1;
                }).toList();

                if (cars.isEmpty) return _buildNoCarsFound();

                List<String> plates = cars
                    .map(
                      (c) => (c.data() as Map<String, dynamic>)['plate']
                          .toString(),
                    )
                    .toList();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _updateBookingsListener(plates);
                });

                cars.sort((a, b) {
                  var dA = a.data() as Map<String, dynamic>;
                  var dB = b.data() as Map<String, dynamic>;
                  Timestamp? timeA = dA['lastServiceDate'];
                  Timestamp? timeB = dB['lastServiceDate'];
                  if (timeA != null && timeB != null)
                    return timeB.compareTo(timeA);
                  return 0;
                });

                if (_selectedCarIndex >= cars.length) _selectedCarIndex = 0;

                var selectedCarData =
                    cars[_selectedCarIndex].data() as Map<String, dynamic>;

                String vin = (selectedCarData['vin'] ?? '')
                    .toString()
                    .toUpperCase();
                String plate = selectedCarData['plate'] ?? '---';
                double currentKm =
                    double.tryParse(selectedCarData['currentKm'].toString()) ??
                    0.0;
                String clientName =
                    selectedCarData['clientName'] ?? 'عميلنا العزيز';
                String make = selectedCarData['make'] ?? 'مركبة';
                String model = selectedCarData['model'] ?? '';
                String workshopId = selectedCarData['workshopId'] ?? '';

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeader(clientName, "$make $model", plate),
                      const SizedBox(height: 10),

                      _buildOffersSlider(context, make, model),
                      const SizedBox(height: 10),

                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: cars.length + 1,
                          itemBuilder: (context, index) {
                            if (index == cars.length) {
                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AddCarScreen(),
                                  ),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 10),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.add_circle,
                                        color: Colors.grey,
                                      ),
                                      Text(
                                        "إضافة سيارة",
                                        style: GoogleFonts.cairo(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            var c = cars[index].data() as Map<String, dynamic>;
                            bool isSel = index == _selectedCarIndex;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedCarIndex = index),
                              child: Container(
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? AppColors.primary
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSel
                                        ? AppColors.primary
                                        : Colors.grey.shade300,
                                  ),
                                  boxShadow: isSel
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primary
                                                .withOpacity(0.2),
                                            blurRadius: 5,
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.directions_car,
                                      color: isSel ? Colors.white : Colors.grey,
                                    ),
                                    Text(
                                      c['plate'] ?? '',
                                      style: TextStyle(
                                        color: isSel
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildSmartOilMeter(vin, currentKm),
                      ),
                      const SizedBox(height: 20),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildActionButton(
                                    "حجز موعد جديد",
                                    Icons.add_task,
                                    Colors.orange.shade700,
                                    () => _showServiceSelectionSheet(
                                      context,
                                      clientName,
                                      plate,
                                      workshopId,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildActionButton(
                                    "حجوزاتي",
                                    Icons.calendar_month,
                                    Colors.purple,
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ClientBookingsScreen(
                                          plateNumber: plate,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildActionButton(
                                    "السجل الكامل",
                                    Icons.history,
                                    Colors.blue,
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ClientServiceHistoryScreen(
                                              carVin: vin,
                                              plate: plate,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildActionButton(
                                    "قيمة سيارتي",
                                    Icons.verified,
                                    Colors.green,
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            CarValueReportScreen(carId: vin),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            "الصيانة الدورية",
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildTimeBasedServices(vin),
                      ),
                      const SizedBox(height: 25),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            "تفاصيل الخدمة الحالية",
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      _buildRecentServicesList(vin),
                      const SizedBox(height: 50),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // ✅ النافذة المنبثقة لاختيار الخدمة (مدمج معها قفل الأمان)
  void _showServiceSelectionSheet(
    BuildContext context,
    String clientName,
    String plate,
    String workshopId,
  ) {
    if (workshopId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "⚠️ عذراً، هذه السيارة غير مرتبطة بورشة محددة حتى الآن. يرجى التواصل مع الورشة لربط سيارتك.",
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    List<String> services = [
      'تغيير زيت المحرك',
      'تغيير فحمات الفرامل',
      'تغيير فلتر المكيف',
      'فحص حاسوب (برمجة)',
      'فحص شامل',
      'أخرى',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "اختر نوع الخدمة المطلوبة",
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Divider(color: Colors.grey.shade300),
              Expanded(
                child: ListView.builder(
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Icon(
                        Icons.build_circle,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        services[index],
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingScreen(
                              serviceName: services[index],
                              clientName: clientName,
                              plateNumber: plate,
                              workshopId: workshopId,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- بقية الدوال المساعدة داخل الكلاس ---
  Widget _buildOffersSlider(BuildContext context, String make, String model) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('spare_parts')
          .where('isFeatured', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        List<Widget> sliderItems = [
          _buildSliderCard(
            context: context,
            title: "المتجر الذكي 🛒",
            subtitle: "اكتشف قطع الغيار المتوافقة تماماً مع $make $model",
            color1: Colors.blue.shade800,
            color2: Colors.blue.shade400,
            icon: Icons.storefront,
            make: make,
            model: model,
          ),
        ];

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          var compatibleFeatured = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            List<dynamic> models = data['compatibleModels'] ?? [];
            return models.any((m) {
              String target = m.toString().toUpperCase();
              return target.contains(make.toUpperCase()) ||
                  target.contains(model.toUpperCase());
            });
          }).toList();

          for (var part in compatibleFeatured) {
            var data = part.data() as Map<String, dynamic>;
            sliderItems.add(
              _buildSliderCard(
                context: context,
                title: data['name'] ?? 'عرض خاص',
                subtitle:
                    "سعر حصري لملاك $model: ${data['discountPrice'] ?? data['price']} ﷼",
                color1: Colors.orange.shade800,
                color2: Colors.orange.shade400,
                icon: Icons.local_offer,
                make: make,
                model: model,
              ),
            );
          }
        }
        return Container(
          height: 140,
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: PageView(
            controller: PageController(viewportFraction: 0.92),
            children: sliderItems,
          ),
        );
      },
    );
  }

  Widget _buildSliderCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required Color color1,
    required Color color2,
    required IconData icon,
    required String make,
    required String model,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ClientStoreScreen(carMake: make, carModel: model),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: color1.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, size: 50, color: Colors.white.withOpacity(0.8)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCarsFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.no_crash_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            "لا توجد سيارات مسجلة لهذا الرقم",
            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(widget.clientPhone, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildHeader(String name, String car, String plate) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: AppColors.secondary,
        child: Icon(Icons.person, color: Colors.white),
      ),
      title: Text(
        "مرحباً $name",
        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
      ),
      subtitle: Text("$car | $plate"),
    );
  }

  Widget _buildSmartOilMeter(String vin, double currentKm) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('services')
          .where('carId', isEqualTo: vin)
          .where('type', isEqualTo: 'oil')
          .snapshots(),
      builder: (context, snapshot) {
        double limit = 5000.0;
        double lastKm = 0.0;
        Map<String, dynamic> lastServiceData = {};

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          var docs = snapshot.data!.docs;
          docs.sort(
            (a, b) => (b['lastChangeDate'] as Timestamp).compareTo(
              a['lastChangeDate'],
            ),
          );
          lastServiceData = docs.first.data() as Map<String, dynamic>;
          lastKm =
              double.tryParse(lastServiceData['lastChangeKm'].toString()) ??
              0.0;
          limit =
              double.tryParse(lastServiceData['limitKm'].toString()) ?? 5000.0;
        } else {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "لا يوجد سجل زيت سابق لحساب العداد",
                    style: GoogleFonts.cairo(fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        }

        double driven = currentKm - lastKm;
        if (driven < 0) driven = 0.0;
        double remaining = limit - driven;
        double progress = (driven / limit).clamp(0.0, 1.0);

        if (progress >= 0.9) {
          Future.delayed(Duration.zero, () {
            NotificationService().showWarningNotification(
              id: vin.hashCode,
              title: "⚠️ تنبيه من مصون: زيت المحرك",
              body:
                  "استهلاك زيت سيارتك ($vin) وصل لنسبة حرجة. يرجى حجز موعد صيانة الآن لتجنب ضرر المحرك.",
            );
          });
        }

        Color barColor = remaining > 1000
            ? Colors.green
            : (remaining > 0 ? Colors.orange : Colors.red);

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ServiceDetailsScreen(
                serviceData: lastServiceData,
                carId: vin,
              ),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "حالة الزيت",
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      remaining > 0 ? "ممتازة" : "تغيير ضروري",
                      style: TextStyle(
                        color: barColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: 1.0 - progress,
                  backgroundColor: Colors.grey[100],
                  color: barColor,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _meterInfo("الممشى الحالي", "${currentKm.toInt()}"),
                    _meterInfo("تغيير عند", "${(lastKm + limit).toInt()}"),
                    _meterInfo(
                      "المتبقي",
                      "${remaining.toInt()} كم",
                      isBold: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _meterInfo(String label, String val, {bool isBold = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(
          val,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
            color: isBold ? AppColors.primary : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 5),
            Text(
              title,
              style: GoogleFonts.cairo(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentServicesList(String vin) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('services')
          .where('carId', isEqualTo: vin)
          .limit(1)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty)
          return const Text("لا توجد خدمات");
        var docs = snap.data!.docs;
        docs.sort(
          (a, b) =>
              (b['lastChangeDate'] as Timestamp).compareTo(a['lastChangeDate']),
        );
        var s = docs.first.data() as Map<String, dynamic>;
        String date = s['lastChangeDate'] != null
            ? DateFormat(
                'yyyy-MM-dd',
              ).format((s['lastChangeDate'] as Timestamp).toDate())
            : '';
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ServiceDetailsScreen(serviceData: s, carId: vin),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10, left: 20, right: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: const Icon(
                  Icons.build,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              title: Text(
                s['name'] ?? '',
                style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                date,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeBasedServices(String vin) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('services')
          .where('carId', isEqualTo: vin)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        var docs = snapshot.data!.docs;
        Map<String, dynamic>? getLatestService(String type) {
          var specificDocs = docs.where((d) => d['type'] == type).toList();
          if (specificDocs.isEmpty) return null;
          specificDocs.sort(
            (a, b) => (b['lastChangeDate'] as Timestamp).compareTo(
              a['lastChangeDate'],
            ),
          );
          return specificDocs.first.data() as Map<String, dynamic>;
        }

        return Column(
          children: [
            _buildTimeCard(
              "الكفرات",
              Icons.tire_repair,
              getLatestService('tires'),
              24,
            ),
            const SizedBox(height: 15),
            _buildTimeCard(
              "المكيف والفلاتر",
              Icons.ac_unit,
              getLatestService('ac'),
              12,
            ),
            const SizedBox(height: 15),
            _buildTimeCard(
              "زيت الفرامل",
              Icons.water_drop,
              getLatestService('brake_fluid'),
              24,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimeCard(
    String title,
    IconData icon,
    Map<String, dynamic>? data,
    int lifeSpanMonths,
  ) {
    if (data == null) {
      return Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.grey),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                ),
                Text(
                  "لا يوجد سجل سابق",
                  style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.add_circle_outline, color: Colors.grey),
          ],
        ),
      );
    }
    Timestamp lastDateTs = data['lastChangeDate'];
    DateTime lastDate = lastDateTs.toDate();
    DateTime expiryDate = lastDate.add(Duration(days: lifeSpanMonths * 30));
    DateTime now = DateTime.now();
    int totalDays = lifeSpanMonths * 30;
    int daysPassed = now.difference(lastDate).inDays;
    int daysRemaining = expiryDate.difference(now).inDays;
    double progress = (daysPassed / totalDays).clamp(0.0, 1.0);

    Color statusColor = progress > 0.9
        ? Colors.red
        : (progress > 0.75 ? Colors.orange : Colors.green);
    String statusText = progress > 0.9
        ? "منتهية الصلاحية"
        : (progress > 0.75 ? "تغيير قريب" : "حالة ممتازة");

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: statusColor),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    DateFormat('yyyy-MM-dd').format(lastDate),
                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: 1.0 - progress,
            backgroundColor: Colors.grey[100],
            color: statusColor,
            minHeight: 8,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "متبقي ${daysRemaining > 0 ? daysRemaining : 0} يوم",
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "${(progress * 100).toInt()}% مستهلك",
                style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
