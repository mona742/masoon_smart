import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../views/workshop_home_screen.dart';

class WorkshopProfileViewModel extends ChangeNotifier {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController districtController =
      TextEditingController(); // الحي يدوياً

  // متغيرات الهاتف
  String fullPhoneNumber = "";
  bool isPhoneValid = false;

  // --- 1. قائمة المناطق الثابتة (بالأرقام الصحيحة) ---
  final List<Map<String, dynamic>> regionsList = [
    {"id": 1, "name": "منطقة الرياض"},
    {"id": 2, "name": "منطقة مكة المكرمة"},
    {"id": 3, "name": "المدينة المنورة"},
    {"id": 4, "name": "منطقة القصيم"},
    {"id": 5, "name": "المنطقة الشرقية"},
    {"id": 6, "name": "منطقة عسير"},
    {"id": 7, "name": "منطقة تبوك"},
    {"id": 8, "name": "منطقة حائل"},
    {"id": 9, "name": "منطقة الحدود الشمالية"},
    {"id": 10, "name": "منطقة جازان"},
    {"id": 11, "name": "منطقة نجران"},
    {"id": 12, "name": "منطقة الباحة"},
    {"id": 13, "name": "منطقة الجوف"},
  ];

  List<dynamic> _allCitiesData = []; // البيانات الخام
  List<String> filteredCities = []; // المدن المفلترة للعرض

  // الاختيارات
  int? selectedRegionId;
  String? selectedRegionName;
  String? selectedCity;
  String? selectedSpecialty;

  final List<String> specialties = [
    'ميكانيكا عامة',
    'كهرباء وتكييف',
    'سمكرة ودهان',
    'فحص دوري',
    'قطع غيار',
  ];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  WorkshopProfileViewModel() {
    _loadCitiesData();
  }

  // تحميل ملف المدن
  Future<void> _loadCitiesData() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/json/cities.json',
      );
      _allCitiesData = json.decode(response);
      notifyListeners();
    } catch (e) {
      print("خطأ في قراءة ملف المدن: $e");
    }
  }

  // ✅ الفلترة الذكية بناءً على Region ID
  void setRegion(int? id) {
    selectedRegionId = id;
    if (id != null) {
      selectedRegionName = regionsList.firstWhere((e) => e['id'] == id)['name'];
    }

    selectedCity = null; // تصفير المدينة عند تغيير المنطقة
    filteredCities = [];

    if (id != null) {
      filteredCities = _allCitiesData
          .where((item) => item['region_id'] == id)
          .map((item) => item['name_ar'].toString())
          .toSet()
          .toList();

      filteredCities.sort(); // ترتيب أبجدي
    }
    notifyListeners();
  }

  void setCity(String? city) {
    selectedCity = city;
    notifyListeners();
  }

  void setSpecialty(String? value) {
    selectedSpecialty = value;
    notifyListeners();
  }

  void updatePhone(String number, bool isValid) {
    fullPhoneNumber = number;
    isPhoneValid = isValid;
    notifyListeners();
  }

  // ✅ تعديل دالة الحفظ لتستقبل uid وتمررها للشاشة الرئيسية
  Future<void> saveWorkshopData(BuildContext context, String uid) async {
    if (nameController.text.isEmpty ||
        selectedSpecialty == null ||
        selectedRegionId == null ||
        selectedCity == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("يرجى إكمال البيانات")));
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final workshopData = {
        'name': nameController.text,
        'specialty': selectedSpecialty,
        'region': selectedRegionName,
        'city': selectedCity,
        'district': districtController.text,
        'phone': fullPhoneNumber,
        'createdAt': FieldValue.serverTimestamp(),
        'ownerId': uid, // ✅ الحفظ بنفس الرقم المستخدم في الدخول
      };

      // الحفظ باستخدام الـ uid كمعرف للوثيقة
      await FirebaseFirestore.instance
          .collection('workshops')
          .doc(uid)
          .set(workshopData);

      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            // ✅ التعديل هنا: تمرير workshopId
            builder: (_) => WorkshopHomeScreen(
              workshopName: nameController.text,
              workshopId: uid,
            ),
          ),
        );
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("خطأ: $e")));
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    districtController.dispose();
    super.dispose();
  }
}
