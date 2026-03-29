// lib/views/add_part_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../colors.dart';

class AddPartScreen extends StatefulWidget {
  final String? workshopId;

  const AddPartScreen({super.key, this.workshopId});

  @override
  State<AddPartScreen> createState() => _AddPartScreenState();
}

class _AddPartScreenState extends State<AddPartScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discountPriceController =
      TextEditingController();
  final TextEditingController _modelInputController = TextEditingController();

  List<String> _compatibleModels = [];

  void _addModel() {
    String text = _modelInputController.text.trim().toUpperCase();
    if (text.isNotEmpty && !_compatibleModels.contains(text)) {
      setState(() {
        _compatibleModels.add(text);
        _modelInputController.clear();
      });
    }
  }

  Future<void> _savePartToFirebase() async {
    if (!_formKey.currentState!.validate()) return;
    if (_compatibleModels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("يرجى إضافة موديل واحد على الأقل للتوافق"),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      double price = double.parse(_priceController.text);
      double discountPrice =
          double.tryParse(_discountPriceController.text) ?? 0.0;

      await FirebaseFirestore.instance.collection('spare_parts').add({
        'name': _nameController.text.trim(),
        'sku': _skuController.text.trim(),
        'price': price,
        'discountPrice': discountPrice,
        'compatibleModels': _compatibleModels,
        'workshopId': widget.workshopId ?? 'unknown',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ تم إضافة القطعة للمتجر الذكي!"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "إضافة قطعة (المتجر الذكي)",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "بيانات القطعة",
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "اسم القطعة (مثال: فحمات سيراميك)",
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val!.isEmpty ? "مطلوب" : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _skuController,
                      decoration: const InputDecoration(
                        labelText: "رمز القطعة (SKU) اختياري",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "السعر الأساسي",
                              suffixText: "﷼",
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) => val!.isEmpty ? "مطلوب" : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _discountPriceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "سعر العرض (اختياري)",
                              suffixText: "﷼",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Text(
                      "التوافق (الفلترة الذكية للعملاء)",
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      "اكتب الماركة أو الموديل (مثال: TOYOTA أو CAMRY) ليتم عرضها لأصحاب هذه السيارات فقط.",
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _modelInputController,
                      decoration: InputDecoration(
                        labelText: "اكتب الموديل واضغط إضافة",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Colors.blue,
                          ),
                          onPressed: _addModel,
                        ),
                      ),
                      onFieldSubmitted: (_) => _addModel(),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: _compatibleModels
                          .map(
                            (model) => Chip(
                              label: Text(model),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () {
                                setState(() => _compatibleModels.remove(model));
                              },
                              backgroundColor: Colors.blue[50],
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _savePartToFirebase,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.storefront, color: Colors.white),
                        label: Text(
                          "حفظ وعرض في متجر العملاء",
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
            ),
    );
  }
}
