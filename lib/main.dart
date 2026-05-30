// =============================================================================
// Neon Drift Mini
// Entry point. Sets up:
//  - Portrait-only orientation (this is a vertical mobile game)
//  - Transparent status bar with light icons (looks good on the dark theme)
//  - Material 3 theme (custom neon palette)
//  - Initial route: HomeScreen
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  // Required before any platform-channel call (SystemChrome).
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation — the gameplay layout is designed for portrait.
  SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  // Transparent status bar so our gradient flows behind it.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));

  runApp(const NeonDriftApp());
}

class NeonDriftApp extends StatelessWidget {
  const NeonDriftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neon Drift Mini',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkNeonTheme(),
      home: const HomeScreen(),
    );
  }
}
