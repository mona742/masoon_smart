// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:masoon_smart/main.dart';

void main() {
  testWidgets('فحص تشغيل التطبيق الأساسي', (WidgetTester tester) async {
    // ✅ تمرير القيم المطلوبة (isLoggedIn, userRole, userPhone) لنجاح الاختبار
    await tester.pumpWidget(
      const MasoonSmartApp(
        isLoggedIn: false,
        userRole: 'customer',
        userPhone: '',
      ),
    );

    // التحقق من أن التطبيق تم بناؤه بنجاح
    expect(find.byType(MasoonSmartApp), findsOneWidget);
  });
}
