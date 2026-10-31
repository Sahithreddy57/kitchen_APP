
import 'package:flutter/foundation.dart';

import 'api_client.dart';

class KitchenStatus {
  final bool isOpen;
  final bool isPaused;
  final bool orderNowEnabled;
  final bool preOrderEnabled;
  final String status;
  final String? code;
  final String message;
  final String? openTime;
  final String? closeTime;
  final String? pausedUntil;
  final int? resumesInMinutes;
  final String? serverTime;

  const KitchenStatus({
    required this.isOpen,
    required this.isPaused,
    required this.orderNowEnabled,
    required this.preOrderEnabled,
    required this.status,
    this.code,
    required this.message,
    this.openTime,
    this.closeTime,
    this.pausedUntil,
    this.resumesInMinutes,
    this.serverTime,
  });

  factory KitchenStatus.fromJson(Map<String, dynamic> json) {
    final resume = json['resumes_in_minutes'];
    return KitchenStatus(
      isOpen: json['is_open'] == true,
      isPaused: json['is_paused'] == true,
      orderNowEnabled: json['order_now_enabled'] == true,
      preOrderEnabled: json['pre_order_enabled'] != false,
      status: (json['status'] ?? 'UNAVAILABLE').toString().toUpperCase(),
      code: json['code']?.toString(),
      message: (json['message'] ?? 'Kitchen status unavailable').toString(),
      openTime: json['open_time']?.toString(),
      closeTime: json['close_time']?.toString(),
      pausedUntil: json['paused_until']?.toString(),
      resumesInMinutes: resume is num ? resume.round() : int.tryParse('$resume'),
      serverTime: json['server_time']?.toString(),
    );
  }

  String get displayMessage {
    if (status == 'PAUSED' && resumesInMinutes != null) {
      return 'Kitchen is temporarily paused. Resumes in about $resumesInMinutes min.';
    }
    return message;
  }
}

class KitchenStatusService {
  Future<KitchenStatus> fetch() async {
    final root = await ApiClient.getJson(
      '/api/customer/kitchen/status',
      logBody: false,
      authenticated: true,
    );
    final data = root['data'];
    if (root['success'] != true || data is! Map) {
      throw ApiException(
        (root['message'] ?? 'Unable to fetch kitchen status').toString(),
      );
    }
    return KitchenStatus.fromJson(Map<String, dynamic>.from(data));
  }
}
