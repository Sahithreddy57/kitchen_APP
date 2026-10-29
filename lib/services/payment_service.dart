
// import 'dart:convert';

// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;

// import '../core/api_config.dart';
// import '../models/order.dart';

// class CreatedOrder {
//   final String id;
//   final String orderNumber;

//   const CreatedOrder({
//     required this.id,
//     required this.orderNumber,
//   });
// }

// class PaymentRequest {
//   final int amount;
//   final String method;
//   final String detail;

//   const PaymentRequest({
//     required this.amount,
//     required this.method,
//     required this.detail,
//   });
// }

// class PaymentResult {
//   final bool success;
//   final String? txnId;
//   final String? error;

//   const PaymentResult({
//     required this.success,
//     this.txnId,
//     this.error,
//   });
// }

// class PaymentService {
//   /// MOCK ONLY. This does not charge a real payment method.
//   Future<PaymentResult> startPayment(PaymentRequest request) async {
//     await Future.delayed(const Duration(milliseconds: 1500));

//     return PaymentResult(
//       success: true,
//       txnId: 'TXN${DateTime.now().millisecondsSinceEpoch}',
//     );
//   }

//   /// MOCK ONLY. This does not verify an actual payment.
//   Future<bool> confirmPayment(String txnId) async {
//     await Future.delayed(const Duration(milliseconds: 1200));
//     return true;
//   }

//   Future<CreatedOrder> sendToKitchen(
//     Order draft, {
//     required String customerId,
//     required String token,
//     required String idempotencyKey,
//   }) async {
//     final normalizedCustomerId = customerId.trim();
//     final normalizedToken = token.trim();
//     final normalizedKey = idempotencyKey.trim();

//     if (normalizedCustomerId.isEmpty) {
//       throw Exception(
//         'Customer ID is missing. Please sign in again.',
//       );
//     }

//     if (normalizedToken.isEmpty) {
//       throw Exception(
//         'Authentication token is missing. Please sign in again.',
//       );
//     }

//     if (normalizedKey.isEmpty) {
//       throw Exception('Order idempotency key is missing.');
//     }

//     if (draft.lines.isEmpty) {
//       throw Exception('Cannot place an order with an empty cart.');
//     }

//     final deliveryAddressId = draft.deliveryAddressId?.trim();

//     if (draft.isDelivery &&
//         (deliveryAddressId == null || deliveryAddressId.isEmpty)) {
//       throw Exception(
//         'Please select a saved delivery address before placing your order.',
//       );
//     }

//     final uri = Uri.parse('$apiBaseUrl$kCreateOrderPath');

//     // Confirm that the backend accepts these order_type values.
//     final orderType = draft.isOrderNow ? 'ORDER_NOW' : 'PRE_ORDER';

//     final body = <String, dynamic>{
//       'order_type': orderType,
//       'requested_at': draft.scheduledAt.toIso8601String(),
//       'fulfillment_type': draft.isDelivery ? 'DELIVERY' : 'PICKUP',
//       if (draft.isDelivery)
//         'delivery_address_id': deliveryAddressId,
//       'items': draft.lines.map((line) {
//         return <String, dynamic>{
//           'product_id': line.dish.id,
//           'variant_id': line.option.id,
//           'quantity': line.qty,
//         };
//       }).toList(),
//       'notes': '',
//       'idempotency_key': normalizedKey,
//     };

//     debugPrint('CREATE ORDER URL: $uri');
//     debugPrint('CREATE ORDER TYPE: $orderType');
//     debugPrint('CREATE ORDER BODY: ${jsonEncode(body)}');

//     final response = await http.post(
//       uri,
//       headers: {
//         'Content-Type': 'application/json',
//         'Accept': 'application/json',
//         'Authorization': 'Bearer $normalizedToken',
//         'Idempotency-Key': normalizedKey,
//       },
//       body: jsonEncode(body),
//     );

//     debugPrint('ORDER API STATUS: ${response.statusCode}');
//     debugPrint('ORDER API RESPONSE: ${response.body}');

