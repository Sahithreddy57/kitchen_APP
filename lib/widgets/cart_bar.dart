import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_core.dart';
import '../providers/language_provider.dart';
import '../screens/cart_screen.dart';

/// "2 items · ₹1,450   View cart" above the bottom nav when the cart isn't empty.
/// With Hundi in the cart it also shows the small pre-order message.
class CartBar extends StatelessWidget {
  const CartBar({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    if (cart.totalItems == 0) return const SizedBox.shrink();

    final label = cart.totalItems == 1 ? context.tr('item') : context.tr('items');

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cart.hasPreOrderItem)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 2),
              child: Text(context.tr('preOrderNote'),
                  style: const TextStyle(
                      fontSize: 12, height: 1.3, color: Color(0xFF9A3412))),
            ),
          Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              mouseCursor: SystemMouseCursors.click,
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined,
                        color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                        '${cart.totalItems} $label  ·  ${rupees(cart.totalPrice)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text(context.tr('viewCart'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}