import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/prayer_list_screen.dart';
import 'state/prayer_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = PrayerController();
  await controller.load();
  runApp(PrayerTimesApp(controller: controller));
}

class PrayerTimesApp extends StatelessWidget {
  const PrayerTimesApp({super.key, required this.controller});

  final PrayerController controller;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PrayerController>.value(
      value: controller,
      child: MaterialApp(
        title: 'Prayer Focus',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const PrayerListScreen(),
      ),
    );
  }

  ThemeData _buildTheme() {
    final dark = ThemeData.dark(useMaterial3: true);
    final scheme = dark.colorScheme.copyWith(
      primary: const Color(0xFFB388FF),
      onPrimary: Colors.black,
      secondary: const Color(0xFF7C4DFF),
      tertiary: const Color(0xFF64FFDA),
      surface: const Color(0xFF101018),
      surfaceContainerHighest: const Color(0xFF1F1F2E),
      onSurface: Colors.white,
      onSurfaceVariant: Colors.white70,
    );

    return dark.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: dark.textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardColor: scheme.surfaceContainerHighest,
      textTheme: dark.textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.primary.withOpacity(0.6)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      sliderTheme: dark.sliderTheme.copyWith(
        trackHeight: 4,
        thumbColor: scheme.primary,
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.onSurfaceVariant.withOpacity(0.3),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      ),
    );
  }
}
