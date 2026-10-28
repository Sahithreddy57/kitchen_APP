import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'tap_cursor.dart';
import '../core/app_core.dart';
import '../models/dish.dart';
import '../providers/language_provider.dart';
import '../screens/product_detail_screen.dart';
import '../services/menu_api_service.dart';

/// Peach "Weekend Hundi" card at the bottom of the home list.
/// Shown ONLY when the hundi API returns at least one hundi with prices.
/// One hundi -> opens its page. Several (Mutton, Chicken, ...) -> choose first.
class WeekendHundiBanner extends StatefulWidget {
  const WeekendHundiBanner({super.key});

  @override
  State<WeekendHundiBanner> createState() => _WeekendHundiBannerState();
}

class _WeekendHundiBannerState extends State<WeekendHundiBanner> {
  late final Future<List<Dish>> _future = MenuApiService()
      .fetchWeekendHundis()
      .catchError((_) => <Dish>[]);

  void _openDish(Dish d) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => ProductDetailScreen(dish: d)));

  void _onTap(List<Dish> dishes) {
    if (dishes.length == 1) return _openDish(dishes.first);

    final isTe = context.read<LanguageProvider>().isTelugu;
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
              Text(AppStrings.get('pickHundi', isTe),
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark)),
              const SizedBox(height: 16),
              for (final d in dishes)
                TapCursor(
                  onTap: () {
                    Navigator.pop(sheet);
                    _openDish(d);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE6DFD3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isTe ? d.nameTe : d.name,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textDark)),
                              const SizedBox(height: 2),
                              Text(
                                  '${AppStrings.get('from', isTe)} ${rupees(d.startPrice)}',
                                  style: const TextStyle(
                                      fontSize: 13.5,
                                      color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Serves 5 to 10 · pre-order for your date" from the real sizes.
  String _subtitle(BuildContext context, List<Dish> dishes) {
    final nums = <int>[
      for (final d in dishes)
        for (final o in d.options)
          if (int.tryParse(RegExp(r'^\d+').firstMatch(o.label)?.group(0) ?? '') != null)
            int.parse(RegExp(r'^\d+').firstMatch(o.label)!.group(0)!),
    ];
    if (nums.isEmpty) return context.tr('weekendHundiSub');
    nums.sort();
    final lo = nums.first;
    final hi = nums.last;
    if (lo == hi) return context.tr('weekendHundiOne').replaceAll('{n}', '$lo');
    return context
        .tr('weekendHundiRange')
        .replaceAll('{min}', '$lo')
        .replaceAll('{max}', '$hi');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Dish>>(
      future: _future,
      builder: (context, snap) {
        final dishes = snap.data ?? const <Dish>[];
        if (dishes.isEmpty) return const SizedBox.shrink();

        return TapCursor(
          onTap: () => _onTap(dishes),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: BoxDecoration(
              color: const Color(0xFFFDE8DD),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr('weekendHundi'),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFB23A12))),
                      const SizedBox(height: 4),
                      Text(_subtitle(context, dishes),
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xFFB23A12))),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward, color: Color(0xFFB23A12)),
              ],
            ),
          ),
        );
      },
    );
  }
}