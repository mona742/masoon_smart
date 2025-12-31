import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'client_dashboard.dart';
import 'workshop_home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _otpSent = false;
  bool _isWorkshopOwner = false;

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Scaffold هو الهيكل الرئيسي
    return Scaffold(
      // resizeToAvoidBottomInset: true يسمح للشاشة بالتقلص عند فتح الكيبورد
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // 1. الخلفية الثابتة (لا تتحرك مع الكيبورد)
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _isWorkshopOwner
                    ? [Colors.blueGrey.shade900, Colors.blueGrey.shade700]
                    : [Colors.blue.shade900, Colors.blue.shade500],
              ),
            ),
          ),

          // 2. المحتوى القابل للتمرير
          // نستخدم LayoutBuilder لمعرفة ارتفاع الشاشة المتاح
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                // هذا السطر مهم: يجعل الكيبورد يختفي عند لمس الشاشة
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  // نجبر المحتوى أن يكون ارتفاعه على الأقل بحجم الشاشة
                  // لكي تعمل خاصية Center بشكل صحيح
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Container(
                        // تحديد عرض أقصى للتابلت، وعرض كامل للجوال
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isWorkshopOwner
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
                              _isWorkshopOwner
                                  ? "بوابة الشركاء والورش"
                                  : "حماية وصيانة لمركبتك",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),

                            const SizedBox(height: 30),

                            // مفتاح التبديل
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildRoleTab("عميل", false),
                                  _buildRoleTab("صاحب ورشة", true),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),

                            // البطاقة البيضاء
                            Container(
                              padding: const EdgeInsets.all(25),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    _otpSent
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

                                  if (!_otpSent) ...[
                                    TextField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      decoration: InputDecoration(
                                        labelText: "رقم الجوال",
                                        prefixIcon: const Icon(Icons.phone),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        hintText: "05xxxxxxxx",
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            _otpSent = true;
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _isWorkshopOwner
                                              ? Colors.blueGrey[800]
                                              : Colors.blue[900],
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text(
                                          "إرسال الرمز",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    TextField(
                                      controller: _otpController,
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
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(4),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          if (_otpController.text == "1234") {
                                            if (_isWorkshopOwner) {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      WorkshopHomeScreen(),
                                                ),
                                              );
                                            } else {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      ClientDashboard(),
                                                ),
                                              );
                                            }
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text("الرمز غير صحيح"),
                                              ),
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green[700],
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
                                      onPressed: () => setState(() {
                                        _otpSent = false;
                                      }),
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
      ),
    );
  }

  Widget _buildRoleTab(String title, bool isWorkshop) {
    bool isSelected = _isWorkshopOwner == isWorkshop;
    return GestureDetector(
      onTap: () => setState(() {
        _isWorkshopOwner = isWorkshop;
      }),
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
