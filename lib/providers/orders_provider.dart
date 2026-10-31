
// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import '../models/order.dart';
// import '../services/order_tracking_service.dart';
// import '../services/order_cancellation_service.dart';

// class OrdersProvider extends ChangeNotifier {
//   OrdersProvider(this._prefs);

//   static const _key = 'orders';
// final OrderCancellationService _cancellationService =
//     OrderCancellationService();
//   final SharedPreferences _prefs;
//   final List<Order> _all = [];
//   final OrderTrackingService _trackingService = OrderTrackingService();

//   String _phone = '';
//   bool _isRefreshing = false;

//   bool get isRefreshing => _isRefreshing;
 
// Future<String> cancelOrder(
//   String orderId, {
//   String? reason,
// }) async {
//   final index = _all.indexWhere((order) => order.id == orderId);

//   if (index == -1) {
//     throw Exception('Order not found.');
//   }

//   final message = await _cancellationService.cancelOrder(
//     orderId: orderId,
//     reason: reason,
//   );

//   _all[index] = _all[index].withBackendStatus('CANCELLED');

//   await _prefs.setString(
//     _key,
//     jsonEncode(_all.map((order) => order.toJson()).toList()),
//   );

//   notifyListeners();
//   return message;
// }
//   /// Call this after authentication changes.
//   void setPhone(String phone) {
//     _phone = phone;
//     notifyListeners();
//   }

//   /// Logged-in customer's locally stored orders only.
//   List<Order> get orders => _phone.isEmpty
//       ? const []
//       : _all.where((order) => order.phone == _phone).toList();

//   List<Order> forPhone(String phone) => phone.isEmpty || phone != _phone
//       ? const []
//       : _all.where((order) => order.phone == phone).toList();

//   Order? findById(String id) {
//     for (final order in _all) {
//       if (order.id == id) return order;
//     }
//     return null;
//   }

//   void _persist() {
//     _prefs.setString(
//       _key,
//       jsonEncode(_all.map((order) => order.toJson()).toList()),
//     );
//   }

//   /// Load locally saved orders. Call once after creating the provider.
//   void loadSavedOrders() {
//     final raw = _prefs.getString(_key);
//     if (raw == null) return;

//     try {
//       final decoded = jsonDecode(raw);
//       if (decoded is! List) return;

//       _all
//         ..clear()
//         ..addAll(
//           decoded.map(
//             (item) => Order.fromJson(
//               Map<String, dynamic>.from(item as Map),
//             ),
//           ),
//         );

//       notifyListeners();
//     } catch (error) {
//       debugPrint('Could not read saved orders: $error');
//     }
//   }

//   /// Fetches the status from GET /api/customer/orders/:id.
//   /// The customer token is supplied by ApiClient's authenticated GET method.
//   Future<Order?> refreshOrderStatus(String orderId) async {
//     final existing = findById(orderId);
//     if (existing == null) {
//       debugPrint('Cannot refresh status: order $orderId is not saved locally.');
//       return null;
//     }

//     try {
//       final status = await _trackingService.fetchStatus(orderId);

//       final index = _all.indexWhere((order) => order.id == orderId);
//       if (index == -1) return null;

//       final updated = _all[index].withBackendStatus(status);
//       _all[index] = updated;

//       _persist();
//       notifyListeners();

//       return updated;
//     } catch (error) {
//       // Keep displaying the last known status if the network is unavailable.
//       debugPrint('Could not refresh order status for $orderId: $error');
//       return findById(orderId);
//     }
//   }

//   /// Optionally refresh all saved orders belonging to the logged-in customer.
//   /// This calls the single-order endpoint for each saved order.
//   Future<void> refreshCustomerOrders() async {
//     if (_phone.isEmpty || _isRefreshing) return;

//     _isRefreshing = true;
//     notifyListeners();

//     try {
//       final ids = orders.map((order) => order.id).toList();
//       for (final id in ids) {
//         await refreshOrderStatus(id);
//       }
//     } finally {
//       _isRefreshing = false;
//       notifyListeners();
//     }
//   }

//   void reassignPhone(String oldPhone, String newPhone) {
//     for (var i = 0; i < _all.length; i++) {
//       if (_all[i].phone == oldPhone) {
//         _all[i] = _all[i].withPhone(newPhone);
//       }
//     }

//     _persist();
//     notifyListeners();
//   }

//   void add(Order order) {
//     final existingIndex = _all.indexWhere((item) => item.id == order.id);

//     if (existingIndex >= 0) {
//       _all[existingIndex] = order;
//     } else {
//       _all.insert(0, order);
//     }

//     _persist();
//     notifyListeners();
//   }
// }


import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/order.dart';
import '../services/order_service.dart';
import '../services/order_tracking_service.dart';
import '../services/order_cancellation_service.dart';

class OrdersProvider extends ChangeNotifier {
  OrdersProvider(this._prefs);

  static const _key = 'orders';

  final SharedPreferences _prefs;
  final List<Order> _all = [];

