
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import '../models/dish.dart';

class VariantApiService {
  Future<List<DishOption>> fetchVariants(String productId) async {
    final uri = Uri.parse(
      '$apiBaseUrl/api/admin/products/$productId/variants',
    );

    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (kDevApiToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $kDevApiToken';
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to load variants. HTTP ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> ||
        decoded['success'] != true) {
      throw Exception(
        decoded is Map
            ? decoded['message']?.toString() ?? 'Failed to load variants.'
            : 'Invalid variants response.',
      );
    }

    final data = decoded['data'];
    if (data is! List) {
      throw Exception('The variants API did not return a list.');
    }

    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((v) =>
            v['status'] == 'active' &&
            v['availability'] == true)
        .map((v) {
          final orderType = (v['order_type'] ?? 'instock')
              .toString()
              .toLowerCase();

          return DishOption(
            (v['variant_name'] ?? '').toString(),
            (v['price'] as num?)?.toInt() ?? 0,
            id: (v['_id'] ?? v['id'] ?? '').toString(),
            preOrderOnly: orderType == 'preorder' ||
                v['pre_order_only'] == true ||
                v['requires_preorder'] == true,
          );
        })
        .where((option) => option.id.isNotEmpty)
        .toList();
  }
}
