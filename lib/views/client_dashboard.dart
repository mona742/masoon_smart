import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../colors.dart';
import '../models/service_model.dart';
import 'client_bookings_screen.dart';
import 'service_details_screen.dart';

// --- النماذج (Models) ---

// 1. نموذج العروض
class OfferModel {
  final String title;
  final String description;
  final Color imageColor;
  final String details;
  OfferModel({
    required this.title,
    required this.description,
    required this.imageColor,
    required this.details,
  });
}

// 2. نموذج عنصر الخدمة (للعرض)
class ServiceItem {
  final String id;
  final String name;
  final double limitKm;
  final double lastChangeKm;
  final String lastChangeDate;
  final IconData icon;
  final Color color;
  final Map<String, String> detailsMap;

  ServiceItem({
    required this.id,
    required this.name,
    required this.limitKm,
    required this.lastChangeKm,
    required this.lastChangeDate,
    required this.icon,
    required this.color,
    required this.detailsMap,
  });
}

// 3. شاشة تفاصيل العرض (تم نقلها للأعلى لتفادي الأخطاء)
class OfferDetailsScreen extends StatelessWidget {
  final OfferModel offer;
  const OfferDetailsScreen({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          offer.title,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.cardBg,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: offer.imageColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: offer.imageColor.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.local_offer, size: 80, color: Colors.white),
              ),
            ),
            const SizedBox(height: 25),
            Text(
              offer.title,
              style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              offer.description,
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: AppColors.textLight,
              ),
            ),
            const Divider(height: 40),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "تفاصيل العرض:",
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              offer.details,
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: AppColors.textDark,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "سيتم تفعيل الحجز قريباً",
                        style: GoogleFonts.cairo(),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  "الاستفادة من العرض",
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- الشاشة الرئيسية ---

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key});

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> {
  final String clientName = "أحمد محمد";
  final String carModel = "Toyota Camry";
  final String carYear = "2023";

  // ✅ تم التعديل: رقم اللوحة مطابق تماماً لما في الفايربيز
  final String plateNumber = "1234 س ح ط ";

  double _currentCarOdometer = 50000.0;

  final List<OfferModel> offers = [
    OfferModel(
      title: 'خصم 50% على الزيوت',
      description: 'لأول 100 عميل هذا الشهر',
      imageColor: AppColors.primary,
      details:
          'احصل على خصم 50% شامل أجور اليد والفلتر عند تغيير زيت كاسترول. العرض ساري في جميع فروعنا.',
    ),
    OfferModel(
      title: 'فحص شامل مجاني',
      description: 'مع طقم الكفرات الجديد',
      imageColor: const Color(0xFF1E40AF),
      details:
          'عند شراء 4 إطارات من نوع هانكوك أو يوكوهاما، تحصل على فحص كمبيوتر شامل + ترصيد مجاني.',
    ),
  ];

  Position? _lastPosition;
  StreamSubscription<Position>? _positionStream;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadSavedData();
    _requestPermissionsAndStartTracking();
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
    await _notificationsPlugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  Future<void> _requestPermissionsAndStartTracking() async {
    await Permission.notification.request();
    var status = await Permission.location.request();
    if (status.isGranted) {
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );
      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen((Position position) {
            _updateDistance(position);
          });
    }
  }

  void _updateDistance(Position currentPosition) {
    if (_lastPosition != null) {
      double distanceInMeters = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        currentPosition.latitude,
        currentPosition.longitude,
      );
      double distanceInKm = distanceInMeters / 1000;
      setState(() {
        _currentCarOdometer += distanceInKm;
      });
      _saveData();
    }
    _lastPosition = currentPosition;
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('car_odometer', _currentCarOdometer);
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentCarOdometer = prefs.getDouble('car_odometer') ?? 50000.0;
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  // دالة فتح تفاصيل العرض
  void _openOfferDetails(OfferModel offer) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OfferDetailsScreen(offer: offer)),
    );
  }

  // دالة مساعدة للألوان
  Color _getServiceColor(String type) {
    switch (type) {
      case 'oil':
        return AppColors.secondary;
      case 'tires':
        return AppColors.primary;
      case 'brakes':
        return AppColors.danger;
      case 'ac':
        return Colors.teal;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserHeader(),
              const SizedBox(height: 20),
              _buildOffersSlider(),
              const SizedBox(height: 25),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "سجل الصيانة (حي)",
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.speed,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "${_currentCarOdometer.toInt()} كم",
                            style: GoogleFonts.tajawal(
                              fontSize: 14,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              // قائمة الخدمات المتصلة بـ Firebase
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('services')
                      .where('carId', isEqualTo: plateNumber)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "خطأ: ${snapshot.error}",
                          style: GoogleFonts.cairo(color: Colors.red),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.assignment_late_outlined,
                              size: 40,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "لا توجد خدمات مسجلة لهذه السيارة",
                              style: GoogleFonts.cairo(color: Colors.grey),
                            ),
                            Text(
                              "رقم اللوحة: $plateNumber",
                              style: GoogleFonts.tajawal(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final services = snapshot.data!.docs.map((doc) {
                      return ServiceModel.fromFirestore(doc);
                    }).toList();

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.8,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                          ),
                      itemCount: services.length,
                      itemBuilder: (ctx, index) {
                        final serviceModel = services[index];

                        final serviceItem = ServiceItem(
                          id: serviceModel.id,
                          name: serviceModel.name,
                          limitKm: serviceModel.limitKm,
                          lastChangeKm: serviceModel.lastChangeKm,
                          lastChangeDate:
                              "${serviceModel.lastChangeDate.day}/${serviceModel.lastChangeDate.month}/${serviceModel.lastChangeDate.year}",
                          icon: serviceModel.getIcon(),
                          color: _getServiceColor(serviceModel.type),
                          detailsMap: serviceModel.details,
                        );

                        return _buildServiceCard(serviceItem);
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 30),

              // زر المحاكاة
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentCarOdometer += 500.0;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textDark,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                  ),
                  child: const Icon(Icons.add, size: 30),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "إضافة 500 كم",
                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.secondary, width: 2),
                ),
                child: const CircleAvatar(
                  radius: 25,
                  backgroundColor: AppColors.background,
                  child: Icon(Icons.person, color: AppColors.primary, size: 30),
                ),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "مرحباً، $clientName",
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    "نتمنى لك قيادة آمنة 🛡️",
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // ✅ زر الحجوزات الجديد (أيقونة التقويم)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ClientBookingsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.calendar_month_outlined,
                    color: AppColors.primary,
                  ),
                  tooltip: "حجوزاتي",
                ),
              ),

              // زر الإشعارات القديم
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.notifications_none,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF102A66)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      carModel,
                      style: GoogleFonts.tajawal(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "موديل $carYear",
                      style: GoogleFonts.tajawal(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: Text(
                    plateNumber,
                    style: GoogleFonts.tajawal(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOffersSlider() {
    return CarouselSlider(
      options: CarouselOptions(
        height: 160.0,
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 0.9,
      ),
      items: offers.map((offer) {
        return GestureDetector(
          onTap: () => _openOfferDetails(offer),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 5.0),
            decoration: BoxDecoration(
              color: offer.imageColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: offer.imageColor.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -30,
                  bottom: -30,
                  child: Icon(
                    Icons.local_offer,
                    size: 150,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          "عرض خاص 🔥",
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        offer.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        offer.description,
                        maxLines: 1,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildServiceCard(ServiceItem service) {
    double drivenDistance = _currentCarOdometer - service.lastChangeKm;
    double remaining = service.limitKm - drivenDistance;
    double progress = (drivenDistance / service.limitKm).clamp(0.0, 1.0);
    Color statusColor = progress < 0.8
        ? AppColors.primary
        : (progress < 0.95 ? AppColors.secondary : AppColors.danger);
    String statusText = remaining > 0 ? "باقي ${remaining.toInt()}" : "تجاوز!";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailsScreen(service: service),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: service.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(service.icon, color: service.color, size: 20),
                ),
                CircularProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[100],
                  color: statusColor,
                  strokeWidth: 3,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              service.name,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const Spacer(),
            Text(
              "تغيير: ${service.lastChangeDate}",
              style: GoogleFonts.cairo(
                fontSize: 10,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusText,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
