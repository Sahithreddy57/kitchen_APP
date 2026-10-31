// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../core/app_core.dart';
// import '../models/order.dart';
// import '../providers/auth_provider.dart';
// import '../providers/language_provider.dart';
// import '../providers/orders_provider.dart';
// import '../services/payment_service.dart';
// import '../widgets/checkout_widgets.dart';
// import 'order_confirmed_screen.dart';

// const _green = Color(0xFF2E7D4F);

// class ProcessingScreen extends StatefulWidget {
//   final PaymentRequest request;
//   final Order draft;
//   const ProcessingScreen({super.key, required this.request, required this.draft});

//   @override
//   State<ProcessingScreen> createState() => _ProcessingScreenState();
// }

// class _ProcessingScreenState extends State<ProcessingScreen> {
//   int _step = 0; // steps below _step are done, _step is in progress

//   @override
//   void initState() {
//     super.initState();
//     _run();
//   }

//   Future<void> _run() async {
//     final svc = PaymentService();
//     try {
//       // 1. Contacting your bank (gateway)
//       final pay = await svc.startPayment(widget.request);
//       if (!pay.success) throw Exception(pay.error ?? 'Payment failed');
//       if (!mounted) return;
//       setState(() => _step = 1);

//       // 2. Confirming payment (server verification)
//       final ok = await svc.confirmPayment(pay.txnId!);
//       if (!ok) throw Exception('Payment not confirmed');
//       if (!mounted) return;
//       setState(() => _step = 2);

//       // 3. Sending to kitchen
// final auth = context.read<AuthProvider>();

// final id = await svc.sendToKitchen(
//   widget.draft,
//   customerId: auth.customerId,
//   token: auth.token!,
//   idempotencyKey: 'order-${widget.draft.createdAt.microsecondsSinceEpoch}',
// );
//       if (!mounted) return;
//       setState(() => _step = 3); // all ticked
//       await Future.delayed(const Duration(milliseconds: 600));
//       if (!mounted) return;

//       final order = widget.draft.withId(id);
//       context.read<OrdersProvider>().add(order);
//       context.read<CartProvider>().clear();
//       context.read<AuthProvider>().register(
//   order.customerName,
//   order.phone,
//   token: auth.token,
//   customerId: auth.customerId,
// );

//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(builder: (_) => OrderConfirmedScreen(order: order)),
//         (route) => route.isFirst, // keep MainShell underneath
//       );
//     } catch (_) {
//       if (mounted) Navigator.pop(context, 'failed'); // back to checkout
//     }
//   }

