
import 'dish.dart';

class OrderLine {
  final Dish dish;
  final DishOption option;
  final int qty;

  const OrderLine({
    required this.dish,
    required this.option,
    required this.qty,
  });

  int get lineTotal => option.price * qty;

  Map<String, dynamic> toJson() => {
        'dish': dish.toJson(),
        'option': option.toJson(),
        'qty': qty,
      };

  factory OrderLine.fromJson(Map<String, dynamic> json) {
    return OrderLine(
      dish: Dish.fromJson(
        Map<String, dynamic>.from(json['dish'] as Map),
      ),
      option: DishOption.fromJson(
        Map<String, dynamic>.from(json['option'] as Map),
      ),
      qty: (json['qty'] as num).toInt(),
    );
  }
}

class Order {
  final String id;
  final String orderNumber;
  final List<OrderLine> lines;

  final int subtotal;
  final int packing;
  final int deliveryFee;
  final int total;

  final bool isDelivery;
  final bool isOrderNow;

  final String whenText;
  final DateTime scheduledAt;

  final String? address;
  final String? deliveryAddressId;

  final String customerName;
  final String phone;
  final String paymentLabel;

  final DateTime createdAt;

  final String? backendStatus;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.lines,
    required this.subtotal,
    required this.packing,
    required this.deliveryFee,
    required this.total,
    required this.isDelivery,
    required this.isOrderNow,
    required this.whenText,
    required this.scheduledAt,
    this.address,
    this.deliveryAddressId,
    required this.customerName,
    required this.phone,
    required this.paymentLabel,
    required this.createdAt,
    this.backendStatus,
  });

  String get normalizedStatus => (backendStatus ?? '')
      .trim()
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  bool get isCancellationLocked {
    final compactStatus = normalizedStatus.replaceAll('_', '');

    return const {
      'PREPARING',
      'PROCESSING',
      'INPREPARATION',
      'READY',
      'READYFORPICKUP',
      'OUTFORDELIVERY',
      'ONWAY',
      'ONTHEWAY',
      'DELIVERING',
      'COMPLETED',
    }.contains(compactStatus);
  }

  String get statusLabel {
    switch (normalizedStatus) {
      case 'NEW':
        return 'New';
      case 'PAYMENT_PENDING':
        return 'Payment Pending';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'PREPARING':
      case 'PROCESSING':
      case 'IN_PREPARATION':
        return 'Preparing';
      case 'READY':
      case 'READY_FOR_PICKUP':
        return 'Ready for Pickup';
      case 'OUT_FOR_DELIVERY':
      case 'ON_THE_WAY':
      case 'DELIVERING':
        return 'Out for Delivery';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      case 'PAYMENT_FAILED':
        return 'Payment Failed';
      case 'PAYMENT_EXPIRED':
        return 'Payment Expired';
      default:
        return 'Awaiting status';
    }
  }

  bool get isTerminalStatus => const {
        'COMPLETED',
        'CANCELLED',
        'PAYMENT_FAILED',
        'PAYMENT_EXPIRED',
      }.contains(normalizedStatus);

  int get status {
    switch (normalizedStatus) {
      case 'NEW':
      case 'PAYMENT_PENDING':
      case 'CONFIRMED':
        return 0;
      case 'PREPARING':
      case 'PROCESSING':
      case 'IN_PREPARATION':
        return 1;
      case 'READY':
      case 'READY_FOR_PICKUP':
      case 'OUT_FOR_DELIVERY':
      case 'ON_THE_WAY':
      case 'DELIVERING':
        return 2;
      case 'COMPLETED':
        return 3;
      case 'CANCELLED':
      case 'PAYMENT_FAILED':
      case 'PAYMENT_EXPIRED':
        return 0;
    }

    final now = DateTime.now();

    if (now.isAfter(scheduledAt.add(const Duration(hours: 1)))) {
      return 3;
    }

    if (now.isAfter(scheduledAt.subtract(const Duration(minutes: 10)))) {
      return 2;
    }

    if (now.isAfter(scheduledAt.subtract(const Duration(minutes: 60))) &&
        now.isAfter(createdAt.add(const Duration(minutes: 2)))) {
      return 1;
    }

    return 0;
  }

  Order withId(String newId) => _copyWith(id: newId);

  Order withOrderNumber(String newOrderNumber) =>
      _copyWith(orderNumber: newOrderNumber);

  Order withPhone(String newPhone) => _copyWith(phone: newPhone);

  Order withBackendStatus(String? newStatus) =>
      _copyWith(
        backendStatus: newStatus,
        clearBackendStatus: newStatus == null,
      );

  Order _copyWith({
    String? id,
    String? orderNumber,
    String? phone,
    String? backendStatus,
    bool clearBackendStatus = false,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      lines: lines,
      subtotal: subtotal,
      packing: packing,
      deliveryFee: deliveryFee,
      total: total,
      isDelivery: isDelivery,
      isOrderNow: isOrderNow,
      whenText: whenText,
      scheduledAt: scheduledAt,
      address: address,
      deliveryAddressId: deliveryAddressId,
      customerName: customerName,
      phone: phone ?? this.phone,
      paymentLabel: paymentLabel,
      createdAt: createdAt,
      backendStatus:
          clearBackendStatus ? null : backendStatus ?? this.backendStatus,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderNumber': orderNumber,
        'lines': lines.map((line) => line.toJson()).toList(),
        'subtotal': subtotal,
        'packing': packing,
        'deliveryFee': deliveryFee,
        'total': total,
        'isDelivery': isDelivery,
        'isOrderNow': isOrderNow,
        'whenText': whenText,
        'scheduledAt': scheduledAt.toIso8601String(),
        'address': address,
        'deliveryAddressId': deliveryAddressId,
        'customerName': customerName,
        'phone': phone,
        'paymentLabel': paymentLabel,
        'createdAt': createdAt.toIso8601String(),
        'backendStatus': backendStatus,
      };

  factory Order.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'];
    final payment = json['payment'];

    return Order(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      orderNumber:
          (json['orderNumber'] ?? json['order_number'])?.toString() ?? '',
      lines: (json['lines'] as List? ?? [])
          .whereType<Map>()
          .map(
            (line) => OrderLine.fromJson(
              Map<String, dynamic>.from(line),
            ),
          )
          .toList(),
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
      packing: (json['packing'] as num?)?.toInt() ??
          (json['packing_charge'] as num?)?.toInt() ??
          0,
      deliveryFee: (json['deliveryFee'] as num?)?.toInt() ??
          (json['delivery_charge'] as num?)?.toInt() ??
          0,
      total: (json['total'] as num?)?.toInt() ??
          (json['total_amount'] as num?)?.toInt() ??
          0,
      isDelivery: json['isDelivery'] as bool? ??
          (json['fulfillment_type']?.toString().toUpperCase() == 'DELIVERY'),
      isOrderNow: json['isOrderNow'] as bool? ??
          (json['order_type']?.toString().toUpperCase() == 'IMMEDIATE'),
      whenText: json['whenText']?.toString() ??
          json['when']?.toString() ??
          '',
      scheduledAt: DateTime.tryParse(
            (json['scheduledAt'] ?? json['requested_at'])?.toString() ?? '',
          ) ??
          DateTime.now(),
      address: json['address']?.toString(),
      deliveryAddressId: json['deliveryAddressId']?.toString() ??
          json['delivery_address_id']?.toString(),
      customerName: json['customerName']?.toString() ??
          (customer is Map ? customer['name']?.toString() ?? '' : ''),
      phone: json['phone']?.toString() ??
          (customer is Map ? customer['phone']?.toString() ?? '' : ''),
      paymentLabel: json['paymentLabel']?.toString() ??
          (payment is Map ? payment['method']?.toString() ?? '' : ''),
      createdAt: DateTime.tryParse(
            (json['createdAt'] ?? json['created_at'])?.toString() ?? '',
          ) ??
          DateTime.now(),
      backendStatus:
          json['status']?.toString() ?? json['backendStatus']?.toString(),
    );
  }

  /// Converts an order from GET /api/customer/orders/by-mobile.
  factory Order.fromBackendJson(
    Map<String, dynamic> json, {
    required String customerName,
    required String phone,
  }) {
    int readInt(dynamic value, [int fallback = 0]) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    final items = json['items'] is List
        ? json['items'] as List
        : <dynamic>[];

    final lines = items.map((item) {
      final itemJson = Map<String, dynamic>.from(item as Map);

      final quantity =
          readInt(itemJson['quantity'], 1).clamp(1, 100).toInt();

      final itemType =
          (itemJson['item_type'] ?? 'PRODUCT').toString();

      final productName =
          (itemJson['product_name'] ?? 'Item').toString();

      final variantName =
          (itemJson['variant_name'] ?? '').toString();
final option = DishOption(
  variantName.isEmpty ? 'Regular' : variantName,
  readInt(itemJson['unit_price']),
  id: (itemJson['variant_id'] ?? '').toString(),
);

      final dish = Dish(
        id: (itemJson['product_id'] ?? itemJson['item_id'] ?? '').toString(),
        name: productName,
        nameTe: '',
        description: '',
        descriptionTe: '',
        category: '',
        categoryName: '',
        options: [option],
        imageUrl: '',
        itemType: itemType,
      );

      return OrderLine(
        dish: dish,
        option: option,
        qty: quantity,
      );
    }).toList();

    final addressJson = json['delivery_address'];
    String? address;

    if (addressJson is Map) {
      final parts = [
        addressJson['label'],
        addressJson['house_flat_no'],
        addressJson['street_area'],
        addressJson['landmark'],
        addressJson['pincode'],
      ]
          .where((value) =>
              value != null && value.toString().trim().isNotEmpty)
          .map((value) => value.toString().trim())
          .toList();

      if (parts.isNotEmpty) {
        address = parts.join(', ');
      }
    }

    final createdAt =
        DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now();

    final requestedAt =
        DateTime.tryParse(json['requested_at']?.toString() ?? '');

    final orderType =
        (json['order_type'] ?? 'IMMEDIATE').toString().toUpperCase();

    final fulfillmentType =
        (json['fulfillment_type'] ?? 'PICKUP').toString().toUpperCase();

    return Order(
      id: (json['order_id'] ?? json['_id'] ?? json['id'] ?? '').toString(),
      orderNumber: (json['order_number'] ?? '').toString(),
      lines: lines,
      subtotal: readInt(json['subtotal']),
      packing: readInt(json['packing_charge']),
      deliveryFee: readInt(json['delivery_charge']),
      total: readInt(json['total_amount']),
      isDelivery: fulfillmentType == 'DELIVERY',
      isOrderNow: orderType == 'IMMEDIATE',
      whenText: requestedAt == null ? 'Immediate' : 'Scheduled',
      scheduledAt: requestedAt ?? createdAt,
      address: address,
      deliveryAddressId: '',
      customerName: customerName,
      phone: phone,
      paymentLabel: (json['payment_status'] ?? 'PENDING').toString(),
      createdAt: createdAt,
      backendStatus: (json['status'] ?? 'NEW').toString(),
    );
  }
}
