import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/prayer_models.dart';

const String _customDurationsKey = 'custom_durations';
const String _historyKey = 'prayer_history';
const int _historyRetentionDays = 9000; // Approximately 25 years

class PrayerTimerState {
  PrayerTimerState({
    required this.total,
    Duration? remaining,
    this.isCompleted = false,
  }) : remaining = remaining ?? total,
       accruedSeconds = 0;

  Duration total;
  Duration remaining;
  bool isRunning = false;
  bool isPaused = false;
  bool isCompleted;
  Timer? ticker;
  int accruedSeconds;

  void cancelTicker() {
    ticker?.cancel();
    ticker = null;
  }
}

class PrayerController extends ChangeNotifier {
  PrayerController();

  final List<PrayerInfo> prayers = const [
    PrayerInfo(
      type: PrayerType.fajr,
      defaultDuration: Duration(minutes: 8),
      label: 'Fajr',
    ),
    PrayerInfo(
      type: PrayerType.dhuhr,
      defaultDuration: Duration(minutes: 15),
      label: 'Duhr',
    ),
    PrayerInfo(
      type: PrayerType.asr,
      defaultDuration: Duration(minutes: 8),
      label: 'Asr',
    ),
    PrayerInfo(
      type: PrayerType.maghrib,
      defaultDuration: Duration(minutes: 10),
      label: 'Maghrib',
    ),
    PrayerInfo(
      type: PrayerType.isha,
      defaultDuration: Duration(minutes: 16),
      label: 'Isha',
    ),
  ];

  late final Map<PrayerType, PrayerTimerState> _timers = {
    for (final info in prayers)
      info.type: PrayerTimerState(total: info.defaultDuration),
  };

  final Map<PrayerType, Duration> _customDurations = {};
  final Map<String, DailyPrayerLog> _history = {};

  late DateTime _currentDay;
  bool _isReady = false;
  SharedPreferences? _prefs;

  bool get isReady => _isReady;

  Future<void> load() async {
    _currentDay = _truncateToDate(DateTime.now());
    _prefs = await SharedPreferences.getInstance();

    _restoreCustomDurations();
    _restoreHistory();
    _syncTimerDurations();
    _applyCompletionFlags();

    _isReady = true;
    notifyListeners();
  }

  void _restoreCustomDurations() {
    final raw = _prefs?.getString(_customDurationsKey);
    if (raw == null) {
      return;
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    for (final entry in decoded.entries) {
      final type = prayerTypeFromKey(entry.key);
      final minutes = (entry.value as num?)?.toInt();
      if (minutes == null || minutes <= 0) {
        continue;
      }
      _customDurations[type] = Duration(minutes: minutes);
    }
  }

  void _restoreHistory() {
    final raw = _prefs?.getString(_historyKey);
    if (raw == null) {
      return;
    }

    final logs = DailyPrayerLog.decodeList(raw);
    for (final log in logs) {
      _history[log.dateKey] = log;
    }
  }

  void _syncTimerDurations() {
    for (final info in prayers) {
      final state = _timers[info.type]!;
      final custom = _customDurations[info.type];
      state.total = custom ?? info.defaultDuration;
      if (!state.isRunning) {
        state.remaining = state.isCompleted ? Duration.zero : state.total;
      }
    }
  }

  void _applyCompletionFlags() {
    final today = _ensureTodayLog();
    for (final type in PrayerType.values) {
      final isCompleted = today.entries[type]?.completed ?? false;
      final state = _timers[type]!;
      state.isCompleted = isCompleted;
      if (isCompleted) {
        state.remaining = Duration.zero;
      }
    }
  }

  Duration totalDuration(PrayerType type) => _timers[type]!.total;

  Duration remaining(PrayerType type) {
    _refreshDay();
    return _timers[type]!.remaining;
  }

  bool isRunning(PrayerType type) => _timers[type]!.isRunning;

  bool isPaused(PrayerType type) => _timers[type]!.isPaused;

  bool isCompleted(PrayerType type) {
    _refreshDay();
    return _timers[type]!.isCompleted;
  }

  Duration customDurationOrDefault(PrayerType type) {
    return _customDurations[type] ?? _timers[type]!.total;
  }

  void startTimer(PrayerType type) {
    _refreshDay();
    final state = _timers[type]!;

    if (state.isRunning) {
      return;
    }

    if (state.isCompleted) {
      _resetTimerInternal(type, keepCompletion: false);
    }

    state.isRunning = true;
    state.isPaused = false;
    state.ticker?.cancel();
    state.ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _handleTick(type),
    );
    notifyListeners();
  }

  void pauseTimer(PrayerType type) {
    final state = _timers[type]!;
    if (!state.isRunning) {
      return;
    }

    state.isRunning = false;
    state.isPaused = true;
    state.cancelTicker();
    notifyListeners();
  }