  final OrderService _orderService = OrderService();
  final OrderTrackingService _trackingService = OrderTrackingService();
  final OrderCancellationService _cancellationService =
      OrderCancellationService();

  String _phone = '';
  bool _isRefreshing = false;
  String? _errorMessage;

  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;

  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'\D'), '');
  }

  void setPhone(String phone) {
    _phone = _normalizePhone(phone);
    notifyListeners();
  }

  List<Order> get orders {
    if (_phone.isEmpty) return const [];

    return _all
        .where((order) => _normalizePhone(order.phone) == _phone)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<Order> forPhone(String phone) {
    final normalized = _normalizePhone(phone);

    if (normalized.isEmpty || normalized != _phone) {
      return const [];
    }

    return orders;
  }

  Order? findById(String id) {
    for (final order in _all) {
      if (order.id == id) return order;
    }
    return null;
  }

  Future<void> _persist() async {
    await _prefs.setString(
      _key,
      jsonEncode(_all.map((order) => order.toJson()).toList()),
    );
  }

  void loadSavedOrders() {
    final raw = _prefs.getString(_key);

    if (raw == null) return;

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) return;

      _all
        ..clear()
        ..addAll(
          decoded.map(
            (item) => Order.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          ),
        );

      notifyListeners();
    } catch (error) {
      debugPrint('Could not read saved orders: $error');
    }
  }

  /// Fetch the logged-in customer's complete order history by mobile.
  Future<void> fetchCustomerOrders({
  required String phone,
}) async {
  final normalizedPhone = phone.replaceAll(RegExp(r'\D'), '');

  if (normalizedPhone.isEmpty) return;

  _phone = normalizedPhone;
  _isRefreshing = true;
  notifyListeners();

  try {
    final response = await _orderService.fetchOrdersByMobile(
      mobile: normalizedPhone,
    );

    final data = response['data'] as Map<String, dynamic>? ?? {};

    final customer =
        data['customer'] as Map<String, dynamic>? ?? {};

    final customerName =
        (customer['name'] ?? '').toString();

    final backendOrders =
        data['orders'] as List<dynamic>? ?? [];

    final fetchedOrders = backendOrders.map((item) {
      return Order.fromBackendJson(
        Map<String, dynamic>.from(item as Map),
        customerName: customerName,
        phone: normalizedPhone,
      );
    }).toList();

    // Replace this mobile's cached orders with the latest API results.
    _all.removeWhere(
      (order) =>
          order.phone.replaceAll(RegExp(r'\D'), '') ==
          normalizedPhone,
    );

    _all.addAll(fetchedOrders);

    _all.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );

    await _persist();
  } catch (e) {
    debugPrint('Fetch customer orders failed: $e');
  } finally {
    _isRefreshing = false;
    notifyListeners();
  }
}



  /// Refresh one order's status.
  Future<Order?> refreshOrderStatus(String orderId) async {
    final existing = findById(orderId);

    if (existing == null) {
      debugPrint('Order $orderId is not saved locally.');
      return null;
    }

    try {
      final status = await _trackingService.fetchStatus(orderId);

      final index = _all.indexWhere((order) => order.id == orderId);

      if (index == -1) return null;

      final updated = _all[index].withBackendStatus(status);
      _all[index] = updated;

      await _persist();
      notifyListeners();

      return updated;
    } catch (error) {
      debugPrint('Could not refresh order status: $error');
      return findById(orderId);
    }
  }

  /// Refresh status for all orders currently displayed.
  Future<void> refreshCustomerOrders() async {
    if (_phone.isEmpty || _isRefreshing) return;

    _isRefreshing = true;
    notifyListeners();

    try {
      final ids = orders.map((order) => order.id).toList();

      for (final id in ids) {
        await refreshOrderStatus(id);
      }
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  void reassignPhone(String oldPhone, String newPhone) {
    final oldNormalized = _normalizePhone(oldPhone);
    final newNormalized = _normalizePhone(newPhone);

    for (var i = 0; i < _all.length; i++) {
      if (_normalizePhone(_all[i].phone) == oldNormalized) {
        _all[i] = _all[i].withPhone(newNormalized);
      }
    }

    _persist();
    notifyListeners();
  }

  void add(Order order) {
    final existingIndex = _all.indexWhere(
      (item) => item.id == order.id,
    );

    if (existingIndex >= 0) {
      _all[existingIndex] = order;
    } else {
      _all.insert(0, order);
    }

    _persist();
    notifyListeners();
  }

  Future<String> cancelOrder(
    String orderId, {
    String? reason,
  }) async {
    final index = _all.indexWhere(
      (order) => order.id == orderId,
    );

    if (index == -1) {
      throw Exception('Order not found.');
    }

    final message = await _cancellationService.cancelOrder(
      orderId: orderId,
      reason: reason,
    );

    _all[index] = _all[index].withBackendStatus('CANCELLED');

    await _persist();
    notifyListeners();

    return message;
  }
}