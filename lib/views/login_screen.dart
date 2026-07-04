import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // مطلوب لاستخدام inputFormatters (لتقييد الإدخال)
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../viewmodels/login_vm.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. ربط الشاشة بالـ ViewModel الخاص بها
    return ChangeNotifierProvider(
      create: (_) => LoginViewModel(),
      child: Scaffold(
        resizeToAvoidBottomInset: true, // لرفع الشاشة عند فتح الكيبورد
        body: Consumer<LoginViewModel>(
          builder: (context, vm, child) {
            return Stack(
              children: [
                // 🔴 الخلفية الذكية: يتغير لونها بناءً على دور المستخدم
                Container(
                  height: double.infinity,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      // ألوان داكنة للورشة، وألوان زرقاء للعميل
                      colors: vm.isWorkshopOwner
                          ? [Colors.blueGrey.shade900, Colors.blueGrey.shade700]
                          : [Colors.blue.shade900, Colors.blue.shade500],
                    ),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Container(
                              constraints: const BoxConstraints(
                                maxWidth: 500,
                              ), // للحفاظ على التصميم في الشاشات الكبيرة
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // أيقونة متغيرة حسب الدور
                                  Icon(
                                    vm.isWorkshopOwner
                                        ? Icons.build_circle
                                        : Icons.shield_moon,
                                    size: 80,
                                    color: Colors.white,
                                  ),
                                  Text(
                                    "مصون",
                                    style: GoogleFonts.cairo(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    vm.isWorkshopOwner
                                        ? "بوابة الشركاء والورش"
                                        : "حماية وصيانة لمركبتك",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 30),

                                  // أزرار التبديل (عميل / ورشة)
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildRoleTab(vm, "عميل", false),
                                        _buildRoleTab(vm, "صاحب ورشة", true),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 30),

                                  // 🔴 المربع الأبيض الذي يحتوي على الحقول
                                  Container(
                                    padding: const EdgeInsets.all(25),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          vm.otpSent
                                              ? "أدخل رمز التحقق"
                                              : "تسجيل الدخول",
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 20),

                                        // 🔴 الحالة الأولى: إدخال رقم الجوال
                                        if (!vm.otpSent) ...[
                                          TextField(
                                            controller: vm.phoneController,
                                            keyboardType: TextInputType
                                                .phone, // إظهار كيبورد الأرقام فقط
                                            // 🔴 هذا الجزء هو الذي يمنع المستخدم من إدخال حروف أو أرقام أكثر من 10
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly, // يمنع المسافات والحروف والرموز
                                              LengthLimitingTextInputFormatter(
                                                10,
                                              ), // يحدد الحد الأقصى بـ 10 أرقام
                                            ],
                                            decoration: InputDecoration(
                                              labelText: "رقم الجوال",
                                              prefixIcon: const Icon(
                                                Icons.phone,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              hintText: "05xxxxxxxx",
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          SizedBox(
                                            height: 50,
                                            child: ElevatedButton(
                                              onPressed: vm.isLoading
                                                  ? null
                                                  : () => vm.sendOtp(context),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    vm.isWorkshopOwner
                                                    ? Colors.blueGrey[800]
                                                    : Colors.blue[900],
                                                foregroundColor: Colors.white,
                                              ),
                                              child: vm.isLoading
                                                  ? const CircularProgressIndicator(
                                                      color: Colors.white,
                                                    )
                                                  : const Text(
                                                      "إرسال الرمز",
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ]
                                        // 🔴 الحالة الثانية: إدخال رمز التحقق (OTP)
                                        else ...[
                                          TextField(
                                            controller: vm.otpController,
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 10.0,
                                            ),
                                            decoration: InputDecoration(
                                              labelText: "رمز OTP (جرب 1234)",
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            // 🔴 تقييد الرمز بـ 4 أرقام فقط
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                              LengthLimitingTextInputFormatter(
                                                4,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),
                                          SizedBox(
                                            height: 50,
                                            child: ElevatedButton(
                                              onPressed: () =>
                                                  vm.verifyOtp(context),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.green[700],
                                                foregroundColor: Colors.white,
                                              ),
                                              child: const Text(
                                                "دخول",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                vm.changePhoneNumber(),
                                            child: const Text("تغيير الرقم"),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // تصميم أزرار التبديل (عميل/ورشة)
  Widget _buildRoleTab(LoginViewModel vm, String title, bool isWorkshop) {
    bool isSelected = vm.isWorkshopOwner == isWorkshop;
    return GestureDetector(
      onTap: () => vm.toggleRole(isWorkshop),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
