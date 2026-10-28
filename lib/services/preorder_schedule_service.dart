
import '../core/api_config.dart';
import 'api_client.dart';

class PreorderSlot {
  final String start;
  final String end;
  final String label;
  final int booked;
  final int capacity;
  final String status;
  final bool disabled;
  final String statusLabel;

  const PreorderSlot({
    required this.start,
    required this.end,
    required this.label,
    required this.booked,
    required this.capacity,
    required this.status,
    required this.disabled,
    required this.statusLabel,
  });

  factory PreorderSlot.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) =>
        value is num ? value.toInt() : int.tryParse('$value') ?? 0;

    final booked = asInt(json['booked']);
    final capacity = asInt(json['capacity']);
    final status = (json['status'] ?? '').toString().toLowerCase();

    return PreorderSlot(
      start: (json['start'] ?? '').toString(),
      end: (json['end'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      booked: booked,
      capacity: capacity,
      status: status,
      disabled: json['disabled'] == true ||
          status != 'open' ||
          (capacity > 0 && booked >= capacity),
      statusLabel: (json['statusLabel'] ??
              json['status_label'] ??
              '').toString(),
    );
  }

  bool get isAvailable =>
      !disabled && status == 'open';
}

class PreorderSchedule {
  final bool closed;
  final Map<String, PreorderSlot> slots;

  const PreorderSchedule({
    required this.closed,
    required this.slots,
  });
}

class PreorderScheduleService {
  Future<PreorderSchedule> fetch(DateTime date) async {
    final dateString =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final body = await ApiClient.getJson(
      kPreorderScheduleDayPath,
      query: {'date': dateString},
      logBody: false,
    );

    final data = body['data'];
    if (data is! Map) {
      throw ApiException('Invalid preorder schedule response');
    }

    final closed = data['closed'] == true;
    final rawSlots = data['slots'];

    if (rawSlots is! List) {
      throw ApiException('No slot availability returned');
    }

    final slots = <String, PreorderSlot>{};

    for (final item in rawSlots) {
      if (item is! Map) continue;

      final slot = PreorderSlot.fromJson(
        Map<String, dynamic>.from(item),
      );

      if (slot.start.isNotEmpty) {
        slots[slot.start] = slot;
      }
    }

    return PreorderSchedule(
      closed: closed,
      slots: slots,
    );
  }
}
