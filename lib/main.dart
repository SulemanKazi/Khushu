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
    const background = Color(0xFFF7F0E6);
    const cardColor = Color(0xFFFFFBFA);
    const primary = Color(0xFFE2745B);
    const secondary = Color(0xFF5CB8B2);
    const tertiary = Color(0xFFF3C76B);
    const onSurface = Color(0xFF2E2A28);
    const onSurfaceVariant = Color(0xFF726B65);

    final base = ThemeData.light(useMaterial3: true);
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      onSecondary: Colors.white,
      tertiary: tertiary,
      surface: cardColor,
      surfaceTint: Colors.transparent,
      background: background,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      outlineVariant: const Color(0xFFE1D8CF),
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: primary,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: primary),
      ),
      cardColor: cardColor,
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 32,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: onSurface,
        displayColor: onSurface,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary.withOpacity(0.6)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        iconColor: primary,
      ),
      iconTheme: const IconThemeData(color: primary),
      sliderTheme: base.sliderTheme.copyWith(
        trackHeight: 4,
        activeTrackColor: tertiary,
        inactiveTrackColor: tertiary.withOpacity(0.3),
        thumbColor: tertiary,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith(
          (states) => states.contains(MaterialState.selected)
              ? const Color(0xFF51B266)
              : scheme.outlineVariant,
        ),
        checkColor: MaterialStateProperty.all<Color>(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
