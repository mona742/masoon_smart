import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../colors.dart';
import 'login_screen.dart';
import 'workshop_add_service_screen.dart';
import 'workshop_bookings_screen.dart';
import 'workshop_car_profile_screen.dart'; // ✅ تأكد أن هذا الملف موجود

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
  // متغيرات البحث
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];
  bool _isSearching = false;
  String _searchError = '';

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
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الترحيب
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

            // ==========================================
            // 1. الزر الرئيسي: تسجيل خدمة صيانة
            // ==========================================
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkshopAddServiceScreen(
                      workshopId: widget.workshopId, // تمرير الهوية
                    ),
                  ),
                );
              },
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

            // ==========================================
            // 2. زر البحث: قائمة العملاء
            // ==========================================
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

            // زر الحجوزات
            _buildListTile(
              "طلبات الحجز",
              "إدارة المواعيد القادمة",
              Icons.calendar_month,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WorkshopBookingsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // الإحصائيات (بتصميم مرن)
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
                // ✅ هنا التعديل: استخدام رمز الريال المدمج
                Expanded(
                  child: _buildStatCard(
                    "إجمالي الدخل",
                    "0",
                    "﷼", // رمز الريال السعودي المتداخل
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Widgets مساعدة ---

  // ✅ دالة البطاقة المعدلة لتقبل (IconData) أو (String)
  Widget _buildStatCard(
    String title,
    String value,
    Object icon, // غيرنا النوع ليقبل نص أو أيقونة
    Color color,
  ) {
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
          // فحص نوع الأيقونة: إذا كانت أيقونة نعرضها، وإذا نص نعرضه كرمز
          icon is IconData
              ? Icon(icon, color: color, size: 28)
              : Text(
                  icon.toString(),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontFamily: 'Arial', // خط يدعم الرموز جيداً
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

  Widget _buildListTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.secondary),
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

  // --- منطق البحث (قائمة العملاء) ---
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
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _searchError,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
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
                                "${data['make'] ?? 'غير محدد'} ${data['model'] ?? ''}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                "اللوحة: ${data['plate']} \nالمالك: ${data['ownerPhone']}",
                              ),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          WorkshopCarProfileScreen(
                                            carData: data,
                                            workshopId: widget.workshopId,
                                          ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueGrey,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text("ملف السيارة"),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 50),
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

      if (snapshot.docs.isEmpty) {
        snapshot = await FirebaseFirestore.instance
            .collection('cars')
            .where('ownerPhone', isEqualTo: "0$input")
            .get();
      }

      if (snapshot.docs.isEmpty) {
        snapshot = await FirebaseFirestore.instance
            .collection('cars')
            .where('ownerPhone', isEqualTo: "+966$input")
            .get();
      }

      setStateSheet(() {
        _isSearching = false;
        if (snapshot.docs.isEmpty) {
          _searchError = "لم يتم العثور على نتائج.";
        } else {
          _searchResults = snapshot.docs;
        }
      });
    } catch (e) {
      setStateSheet(() {
        _isSearching = false;
        _searchError = "خطأ في الاتصال: $e";
      });
    }
  }
}