//     dynamic decoded;

//     try {
//       decoded = jsonDecode(response.body);
//     } catch (_) {
//       decoded = null;
//     }

//     if (response.statusCode < 200 || response.statusCode >= 300) {
//       final message = _extractErrorMessage(decoded);

//       switch (response.statusCode) {
//         case 400:
//           throw Exception(
//             'Order request is invalid (400).'
//             '${message == null ? '' : ' Server message: $message'}',
//           );

//         case 401:
//           throw Exception(
//             'Order API returned 401 Unauthorized. '
//             'Check whether the customer token is valid.'
//             '${message == null ? '' : ' Server message: $message'}',
//           );

//         case 403:
//           throw Exception(
//             'Order API returned 403 Forbidden.'
//             '${message == null ? '' : ' Server message: $message'}',
//           );

//         case 422:
//           throw Exception(
//             'Order request failed validation (422).'
//             '${message == null ? '' : ' Server message: $message'}',
//           );

//         default:
//           throw Exception(
//             'Order API failed (${response.statusCode}).'
//             '${message == null ? '' : ' Server message: $message'}',
//           );
//       }
//     }

//     if (decoded is! Map) {
//       throw Exception(
//         'Order API returned an unexpected response format.',
//       );
//     }

//     // Safely convert nested JSON objects to maps.
//     Map<String, dynamic> asMap(dynamic value) {
//       if (value is Map) {
//         return Map<String, dynamic>.from(value);
//       }
//       return <String, dynamic>{};
//     }

//     final root = asMap(decoded);

//     // Supports responses such as:
//     // { "data": { "order_id": "...", "order_number": "DRK-123" } }
//     // { "data": { "order": { "id": "...", "order_number": "DRK-123" } } }
//     // { "order_id": "...", "order_number": "DRK-123" }
//     final data = asMap(root['data']);
//     final result = data.isNotEmpty ? data : root;

//     final nestedOrder = asMap(result['order']);
//     final orderData = nestedOrder.isNotEmpty ? nestedOrder : result;

//     final rootOrder = asMap(root['order']);

//     // Extract the database order ID.
//     final orderId = orderData['order_id'] ??
//         orderData['id'] ??
//         orderData['_id'] ??
//         result['order_id'] ??
//         result['id'] ??
//         result['_id'] ??
//         rootOrder['order_id'] ??
//         rootOrder['id'] ??
//         rootOrder['_id'] ??
//         root['order_id'] ??
//         root['id'] ??
//         root['_id'];

//     // Extract the human-readable order number.
//     final orderNumber = orderData['order_number'] ??
//         orderData['orderNumber'] ??
//         orderData['order_no'] ??
//         orderData['orderNo'] ??
//         orderData['number'] ??
//         result['order_number'] ??
//         result['orderNumber'] ??
//         result['order_no'] ??
//         result['orderNo'] ??
//         result['number'] ??
//         rootOrder['order_number'] ??
//         rootOrder['orderNumber'] ??
//         root['order_number'] ??
//         root['orderNumber'] ??
//         root['order_no'] ??
//         root['orderNo'];

//     if (orderId == null || orderId.toString().trim().isEmpty) {
//       throw Exception(
//         'Order response did not contain an order ID.',
//       );
//     }

//     final parsedOrderNumber = orderNumber?.toString().trim() ?? '';

//     debugPrint('PARSED ORDER ID: $orderId');
//     debugPrint(
//       'PARSED ORDER NUMBER: '
//       '${parsedOrderNumber.isEmpty ? '(not returned by API)' : parsedOrderNumber}',
//     );

//     return CreatedOrder(
//       id: orderId.toString(),
//       orderNumber: parsedOrderNumber,
//     );
//   }

//   String? _extractErrorMessage(dynamic decoded) {
//     if (decoded is! Map) return null;

//     final value =
//         decoded['message'] ?? decoded['error'] ?? decoded['detail'];

