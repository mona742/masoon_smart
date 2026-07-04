// lib/views/workshop_inventory_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../viewmodels/inventory_vm.dart';
import 'add_part_screen.dart';

class WorkshopInventoryScreen extends StatelessWidget {
  final String workshopId;
  const WorkshopInventoryScreen({super.key, required this.workshopId});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<InventoryViewModel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "مخزون الورشة والعروض",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('spare_parts')
            .where('workshopId', isEqualTo: workshopId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          var parts = snapshot.data!.docs;
          if (parts.isEmpty)
            return const Center(child: Text("لا توجد قطع مضافة حالياً"));

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: parts.length,
            itemBuilder: (context, index) {
              var partDoc = parts[index];
              var partData = partDoc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                child: ListTile(
                  title: Text(
                    partData['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("السعر: ${partData['price']} ﷼"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // زر التعديل
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          vm.prepareForEdit(partData);
                          _showEditDialog(context, vm, partDoc.id);
                        },
                      ),
                      // زر الحذف
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            _confirmDelete(context, vm, partDoc.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // حوار تأكيد الحذف
  void _confirmDelete(BuildContext context, InventoryViewModel vm, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("تأكيد الحذف", style: GoogleFonts.cairo()),
        content: const Text("هل أنت متأكد من حذف هذه القطعة نهائياً؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () {
              vm.deletePart(context, id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              "نعم، احذف",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // حوار تأكيد التعديل (اختياري، أو يمكن الانتقال لشاشة التعديل مباشرة)
  void _showEditDialog(BuildContext context, InventoryViewModel vm, String id) {
    // هنا سننتقل لشاشة AddPartScreen ولكن بوضع "التعديل"
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddPartScreen(workshopId: workshopId, isEdit: true, partId: id),
      ),
    );
  }
}
