import 'package:flutter/material.dart';

import 'screens/auth_gate.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'theme/dynamic_theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiService = ApiService();
  await apiService.loadSettings();
  final dynamicThemeController = DynamicThemeController();

  runApp(
    CoupleSnapApp(
      apiService: apiService,
      dynamicThemeController: dynamicThemeController,
    ),
  );
}

class CoupleSnapApp extends StatelessWidget {
  const CoupleSnapApp({
    required this.apiService,
    required this.dynamicThemeController,
    super.key,
  });

  final ApiService apiService;
  final DynamicThemeController dynamicThemeController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: dynamicThemeController,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Couple Snap',
          theme: AppTheme.light(dynamicThemeController.seedColor),
          home: AuthGate(
            apiService: apiService,
            dynamicThemeController: dynamicThemeController,
          ),
        );
      },
    );
  }
}