//     if (value == null) return null;

//     if (value is String && value.trim().isNotEmpty) {
//       return value.trim();
//     }

//     if (value is Map) return value.toString();
//     if (value is List) return value.join(', ');

//     return null;
//   }
// }

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import '../models/order.dart';

class CreatedOrder {
  final String id;
  final String orderNumber;

  const CreatedOrder({
    required this.id,
    required this.orderNumber,
  });
}

class PaymentRequest {
  final int amount;
  final String method;
  final String detail;

  const PaymentRequest({
    required this.amount,
    required this.method,
    required this.detail,
  });
}

class PaymentResult {
  final bool success;
  final String? txnId;
  final String? error;

  const PaymentResult({
    required this.success,
    this.txnId,
    this.error,
  });
}

class PaymentService {
  /// MOCK ONLY. This does not charge a real payment method.
  Future<PaymentResult> startPayment(PaymentRequest request) async {
    await Future.delayed(const Duration(milliseconds: 1500));

    return PaymentResult(
      success: true,
      txnId: 'TXN${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// MOCK ONLY. This does not verify an actual payment.
  Future<bool> confirmPayment(String txnId) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    return true;
  }

  /// Builds one item for the backend order API.
  ///
  /// HUNDI and WEEKLY_HUNDI:
  ///   item_type, hundi_package_id, quantity
  ///
  /// Regular products:
  ///   product_id, variant_id, quantity
  Map<String, dynamic> _buildOrderItem(dynamic line) {
    final dish = line.dish;
    final option = line.option;
    final quantity = line.qty as int;

    final itemType = dish.orderItemType as String;

    if (itemType == 'HUNDI' || itemType == 'WEEKLY_HUNDI') {
      // Hundi option.id must be the actual MongoDB package _id,
      // not the synthetic dish ID such as "hundi-muttonhundi".
      final packageId = option.id.toString().trim();

      if (packageId.isEmpty) {
        throw Exception(
          'Missing Hundi package ID for ${dish.name}. '
          'Refresh the menu and select the Hundi package again.',
        );
      }

      return {
        'item_type': itemType,
        'hundi_package_id': packageId,
        'quantity': quantity,
      };
    }

    // Keep the existing regular-product payload unchanged.
    final productId = dish.id.toString().trim();
    final variantId = option.id.toString().trim();

    if (productId.isEmpty || variantId.isEmpty) {
      throw Exception(
        'Missing product or variant ID for ${dish.name}. '
        'Refresh the menu and select the product again.',
      );
    }

    return {
      'product_id': productId,
      'variant_id': variantId,
      'quantity': quantity,
    };
  }

  Future<CreatedOrder> sendToKitchen(
    Order draft, {
    required String customerId,
    required String token,
    required String idempotencyKey,
  }) async {
    final normalizedCustomerId = customerId.trim();
    final normalizedToken = token.trim();
    final normalizedKey = idempotencyKey.trim();

    if (normalizedCustomerId.isEmpty) {
      throw Exception(
        'Customer ID is missing. Please sign in again.',
      );
    }

    if (normalizedToken.isEmpty) {
      throw Exception(
        'Authentication token is missing. Please sign in again.',
      );
    }

    if (normalizedKey.isEmpty) {
      throw Exception('Order idempotency key is missing.');
    }

    if (draft.lines.isEmpty) {
      throw Exception('Cannot place an order with an empty cart.');
    }

    final deliveryAddressId = draft.deliveryAddressId?.trim();

    if (draft.isDelivery &&
        (deliveryAddressId == null || deliveryAddressId.isEmpty)) {
      throw Exception(
        'Please select a saved delivery address before placing your order.',
      );
    }

    final uri = Uri.parse('$apiBaseUrl$kCreateOrderPath');

    final orderType = draft.isOrderNow ? 'ORDER_NOW' : 'PRE_ORDER';

    final body = <String, dynamic>{
      'order_type': orderType,
      'requested_at': draft.scheduledAt.toIso8601String(),
      'fulfillment_type': draft.isDelivery ? 'DELIVERY' : 'PICKUP',
      if (draft.isDelivery)
        'delivery_address_id': deliveryAddressId,
      'items': draft.lines.map(_buildOrderItem).toList(),
      'notes': '',
      'idempotency_key': normalizedKey,
    };

    debugPrint('CREATE ORDER URL: $uri');
    debugPrint('CREATE ORDER TYPE: $orderType');
    debugPrint('CREATE ORDER BODY: ${jsonEncode(body)}');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $normalizedToken',
        'Idempotency-Key': normalizedKey,
      },
      body: jsonEncode(body),
    );

