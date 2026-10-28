// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../core/app_core.dart';
// import '../models/order.dart';
// import '../providers/language_provider.dart';
// import '../widgets/checkout_widgets.dart';
// import 'order_actions.dart';
// import 'track_order_screen.dart';

// const _green = Color(0xFF2E7D4F);

// class OrderDetailsScreen extends StatelessWidget {
//   final Order order;
//   const OrderDetailsScreen({super.key, required this.order});

//   @override
//   Widget build(BuildContext context) {
//     final isTe = context.watch<LanguageProvider>().isTelugu;
//     final done = order.status >= 3;
//     final bannerColor = done ? _green : AppColors.primary;

//     Widget row(String l, String v) => Padding(
//           padding: const EdgeInsets.symmetric(vertical: 5),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(l,
//                   style: const TextStyle(
//                       fontSize: 15, color: Color(0xFF55606B))),
//               Text(v,
//                   style: const TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w600,
//                       color: kNavy)),
//             ],
//           ),
//         );

//     return Scaffold(
//       backgroundColor: AppColors.background,
//       body: SafeArea(
//         child: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.fromLTRB(12, 16, 20, 8),
//               child: Row(children: [
//                 IconButton(
//                   onPressed: () => Navigator.pop(context),
//                   icon: const Icon(Icons.chevron_left, size: 30, color: kNavy),
//                 ),
//                 Text( '#${order.orderNumber.trim().isNotEmpty ? order.orderNumber : order.id}',
//                     style: const TextStyle(
//                         fontFamily: 'monospace',
//                         fontSize: 17,
//                         fontWeight: FontWeight.w800,
//                         color: kNavy)),
//               ]),
//             ),
//             Expanded(
//               child: ListView(
//                 padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
//                 children: [
//                   // status banner
//                   Container(
//                     padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
//                     decoration: BoxDecoration(
//                       color: bannerColor,
//                       borderRadius: BorderRadius.circular(24),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                             '${context.tr('orderWord')} · ${formatOrderDate(isTe, order.createdAt)}',
//                             style: const TextStyle(
//                                 fontFamily: 'monospace',
//                                 fontSize: 12,
//                                 letterSpacing: 1.5,
//                                 color: Color(0xFFF6C9A0))),
//                         const SizedBox(height: 6),
//                         Text(context.tr(statusKey(order)),
//                             style: const TextStyle(
//                                 fontSize: 32,
//                                 fontWeight: FontWeight.w800,
//                                 color: Colors.white)),
//                         const SizedBox(height: 4),
//                         Text(
//                             context.tr(done ? 'enjoyMeal' : 'weUpdate'),
//                             style: const TextStyle(
//                                 fontSize: 15, color: Colors.white)),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 18),
//                   // receipt
//                   Container(
//                     padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(color: const Color(0xFFEFE8DC)),
//                     ),
//                     child: Column(
//                       children: [
//                         Row(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                                 order.isDelivery
//                                     ? context.tr('delivery')
//                                     : context.tr('pickup'),
//                                 style: const TextStyle(
//                                     fontSize: 14, color: Color(0xFF55606B))),
//                             const SizedBox(width: 16),
//                             Expanded(
//                               child: Text(
//                                   order.isDelivery
//                                       ? (order.address ?? '')
//                                       : context.tr('pickupSub'),
//                                   textAlign: TextAlign.right,
//                                   style: const TextStyle(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.w700,
//                                       color: kNavy)),
//                             ),
//                           ],
//                         ),
//                         const Divider(height: 24, color: Color(0xFFEFE8DC)),
//                         for (final l in order.lines)
//                           row(
//                               '${isTe ? l.dish.nameTe : l.dish.name} · ${l.option.label} × ${l.qty}',
//                               rupees(l.lineTotal)),
//                         const Divider(height: 24, color: Color(0xFFEFE8DC)),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(context.tr('paid'),
//                                 style: const TextStyle(
//                                     fontSize: 17,
//                                     fontWeight: FontWeight.w800,
//                                     color: kNavy)),
//                             Text(rupees(order.total),
//                                 style: const TextStyle(
//                                     fontSize: 19,
//                                     fontWeight: FontWeight.w800,
//                                     color: kNavy)),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   // main action
//                   SizedBox(
//                     height: 56,
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: AppColors.primary,
//                         foregroundColor: Colors.white,
//                         elevation: 0,
//                         shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(16)),
//                       ),
//                       onPressed: () => done
//                           ? reorder(context, order)
//                           : Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                   builder: (_) =>
//                                       TrackOrderScreen(order: order))),
//                       child: Text(
//                           context.tr(done ? 'reorderItems' : 'trackOrder'),
//                           style: const TextStyle(
//                               fontSize: 17, fontWeight: FontWeight.w800)),
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   SizedBox(
//                     height: 56,
//                     child: OutlinedButton(
//                       style: OutlinedButton.styleFrom(
//                         foregroundColor: kNavy,
//                         side: const BorderSide(color: kNavy, width: 1.2),
//                         shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(16)),
//                       ),
//                       onPressed: () => showHelpSheet(context, isTe, order: order),
//                       child: Text(context.tr('getHelp'),
//                           style: const TextStyle(
//                               fontSize: 16, fontWeight: FontWeight.w800)),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_core.dart';
import '../models/order.dart';
import '../providers/language_provider.dart';
import '../widgets/checkout_widgets.dart';
import 'order_actions.dart';

const _green = Color(0xFF2E7D4F);

class OrderDetailsScreen extends StatelessWidget {
  final Order order;

  const OrderDetailsScreen({super.key, required this.order});

  void _reorder(BuildContext context) {
    if (order.lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No items are available to reorder.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final cart = context.read<CartProvider>();

    // Add the original dishes, options, and quantities to the cart.
    for (final line in order.lines) {
      cart.add(line.dish, line.option, line.qty);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Items added to your cart.'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Return to the previous screen.
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isTe = context.watch<LanguageProvider>().isTelugu;
    final done = order.status >= 3;
    final bannerColor = done ? _green : AppColors.primary;

    Widget row(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 15, color: Color(0xFF55606B)),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: kNavy,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with order number
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.chevron_left,
                      size: 30,
                      color: kNavy,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '#${order.orderNumber.trim().isNotEmpty ? order.orderNumber : order.id}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: kNavy,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Order details and actions
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  // Order status banner
                  Container(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                    decoration: BoxDecoration(
                      color: bannerColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${context.tr('orderWord')} · ${formatOrderDate(isTe, order.createdAt)}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            letterSpacing: 1.5,
                            color: Color(0xFFF6C9A0),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.tr(statusKey(order)),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr(done ? 'enjoyMeal' : 'weUpdate'),
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Order receipt
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEFE8DC)),
                    ),
                    child: Column(
                      children: [
                        // Delivery address or pickup information
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.isDelivery
                                  ? context.tr('delivery')
                                  : context.tr('pickup'),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF55606B),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                order.isDelivery
                                    ? (order.address ?? '')
                                    : context.tr('pickupSub'),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: kNavy,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const Divider(height: 24, color: Color(0xFFEFE8DC)),

                        // Ordered dishes and prices
                        if (order.lines.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'No item details available.',
                              style: TextStyle(color: Color(0xFF55606B)),
                            ),
                          )
                        else
                          for (final line in order.lines)
                            row(
                              '${isTe ? line.dish.nameTe : line.dish.name} · ${line.option.label} × ${line.qty}',
                              rupees(line.lineTotal),
                            ),

                        const Divider(height: 24, color: Color(0xFFEFE8DC)),

                        // Total paid
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.tr('paid'),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: kNavy,
                              ),
                            ),
                            Text(
                              rupees(order.total),
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: kNavy,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Order again button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => _reorder(context),
                      child: Text(
                        context.tr('orderAgain'),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Help button remains unchanged
                  SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kNavy,
                        side: const BorderSide(color: kNavy, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        showHelpSheet(context, isTe, order: order);
                      },
                      child: Text(
                        context.tr('getHelp'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
