import 'package:flutter/material.dart';
import '../core/app_core.dart';
import '../models/order.dart';
import '../widgets/checkout_widgets.dart';
import 'track_order_screen.dart';

const _green = Color(0xFF2E7D4F);

class OrderConfirmedScreen extends StatelessWidget {
  final Order order;
  const OrderConfirmedScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final firstName = order.customerName.trim().split(' ').first;

    Widget row(String l, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l,
                  style: const TextStyle(
                      fontSize: 15, color: Color(0xFF55606B))),
              Flexible(
                child: Text(v,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: kNavy)),
              ),
            ],
          ),
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 36, 22, 24),
          children: [
            Center(
              child: Container(
                width: 124,
                height: 124,
                decoration: const BoxDecoration(
                    color: Color(0xFFDDEDE2), shape: BoxShape.circle),
                child: Center(
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: const BoxDecoration(
                        color: _green, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded,
                        size: 58, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(context.tr('orderConfirmed'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12,
                    letterSpacing: 2,
                    color: _green,
                    fontFamily: 'monospace')),
            const SizedBox(height: 8),
            Text(
                context
                    .tr('thankYouName')
                    .replaceAll('{name}', firstName),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 30, fontWeight: FontWeight.w800, color: kNavy)),
            const SizedBox(height: 8),
            Text(context.tr('kitchenHasOrder'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16, color: Color(0xFF55606B))),
            const SizedBox(height: 26),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFEFE8DC)),
              ),
              child: Column(
                children: [
                  row(
  context.tr('orderLabel'),
  order.orderNumber.isNotEmpty
      ? order.orderNumber
      : order.id,
),
                  row(
                      order.isDelivery
                          ? context.tr('delivery')
                          : context.tr('pickup'),
                      order.whenText),
                  const Divider(height: 22, color: Color(0xFFEFE8DC)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(context.tr('paid'),
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: kNavy)),
                      Text(rupees(order.total),
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: kNavy)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 58,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => TrackOrderScreen(order: order)),
                ),
                child: Text(context.tr('trackOrder'),
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 58,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: kNavy,
                  side: const BorderSide(color: kNavy, width: 1.2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                child: Text(context.tr('backHome'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}