
// import '../core/api_config.dart';
// import 'api_client.dart';

// class OrderCancellationService {
//   Future<String> cancelOrder({
//     required String orderId,
//     String? reason,
//   }) async {
//     final id = orderId.trim();

//     if (id.isEmpty) {
//       throw ArgumentError('Order ID cannot be empty.');
//     }

//     final token = ApiClient.customerToken;
//     if (token == null || token.isEmpty) {
//       throw ApiException('Please log in again.', 401);
//     }

//     final cleanReason = reason?.trim() ?? '';
//     if (cleanReason.length > 500) {
//       throw ArgumentError(
//         'Cancellation reason cannot exceed 500 characters.',
//       );
//     }

//     final body = <String, dynamic>{};
//     if (cleanReason.isNotEmpty) {
//       body['reason'] = cleanReason;
//     }

//     final response = await ApiClient.postJson(
//       '$kCreateOrderPath/$id/cancel',
//       body,
//       authenticated: true,
//     );

//     if (!response.ok) {
//       throw ApiException(
//         response.body['message']?.toString() ??
//             'Unable to cancel this order.',
//         response.status,
//       );
//     }

//     final data = response.body['data'];
//     if (data is! Map ||
//         data['status']?.toString().toUpperCase() != 'CANCELLED') {
//       throw ApiException(
//         'The server did not confirm order cancellation.',
//         response.status,
//       );
//     }

//     return response.body['message']?.toString() ??
//         'Order cancelled successfully';
//   }
// }
import '../core/api_config.dart';
import 'api_client.dart';

class OrderCancellationService {
  Future<String> cancelOrder({
    required String orderId,
    String? reason,
  }) async {
    final id = orderId.trim();

    if (id.isEmpty) {
      throw ArgumentError('Order ID cannot be empty.');
    }

    final token = ApiClient.customerToken;
    if (token == null || token.isEmpty) {
      throw ApiException('Please log in again.', 401);
    }

    final cleanReason = reason?.trim() ?? '';
    if (cleanReason.length > 500) {
      throw ArgumentError(
        'Cancellation reason cannot exceed 500 characters.',
      );
    }

    final body = <String, dynamic>{};
    if (cleanReason.isNotEmpty) {
      body['reason'] = cleanReason;
    }

    final response = await ApiClient.postJson(
      '$kCreateOrderPath/$id/cancel',
      body,
      authenticated: true,
    );

    if (!response.ok) {
      throw ApiException(
        response.body['message']?.toString() ??
            'Unable to cancel this order.',
        response.status,
      );
    }

    final data = response.body['data'];
    if (data is! Map ||
        data['status']?.toString().toUpperCase() != 'CANCELLED') {
      throw ApiException(
        'The server did not confirm order cancellation.',
        response.status,
      );
    }

    return response.body['message']?.toString() ??
        'Order cancelled successfully';
  }
}
