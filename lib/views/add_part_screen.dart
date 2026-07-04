import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../colors.dart';
import '../viewmodels/inventory_vm.dart';

class AddPartScreen extends StatefulWidget {
  final String? workshopId;
  final bool isEdit; // ✅ هل نحن في وضع التعديل؟
  final String? partId; // ✅ معرف القطعة في حال التعديل

  const AddPartScreen({
    super.key,
    this.workshopId,
    this.isEdit = false,
    this.partId,
  });

  @override
  State<AddPartScreen> createState() => _AddPartScreenState();
}

class _AddPartScreenState extends State<AddPartScreen> {
  @override
  void initState() {
    super.initState();
    // إذا كان وضع تعديل، البيانات تكون مسبقة التعبئة من الـ ViewModel
    // (يتم استدعاء vm.prepareForEdit قبل الانتقال لهذه الشاشة)
  }

  // 1. حوار تأكيد التعديل (نعم/لا)
  void _confirmSaveOrUpdate(BuildContext context, InventoryViewModel vm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          widget.isEdit ? "تأكيد التعديل" : "تأكيد الحفظ",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          textAlign: TextAlign.right,
        ),
        content: Text(
          widget.isEdit
              ? "هل أنت متأكد من رغبتك في تحديث بيانات هذا العرض؟"
              : "هل تريد نشر هذا العرض الآن في المتجر الذكي؟",
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // إغلاق الحوار
              if (widget.isEdit) {
                vm.updatePart(context, widget.partId!); // دالة التحديث
              } else {
                vm.savePart(context, widget.workshopId); // دالة الحفظ
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isEdit ? Colors.blue : AppColors.primary,
            ),
            child: Text(
              widget.isEdit ? "نعم، حدّث" : "نعم، احفظ",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<InventoryViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEdit ? "تعديل العرض" : "إضافة قطعة للمتجر",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("بيانات القطعة الأساسية"),
                  _buildTextField(
                    vm.nameController,
                    "اسم القطعة (مثلاً: زيت بترومين)",
                    Icons.inventory_2,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          vm.priceController,
                          "السعر الأصلي",
                          Icons.payments,
                          isNumber: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTextField(
                          vm.discountPriceController,
                          "سعر العرض",
                          Icons.local_offer,
                          isNumber: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    vm.skuController,
                    "رمز القطعة (SKU) اختياري",
                    Icons.qr_code,
                  ),

                  const SizedBox(height: 25),
                  _buildSectionTitle("خيارات العرض المميز"),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.withOpacity(0.2)),
                    ),
                    child: SwitchListTile(
                      title: Text(
                        "ظهور في السلايدر العلوي للعميل",
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "سيظهر كإعلان مميز لأصحاب السيارات المتوافقة",
                        style: GoogleFonts.cairo(fontSize: 11),
                      ),
                      value: vm.isFeatured,
                      onChanged: (val) => vm.toggleFeatured(val),
                      activeColor: Colors.orange,
                    ),
                  ),

                  const SizedBox(height: 25),
                  _buildSectionTitle("التوافق الذكي (Tags)"),
                  TextFormField(
                    controller: vm.modelInputController,
                    decoration: InputDecoration(
                      labelText: "اكتب الماركة أو الموديل (مثلاً: TOYOTA)",
                      prefixIcon: const Icon(Icons.directions_car),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.blue),
                        onPressed: vm.addCompatibleModel,
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    onFieldSubmitted: (_) => vm.addCompatibleModel(),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: vm.compatibleModels
                        .map(
                          (model) => Chip(
                            label: Text(model),
                            onDeleted: () => vm.removeModel(model),
                            backgroundColor: Colors.blue[50],
                            deleteIconColor: Colors.red,
                          ),
                        )
                        .toList(),
                  ),

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmSaveOrUpdate(context, vm),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.isEdit
                            ? Colors.blue[700]
                            : AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(
                        widget.isEdit ? Icons.update : Icons.cloud_upload,
                        color: Colors.white,
                      ),
                      label: Text(
                        widget.isEdit
                            ? "تحديث البيانات الآن"
                            : "نشر العرض في المتجر",
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
