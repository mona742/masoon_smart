import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../colors.dart';
import 'workshop_add_service_screen.dart';

class WorkshopCarProfileScreen extends StatelessWidget {
  final Map<String, dynamic> carData;
  final String workshopId;

  const WorkshopCarProfileScreen({
    super.key,
    required this.carData,
    required this.workshopId,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('yyyy-MM-dd | hh:mm a');

    // توحيد رقم الهيكل للبحث
    final String searchVin = (carData['vin'] ?? '').toString().toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          "ملف المركبة",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // بطاقة السيارة
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10),
              ],
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.directions_car,
                        size: 30,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${carData['make']} ${carData['model'] ?? ''}",
                          style: GoogleFonts.tajawal(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "اللوحة: ${carData['plate']}",
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoItem(
                      Icons.person,
                      "العميل",
                      carData['clientName'] ?? 'غير مسجل',
                    ),
                    _infoItem(
                      Icons.phone,
                      "الجوال",
                      carData['ownerPhone'] ?? '',
                    ),
                    _infoItem(
                      Icons.speed,
                      "العداد",
                      "${carData['currentKm'] ?? 0} كم",
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.history, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Text(
                  "سجل الخدمات",
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),

          // ✅ StreamBuilder المعدل (بدون orderBy مؤقتاً)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('services')
                  .where('carId', isEqualTo: searchVin)
                  .where('workshopId', isEqualTo: workshopId)
                  // .orderBy('lastChangeDate', descending: true) ❌ تم إيقافه مؤقتاً ليظهر السجل
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
                        Icon(
                          Icons.assignment_outlined,
                          size: 60,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "لا يوجد سجل خدمات سابق",
                          style: GoogleFonts.cairo(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var service =
                        snapshot.data!.docs[index].data()
                            as Map<String, dynamic>;
                    Timestamp? ts = service['lastChangeDate'];
                    String date = ts != null
                        ? dateFormatter.format(ts.toDate())
                        : '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 1,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Icon(
                            _getIcon(service['type']),
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          service['name'] ?? 'خدمة',
                          style: GoogleFonts.tajawal(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          "$date  •  ${service['lastChangeKm']} كم",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),

                        // ✅ عرض السعر برمز الريال المدمج
                        trailing: Text(
                          "${service['price'] ?? 0} ﷼",
                          style: GoogleFonts.tajawal(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                            fontSize: 18,
                          ),
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

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkshopAddServiceScreen(
                workshopId: workshopId,
                carData: carData,
              ),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_circle_outline, color: Colors.white),
        label: Text(
          "إضافة خدمة جديدة",
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[400]),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(
          value.length > 15 ? "${value.substring(0, 15)}..." : value,
          style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'oil':
        return Icons.water_drop;
      case 'tires':
        return Icons.tire_repair;
      case 'brakes':
        return Icons.car_crash;
      case 'ac':
        return Icons.ac_unit;
      default:
        return Icons.build;
    }
  }
}
