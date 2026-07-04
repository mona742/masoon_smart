import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../colors.dart';
import 'add_part_screen.dart';
import 'login_screen.dart';
import 'workshop_add_service_screen.dart';
import 'workshop_bookings_screen.dart';
import 'workshop_car_profile_screen.dart';

class WorkshopHomeScreen extends StatefulWidget {
  final String workshopId;
  final String? workshopName;

  const WorkshopHomeScreen({
    super.key,
    required this.workshopId,
    this.workshopName,
  });

  @override
  State<WorkshopHomeScreen> createState() => _WorkshopHomeScreenState();
}

class _WorkshopHomeScreenState extends State<WorkshopHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];
  bool _isSearching = false;
  String _searchError = '';

  // 🔴 مستمع ذكي للتنبيهات الفورية
  StreamSubscription? _notificationsSub;

  @override
  void initState() {
    super.initState();
    _listenForNewBookings();
  }

  // دالة لمراقبة الطلبات الجديدة وعرض إشعار فوري للورشة
  void _listenForNewBookings() {
    _notificationsSub = FirebaseFirestore.instance
        .collection('bookings')
        .where('workshopId', isEqualTo: widget.workshopId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              // جلب وقت الإنشاء لمعرفة ما إذا كان الطلب جديداً جداً (آخر دقيقتين)
              final data = change.doc.data() as Map<String, dynamic>;
              final createdAtTs = data['createdAt'] as Timestamp?;
              if (createdAtTs != null) {
                final diff = DateTime.now()
                    .difference(createdAtTs.toDate())
                    .inMinutes;
                if (diff <= 2 && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.orange.shade800,
                      content: Text(
                        "🔔 يوجد طلب حجز جديد بانتظار موافقتك!",
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            }
          }
        });
  }

  @override
  void dispose() {
    _notificationsSub?.cancel(); // إيقاف المستمع عند الخروج
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String displayName = widget.workshopName ?? "مركز الصيانة";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          displayName,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.cardBg,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.danger),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "أهلاً بك 👋",
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "رقم الورشة: ${widget.workshopId}",
              style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // 1. تسجيل خدمة صيانة
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      WorkshopAddServiceScreen(workshopId: widget.workshopId),
                ),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF1565C0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_circle_outline,
                      size: 40,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 15),
                    Flexible(
                      child: Text(
                        "تسجيل خدمة صيانة",
                        style: GoogleFonts.tajawal(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 2. البحث
            GestureDetector(
              onTap: () => _showSearchSheet(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange[700],
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.white, size: 28),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "قائمة العملاء",
                            style: GoogleFonts.tajawal(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "بحث وتعديل بيانات العملاء",
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔴 3. زر الحجوزات مع البادج (الشارة الحمراء للطلبات المعلقة)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where(
                    'workshopId',
                    isEqualTo: widget.workshopId,
                  ) // فلترة خاصة بالورشة
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                int pendingCount = snapshot.hasData
                    ? snapshot.data!.docs.length
                    : 0;
                return _buildListTile(
                  "طلبات الحجز",
                  "إدارة المواعيد القادمة",
                  Icons.calendar_month,
                  () {
                    Navigator.push(
                      context,
                      // ✅ تمرير رقم الورشة للشاشة
                      MaterialPageRoute(
                        builder: (context) => WorkshopBookingsScreen(
                          workshopId: widget.workshopId,
                        ),
                      ),
                    );
                  },
                  badgeCount: pendingCount, // تمرير العدد
                );
              },
            ),

            const SizedBox(height: 20),

            // 4. إدارة المتجر
            _buildListTile(
              "إدارة المتجر والعروض",
              "إضافة قطع غيار وعروض مخصصة لعملائك",
              Icons.storefront,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddPartScreen(workshopId: widget.workshopId),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // 5. الإحصائيات
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    "خدمات اليوم",
                    "0",
                    Icons.today,
                    Colors.blueGrey,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildStatCard("إجمالي الدخل", "0", "﷼", Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // تحديث دالة الأزرار لتدعم الشارة الحمراء (Badge)
  Widget _buildListTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.secondary),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.tajawal(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // --- منطق البحث كما هو ---
  void _showSearchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: StatefulBuilder(
            builder: (context, setStateSheet) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "بحث في قائمة العملاء",
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _searchController,
                    keyboardType: TextInputType.number,
                    maxLength: 9,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: "رقم الجوال",
                      hintText: "5xxxxxxxx",
                      counterText: "",
                      prefixIcon: const Icon(Icons.phone),
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.search,
                          color: AppColors.primary,
                        ),
                        onPressed: () => _performSmartSearch(setStateSheet),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_isSearching)
                    const CircularProgressIndicator()
                  else if (_searchError.isNotEmpty)
                    Text(
                      _searchError,
                      style: const TextStyle(color: Colors.red),
                    )
                  else if (_searchResults.isNotEmpty)
                    Flexible(
                      child: SizedBox(
                        height: 250,
                        child: ListView.separated(
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            var data =
                                _searchResults[index].data()
                                    as Map<String, dynamic>;
                            return ListTile(
                              leading: const Icon(
                                Icons.directions_car,
                                color: AppColors.primary,
                                size: 35,
                              ),
                              title: Text(
                                "${data['make'] ?? ''} ${data['model'] ?? ''}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text("اللوحة: ${data['plate']}"),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => WorkshopCarProfileScreen(
                                        carData: data,
                                        workshopId: widget.workshopId,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text("ملف السيارة"),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        );
      },
    ).whenComplete(() {
      _searchController.clear();
      _searchResults.clear();
      _searchError = '';
    });
  }

  Future<void> _performSmartSearch(StateSetter setStateSheet) async {
    String input = _searchController.text.trim();
    if (input.length < 5) {
      setStateSheet(() => _searchError = "الرقم قصير جداً");
      return;
    }
    setStateSheet(() {
      _isSearching = true;
      _searchError = '';
      _searchResults = [];
    });
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('cars')
          .where('ownerPhone', isEqualTo: input)
          .get();
      if (snapshot.docs.isEmpty)
        snapshot = await FirebaseFirestore.instance
            .collection('cars')
            .where('ownerPhone', isEqualTo: "0$input")
            .get();
      if (snapshot.docs.isEmpty)
        snapshot = await FirebaseFirestore.instance
            .collection('cars')
            .where('ownerPhone', isEqualTo: "+966$input")
            .get();
      setStateSheet(() {
        _isSearching = false;
        if (snapshot.docs.isEmpty)
          _searchError = "لم يتم العثور على نتائج.";
        else
          _searchResults = snapshot.docs;
      });
    } catch (e) {
      setStateSheet(() {
        _isSearching = false;
        _searchError = "خطأ: $e";
      });
    }
  }

  Widget _buildStatCard(String title, String value, Object icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5),
        ],
      ),
      child: Column(
        children: [
          icon is IconData
              ? Icon(icon, color: color, size: 28)
              : Text(
                  icon.toString(),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.tajawal(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}
