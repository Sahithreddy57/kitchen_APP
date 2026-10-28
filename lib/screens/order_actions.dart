import 'package:flutter/material.dart';
import '../widgets/tap_cursor.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_config.dart';
import '../core/app_core.dart';
import '../widgets/checkout_widgets.dart';
import '../models/order.dart';
import '../providers/language_provider.dart';
import 'checkout_screen.dart';

/// "5 Oct"
String formatOrderDate(bool isTe, DateTime d) =>
    '${d.day} ${AppStrings.get('months', isTe).split(',')[d.month - 1]}';

/// Status text key for an order.
String statusKey(Order o) {
  switch (o.status) {
    case 0:
      return 'statusConfirmed';
    case 1:
      return 'statusPreparing';
    case 2:
      return o.isDelivery ? 'statusOnWay' : 'statusReady';
    default:
      return 'statusDone';
  }
}

/// Puts the same items (same sizes + quantities) in the cart and
/// opens Checkout - the normal checkout process from there.
void reorder(BuildContext context, Order order) {
  final cart = context.read<CartProvider>();
  cart.clear();
  for (final l in order.lines) {
    cart.add(l.dish, l.option, l.qty);
  }
  Navigator.push(
      context, MaterialPageRoute(builder: (_) => const CheckoutScreen()));
}

Future<bool> _open(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('launchUrl failed for $uri: $e'); // see the Run/Debug console
    return false;
  }
}

Future<void> callKitchen(BuildContext context, bool isTe) async {
  final ok = await _open(Uri(scheme: 'tel', path: kKitchenPhone));
  if (!ok && context.mounted) _fail(context, isTe);
}

Future<void> whatsappKitchen(BuildContext context, bool isTe, [Order? order]) async {
  final msg = order == null
      ? 'Hi DRK Kitchen, I need some help.'
      : 'Hi DRK Kitchen, I need help with order #${order.id}.';
  final text = Uri.encodeComponent(msg);
  // 1) normal WhatsApp link, 2) direct app link as a fallback
  var ok = await _open(Uri.parse('https://wa.me/$kKitchenWhatsApp?text=$text'));
  if (!ok) {
    ok = await _open(
        Uri.parse('whatsapp://send?phone=$kKitchenWhatsApp&text=$text'));
  }
  if (!ok && context.mounted) _fail(context, isTe);
}

void _fail(BuildContext context, bool isTe) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
        SnackBar(content: Text(AppStrings.get('couldNotOpen', isTe))));
}

/// "How can we help?" sheet with Call + WhatsApp. Pass [order] to mention it.
void showHelpSheet(BuildContext context, bool isTe, {Order? order}) {
  String t(String k) => AppStrings.get(k, isTe);

  Widget tile(IconData icon, String text, VoidCallback onTap) => TapCursor(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorder),
          ),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                  color: Color(0xFFFDEEE6), shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: kNavy)),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ]),
        ),
      );

  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t('helpTitle'),
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: kNavy)),
            if (order != null) ...[
              const SizedBox(height: 4),
              Text(
  '#${order.orderNumber.trim().isNotEmpty ? order.orderNumber : order.id}',
  style: const TextStyle(
    fontFamily: 'monospace',
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: kNavy,
  ),
),
            ],
            const SizedBox(height: 18),
            tile(Icons.call, t('callKitchen'), () {
              Navigator.pop(sheet);
              callKitchen(context, isTe);
            }),
            tile(Icons.chat, t('chatWhatsapp'), () {
              Navigator.pop(sheet);
              whatsappKitchen(context, isTe, order);
            }),
          ],
        ),
      ),
    ),
  );
}