import 'package:flutter/material.dart';
import '../widgets/tap_cursor.dart';

import '../core/app_core.dart';
import '../models/category.dart';
import '../models/dish.dart';

import '../services/menu_api_service.dart';
import '../widgets/category_chips.dart';
import '../widgets/dish_card.dart';
import 'product_detail_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _api = MenuApiService();
  late Future<List<Dish>> _future;
  String? _selectedCategory; // null = All
  List<MenuCategory> _cats = MenuCategory.standard; // replaced by the API's list
  String _query = '';
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _api.fetchMenu();
    _api.fetchCategories().then((c) {
      if (mounted) setState(() => _cats = c);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.tr('menu'),
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark)),
                TapCursor(
                  onTap: () => setState(() {
                    _showSearch = !_showSearch;
                    if (!_showSearch) _query = '';
                  }),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE6DFD3)),
                    ),
                    child: Icon(_showSearch ? Icons.close : Icons.search,
                        color: AppColors.textDark),
                  ),
                ),
              ],
            ),
          ),
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: context.tr('search'),
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          CategoryChips(
            categories: _cats,
            selected: _selectedCategory,
            onSelected: (c) => setState(() => _selectedCategory = c),
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          const SizedBox(height: 14),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    return FutureBuilder<List<Dish>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snap.hasError) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(context.tr('error')),
              TextButton(
                  onPressed: () => setState(_load),
                  child: Text(context.tr('retry'))),
            ]),
          );
        }

        final q = _query.trim().toLowerCase();
        final dishes = (snap.data ?? []).where((d) {
          final matchCat =
              _selectedCategory == null || d.category == _selectedCategory;
          final matchQ = q.isEmpty ||
              d.name.toLowerCase().contains(q) ||
              d.nameTe.contains(q);
          return matchCat && matchQ;
        }).toList();

        if (dishes.isEmpty) {
          return Center(child: Text(context.tr('noResults')));
        }

        // Group by category (in chip order) with a small section label.
        final children = <Widget>[];

        void addGroup(String label, List<Dish> group) {
          if (group.isEmpty) return;
          children.add(Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 10),
            child: Text(label.toUpperCase(),
                style: const TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.4,
                    color: AppColors.textMuted)),
          ));
          for (final d in group) {
            children.add(DishCard(
              dish: d,
              showDescription: true,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(dish: d)),
              ),
            ));
          }
          children.add(const SizedBox(height: 8));
        }

        // categories from the API (or the 5 standard ones), in chip order
        for (final c in _cats) {
          addGroup(context.trCategory(c.key, c.name),
              dishes.where((d) => d.category == c.key).toList());
        }
        // dishes whose category isn't in the list above
        final known = _cats.map((c) => c.key).toSet();
        final extra = <String, String>{
          for (final d in dishes)
            if (!known.contains(d.category)) d.category: d.categoryName,
        };
        extra.forEach((key, name) {
          addGroup(context.trCategory(key, name),
              dishes.where((d) => d.category == key).toList());
        });

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: children,
        );
      },
    );
  }
}