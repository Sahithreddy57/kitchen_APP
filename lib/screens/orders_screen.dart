
import 'package:flutter/material.dart';
import '../widgets/tap_cursor.dart';
import 'package:provider/provider.dart';
import '../core/app_core.dart';
import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../providers/orders_provider.dart';
import '../widgets/checkout_widgets.dart';
import 'order_actions.dart';
import '../core/app_nav.dart';
import '../widgets/empty_state.dart';
import 'login_screen.dart';
import 'order_details_screen.dart';
import 'track_order_screen.dart';

const _green = Color(0xFF2E7D4F);
const _cancelRed = Color(0xFFD94B36);

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  bool _isPastOrder(Order order) {
    final status = order.normalizedStatus;

    return order.status >= 3 ||
        const {
          'CANCELLED',
          'PAYMENT_FAILED',
          'PAYMENT_EXPIRED',
        }.contains(status);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final loggedIn = auth.isLoggedIn;

    final orders = loggedIn
        ? context.watch<OrdersProvider>().forPhone(auth.phone)
        : <Order>[];

    final ongoing = orders.where((o) => !_isPastOrder(o)).toList();
    final past = orders.where(_isPastOrder).toList();

    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 12),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              letterSpacing: 1.4,
              color: AppColors.textMuted,
            ),
          ),
        );

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 14),
            child: Text(
              context.tr('orders'),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: kNavy,
              ),
            ),
          ),
          Expanded(
            child: orders.isEmpty
                ? _EmptyOrders(loggedIn: loggedIn)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      if (ongoing.isNotEmpty) ...[
                        label(context.tr('ongoing')),
                        for (final order in ongoing)
                          _OrderCard(order: order),
                      ],
                      if (past.isNotEmpty) ...[
                        label(context.tr('past')),
                        for (final order in past)
                          _OrderCard(order: order),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final isTe = context.watch<LanguageProvider>().isTelugu;
    final status = order.normalizedStatus;

    final isCancelled = status == 'CANCELLED';

    final isPaymentFailed = const {
      'PAYMENT_FAILED',
      'PAYMENT_EXPIRED',
    }.contains(status);

    final done = order.status >= 3;
    final isTerminal = done || isCancelled || isPaymentFailed;

    final String statusText;

    if (isCancelled) {
      statusText = isTe ? 'రద్దు చేయబడింది' : 'Cancelled';
    } else if (isPaymentFailed) {
      statusText = isTe ? 'చెల్లింపు విఫలమైంది' : 'Payment failed';
    } else if (done) {
      statusText =
          '${context.tr('statusDone')} · ${formatOrderDate(isTe, order.createdAt)}';
    } else {
      statusText = context.tr(statusKey(order));
    }

    final items = order.lines
        .map(
          (line) =>
              '${isTe ? line.dish.nameTe : line.dish.name} ${line.option.label} ×${line.qty}',
        )
        .join(', ');

    final statusColor = isCancelled || isPaymentFailed
        ? _cancelRed
        : done
            ? _green
            : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEFE8DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '#${order.orderNumber.trim().isNotEmpty ? order.orderNumber : order.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: kNavy,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  statusText,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            items,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.35,
              color: Color(0xFF55606B),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                rupees(order.total),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: kNavy,
                ),
              ),
              const Spacer(),
              _Btn(
                label: context.tr('details'),
                filled: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderDetailsScreen(order: order),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (isTerminal)
                _Btn(
                  label: context.tr('reorder'),
                  onTap: () => reorder(context, order),
                )
              else
                _Btn(
                  label: context.tr('trackOrder'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrackOrderScreen(order: order),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _Btn({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return TapCursor(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: filled ? const Color(0xFFF1ECE3) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: filled ? null : Border.all(color: kNavy, width: 1.2),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: kNavy,
          ),
        ),
      ),
    );
  }
}

/// Guests see Log in; logged-in users see Explore menu.
class _EmptyOrders extends StatelessWidget {
  final bool loggedIn;

  const _EmptyOrders({required this.loggedIn});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.receipt_long_outlined,
      title: context.tr('noOrders'),
      subtitle: context.tr(loggedIn ? 'noOrdersSub' : 'noOrdersLogin'),
      buttonLabel: context.tr(loggedIn ? 'exploreMenu' : 'logIn'),
      onButton: loggedIn
          ? () => mainTab.value = 1
          : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
              ),
    );
  }
}
