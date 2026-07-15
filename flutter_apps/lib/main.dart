import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'core/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiService(baseUrl: _resolveBaseUrl());
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routes: {
        '/login': (_) => LoginScreen(api: api),
        '/register': (_) => RegisterScreen(api: api),
      },
      home: OnboardingScreen(api: api),
    );
  }

  String _resolveBaseUrl() {
    const fromEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return 'http://127.0.0.1:8000';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.254.169.48:8000';
      default:
        return 'http://127.0.0.1:8000';
    }
  }
}
