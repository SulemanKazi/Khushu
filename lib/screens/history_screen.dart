import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/prayer_models.dart';
import '../state/prayer_controller.dart';
import 'daily_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Consumer<PrayerController>(
        builder: (context, controller, _) {
          final logs = controller.history();
          if (logs.isEmpty) {
            return const _EmptyHistory();
          }

          final recentLogs = logs.take(14).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              SizedBox(
                height: 220,
                child: _CompletionChart(logs: recentLogs.reversed.toList()),
              ),
              const SizedBox(height: 24),
              ...logs.map(
                (log) => _HistoryTile(
                  log: log,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DailyDetailScreen(log: log),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bar_chart,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'Your progress will appear here once you complete a prayer.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CompletionChart extends StatelessWidget {
  const _CompletionChart({required this.logs});

  final List<DailyPrayerLog> logs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Last ${logs.length} days', style: theme.textTheme.titleSmall),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: logs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final count = log.completedCount;
                  final factor = count / PrayerType.values.length;
                  final dateLabel = _formatDate(log.date);
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: 140,
                        width: 32,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: 140 * factor,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.secondary,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('$count/5', style: theme.textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text(
                        dateLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';

    final month = _monthNames[date.month - 1];
    return '${date.day} $month';
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.log, required this.onTap});

  final DailyPrayerLog log;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = log.completedCount;
    final totalSeconds = log.entries.values.fold<int>(
      0,
      (sum, entry) => sum + entry.secondsSpent,
    );
    final minutes = (totalSeconds / 60).floor();

    return Card(
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.25),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        title: Text(_formatFullDate(log.date)),
        subtitle: Text('$completed prayers · ~$minutes minutes'),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    final month = _monthNames[date.month - 1];
    return '${date.day} $month ${date.year}';
  }
}

const List<String> _monthNames = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
