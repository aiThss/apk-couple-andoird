import 'package:couple_snap/main.dart';
import 'package:couple_snap/services/api_service.dart';
import 'package:couple_snap/theme/dynamic_theme_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows cloud onboarding when no session exists', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      CoupleSnapApp(
        apiService: ApiService(),
        dynamicThemeController: DynamicThemeController(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Couple Snap'), findsOneWidget);
    expect(find.text('Setup couple cua hai nguoi'), findsOneWidget);
  });
}
