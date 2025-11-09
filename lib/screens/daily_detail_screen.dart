import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/prayer_models.dart';
import '../state/prayer_controller.dart';

class DailyDetailScreen extends StatelessWidget {
  const DailyDetailScreen({super.key, required this.log});

  final DailyPrayerLog log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = context.read<PrayerController>();

    return Scaffold(
      appBar: AppBar(title: Text(_formatFullDate(log.date))),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        itemCount: controller.prayers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final prayerInfo = controller.prayers[index];
          final entry = log.entries[prayerInfo.type] ?? PrayerEntry();
          final duration = Duration(seconds: entry.secondsSpent);
          final completed = entry.completed;

          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              title: Text(prayerInfo.label),
              subtitle: Text(_formatDuration(duration)),
              trailing: completed
                  ? Icon(Icons.check_circle, color: theme.colorScheme.tertiary)
                  : Icon(
                      Icons.radio_button_unchecked,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
            ),
          );
        },
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    final month = _monthNames[date.month - 1];
    return '${date.day} $month ${date.year}';
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds == 0) {
      return 'No time recorded';
    }

    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    if (minutes == 0) {
      return '$seconds seconds';
    }
    if (seconds == 0) {
      return '$minutes minutes';
    }
    return '$minutes min $seconds sec';
  }
}

const List<String> _monthNames = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
