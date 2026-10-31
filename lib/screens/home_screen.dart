import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/tap_cursor.dart';
import '../core/app_core.dart';
import '../models/category.dart';
import '../models/dish.dart';
import '../providers/language_provider.dart';
import '../providers/orders_provider.dart';
import '../services/menu_api_service.dart';
import '../widgets/category_chips.dart';
import '../widgets/dish_card.dart';
import '../widgets/weekend_hundi_banner.dart';
import 'product_detail_screen.dart';
import 'track_order_screen.dart';
import '../services/kitchen_status_service.dart';


class HomeScreen extends StatefulWidget {
  final VoidCallback onSeeMenu;

  const HomeScreen({
    super.key,
    required this.onSeeMenu,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const _categories = [
    'curries',
    'fry',
    'biryani',
    'hundi',
    'specials',
  ];

  final _api = MenuApiService();
  final _kitchenStatusService = KitchenStatusService();
  KitchenStatus? _kitchenStatus;
bool _kitchenStatusLoading = true;
Timer? _kitchenStatusTimer;

  late Future<List<List<Dish>>> _future;

  String? _selectedCategory;
  List<MenuCategory> _cats = MenuCategory.standard;
  String _query = '';

 @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);
  _load();
  _startKitchenStatusPolling();
}

@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);
  _kitchenStatusTimer?.cancel();
  super.dispose();

}

  void _load() {
    _future = Future.wait([
      _api.fetchPopularDishes(),
      _api.fetchMenu(),
    ]);

    // Load categories from the API.
    // Keep the standard categories if the request fails.
    _api.fetchCategories().then((categories) {
      if (mounted) {
        setState(() => _cats = categories);
      }
    }).catchError((_) {});
  }
Future<void> _loadKitchenStatus() async {
  try {
    final status = await _kitchenStatusService.fetch();

    if (!mounted) return;

    setState(() {
      _kitchenStatus = status;
      _kitchenStatusLoading = false;
    });
  } catch (e) {
    debugPrint('Kitchen status error: $e');

    if (!mounted) return;

    // Keep the last successful status if a refresh fails.
    setState(() {
      _kitchenStatusLoading = false;
    });
  }
}

