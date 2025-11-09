import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/prayer_models.dart';
import '../state/prayer_controller.dart';
import 'history_screen.dart';
import 'prayer_timer_screen.dart';

class PrayerListScreen extends StatelessWidget {
  const PrayerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: controller.prayers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final prayer = controller.prayers[index];
              final duration = controller.totalDuration(prayer.type);
              final isCompleted = controller.isCompleted(prayer.type);
              return _PrayerTile(
                info: prayer,
                duration: duration,
                isCompleted: isCompleted,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          PrayerTimerScreen(prayerType: prayer.type),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _PrayerTile extends StatelessWidget {
  const _PrayerTile({
    required this.info,
    required this.duration,
    required this.isCompleted,
    required this.onTap,
  });

  final PrayerInfo info;
  final Duration duration;
  final bool isCompleted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final timeLabel = seconds == 0
        ? '${minutes.toString().padLeft(2, '0')}:00'
        : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.8),
                      theme.colorScheme.secondary,
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  info.label.substring(0, 1),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(info.label, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Timer: $timeLabel',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCompleted)
                Icon(Icons.check_circle, color: theme.colorScheme.tertiary),
            ],
          ),
        ),
      ),
    );
  }
}
