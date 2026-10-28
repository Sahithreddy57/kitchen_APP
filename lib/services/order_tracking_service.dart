
import 'package:flutter/foundation.dart';

import 'api_client.dart';

class OrderTrackingService {
  /// Fetches the latest order status from the customer API.
  ///
  /// Requires the customer JWT obtained after login/OTP verification.
  Future<String> fetchStatus(String orderId) async {
    final id = orderId.trim();

    if (id.isEmpty) {
      throw ArgumentError('Order ID cannot be empty.');
    }

    final token = ApiClient.customerToken;

    if (token == null || token.isEmpty) {
      throw ApiException(
        'Customer is not authenticated. Please log in again.',
        401,
      );
    }

    try {
      final response = await ApiClient.getJson(
        '/api/customer/orders/$id',
        authenticated: true,
      );

      final data = response['data'];

      if (data is! Map) {
        throw ApiException('Order data was not found.');
      }

      final status = data['status']?.toString().trim();

      if (status == null || status.isEmpty) {
        throw ApiException('Order status is missing.');
      }

      debugPrint('Order tracking: $id -> $status');

      return status.toUpperCase();
    } catch (error) {
      debugPrint('Failed to fetch status for order $id: $error');
      rethrow;
    }
  }
}
