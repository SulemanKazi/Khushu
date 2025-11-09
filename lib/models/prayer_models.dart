import 'dart:convert';

enum PrayerType { fajr, dhuhr, asr, maghrib, isha }

extension PrayerTypeDisplay on PrayerType {
  String get displayName {
    switch (this) {
      case PrayerType.fajr:
        return 'Fajr';
      case PrayerType.dhuhr:
        return 'Duhr';
      case PrayerType.asr:
        return 'Asr';
      case PrayerType.maghrib:
        return 'Maghrib';
      case PrayerType.isha:
        return 'Isha';
    }
  }

  String get storageKey => name;
}

PrayerType prayerTypeFromKey(String key) {
  return PrayerType.values.firstWhere(
    (type) => type.name == key,
    orElse: () => PrayerType.fajr,
  );
}

class PrayerInfo {
  const PrayerInfo({
    required this.type,
    required this.defaultDuration,
    required this.label,
  });

  final PrayerType type;
  final Duration defaultDuration;
  final String label;
}

class PrayerEntry {
  PrayerEntry({this.secondsSpent = 0, this.completed = false});

  int secondsSpent;
  bool completed;

  Map<String, dynamic> toJson() => {
    'seconds': secondsSpent,
    'completed': completed,
  };

  static PrayerEntry fromJson(Map<String, dynamic> json) {
    return PrayerEntry(
      secondsSpent: (json['seconds'] as num?)?.toInt() ?? 0,
      completed: json['completed'] as bool? ?? false,
    );
  }
}

class DailyPrayerLog {
  DailyPrayerLog({required this.dateKey, Map<PrayerType, PrayerEntry>? entries})
    : entries =
          entries ??
          {for (final type in PrayerType.values) type: PrayerEntry()};

  final String dateKey;
  final Map<PrayerType, PrayerEntry> entries;

  DateTime get date => DateTime.parse(dateKey);

  int get completedCount =>
      entries.values.where((entry) => entry.completed).length;

  Map<String, dynamic> toJson() {
    return {
      'date': dateKey,
      'entries': entries.map(
        (key, value) => MapEntry(key.storageKey, value.toJson()),
      ),
    };
  }

  static DailyPrayerLog fromJson(Map<String, dynamic> json) {
    final rawEntries =
        json['entries'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return DailyPrayerLog(
      dateKey: json['date'] as String,
      entries: {
        for (final entry in rawEntries.entries)
          prayerTypeFromKey(entry.key): PrayerEntry.fromJson(
            entry.value as Map<String, dynamic>,
          ),
      },
    );
  }

  static String encodeList(List<DailyPrayerLog> logs) {
    final payload = logs.map((log) => log.toJson()).toList();
    return jsonEncode(payload);
  }

  static List<DailyPrayerLog> decodeList(String? value) {
    if (value == null || value.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(value) as List<dynamic>;
    return decoded
        .map((item) => DailyPrayerLog.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
