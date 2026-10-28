// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import '../core/app_core.dart';
// import '../models/order.dart';
// import '../providers/orders_provider.dart';
// import '../services/api_client.dart';
// import '../widgets/checkout_widgets.dart';

// const _green = Color(0xFF2E7D4F);
// const _cancelRed = Color(0xFFD94B36);

// class TrackOrderScreen extends StatefulWidget {
//   final Order order;

//   const TrackOrderScreen({super.key, required this.order});

//   @override
//   State<TrackOrderScreen> createState() => _TrackOrderScreenState();
// }

// class _TrackOrderScreenState extends State<TrackOrderScreen> {
//   late Order _currentOrder;
//   Timer? _pollTimer;
//   bool _refreshing = false;
//   bool _cancelling = false;

//   @override
//   void initState() {
//     super.initState();
//     _currentOrder = widget.order;

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (mounted) _refreshStatus();
//     });

//     _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
//       if (mounted && !_currentOrder.isTerminalStatus && !_cancelling) {
//         _refreshStatus();
//       }
//     });
//   }

//   @override
//   void didUpdateWidget(covariant TrackOrderScreen oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.order.id != widget.order.id) {
//       _currentOrder = widget.order;
//       _refreshStatus();
//     }
//   }

//   @override
//   void dispose() {
//     _pollTimer?.cancel();
//     super.dispose();
//   }

//   Future<void> _refreshStatus() async {
//     if (_refreshing || _cancelling || _currentOrder.id.trim().isEmpty) return;

//     _refreshing = true;
//     try {
//       final provider = context.read<OrdersProvider>();
//       final latest = await provider.refreshOrderStatus(_currentOrder.id);
//       if (!mounted || latest == null) return;

//       setState(() => _currentOrder = latest);

//       if (latest.isTerminalStatus) _pollTimer?.cancel();
//     } finally {
//       _refreshing = false;
//     }
//   }

//   bool get _isPreparing {
//     final status = _currentOrder.normalizedStatus;
//     return status == 'PREPARING' ||
//         status == 'PROCESSING' ||
//         status == 'IN_PREPARATION';
//   }

//   Future<void> _showPreparingMessage() async {
//     await showDialog<void>(
//       context: context,
//       builder: (dialogContext) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//         title: const Text(
//           'Order is being prepared',
//           style: TextStyle(fontWeight: FontWeight.w800, color: kNavy),
//         ),
//         content: const Text(
//           'Your food is already being prepared, so this order can no longer be cancelled. We’re sorry for the inconvenience.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(dialogContext),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<String?> _askCancellationReason() async {
//     const reasons = <String>[
//       'Ordered by mistake',
//       'Selected the wrong items',
//       'Delivery time is too long',
//       'Changed my mind',
//       'Other',
//     ];
//     String selectedReason = reasons.first;
//     final otherController = TextEditingController();

//     final result = await showDialog<String>(
//       context: context,
//       barrierDismissible: false,
//       builder: (dialogContext) => StatefulBuilder(
//         builder: (context, setDialogState) => AlertDialog(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//           title: const Text(
//             'Why are you cancelling?',
//             style: TextStyle(fontWeight: FontWeight.w800, color: kNavy),
//           ),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text('Please select a reason for cancelling your order.'),
//                 const SizedBox(height: 10),
//                 for (final reason in reasons)
//                   RadioListTile<String>(
//                     contentPadding: EdgeInsets.zero,
//                     dense: true,
//                     title: Text(reason),
//                     value: reason,
//                     groupValue: selectedReason,
//                     onChanged: (value) {
//                       if (value == null) return;
//                       setDialogState(() => selectedReason = value);
//                     },
//                   ),
//                 if (selectedReason == 'Other') ...[
//                   const SizedBox(height: 8),
//                   TextField(
//                     controller: otherController,
//                     maxLength: 500,
//                     maxLines: 3,
//                     decoration: InputDecoration(
//                       labelText: 'Tell us the reason',
//                       hintText: 'Enter your reason',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(dialogContext),
//               child: const Text('Keep Order', style: TextStyle(color: kNavy)),
//             ),
//             TextButton(
//               onPressed: () {
//                 final reason = selectedReason == 'Other'
//                     ? otherController.text.trim()
//                     : selectedReason;
//                 if (reason.isEmpty) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Please enter your reason.')),
//                   );
//                   return;
//                 }
//                 Navigator.pop(dialogContext, reason);
//               },
//               child: const Text(
//                 'Continue to Cancel',
//                 style: TextStyle(color: _cancelRed, fontWeight: FontWeight.w700),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//     otherController.dispose();
//     return result;
//   }