  void resumeTimer(PrayerType type) {
    final state = _timers[type]!;
    if (state.isRunning || state.isCompleted) {
      return;
    }

    state.isRunning = true;
    state.isPaused = false;
    state.ticker?.cancel();
    state.ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _handleTick(type),
    );
    notifyListeners();
  }

  void stopTimer(PrayerType type) {
    final state = _timers[type]!;
    final secondsWorked = state.accruedSeconds;
    state.cancelTicker();
    state.isRunning = false;
    state.isPaused = false;
    state.accruedSeconds = 0;
    state.remaining = state.total;

    if (secondsWorked > 0) {
      _recordSession(type, secondsWorked, completed: false);
    }

    notifyListeners();
  }

  void completePrayer(PrayerType type) {
    final state = _timers[type]!;

    if (state.isCompleted) {
      return;
    }

    final secondsWorked = state.accruedSeconds;
    state.cancelTicker();
    state.isRunning = false;
    state.isPaused = false;
    state.isCompleted = true;
    state.remaining = Duration.zero;
    state.accruedSeconds = 0;

    _recordSession(type, secondsWorked, completed: true);
    notifyListeners();
  }

  void resetCompletion(PrayerType type) {
    final today = _ensureTodayLog();
    final entry = today.entries[type];
    if (entry != null) {
      entry
        ..completed = false
        ..secondsSpent = 0;
    }
    _timers[type]!
      ..isCompleted = false
      ..remaining = _timers[type]!.total
      ..accruedSeconds = 0;
    _saveHistory();
    notifyListeners();
  }

  void setDuration(PrayerType type, Duration duration) {
    final state = _timers[type]!;
    final wasRunning = state.isRunning || state.isPaused;

    if (wasRunning) {
      state.cancelTicker();
      if (state.accruedSeconds > 0) {
        _recordSession(type, state.accruedSeconds, completed: false);
      }
      state.isRunning = false;
      state.isPaused = false;
      state.accruedSeconds = 0;
    }

    state.total = duration;
    state.remaining = state.isCompleted ? Duration.zero : duration;

    if (duration != _defaultDurationFor(type)) {
      _customDurations[type] = duration;
    } else {
      _customDurations.remove(type);
    }

    _saveCustomDurations();
    notifyListeners();
  }

  DailyPrayerLog todayLog() => _ensureTodayLog();

  List<DailyPrayerLog> history() {
    _refreshDay();
    final logs = _history.values.toList()
      ..sort((a, b) => b.dateKey.compareTo(a.dateKey));
    return logs;
  }

  @override
  void dispose() {
    for (final state in _timers.values) {
      state.cancelTicker();
    }
    super.dispose();
  }

  void _handleTick(PrayerType type) {
    final state = _timers[type]!;
    final secondsLeft = state.remaining.inSeconds - 1;
    state.accruedSeconds += 1;

    if (secondsLeft <= 0) {
      state.remaining = Duration.zero;
      state.cancelTicker();
      state.isRunning = false;
      state.isPaused = false;
      state.isCompleted = true;
      final sessionSeconds = state.total.inSeconds;
      state.accruedSeconds = 0;
      _recordSession(type, sessionSeconds, completed: true);
    } else {
      state.remaining = Duration(seconds: secondsLeft);
    }

    notifyListeners();
  }

  void _recordSession(PrayerType type, int seconds, {required bool completed}) {
    final log = _ensureTodayLog();
    final entry = log.entries[type] ?? PrayerEntry();
    entry.secondsSpent += seconds;
    entry.completed = entry.completed || completed;
    log.entries[type] = entry;
    _history[log.dateKey] = log;
    _trimHistory();
    _saveHistory();
  }

  void _resetTimerInternal(PrayerType type, {required bool keepCompletion}) {
    final state = _timers[type]!;
    state.cancelTicker();
    state.isRunning = false;
    state.isPaused = false;
    if (!keepCompletion) {
      state.isCompleted = false;
      state.remaining = state.total;
    }
  }

  DailyPrayerLog _ensureTodayLog() {
    _refreshDay();
    final key = _dateKey(_currentDay);
    return _history.putIfAbsent(key, () => DailyPrayerLog(dateKey: key));
  }

  void _refreshDay() {
    final now = _truncateToDate(DateTime.now());
    if (now.isAtSameMomentAs(_currentDay)) {
      return;
    }

    _currentDay = now;
    for (final state in _timers.values) {
      state.cancelTicker();
      state.isRunning = false;
      state.isPaused = false;
      state.isCompleted = false;
      state.accruedSeconds = 0;
      state.remaining = state.total;
    }

    final key = _dateKey(_currentDay);
    _history.putIfAbsent(key, () => DailyPrayerLog(dateKey: key));
  }

  void _trimHistory() {
    if (_history.length <= _historyRetentionDays) {
      return;
    }

    final sortedKeys = _history.keys.toList()..sort();
    final removeCount = _history.length - _historyRetentionDays;
    for (var i = 0; i < removeCount; i++) {
      _history.remove(sortedKeys[i]);
    }
  }

  void _saveCustomDurations() {
    final payload = _customDurations.map(
      (key, value) => MapEntry(key.storageKey, value.inMinutes),
    );
    _prefs?.setString(_customDurationsKey, jsonEncode(payload));
  }

  void _saveHistory() {
    final logs = _history.values.toList();
    logs.sort((a, b) => a.dateKey.compareTo(b.dateKey));
    final encoded = DailyPrayerLog.encodeList(logs);
    _prefs?.setString(_historyKey, encoded);
    notifyListeners();
  }

  Duration _defaultDurationFor(PrayerType type) {
    return prayers.firstWhere((info) => info.type == type).defaultDuration;
  }

  static DateTime _truncateToDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static String _dateKey(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}
