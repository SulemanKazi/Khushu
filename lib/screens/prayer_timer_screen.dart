import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/prayer_models.dart';
import '../state/prayer_controller.dart';
import '../widgets/animated_progress_ring.dart';

class PrayerTimerScreen extends StatelessWidget {
  const PrayerTimerScreen({super.key, required this.prayerType});

  final PrayerType prayerType;

  @override
  Widget build(BuildContext context) {
    return Consumer<PrayerController>(
      builder: (context, controller, _) {
        final info = controller.prayers.firstWhere(
          (item) => item.type == prayerType,
        );
        final total = controller.totalDuration(prayerType);
        final remaining = controller.remaining(prayerType);
        final isRunning = controller.isRunning(prayerType);
        final isPaused = controller.isPaused(prayerType);
        final isCompleted = controller.isCompleted(prayerType);
        final totalSeconds = total.inSeconds;
        final remainingSeconds = remaining.inSeconds.clamp(0, totalSeconds);
        final progress = totalSeconds == 0
            ? 0.0
            : (totalSeconds - remainingSeconds) / totalSeconds;

        return Scaffold(
          appBar: AppBar(
            title: Text(info.label),
            actions: [
              IconButton(
                icon: const Icon(Icons.timer_outlined),
                tooltip: 'Adjust duration',
                onPressed: () =>
                    _showDurationSheet(context, controller, info, total),
              ),
              PopupMenuButton<_TimerMenuAction>(
                onSelected: (action) => _handleMenuAction(action, controller),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: _TimerMenuAction.resetCompletion,
                    child: Text('Clear completion for today'),
                  ),
                  const PopupMenuItem(
                    value: _TimerMenuAction.restoreDefault,
                    child: Text('Restore default duration'),
                  ),
                ],
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _TimerRing(
                          progress: progress,
                          remaining: remaining,
                          total: total,
                          isActive: isRunning || isPaused,
                          isCompleted: isCompleted,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          isCompleted
                              ? 'Completed for today'
                              : isRunning
                              ? 'Prayer in progress'
                              : isPaused
                              ? 'Paused'
                              : 'Ready when you are',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  _TimerControls(
                    prayerType: prayerType,
                    isRunning: isRunning,
                    isPaused: isPaused,
                    isCompleted: isCompleted,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDurationSheet(
    BuildContext context,
    PrayerController controller,
    PrayerInfo info,
    Duration currentDuration,
  ) {
    final minMinutes = 3.0;
    final maxMinutes = 45.0;
    final currentMinutes = currentDuration.inMinutes
        .clamp(minMinutes.toInt(), maxMinutes.toInt())
        .toDouble();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        double tempMinutes = currentMinutes;
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set duration for ${info.label}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${tempMinutes.toInt()} minutes',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Slider(
                    value: tempMinutes,
                    min: minMinutes,
                    max: maxMinutes,
                    divisions: (maxMinutes - minMinutes).toInt(),
                    label: '${tempMinutes.toInt()} min',
                    onChanged: (value) {
                      setState(() {
                        tempMinutes = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          final minutes = tempMinutes.round().clamp(
                            minMinutes.toInt(),
                            maxMinutes.toInt(),
                          );
                          controller.setDuration(
                            prayerType,
                            Duration(minutes: minutes),
                          );
                          Navigator.of(context).maybePop();
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _handleMenuAction(_TimerMenuAction action, PrayerController controller) {
    switch (action) {
      case _TimerMenuAction.resetCompletion:
        controller.resetCompletion(prayerType);
        break;
      case _TimerMenuAction.restoreDefault:
        final info = controller.prayers.firstWhere(
          (item) => item.type == prayerType,
        );
        controller.setDuration(prayerType, info.defaultDuration);
        break;
    }
  }
}

class _TimerRing extends StatelessWidget {
  const _TimerRing({
    required this.progress,
    required this.remaining,
    required this.total,
    required this.isActive,
    required this.isCompleted,
  });

  final double progress;
  final Duration remaining;
  final Duration total;
  final bool isActive;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String format(Duration duration) {
      final minutes = duration.inMinutes.remainder(60);
      final hours = duration.inHours;
      final seconds = duration.inSeconds.remainder(60);
      if (hours > 0) {
        return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      }
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            AnimatedProgressRing(
              progress: progress,
              size: 220,
              isActive: isActive,
              isCompleted: isCompleted,
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  format(remaining),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'of ${format(total)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _TimerControls extends StatelessWidget {
  const _TimerControls({
    required this.prayerType,
    required this.isRunning,
    required this.isPaused,
    required this.isCompleted,
  });

  final PrayerType prayerType;
  final bool isRunning;
  final bool isPaused;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<PrayerController>();

    String primaryLabel;
    VoidCallback primaryAction;
    if (isRunning) {
      primaryLabel = 'Pause';
      primaryAction = () => controller.pauseTimer(prayerType);
    } else if (isCompleted) {
      primaryLabel = 'Restart';
      primaryAction = () => controller.startTimer(prayerType);
    } else if (isPaused) {
      primaryLabel = 'Resume';
      primaryAction = () => controller.resumeTimer(prayerType);
    } else {
      primaryLabel = 'Start';
      primaryAction = () => controller.startTimer(prayerType);
    }

    final showComplete = isRunning || isPaused;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: primaryAction,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(primaryLabel),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {
            if (showComplete) {
              controller.completePrayer(prayerType);
            } else if (isCompleted) {
              controller.resetCompletion(prayerType);
            } else {
              controller.stopTimer(prayerType);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              showComplete
                  ? 'Complete Prayer'
                  : isCompleted
                  ? 'Clear completion for today'
                  : 'Reset',
            ),
          ),
        ),
      ],
    );
  }
}

enum _TimerMenuAction { resetCompletion, restoreDefault }