    debugPrint('ORDER API STATUS: ${response.statusCode}');
    debugPrint('ORDER API RESPONSE: ${response.body}');

    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = _extractErrorMessage(decoded);

      switch (response.statusCode) {
        case 400:
          throw Exception(
            'Order request is invalid (400).'
            '${message == null ? '' : ' Server message: $message'}',
          );

        case 401:
          throw Exception(
            'Order API returned 401 Unauthorized. '
            'Check whether the customer token is valid.'
            '${message == null ? '' : ' Server message: $message'}',
          );

        case 403:
          throw Exception(
            'Order API returned 403 Forbidden.'
            '${message == null ? '' : ' Server message: $message'}',
          );

        case 422:
          throw Exception(
            'Order request failed validation (422).'
            '${message == null ? '' : ' Server message: $message'}',
          );

        default:
          throw Exception(
            'Order API failed (${response.statusCode}).'
            '${message == null ? '' : ' Server message: $message'}',
          );
      }
    }

    if (decoded is! Map) {
      throw Exception(
        'Order API returned an unexpected response format.',
      );
    }

    Map<String, dynamic> asMap(dynamic value) {
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
      return <String, dynamic>{};
    }

    final root = asMap(decoded);
    final data = asMap(root['data']);
    final result = data.isNotEmpty ? data : root;

    final nestedOrder = asMap(result['order']);
    final orderData = nestedOrder.isNotEmpty ? nestedOrder : result;
    final rootOrder = asMap(root['order']);

    final orderId = orderData['order_id'] ??
        orderData['id'] ??
        orderData['_id'] ??
        result['order_id'] ??
        result['id'] ??
        result['_id'] ??
        rootOrder['order_id'] ??
        rootOrder['id'] ??
        rootOrder['_id'] ??
        root['order_id'] ??
        root['id'] ??
        root['_id'];

    final orderNumber = orderData['order_number'] ??
        orderData['orderNumber'] ??
        orderData['order_no'] ??
        orderData['orderNo'] ??
        orderData['number'] ??
        result['order_number'] ??
        result['orderNumber'] ??
        result['order_no'] ??
        result['orderNo'] ??
        result['number'] ??
        rootOrder['order_number'] ??
        rootOrder['orderNumber'] ??
        root['order_number'] ??
        root['orderNumber'] ??
        root['order_no'] ??
        root['orderNo'];

    if (orderId == null || orderId.toString().trim().isEmpty) {
      throw Exception(
        'Order response did not contain an order ID.',
      );
    }

    final parsedOrderNumber = orderNumber?.toString().trim() ?? '';

    debugPrint('PARSED ORDER ID: $orderId');
    debugPrint(
      'PARSED ORDER NUMBER: '
      '${parsedOrderNumber.isEmpty ? '(not returned by API)' : parsedOrderNumber}',
    );

    return CreatedOrder(
      id: orderId.toString(),
      orderNumber: parsedOrderNumber,
    );
  }

  String? _extractErrorMessage(dynamic decoded) {
    if (decoded is! Map) return null;

    final value =
        decoded['message'] ?? decoded['error'] ?? decoded['detail'];

    if (value == null) return null;

    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    if (value is Map) return value.toString();
    if (value is List) return value.join(', ');

    return null;
  }
}
