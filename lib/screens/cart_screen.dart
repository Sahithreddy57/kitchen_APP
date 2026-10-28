import 'package:flutter/material.dart';
import '../widgets/tap_cursor.dart';
import 'package:provider/provider.dart';
import '../core/app_core.dart';
import '../providers/language_provider.dart';
import '../widgets/dish_card.dart';
import '../widgets/checkout_widgets.dart';
import '../core/app_nav.dart';
import '../widgets/empty_state.dart';
import 'checkout_screen.dart';

const _navy = Color(0xFF2D3E50);

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final isTe = context.watch<LanguageProvider>().isTelugu;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Title row
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 20, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.chevron_left, size: 30, color: _navy),
                  ),
                  Text(context.tr('myCart'),
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _navy)),
                ],
              ),
            ),
            Expanded(
              child: cart.items.isEmpty
                  ? EmptyState(
                      icon: Icons.shopping_bag_outlined,
                      title: context.tr('emptyCart'),
                      subtitle: context.tr('emptyCartSub'),
                      buttonLabel: context.tr('exploreMenu'),
                      onButton: () {
                        // close the cart and open the Menu tab
                        Navigator.popUntil(context, (r) => r.isFirst);
                        mainTab.value = 1;
                      },
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      children: [
                        if (cart.hasPreOrderItem)

                          PreOrderNote(text: context.tr('preOrderNote')),

                        for (final item in cart.items)
                          _CartItemCard(item: item, isTe: isTe),
                        const SizedBox(height: 4),
                        _AddMore(),
                        const SizedBox(height: 22),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(context.tr('subtotal'),
                                  style: const TextStyle(
                                      fontSize: 17, color: Color(0xFF55606B))),
                              Text(rupees(cart.totalPrice),
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: _navy)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(context.tr('packingNote'),
                              style: const TextStyle(
                                  fontSize: 12.5, color: AppColors.textMuted)),
                        ),
                      ],
                    ),
            ),
            if (cart.items.isNotEmpty) _CheckoutBar(total: cart.totalPrice),
          ],
        ),
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final bool isTe;
  const _CartItemCard({required this.item, required this.isTe});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFE8DC)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DishImage(url: item.dish.imageUrl, label: item.dish.name, size: 72),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(isTe ? item.dish.nameTe : item.dish.name,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _navy)),
                    ),
                    Text(rupees(item.lineTotal),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _navy)),
                  ],
                ),
                const SizedBox(height: 2),
                Text('${item.option.label} · ${rupees(item.option.price)}',
                    style: const TextStyle(
                        fontSize: 13.5, color: Color(0xFF55606B))),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _btn(Icons.remove, true, () => cart.decrement(item)),
                      SizedBox(
                        width: 36,
                        child: Center(
                          child: Text('${item.qty}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      _btn(Icons.add, item.qty < item.dish.maxPerItem,
                          () => cart.increment(item)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, bool enabled, VoidCallback onTap) => InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon,
              size: 18, color: enabled ? _navy : const Color(0xFFC9C3B8)),
        ),
      );
}

/// Dashed "+ Add more items" button -> back to the menu/home.
class _AddMore extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TapCursor(
      onTap: () => Navigator.pop(context),
      child: CustomPaint(
        painter: _DashedBorderPainter(),
        child: Container(
          height: 54,
          alignment: Alignment.center,
          child: Text(context.tr('addMore'),
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: _navy)),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCFC7B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, const Radius.circular(14)));
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _CheckoutBar extends StatelessWidget {
  final int total;
  const _CheckoutBar({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEFE8DC))),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.tr('subtotal'),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
              Text(rupees(total),
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800, color: _navy)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                ),
                child: Text(context.tr('checkout'),
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}