import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import '../services/api_client.dart';

class OrderService {
  Future<Map<String, dynamic>> createOrder({
    required Map<String, dynamic> order,
    required String token,
  }) async {
    final uri = Uri.parse('$apiBaseUrl$kCreateOrderPath');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(order),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {'data': decoded};
    }

    throw Exception(
      'Order creation failed (${response.statusCode}): ${response.body}',
    );
  } // <-- Properly closes createOrder

  Future<Map<String, dynamic>> fetchOrdersByMobile({
    required String mobile,
  }) async {
    final normalizedMobile = mobile.replaceAll(RegExp(r'\D'), '');

    if (normalizedMobile.isEmpty) {
      throw Exception('Mobile number is required');
    }

    return ApiClient.getJson(
      kCustomerOrdersByMobilePath,
      query: {'mobile': normalizedMobile},
      authenticated: true,
    );
  } 
} 