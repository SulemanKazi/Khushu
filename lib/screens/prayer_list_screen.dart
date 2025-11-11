import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/prayer_models.dart';
import '../state/prayer_controller.dart';
import 'history_screen.dart';
import 'prayer_timer_screen.dart';

const _prayerAssetMap = <PrayerType, String>{
  PrayerType.fajr: 'resources/Fajar.png',
  PrayerType.dhuhr: 'resources/Dhuhr.png',
  PrayerType.asr: 'resources/Asr.png',
  PrayerType.maghrib: 'resources/Maghrib.png',
  PrayerType.isha: 'resources/Isha.png',
};

const _headerAccent = Color(0xFFD75243);
const _labelColor = Color(0xFFD75243);
const _dividerColor = Color(0xFFE4E6EB);
const _pageBackground = Color(0xFFF5F6F8);
const _completedColor = Color(0xFF2F7D58);
const _incompleteColor = Color(0xFFE0E3E7);
const _incompleteIconColor = Color(0xFF9EA2A9);

class PrayerListScreen extends StatelessWidget {
  const PrayerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF343741),
        title: const Text('Prayer Focus'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'History',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const HistoryScreen())),
          ),
        ],
      ),
      body: Consumer<PrayerController>(
        builder: (context, controller, _) {
          if (!controller.isReady) {
            return const Center(child: CircularProgressIndicator());
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final horizontalInset = constraints.maxWidth > 480 ? 48.0 : 16.0;
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: horizontalInset),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'السلام عليكم',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: _headerAccent,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'resources/border.png',
                              width: double.infinity,
                              height: 36,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListView.separated(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: controller.prayers.length,
                            separatorBuilder: (_, __) => const Divider(
                              color: _dividerColor,
                              height: 1,
                              thickness: 1,
                            ),
                            itemBuilder: (context, index) {
                              final prayer = controller.prayers[index];
                              return _PrayerTile(
                                info: prayer,
                                isCompleted:
                                    controller.isCompleted(prayer.type),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PrayerTimerScreen(
                                        prayerType: prayer.type,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PrayerTile extends StatefulWidget {
  const _PrayerTile({
    required this.info,
    required this.isCompleted,
    required this.onTap,
  });

  final PrayerInfo info;
  final bool isCompleted;
  final VoidCallback onTap;

  @override
  State<_PrayerTile> createState() => _PrayerTileState();
}

class _PrayerTileState extends State<_PrayerTile> {
  double _scale = 1.0;

  void _handleTapDown(TapDownDetails details) {
    setState(() => _scale = 0.97);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
  }

  void _handleTapCancel() {
    setState(() => _scale = 1.0);
  }

  void _handleTap() {
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final assetPath = _prayerAssetMap[widget.info.type];
    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          borderRadius: BorderRadius.circular(20),
          splashColor: _labelColor.withOpacity(0.12),
          highlightColor: Colors.transparent,
          child: Ink(
            decoration: const BoxDecoration(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(
                            0.2,
                          ), // Softer black with opacity
                          offset: const Offset(0, 2), // Shadow slightly below
                          blurRadius: 4.0, // Soft blur
                          spreadRadius: 0.0, // No spread
                        ),
                        // Optional: Add another shadow for more depth
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          offset: const Offset(0, 6),
                          blurRadius: 10.0,
                          spreadRadius: 0.0,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: assetPath != null
                          ? Image.asset(
                              assetPath,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: _incompleteColor,
                              alignment: Alignment.center,
                              child: Text(
                                widget.info.label.substring(0, 1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _headerAccent,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.info.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: _labelColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color:
                          widget.isCompleted ? _completedColor : _incompleteColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (widget.isCompleted)
                          BoxShadow(
                            color: _completedColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.check,
                      size: 18,
                      color:
                          widget.isCompleted ? Colors.white : _incompleteIconColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
