// lib/views/workshop_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/workshop_models.dart';
import '../viewmodels/smart_workshop_vm.dart';

class WorkshopScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // استدعاء البيانات من الـ ViewModel
    final vm = Provider.of<SmartWorkshopViewModel>(context);
    final myCar = vm.cars.first;

    return Scaffold(
      appBar: AppBar(
        title: Text("تطبيق مصون"),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // === الجزء الخاص بالورشة ===
            Container(
              color: Colors.grey[200],
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "🔧 لوحة الفني (الورشة)",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text("السيارة: ${myCar.make} ${myCar.model} - ${myCar.year}"),
                  SizedBox(height: 15),
                  ElevatedButton.icon(
                    icon: Icon(Icons.add_task),
                    label: Text("تسجيل تغيير زيت جديد"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      // محاكاة: الفني يسجل زيت عند 105000 كم
                      vm.addServiceRecord(
                        myCar.id,
                        ServiceType.oilChange,
                        105000,
                        "زيت 5000 كم",
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("تم تسجيل الخدمة بنجاح")),
                      );
                    },
                  ),
                ],
              ),
            ),

            Divider(height: 1, thickness: 2),

            // === الجزء الخاص بالعميل ===
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "📱 شاشة العميل",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                  SizedBox(height: 10),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        children: [
                          Text(
                            "العداد الحالي: ${myCar.currentMileage} كم",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Slider(
                            min: 100000,
                            max: 110000,
                            value: myCar.currentMileage.toDouble(),
                            label: "تحديث العداد",
                            onChanged: (val) {
                              vm.updateMileage(myCar.id, val.toInt());
                            },
                          ),
                          Text(
                            "حرك الشريط لمحاكاة مشي السيارة",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "التنبيهات:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  // عرض التنبيهات
                  if (vm.alerts.isEmpty)
                    Text("لا توجد تنبيهات حالياً")
                  else
                    ...vm.alerts
                        .map(
                          (alert) => Container(
                            margin: EdgeInsets.only(top: 8),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: alert.contains("⚠️")
                                  ? Colors.red[100]
                                  : Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [Expanded(child: Text(alert))],
                            ),
                          ),
                        )
                        .toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