void _startKitchenStatusPolling() {
  _kitchenStatusTimer?.cancel();

  _loadKitchenStatus();

  _kitchenStatusTimer = Timer.periodic(
    const Duration(seconds: 45),
    (_) => _loadKitchenStatus(),
  );
}
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    _loadKitchenStatus();
  }
}

  List<Dish> _filter(List<Dish> all, bool isTe) {
    return all.where((dish) {
      final matchCategory = _selectedCategory == null ||
          dish.category == _selectedCategory;

      final query = _query.trim().toLowerCase();

      final matchQuery = query.isEmpty ||
          dish.name.toLowerCase().contains(query) ||
          dish.nameTe.toLowerCase().contains(query);

      return matchCategory && matchQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isTe = context.watch<LanguageProvider>().isTelugu;

    return Column(
      children: [
        _Header(
          onSearch: (value) {
            setState(() => _query = value);
          },
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _buildCategories(isTe),

const SizedBox(height: 8),

_buildRecentOrder(),

const SizedBox(height: 8),


              // Popular dishes heading
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('popular'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  TapCursor(
                    onTap: widget.onSeeMenu,
                    child: Text(
                      context.tr('seeMenu'),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Popular dishes from the API
              _buildPopular(isTe),

              const SizedBox(height: 6),

              // Existing Hundi banner
              const WeekendHundiBanner(),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildKitchenStatus(bool isTe) {
  if (_kitchenStatusLoading || _kitchenStatus == null) {
    return const SizedBox.shrink();
  }

  final status = _kitchenStatus!;

  final isAvailable = status.orderNowEnabled;
  final isPaused = status.status == 'PAUSED';

  final message = isAvailable
      ? (isTe
          ? 'వంటగది తెరిచి ఉంది. ఇప్పుడే ఆర్డర్ చేయండి!'
          : status.message)
      : isPaused
          ? (isTe
              ? status.resumesInMinutes != null
                  ? 'వంటగది తాత్కాలికంగా నిలిపివేయబడింది. సుమారు ${status.resumesInMinutes} నిమిషాల్లో తిరిగి ప్రారంభమవుతుంది.'
                  : 'వంటగది తాత్కాలికంగా నిలిపివేయబడింది. దయచేసి కొద్దిసేపటి తర్వాత ప్రయత్నించండి.'
              : status.displayMessage)
          : (isTe
              ? 'వంటగది ప్రస్తుతం మూసివేయబడింది. తదుపరి అందుబాటులో ఉన్న రోజు మరియు సమయానికి ముందస్తు ఆర్డర్ చేయండి.'
              : status.message);

  final backgroundColor = isAvailable
      ? const Color(0xFFE3F4E8)
      : isPaused
          ? const Color(0xFFFFF3D6)
          : const Color(0xFFFDE8DD);

  final borderColor = isAvailable
      ? const Color(0xFFB8E2C4)
      : isPaused
          ? const Color(0xFFF2D28A)
          : const Color(0xFFF3C6B2);

  final foregroundColor = isAvailable
      ? const Color(0xFF238447)
      : isPaused
          ? const Color(0xFF946200)
          : const Color(0xFF9A3412);

  final icon = isAvailable
      ? Icons.check_circle_outline
      : isPaused
          ? Icons.pause_circle_outline
          : Icons.access_time;

  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: borderColor),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: foregroundColor,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: foregroundColor,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildCategories(bool isTe) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CategoryChips(
        categories: _cats,
        showAll: false,
        selected: _selectedCategory,
        onSelected: (category) {
          setState(() => _selectedCategory = category);
        },
      ),
       const SizedBox(height: 10),

      _buildKitchenStatus(isTe),

    ],
  );
}
  

  /// Displays the most recent order belonging to the logged-in customer.
  ///
  /// OrdersProvider currently reads locally saved orders from SharedPreferences.
  /// It does not fetch order history from the backend.

Widget _buildRecentOrder() {
  return Consumer<OrdersProvider>(
    builder: (context, ordersProvider, _) {
      final orders = ordersProvider.orders;

      if (orders.isEmpty) {
        return const SizedBox.shrink();
      }

      final order = orders.first;

      // Compact item summary, similar to the second screenshot.
      final itemSummary = order.lines.map((line) {
        return '${line.dish.name} ${line.option.label} ×${line.qty}';
      }).join(', ');

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
  context.tr('trackYourRecentOrder'),
  style: const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  ),
),
          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFEFE8DC),
              ),
            ),
            child: Row(
              children: [
                // Order icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),

                // Order details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '#${order.orderNumber.trim().isNotEmpty ? order.orderNumber : order.id}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),

                      Text(
                        itemSummary.isNotEmpty
                            ? itemSummary
                            : order.whenText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        '${order.whenText} · ${rupees(order.total)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Track Order replaces Reorder
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TrackOrderScreen(
                          order: order,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(
                      color: AppColors.primary,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
  context.tr('trackOrder'),
  style: const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
  ),
),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

  /// Loading, error, empty and data states for the menu API.
  Widget _buildPopular(bool isTe) {
    return FutureBuilder<List<List<Dish>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Column(
            children: [
              const SizedBox(height: 24),
              Text(context.tr('error')),
              TextButton(
                onPressed: () {
                  setState(_load);
                },
                child: Text(context.tr('retry')),
              ),
            ],
          );
        }

        final data = snapshot.data;

        // Browse the full menu when a category or search query is selected.
        final browsing = _selectedCategory != null ||
            _query.trim().isNotEmpty;

        final base = data == null
            ? <Dish>[]
            : (browsing ? data[1] : data[0]);

        final dishes = _filter(base, isTe);

        if (dishes.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(context.tr('noResults')),
            ),
          );
        }

        return Column(
          children: [
            for (final dish in dishes)
              DishCard(
                dish: dish,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(
                        dish: dish,
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final ValueChanged<String> onSearch;

  const _Header({
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 12,
        16,
        20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo with fallback if the asset is missing.
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      width: 52,
                      height: 52,
                      color: Colors.white,
                      child: const Icon(
                        Icons.restaurant,
                        color: AppColors.primary,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('welcome'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      context.tr('craving'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Language toggle
              TapCursor(
                onTap: lang.toggle,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    lang.isTelugu ? 'English' : 'తెలుగు',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Search menu
          TextField(
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: context.tr('search'),
              hintStyle: const TextStyle(
                color: AppColors.textMuted,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textDark,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
