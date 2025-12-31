import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/inventory_vm.dart';

class AddPartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InventoryViewModel(),
      child: Scaffold(
        appBar: AppBar(title: Text("إضافة قطعة جديدة (المخزون)")),
        body: Consumer<InventoryViewModel>(
          builder: (context, vm, _) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "بيانات القطعة",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 15),
                  TextField(
                    controller: vm.nameController,
                    decoration: InputDecoration(
                      labelText: "اسم القطعة (مثال: فحمات سيراميك)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: vm.skuController,
                          decoration: InputDecoration(
                            labelText: "رمز القطعة (SKU)",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: vm.priceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "السعر (ريال)",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 30),
                  Text(
                    "التوافق (الذكاء الاصطناعي)",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    "حدد الموديلات التي تركب عليها هذه القطعة لكي نرسل إشعاراً لأصحابها فقط.",
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: vm.modelInputController,
                          decoration: InputDecoration(
                            labelText: "اكتب الموديل (مثال: Toyota Camry 2020)",
                            border: OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.add_circle, color: Colors.blue),
                              onPressed: vm.addCompatibleModel,
                            ),
                          ),
                          onSubmitted: (_) => vm.addCompatibleModel(),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),

                  // عرض التاقات (Chips) للموديلات المضافة
                  Wrap(
                    spacing: 8,
                    children: vm.compatibleModels
                        .map(
                          (model) => Chip(
                            label: Text(model),
                            deleteIcon: Icon(Icons.close, size: 18),
                            onDeleted: () => vm.removeModel(model),
                            backgroundColor: Colors.blue[50],
                          ),
                        )
                        .toList(),
                  ),

                  SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => vm.saveSparePart(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        "حفظ القطعة وإرسال التنبيهات",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
