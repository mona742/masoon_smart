import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../viewmodels/client_store_vm.dart';

class ClientStoreScreen extends StatelessWidget {
  final Car car;

  // نستقبل بيانات السيارة عند فتح الصفحة لنعرف لمن نفلتر
  const ClientStoreScreen({Key? key, required this.car}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ClientStoreViewModel(car),
      child: Scaffold(
        appBar: AppBar(title: const Text("متجر قطع الغيار")),
        backgroundColor: Colors.grey[50],
        body: Consumer<ClientStoreViewModel>(
          builder: (context, vm, _) {
            return Column(
              children: [
                // 1. شريط التنبيه العلوي (يؤكد للعميل أن الفلتر يعمل)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  color: Colors.blue[50],
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "جميع القطع المعروضة متوافقة تماماً مع سيارتك ${car.make} ${car.model} ${car.year}",
                          style: TextStyle(
                            color: Colors.blue[900],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. شبكة المنتجات
                Expanded(
                  child: vm.filteredParts.isEmpty
                      ? Center(
                          child: Text(
                            "لا توجد قطع متوفرة لهذا الموديل حالياً",
                            style: GoogleFonts.tajawal(fontSize: 16),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(15),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, // عمودين
                                childAspectRatio: 0.75, // نسبة الطول للعرض
                                crossAxisSpacing: 15,
                                mainAxisSpacing: 15,
                              ),
                          itemCount: vm.filteredParts.length,
                          itemBuilder: (context, index) {
                            final part = vm.filteredParts[index];
                            return _buildProductCard(context, part, vm);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    SparePart part,
    ClientStoreViewModel vm,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // صورة المنتج (وهمية)
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
              ),
              child: Icon(
                Icons.settings_suggest,
                size: 60,
                color: Colors.blueGrey[300],
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
                  part.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "متوافق مع ${car.model}",
                  style: const TextStyle(fontSize: 10, color: Colors.green),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${part.price.toInt()} ر.س",
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    InkWell(
                      onTap: () => vm.orderPart(context, part),
                      child: Container(
                        padding: const EdgeInsets.all(5),
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
    );
  }
}

/*```

---

### 3. ربط المتجر بالشاشة الرئيسية للعميل
الآن سنعود لملف `lib/views/client_home_screen.dart` لنجعل زر "مشاهدة الكل" وزر "العروض" يفتحان المتجر الجديد.

افتحي ملف `lib/views/client_home_screen.dart` وقومي بالتعديلات التالية:

**أولاً:** في الأعلى أضيفي استيراد ملف المتجر:
```dart
import 'client_store_screen.dart';
```

**ثانياً:** ابحثي عن زر `TextButton(onPressed: (){}, child: Text("مشاهدة الكل"))` واستبدليه بهذا الكود:
```dart
TextButton(
onPressed: () {
// نمرر بيانات السيارة للمتجر ليقوم بالفلترة
Navigator.push(context, MaterialPageRoute(
builder: (_) => ClientStoreScreen(car: vm.myCar)
));
},
child: const Text("المتجر الكامل")
)*/