//   Future<void> _showCancelDialog() async {
//     if (_cancelling || _currentOrder.isTerminalStatus) return;

//     // Do not even attempt the cancellation API after preparation has started.
//     if (_isPreparing) {
//       await _showPreparingMessage();
//       return;
//     }

//     final reason = await _askCancellationReason();
//     if (reason == null || !mounted) return;

//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (dialogContext) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
//         title: const Text(
//           'Confirm cancellation',
//           style: TextStyle(fontWeight: FontWeight.w800, color: kNavy),
//         ),
//         content: Text('Cancel this order for the following reason?\n\n$reason'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(dialogContext, false),
//             child: const Text('Keep Order', style: TextStyle(color: kNavy)),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(dialogContext, true),
//             child: const Text(
//               'Yes, Cancel Order',
//               style: TextStyle(color: _cancelRed, fontWeight: FontWeight.w700),
//             ),
//           ),
//         ],
//       ),
//     );

//     if (confirmed != true || !mounted) return;
//     setState(() => _cancelling = true);

//     try {
//       final provider = context.read<OrdersProvider>();
//       final message = await provider.cancelOrder(_currentOrder.id, reason: reason);
//       if (!mounted) return;
//       final updated = provider.findById(_currentOrder.id);
//       setState(() {
//         if (updated != null) _currentOrder = updated;
//       });
//       _pollTimer?.cancel();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
//       );
//     } catch (error) {
//       if (!mounted) return;
//       final message = error is ApiException ? error.message : error.toString();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(message.isNotEmpty ? message : 'Unable to cancel order. Please try again.'),
//           behavior: SnackBarBehavior.floating,
//           backgroundColor: _cancelRed,
//         ),
//       );
//       // Refresh in case the kitchen changed the order status while the dialog was open.
//       await _refreshStatus();
//     } finally {
//       if (mounted) setState(() => _cancelling = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final order = _currentOrder;
//     final status = order.normalizedStatus;

//     final steps = [
//       'statusConfirmed',
//       'statusPreparing',
//       order.isDelivery ? 'statusOnWay' : 'statusReady',
//       'statusDone',
//     ];

//     final timelineIndex = order.status;
//     final isCancelled = status == 'CANCELLED';
//     final isPaymentIssue =
//         status == 'PAYMENT_FAILED' || status == 'PAYMENT_EXPIRED';
//     final isPaymentPending = status == 'PAYMENT_PENDING';
//     final isPreparing = _isPreparing;

