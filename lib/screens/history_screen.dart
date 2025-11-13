import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
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

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _CompletionChart(logs: logs),
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

class _CompletionChart extends StatefulWidget {
  const _CompletionChart({required this.logs});

  final List<DailyPrayerLog> logs;

  @override
  State<_CompletionChart> createState() => _CompletionChartState();
}

class _CompletionChartState extends State<_CompletionChart> {
  int _weekIndex = 0;
  late List<_WeekBucket> _weeks;

  @override
  void initState() {
    super.initState();
    _weeks = _generateWeeks(widget.logs);
  }

  @override
  void didUpdateWidget(covariant _CompletionChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _weeks = _generateWeeks(widget.logs);
    final maxIndex = _weeks.isEmpty ? 0 : _weeks.length - 1;
    if (_weekIndex > maxIndex) {
      _weekIndex = maxIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chartTheme = theme.colorScheme;

    if (_weeks.isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: chartTheme.surfaceContainerHighest.withOpacity(0.15),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Prayer time trend', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Text(
                'Complete at least one session to see your weekly progress.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    final bucket = _weeks[_weekIndex];
  final maxMinutes = bucket.points.fold<double>(0, (value, point) => math.max(value, point.totalMinutes));
  final maxY = maxMinutes == 0 ? 10.0 : (maxMinutes * 1.2).ceilToDouble();
    final yInterval = _calculateInterval(maxY);
    final spots = <FlSpot>[
      for (var i = 0; i < bucket.points.length; i++)
        FlSpot(i.toDouble(), bucket.points[i].totalMinutes),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: chartTheme.surfaceContainerHighest.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prayer time trend', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              _formatWeekRange(bucket.start, bucket.end),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    enabled: true,
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        final defaultStyle = theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);
                        return touchedSpots.map((spot) {
                          final point = bucket.points[spot.spotIndex];
                          final minutes = point.totalMinutes.round();
                          return LineTooltipItem(
                            '$minutes min\n${point.completedCount}/5 prayers',
                            defaultStyle.copyWith(color: chartTheme.onSurface),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  minX: 0.0,
                  maxX: bucket.points.isEmpty ? 0.0 : (bucket.points.length - 1).toDouble(),
                  minY: 0.0,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    verticalInterval: 1.0,
                    horizontalInterval: yInterval,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: chartTheme.outlineVariant.withOpacity(0.2),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: chartTheme.outlineVariant.withOpacity(0.1),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          final index = value.round();
                          if (index < 0 || index >= bucket.points.length) {
                            return const SizedBox.shrink();
                          }
                          final label = _formatDayLabel(bucket.points[index].date);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              label,
                              style: theme.textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: yInterval,
                        getTitlesWidget: (value, meta) {
                          if (value < 0) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            value.round().toString(),
                            style: theme.textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 3,
                      color: chartTheme.primary,
                      dashArray: const [6, 6],
                      belowBarData: BarAreaData(show: false),
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          final point = bucket.points[index];
                          final dotColor = _dotColorFor(point.completedCount, chartTheme);
                          return FlDotCirclePainter(
                            radius: 5,
                            color: dotColor,
                            strokeWidth: 2,
                            strokeColor: chartTheme.surface,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.start,
                    children: const [
                      _LegendEntry(color: Colors.green, label: '5 prayers'),
                      _LegendEntry(color: Colors.orange, label: '4 prayers'),
                      _LegendEntry(color: Colors.red, label: '< 3 prayers'),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Previous week',
                      onPressed: _weekIndex < _weeks.length - 1
                          ? () => setState(() => _weekIndex += 1)
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    IconButton(
                      tooltip: 'Next week',
                      onPressed: _weekIndex > 0
                          ? () => setState(() => _weekIndex -= 1)
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static List<_WeekBucket> _generateWeeks(List<DailyPrayerLog> logs) {
    if (logs.isEmpty) {
      return const [];
    }

    final sorted = List<DailyPrayerLog>.from(logs)
      ..sort((a, b) => b.date.compareTo(a.date));
    final byDate = <String, DailyPrayerLog>{
      for (final log in sorted) log.dateKey: log,
    };
  final latest = sorted.first.date;
  final earliest = sorted.last.date;
  final earliestDay = DateTime(earliest.year, earliest.month, earliest.day);

    final weeks = <_WeekBucket>[];
    var weekEnd = DateTime(latest.year, latest.month, latest.day);

  while (!weekEnd.isBefore(earliestDay)) {
      final weekStart = weekEnd.subtract(const Duration(days: 6));
      final points = <_DayPoint>[];
      for (var i = 0; i < 7; i++) {
        final day = weekStart.add(Duration(days: i));
        final key = _dateKey(day);
        final log = byDate[key];
        final totalSeconds = log?.entries.values.fold<int>(0, (sum, entry) => sum + entry.secondsSpent) ?? 0;
        final totalMinutes = totalSeconds / 60.0;
        final completedCount = log?.completedCount ?? 0;
        points.add(
          _DayPoint(
            date: day,
            totalMinutes: totalMinutes,
            completedCount: completedCount,
          ),
        );
      }

      weeks.add(_WeekBucket(start: weekStart, end: weekEnd, points: points));
      weekEnd = weekStart.subtract(const Duration(days: 1));
    }

    return weeks;
  }

  static String _dateKey(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static double _calculateInterval(double maxY) {
    if (maxY <= 10) return 2.0;
    if (maxY <= 30) return 5.0;
    if (maxY <= 60) return 10.0;
    return (maxY / 6).ceilToDouble() * 5.0;
  }

  static Color _dotColorFor(int completedCount, ColorScheme scheme) {
    if (completedCount >= 5) {
      return Colors.green;
    }
    if (completedCount == 4) {
      return Colors.orange;
    }
    return Colors.red;
  }

  static String _formatWeekRange(DateTime start, DateTime end) {
    final startLabel = _formatDayLabel(start);
    final endLabel = _formatDayLabel(end);
    return '$startLabel - $endLabel';
  }
}

class _WeekBucket {
  const _WeekBucket({required this.start, required this.end, required this.points});

  final DateTime start;
  final DateTime end;
  final List<_DayPoint> points;
}

class _DayPoint {
  const _DayPoint({required this.date, required this.totalMinutes, required this.completedCount});

  final DateTime date;
  final double totalMinutes;
  final int completedCount;
}

class _LegendEntry extends StatelessWidget {
  const _LegendEntry({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

String _formatDayLabel(DateTime date) {
  final month = _monthNames[date.month - 1];
  return '${date.day} $month';
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
