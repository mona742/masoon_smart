import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../viewmodels/login_vm.dart'; // تأكدي أن مسار الـ ViewModel صحيح

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. حقن الـ ViewModel في الشاشة
    return ChangeNotifierProvider(
      create: (_) => LoginViewModel(),
      child: Scaffold(
        // يسمح للشاشة بالتقلص عند ظهور لوحة المفاتيح
        resizeToAvoidBottomInset: true,
        // 2. المستهلك: يستمع لأي تغيير ويحدث الواجهة
        body: Consumer<LoginViewModel>(
          builder: (context, vm, child) {
            return Stack(
              children: [
                // --- 1. الخلفية الثابتة (تتغير ألوانها بناءً على الدور) ---
                Container(
                  height: double.infinity,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: vm.isWorkshopOwner
                          ? [Colors.blueGrey.shade900, Colors.blueGrey.shade700]
                          : [Colors.blue.shade900, Colors.blue.shade500],
                    ),
                  ),
                ),

                // --- 2. المحتوى القابل للتمرير ---
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
                              constraints: const BoxConstraints(maxWidth: 500),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // الأيقونة (تتغير حسب الدور)
                                  Icon(
                                    vm.isWorkshopOwner
                                        ? Icons.build_circle
                                        : Icons.shield_moon,
                                    size: 80,
                                    color: Colors.white,
                                  ),
                                  // اسم التطبيق
                                  Text(
                                    "مصون",
                                    style: GoogleFonts.cairo(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  // الوصف
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

                                  // --- مفتاح التبديل (عميل / ورشة) ---
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

                                  // --- البطاقة البيضاء (منطقة الإدخال) ---
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
                                        // العنوان يتغير (تسجيل دخول / أدخل الرمز)
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

                                        // --- الحالة 1: قبل إرسال الرمز (إدخال الهاتف) ---
                                        if (!vm.otpSent) ...[
                                          TextField(
                                            controller: vm
                                                .phoneController, // ✅ استخدام الكنترولر من الـ VM
                                            keyboardType: TextInputType.phone,
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

                                          // زر إرسال الرمز
                                          SizedBox(
                                            height: 50,
                                            child: ElevatedButton(
                                              // ✅ تمرير الـ context للدالة لإظهار التنبيهات
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
                                        // --- الحالة 2: بعد إرسال الرمز (إدخال OTP) ---
                                        else ...[
                                          TextField(
                                            controller: vm
                                                .otpController, // ✅ استخدام الكنترولر من الـ VM
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
                                            inputFormatters: [
                                              LengthLimitingTextInputFormatter(
                                                4,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),

                                          // زر الدخول النهائي
                                          SizedBox(
                                            height: 50,
                                            child: ElevatedButton(
                                              // ✅ استدعاء دالة التحقق
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
                                          // زر التراجع لتغيير الرقم
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

  // --- دالة مساعدة لبناء أزرار التبديل (Tabs) ---
  Widget _buildRoleTab(LoginViewModel vm, String title, bool isWorkshop) {
    bool isSelected = vm.isWorkshopOwner == isWorkshop;
    return GestureDetector(
      onTap: () =>
          vm.toggleRole(isWorkshop), // ✅ استدعاء دالة التغيير في الـ VM
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