//     return Scaffold(
//       backgroundColor: AppColors.background,
//       body: SafeArea(
//         child: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.fromLTRB(12, 16, 20, 8),
//               child: Row(
//                 children: [
//                   IconButton(
//                     onPressed: () => Navigator.pop(context),
//                     icon: const Icon(Icons.chevron_left, size: 30, color: kNavy),
//                   ),
//                   Expanded(
//                     child: Text(
//                       context.tr('trackOrder'),
//                       style: const TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.w800,
//                         color: kNavy,
//                       ),
//                     ),
//                   ),
//                   IconButton(
//                     tooltip: 'Refresh status',
//                     onPressed: _refreshing || _cancelling ? null : _refreshStatus,
//                     icon: const Icon(Icons.refresh, color: kNavy),
//                   ),
//                 ],
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
//               child: Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(18),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(18),
//                   border: Border.all(color: const Color(0xFFEFE8DC)),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             '#${order.orderNumber.trim().isNotEmpty ? order.orderNumber : order.id}',
//                             style: const TextStyle(
//                               fontFamily: 'monospace',
//                               fontSize: 16,
//                               fontWeight: FontWeight.w800,
//                               color: kNavy,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             order.whenText,
//                             style: const TextStyle(
//                               fontSize: 13.5,
//                               color: Color(0xFF55606B),
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             order.statusLabel,
//                             style: TextStyle(
//                               fontSize: 15,
//                               fontWeight: FontWeight.w800,
//                               color: isCancelled || isPaymentIssue
//                                   ? _cancelRed
//                                   : AppColors.primary,
//                             ),
//                           ),
//                           if (_refreshing || _cancelling)
//                             Padding(
//                               padding: const EdgeInsets.only(top: 6),
//                               child: Text(
//                                 _cancelling ? 'Cancelling order…' : 'Updating status…',
//                                 style: const TextStyle(
//                                   fontSize: 12,
//                                   color: Color(0xFF667085),
//                                 ),
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Text(
//                       rupees(order.total),
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w800,
//                         color: kNavy,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             if (isCancelled || isPaymentIssue || isPaymentPending || isPreparing)
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
//                 child: Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(14),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(
//                       color: isCancelled || isPaymentIssue
//                           ? const Color(0xFFF2C5BF)
//                           : const Color(0xFFEFE0B2),
//                     ),
//                   ),
//                   child: Text(
//                     isCancelled
//                         ? 'This order has been cancelled.'
//                         : isPreparing
//                             ? 'Your food is already being prepared, so this order can no longer be cancelled. We’re sorry for the inconvenience.'
//                             : isPaymentIssue
//                                 ? 'There is a payment issue with this order.'
//                                 : 'Payment is pending for this order.',
//                     style: const TextStyle(
//                       color: kNavy,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ),
//             Expanded(
//               child: ListView(
//                 padding: const EdgeInsets.symmetric(horizontal: 28),
//                 children: [
//                   for (int i = 0; i < steps.length; i++)
//                     _TimelineStep(
//                       label: context.tr(steps[i]),
//                       done: !isCancelled &&
//                           !isPaymentIssue &&
//                           !isPaymentPending &&
//                           i < timelineIndex,
//                       current: !isCancelled &&
//                           !isPaymentIssue &&
//                           !isPaymentPending &&
//                           i == timelineIndex,
//                       last: i == steps.length - 1,
//                     ),
//                 ],
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
//               child: SizedBox(
//                 width: double.infinity,
//                 height: 50,
//                 child: OutlinedButton.icon(
//                   onPressed: order.isTerminalStatus || _cancelling
//                       ? null
//                       : _showCancelDialog,
//                   icon: _cancelling
//                       ? const SizedBox(
//                           width: 18,
//                           height: 18,
//                           child: CircularProgressIndicator(strokeWidth: 2),
//                         )
//                       : const Icon(Icons.cancel_outlined),
//                   label: Text(
//                     _cancelling ? 'Cancelling...' : context.tr('cancelOrder'),
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                   style: OutlinedButton.styleFrom(
//                     foregroundColor: _cancelRed,
//                     side: const BorderSide(color: _cancelRed),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _TimelineStep extends StatelessWidget {
//   final String label;
//   final bool done;
//   final bool current;
//   final bool last;

//   const _TimelineStep({
//     required this.label,
//     required this.done,
//     required this.current,
//     required this.last,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final active = done || current;

//     return IntrinsicHeight(
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           SizedBox(
//             width: 28,
//             child: Column(
//               children: [
//                 Container(
//                   width: 26,
//                   height: 26,
//                   decoration: BoxDecoration(
//                     color: done
//                         ? _green
//                         : current
//                             ? AppColors.primary
//                             : Colors.transparent,
//                     shape: BoxShape.circle,
//                     border: active
//                         ? null
//                         : Border.all(
//                             color: const Color(0xFFD5CDBF),
//                             width: 2,
//                           ),
//                   ),
//                   child: done
//                       ? const Icon(Icons.check, size: 16, color: Colors.white)
//                       : null,
//                 ),
//                 if (!last)
//                   Expanded(
//                     child: Container(
//                       width: 2,
//                       color: done ? _green : const Color(0xFFD5CDBF),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 16),
//           Padding(
//             padding: const EdgeInsets.only(bottom: 34),
//             child: Text(
//               label,
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: current ? FontWeight.w800 : FontWeight.w600,
//                 color: active ? kNavy : AppColors.textMuted,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_core.dart';
import '../models/order.dart';
import '../providers/orders_provider.dart';
import '../services/api_client.dart';
import '../widgets/checkout_widgets.dart';

const _green = Color(0xFF2E7D4F);
const _cancelRed = Color(0xFFD94B36);

class TrackOrderScreen extends StatefulWidget {
  final Order order;

  const TrackOrderScreen({super.key, required this.order});

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  late Order _currentOrder;
  Timer? _pollTimer;
  bool _refreshing = false;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshStatus();
    });

    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted && !_currentOrder.isTerminalStatus && !_cancelling) {
        _refreshStatus();
      }
    });
  }

  @override
  void didUpdateWidget(covariant TrackOrderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.id != widget.order.id) {
      _currentOrder = widget.order;
      _refreshStatus();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    if (_refreshing || _cancelling || _currentOrder.id.trim().isEmpty) return;

    _refreshing = true;
    try {
      final provider = context.read<OrdersProvider>();
      final latest = await provider.refreshOrderStatus(_currentOrder.id);
      if (!mounted || latest == null) return;

      setState(() => _currentOrder = latest);

      if (latest.isTerminalStatus) _pollTimer?.cancel();
    } finally {
      _refreshing = false;
    }
  }

  bool get _isPreparing {
    final status = _currentOrder.normalizedStatus;
    return status == 'PREPARING' ||
        status == 'PROCESSING' ||
        status == 'IN_PREPARATION';
  }

  Future<void> _showPreparingMessage() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Order is being prepared',
          style: TextStyle(fontWeight: FontWeight.w800, color: kNavy),
        ),
        content: const Text(
          'Your food is already being prepared, so this order can no longer be cancelled. We’re sorry for the inconvenience.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<String?> _askCancellationReason() async {
    const reasons = <String>[
      'Ordered by mistake',
      'Selected the wrong items',
      'Delivery time is too long',
      'Changed my mind',
      'Other',
    ];
    String selectedReason = reasons.first;
    final otherController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text(
            'Why are you cancelling?',
            style: TextStyle(fontWeight: FontWeight.w800, color: kNavy),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Please select a reason for cancelling your order.'),
                const SizedBox(height: 10),
                for (final reason in reasons)
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(reason),
                    value: reason,
                    groupValue: selectedReason,
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => selectedReason = value);
                    },
                  ),
                if (selectedReason == 'Other') ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: otherController,
                    maxLength: 500,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Tell us the reason',
                      hintText: 'Enter your reason',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Keep Order', style: TextStyle(color: kNavy)),
            ),
            TextButton(
              onPressed: () {
                final reason = selectedReason == 'Other'
                    ? otherController.text.trim()
                    : selectedReason;
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your reason.')),
                  );
                  return;
                }
                Navigator.pop(dialogContext, reason);
              },
              child: const Text(
                'Continue to Cancel',
                style: TextStyle(color: _cancelRed, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
    otherController.dispose();
    return result;
  }

  Future<void> _showCancelDialog() async {
    if (_cancelling || _currentOrder.isTerminalStatus) return;

    // Do not even attempt the cancellation API after preparation has started.
    if (_isPreparing) {
      await _showPreparingMessage();
      return;
    }

    final reason = await _askCancellationReason();
    if (reason == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Confirm cancellation',
          style: TextStyle(fontWeight: FontWeight.w800, color: kNavy),
        ),
        content: Text('Cancel this order for the following reason?\n\n$reason'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Order', style: TextStyle(color: kNavy)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Yes, Cancel Order',
              style: TextStyle(color: _cancelRed, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _cancelling = true);

    try {
      final provider = context.read<OrdersProvider>();
      final message = await provider.cancelOrder(_currentOrder.id, reason: reason);
      if (!mounted) return;
      final updated = provider.findById(_currentOrder.id);
      setState(() {
        if (updated != null) _currentOrder = updated;
      });
      _pollTimer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException ? error.message : error.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message.isNotEmpty ? message : 'Unable to cancel order. Please try again.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _cancelRed,
        ),
      );
      // Refresh in case the kitchen changed the order status while the dialog was open.
      await _refreshStatus();
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _currentOrder;
    final status = order.normalizedStatus;

    final steps = [
      'statusConfirmed',
      'statusPreparing',
      order.isDelivery ? 'statusOnWay' : 'statusReady',
      'statusDone',
    ];

    final timelineIndex = order.status;
    final isCancelled = status == 'CANCELLED';
    final isPaymentIssue =
        status == 'PAYMENT_FAILED' || status == 'PAYMENT_EXPIRED';
    final isPaymentPending = status == 'PAYMENT_PENDING';
    final isPreparing = _isPreparing;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.chevron_left, size: 30, color: kNavy),
                  ),
                  Expanded(
                    child: Text(
                      context.tr('trackOrder'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: kNavy,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh status',
                    onPressed: _refreshing || _cancelling ? null : _refreshStatus,
                    icon: const Icon(Icons.refresh, color: kNavy),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFEFE8DC)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${order.orderNumber.trim().isNotEmpty ? order.orderNumber : order.id}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: kNavy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.whenText,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF55606B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            order.statusLabel,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isCancelled || isPaymentIssue
                                  ? _cancelRed
                                  : AppColors.primary,
                            ),
                          ),
                          if (_refreshing || _cancelling)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                _cancelling ? 'Cancelling order…' : 'Updating status…',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF667085),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      rupees(order.total),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: kNavy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isCancelled || isPaymentIssue || isPaymentPending)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCancelled || isPaymentIssue
                          ? const Color(0xFFF2C5BF)
                          : const Color(0xFFEFE0B2),
                    ),
                  ),
                  child: Text(
                    isCancelled
                        ? 'This order has been cancelled.'
                        : isPreparing
                            ? 'Your food is already being prepared, so this order can no longer be cancelled. We’re sorry for the inconvenience.'
                            : isPaymentIssue
                                ? 'There is a payment issue with this order.'
                                : 'Payment is pending for this order.',
                    style: const TextStyle(
                      color: kNavy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                children: [
                  for (int i = 0; i < steps.length; i++)
                    _TimelineStep(
                      label: context.tr(steps[i]),
                      done: !isCancelled &&
                          !isPaymentIssue &&
                          !isPaymentPending &&
                          i < timelineIndex,
                      current: !isCancelled &&
                          !isPaymentIssue &&
                          !isPaymentPending &&
                          i == timelineIndex,
                      last: i == steps.length - 1,
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: order.isTerminalStatus || _cancelling
                      ? null
                      : _showCancelDialog,
                  icon: _cancelling
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cancel_outlined),
                  label: Text(
                    _cancelling ? 'Cancelling...' : context.tr('cancelOrder'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _cancelRed,
                    side: const BorderSide(color: _cancelRed),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String label;
  final bool done;
  final bool current;
  final bool last;

  const _TimelineStep({
    required this.label,
    required this.done,
    required this.current,
    required this.last,
  });

  @override
  Widget build(BuildContext context) {
    final active = done || current;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: done
                        ? _green
                        : current
                            ? AppColors.primary
                            : Colors.transparent,
                    shape: BoxShape.circle,
                    border: active
                        ? null
                        : Border.all(
                            color: const Color(0xFFD5CDBF),
                            width: 2,
                          ),
                  ),
                  child: done
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: done ? _green : const Color(0xFFD5CDBF),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Padding(
            padding: const EdgeInsets.only(bottom: 34),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: current ? FontWeight.w800 : FontWeight.w600,
                color: active ? kNavy : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

