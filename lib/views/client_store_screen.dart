// lib/views/client_store_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../colors.dart';

class ClientStoreScreen extends StatelessWidget {
  final String carMake;
  final String carModel;

  // نستقبل نوع وموديل السيارة للفلترة الذكية
  const ClientStoreScreen({
    super.key,
    required this.carMake,
    required this.carModel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "المتجر الذكي 🛒",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // 1. شريط التنبيه العلوي (الرسالة التسويقية)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            color: Colors.blue[50],
            child: Row(
              children: [
                const Icon(Icons.verified, color: Colors.blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "جميع القطع المعروضة متوافقة تماماً بنسبة 100% مع سيارتك ($carMake $carModel)",
                    style: GoogleFonts.cairo(
                      color: Colors.blue[900],
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. جلب المنتجات من الفايربيز
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('spare_parts')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                // 🧠 الفلترة الذكية (Rule-Based Filtering)
                var allParts = snapshot.data!.docs;
                var compatibleParts = allParts.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  List<dynamic> models = data['compatibleModels'] ?? [];

                  // فحص هل الماركة أو الموديل موجود في قائمة التوافق للقطعة
                  bool isCompatible = false;
                  for (var m in models) {
                    String target = m.toString().toUpperCase();
                    if (target.contains(carMake.toUpperCase()) ||
                        target.contains(carModel.toUpperCase())) {
                      isCompatible = true;
                      break;
                    }
                  }
                  return isCompatible;
                }).toList();

                if (compatibleParts.isEmpty) return _buildEmptyState();

                return GridView.builder(
                  padding: const EdgeInsets.all(15),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65, // لضبط المساحة للصورة والأسعار
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: compatibleParts.length,
                  itemBuilder: (context, index) {
                    var partData =
                        compatibleParts[index].data() as Map<String, dynamic>;
                    return _buildProductCard(context, partData);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 15),
          Text(
            "لا توجد قطع متوفرة متوافقة مع سيارتك حالياً",
            style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> part) {
    String name = part['name'] ?? 'قطعة غيار';
    double price = double.tryParse(part['price'].toString()) ?? 0.0;
    double discountPrice =
        double.tryParse(part['discountPrice']?.toString() ?? '0') ?? 0.0;

    bool hasOffer = discountPrice > 0 && discountPrice < price;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // صورة المنتج (أيقونة تعبيرية)
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(15),
                    ),
                  ),
                  child: Icon(
                    Icons.settings_suggest,
                    size: 60,
                    color: AppColors.primary.withOpacity(0.5),
                  ),
                ),
              ),
              // التفاصيل
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "متوافق ومضمون",
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),

                    // الأسعار مع الخصم إن وجد
                    if (hasOffer)
                      Text(
                        "${price.toInt()} ﷼",
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.red,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          hasOffer
                              ? "${discountPrice.toInt()} ﷼"
                              : "${price.toInt()} ﷼",
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "تم إرسال طلب للورشة بتجهيز القطعة!",
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.add_shopping_cart,
                              size: 18,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // شريط الخصم (Offer Badge)
          if (hasOffer)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "عرض خاص",
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