//   Widget _stepRow(int i, String label) {
//     final done = _step > i;
//     final current = _step == i;
//     Widget icon;
//     if (done) {
//       icon = Container(
//         key: ValueKey('done$i'),
//         width: 24,
//         height: 24,
//         decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
//         child: const Icon(Icons.check, size: 15, color: Colors.white),
//       );
//     } else if (current) {
//       icon = Container(
//         key: ValueKey('cur$i'),
//         width: 24,
//         height: 24,
//         decoration: const BoxDecoration(
//             color: AppColors.primary, shape: BoxShape.circle),
//       );
//     } else {
//       icon = Container(
//         key: ValueKey('wait$i'),
//         width: 24,
//         height: 24,
//         decoration: BoxDecoration(
//           shape: BoxShape.circle,
//           border: Border.all(color: const Color(0xFFD5CDBF), width: 2),
//         ),
//       );
//     }
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 7),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           AnimatedSwitcher(
//               duration: const Duration(milliseconds: 250), child: icon),
//           const SizedBox(width: 12),
//           Text(label,
//               style: TextStyle(
//                   fontSize: 15,
//                   color: done || current ? kNavy : AppColors.textMuted)),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     // No going back while the payment is in flight.
//     return PopScope(
//       canPop: false,
//       child: Scaffold(
//         backgroundColor: AppColors.background,
//         body: SafeArea(
//           child: Center(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const SizedBox(
//                   width: 64,
//                   height: 64,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 5,
//                     color: AppColors.primary,
//                     backgroundColor: Color(0xFFEFE3D5),
//                   ),
//                 ),
//                 const SizedBox(height: 30),
//                 Text(context.tr('processingTitle'),
//                     style: const TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.w800,
//                         color: kNavy)),
//                 const SizedBox(height: 18),
//                 _stepRow(0, context.tr('stepBank')),
//                 _stepRow(1, context.tr('stepConfirm')),
//                 _stepRow(2, context.tr('stepKitchen')),
//                 const SizedBox(height: 22),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 32),
//                   child: Text(context.tr('dontClose'),
//                       textAlign: TextAlign.center,
//                       style: const TextStyle(
//                           fontSize: 12.5, color: AppColors.textMuted)),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_core.dart';
import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../providers/orders_provider.dart';
import '../services/payment_service.dart';
import '../widgets/checkout_widgets.dart';
import 'order_confirmed_screen.dart';
import '../providers/language_provider.dart';

const _green = Color(0xFF2E7D4F);

class ProcessingScreen extends StatefulWidget {
  final PaymentRequest request;
  final Order draft;

  const ProcessingScreen({
    super.key,
    required this.request,
    required this.draft,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  int _step = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _run();
    });
  }

  Future<void> _run() async {
    final svc = PaymentService();

    try {
      // STEP 1: Get authenticated customer details.
      final auth = context.read<AuthProvider>();

      final customerId = auth.customerId.trim();
      final token = auth.token.trim();

      if (customerId.isEmpty || token.isEmpty) {
        throw Exception(
          'Your login session has expired. Please sign in again.',
        );
      }

      if (!mounted) return;
      setState(() => _step = 0);

      // STEP 2: Submit the order to the backend.
      // Backend validates kitchen, slots, Hundi, address and items.
      final createdOrder = await svc.sendToKitchen(
        widget.draft,
        customerId: customerId,
        token: token,
        idempotencyKey:
            'order-${widget.draft.createdAt.microsecondsSinceEpoch}',
      );

      if (createdOrder.id.trim().isEmpty) {
        throw Exception('The backend did not return an order ID.');
      }

      // Your backend currently returns NEW after successful creation.
      const allowedStatuses = {
        'NEW',
        'PAYMENT_PENDING',
      };

      if (!allowedStatuses.contains(
        createdOrder.status.toUpperCase(),
      )) {
        throw Exception(
          'Unexpected order status: ${createdOrder.status}',
        );
      }

      if (createdOrder.payableAmount <= 0) {
        throw Exception(
          'The backend returned an invalid payment amount.',
        );
      }

      debugPrint('ORDER CREATED: ${createdOrder.id}');
      debugPrint('ORDER NUMBER: ${createdOrder.orderNumber}');
      debugPrint('ORDER STATUS: ${createdOrder.status}');
      debugPrint('ORDER AMOUNT: ${createdOrder.payableAmount}');

      if (!mounted) return;
      setState(() => _step = 1);

      // STEP 3: Start mock payment using the backend amount.
      final paymentRequest = PaymentRequest(
        amount: createdOrder.payableAmount,
        method: widget.request.method,
        detail: widget.request.detail,
      );

      final payment = await svc.startPayment(paymentRequest);

      if (!payment.success) {
        throw Exception(
          payment.error ?? 'Payment failed. Please try again.',
        );
      }

      final txnId = payment.txnId;

      if (txnId == null || txnId.trim().isEmpty) {
        throw Exception('Payment transaction ID is missing.');
      }

      if (!mounted) return;
      setState(() => _step = 2);

      // STEP 4: Mock payment confirmation.
      final paymentConfirmed = await svc.confirmPayment(txnId);

      if (!paymentConfirmed) {
        throw Exception('Payment confirmation failed.');
      }

      debugPrint('MOCK PAYMENT SUCCESSFUL: $txnId');

      if (!mounted) return;

      // STEP 5: Save the successfully processed order locally.
      final order = widget.draft
          .withId(createdOrder.id)
          .withOrderNumber(createdOrder.orderNumber);

      context.read<OrdersProvider>().add(order);

      // STEP 6: Clear cart after mock payment success.
      context.read<CartProvider>().clear();

      debugPrint('ORDER SAVED LOCALLY');
      debugPrint('CART CLEARED');

      if (!mounted) return;

      // STEP 7: Navigate to order confirmation.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => OrderConfirmedScreen(
            order: order,
          ),
        ),
        (route) => route.isFirst,
      );
    } catch (error, stackTrace) {
      debugPrint('Checkout processing failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      Navigator.pop(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Widget _stepRow(int i, String label) {
    final done = _step > i;
    final current = _step == i;

    Widget icon;

    if (done) {
      icon = Container(
        key: ValueKey('done$i'),
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: _green,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check,
          size: 15,
          color: Colors.white,
        ),
      );
    } else if (current) {
      icon = Container(
        key: ValueKey('cur$i'),
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
      );
    } else {
      icon = Container(
        key: ValueKey('wait$i'),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFD5CDBF),
            width: 2,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: icon,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: done || current
                  ? kNavy
                  : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    strokeWidth: 5,
                    color: AppColors.primary,
                    backgroundColor: Color(0xFFEFE3D5),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  context.tr('processingTitle'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: kNavy,
                  ),
                ),
                const SizedBox(height: 18),
                _stepRow(0, context.tr('stepBank')),
                _stepRow(1, context.tr('stepConfirm')),
                _stepRow(2, context.tr('stepKitchen')),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                  ),
                  child: Text(
                    context.tr('dontClose'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
