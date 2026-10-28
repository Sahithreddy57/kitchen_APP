

import '../core/api_config.dart';
import 'api_client.dart';

/// Kitchen hours for one selected date.
///
/// Weekly backend response example:
/// {
///   "day": "Monday",
///   "is_open": true,
///   "open_time": "14:00",
///   "close_time": "21:00"
/// }
class KitchenHours {
  final String date;
  final bool isOpen;
  final String? openingTime; // HH:mm (24-hour format)
  final String? closingTime; // HH:mm (24-hour format)

  const KitchenHours({
    required this.date,
    required this.isOpen,
    this.openingTime,
    this.closingTime,
  });

  factory KitchenHours.fromJson(Map<String, dynamic> json) {
    final openFlag = json['is_open'] ?? json['isOpen'];

    return KitchenHours(
      date: (json['date'] ?? '').toString(),
      isOpen: openFlag == true ||
          openFlag == 'true' ||
          openFlag == 1,
      openingTime:
          (json['open_time'] ?? json['openingTime'])?.toString(),
      closingTime:
          (json['close_time'] ?? json['closingTime'])?.toString(),
    );
  }

  /// Converts HH:mm into minutes since midnight.
  /// Example: 14:00 -> 840; 24:00 -> 1440.
  static int? _toMinutes(String? time) {
    if (time == null || time.trim().isEmpty) return null;

    final parts = time.trim().split(':');
    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 24 ||
        minute < 0 ||
        minute > 59 ||
        (hour == 24 && minute != 0)) {
      return null;
    }

    return hour * 60 + minute;
  }

  int? get openMinutes => _toMinutes(openingTime);

  /// A close time of 00:00 after a non-midnight opening means midnight.
  int? get closeMinutes {
    final close = _toMinutes(closingTime);
    final open = openMinutes;

    if (close == null) return null;

    if (close == 0 && open != null && open > 0) {
      return 1440;
    }

    return close;
  }

  /// Formats minutes since midnight as 12-hour time.
  /// Examples: 540 -> 9:00 AM; 1260 -> 9:00 PM.
  static String formatTime(int minutes) {
    final normalized = minutes == 1440 ? 0 : minutes;
    final hour24 = normalized ~/ 60;
    final minute = normalized % 60;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final period = hour24 < 12 ? 'AM' : 'PM';

    return '$hour12:${minute.toString().padLeft(2, '0')} $period';
  }

  String get openingTimeLabel {
    final minutes = openMinutes;
    return minutes == null ? '--' : formatTime(minutes);
  }

  String get closingTimeLabel {
    final minutes = closeMinutes;
    return minutes == null ? '--' : formatTime(minutes);
  }

  String get hoursLabel {
    if (!isOpen) return 'Kitchen is closed';

    if (openMinutes == null || closeMinutes == null) {
      return 'Kitchen hours unavailable';
    }

    return 'Kitchen is open $openingTimeLabel – $closingTimeLabel';
  }
}

class KitchenHoursService {
  // Cache the weekly schedule for five minutes.
  static List<Map<String, dynamic>>? _week;
  static DateTime? _weekAt;

  static const List<String> _days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  /// Returns the backend hours for the weekday of [date].
  Future<KitchenHours> fetch(DateTime date) async {
    final dateString =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    // Use mock hours only when explicitly enabled.
    if (kUseMockHours) {
      return _mock(date, dateString);
    }

    final week = await _loadWeek();
    final weekday = _days[date.weekday - 1];

    Map<String, dynamic>? row;

    for (final item in week) {
      final day = (item['day'] ?? '')
          .toString()
          .trim()
          .toLowerCase();

      if (day == weekday ||
          (day.length >= 3 &&
              weekday.startsWith(day.substring(0, 3)))) {
        row = item;
        break;
      }
    }

    if (row == null) {
      return KitchenHours(
        date: dateString,
        isOpen: false,
      );
    }

    final flag = row['is_open'] ?? row['isOpen'];
    final isOpen = flag == true ||
        flag == 'true' ||
        flag == 1;

    if (!isOpen) {
      return KitchenHours(
        date: dateString,
        isOpen: false,
      );
    }

    final opening = row['open_time'] ?? row['openingTime'];
    final closing = row['close_time'] ?? row['closingTime'];

    final result = KitchenHours(
      date: dateString,
      isOpen: true,
      openingTime: opening?.toString(),
      closingTime: closing?.toString(),
    );

    // Do not show misleading hours if the backend row is incomplete.
    if (result.openMinutes == null ||
        result.closeMinutes == null ||
        result.closeMinutes! <= result.openMinutes!) {
      throw ApiException(
        'Invalid kitchen hours returned for $weekday',
      );
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> _loadWeek() async {
    final cachedWeek = _week;
    final cachedAt = _weekAt;

    if (cachedWeek != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) <
            const Duration(minutes: 5)) {
      return cachedWeek;
    }

    final body = await ApiClient.getJson(
      kHoursPath,
      logBody: true,
    );

    final list = ApiClient.listFrom(
      body['data'],
      ['hours', 'items', 'days'],
    );

    final week = <Map<String, dynamic>>[
      for (final row in list)
        if (row is Map)
          Map<String, dynamic>.from(row),
    ];

    if (week.isEmpty) {
      throw ApiException('No kitchen hours found');
    }

    _week = week;
    _weekAt = DateTime.now();

    return week;
  }

  /// Test schedule. This is intentionally used only when
  /// kUseMockHours is true.
  Future<KitchenHours> _mock(
    DateTime date,
    String dateString,
  ) async {
    await Future.delayed(
      const Duration(milliseconds: 250),
    );

    return KitchenHours(
      date: dateString,
      isOpen: true,
      openingTime: '09:00',
      closingTime: '21:00',
    );
  }

  /// Call this after updating business hours in the admin/backend.
  static void clearCache() {
    _week = null;
    _weekAt = null;
  }
}

