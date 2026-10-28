import 'package:flutter/material.dart';
import '../core/app_core.dart';
import '../models/category.dart';
import 'tap_cursor.dart';

/// Horizontally scrolling chips: [All +] the categories.
/// selected == null means "All". Categories come from the API
/// (MenuCategory.standard is used until they load).
class CategoryChips extends StatefulWidget {
  final List<MenuCategory> categories;
  final String? selected; // category key, e.g. "curries"
  final ValueChanged<String?> onSelected;
  final EdgeInsets padding;
  final bool showAll; // Menu: true. Home: false.

  const CategoryChips({
    super.key,
    required this.selected,
    required this.onSelected,
    this.categories = MenuCategory.standard,
    this.padding = EdgeInsets.zero,
    this.showAll = true,
  });

  @override
  State<CategoryChips> createState() => _CategoryChipsState();
}

class _CategoryChipsState extends State<CategoryChips> {
  final List<GlobalKey> _chipKeys = [];

  @override
  Widget build(BuildContext context) {
    // (key, label) for every chip
    final items = <MapEntry<String, String>>[
      if (widget.showAll) MapEntry('all', context.tr('all')),
      for (final c in widget.categories)
        MapEntry(c.key, context.trCategory(c.key, c.name)),
    ];
    while (_chipKeys.length < items.length) {
      _chipKeys.add(GlobalKey());
    }

    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: widget.padding,
        physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics()),
        child: Row(
          children: [
            for (int i = 0; i < items.length; i++)
              Padding(
                key: _chipKeys[i],
                padding: EdgeInsets.only(right: i == items.length - 1 ? 0 : 10),
                child: TapCursor(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    String? value = items[i].key == 'all' ? null : items[i].key;
                    // without an "All" chip, tapping the active chip clears it
                    if (!widget.showAll && widget.selected == value) value = null;
                    widget.onSelected(value);
                    final ctx = _chipKeys[i].currentContext;
                    if (ctx != null) {
                      Scrollable.ensureVisible(ctx,
                          alignment: 0.5,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut);
                    }
                  },
                  child: Builder(builder: (context) {
                    final selected = items[i].key == 'all'
                        ? widget.selected == null
                        : widget.selected == items[i].key;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : const Color(0xFFE6DFD3)),
                      ),
                      child: Text(
                        items[i].value,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : AppColors.textDark,
                        ),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}