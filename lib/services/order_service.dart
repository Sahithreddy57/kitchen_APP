import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/api_config.dart';

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

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {'data': decoded};
    }

    throw Exception(
      'Order creation failed (${response.statusCode}): '
      '${response.body}',
    );
  }
}