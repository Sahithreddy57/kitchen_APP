
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/tap_cursor.dart';
import '../core/app_core.dart';
import '../models/dish.dart';
import '../providers/language_provider.dart';
import '../widgets/checkout_widgets.dart';
import '../widgets/dish_photo.dart';
import '../services/variant_api_service.dart';

const _navy = Color(0xFF2D3E50);

class ProductDetailScreen extends StatefulWidget {
  final Dish dish;

  const ProductDetailScreen({
    super.key,
    required this.dish,
  });

  @override
  State<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _optionIndex = 0;
  int _qty = 1;

  late List<DishOption> _options;
  bool _variantsLoading = true;
  String? _variantsError;

  Dish get _dish => widget.dish;

  bool get _isHundi =>
      _dish.category.trim().toLowerCase() == 'hundi' ||
      _dish.categoryName.trim().toLowerCase() == 'hundi';

  bool get _productPreOrderOnly =>
      _dish.preOrderOnly || _isHundi;

  bool get _hasSelectedOption =>
      _options.isNotEmpty &&
      _optionIndex >= 0 &&
      _optionIndex < _options.length;

  DishOption get _option => _options[_optionIndex];

  bool _requiresPreOrder(DishOption option) =>
      _productPreOrderOnly || option.preOrderOnly;

  int get _total =>
      _hasSelectedOption ? _option.price * _qty : 0;

  @override
  void initState() {
    super.initState();

    // Show any options already provided by the products API while
    // the product-specific variants request is running.
    _options = List<DishOption>.from(widget.dish.options);

    _loadVariants();
  }

  Future<void> _loadVariants() async {
    try {
      final variants = await VariantApiService().fetchVariants(
        widget.dish.id,
      );

      if (!mounted) return;

      setState(() {
        _options = variants;
        _optionIndex = 0;
        _variantsLoading = false;
        _variantsError = variants.isEmpty
            ? 'No active, available variants were returned for this product.'
            : null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _variantsLoading = false;

        // Keep any options supplied by the products API if the
        // variants endpoint is temporarily unavailable.
        _variantsError = _options.isEmpty ? e.toString() : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTe = context.watch<LanguageProvider>().isTelugu;
    final d = _dish;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImage(d),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      16,
                      20,
                      24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context
                              .trCategory(d.category, d.categoryName)
                              .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            letterSpacing: 1.2,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isTe ? d.nameTe : d.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: _navy,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isTe ? d.descriptionTe : d.description,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.4,
                            color: Color(0xFF55606B),
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (_productPreOrderOnly ||
                            (_hasSelectedOption &&
                                _option.preOrderOnly))
                          PreOrderNote(
                            text: context.tr('preOrderOnlyInfo'),
                            showIcon: false,
                          ),

                        const SizedBox(height: 8),
                        Text(
                          context.tr(
                            _productPreOrderOnly
                                ? 'howManyPeople'
                                : 'chooseQty',
                          ),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: _navy,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildOptions(),
                        const SizedBox(height: 24),
                        _buildQtyRow(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildImage(Dish d) {
    return SizedBox(
      height: 290,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DishPhoto(
            url: d.imageUrl,
            label: 'photo · ${d.name}',
            width: double.infinity,
            height: 290,
            labelSize: 12,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topLeft,
                child: TapCursor(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_left,
                      size: 28,
                      color: _navy,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    if (_variantsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_options.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _variantsError ?? 'No variants available.',
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadVariants,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      );
    }

    final opts = _options;
    final cols = opts.length > 2 ? 2 : opts.length;

    Widget card(int i) {
      final option = opts[i];
      final selected = i == _optionIndex;
      final preOrder = _requiresPreOrder(option);

      return TapCursor(
        onTap: () => setState(() => _optionIndex = i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? _navy : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? _navy : const Color(0xFFE6DFD3),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                option.label,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : _navy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                rupees(option.price),
                style: TextStyle(
                  fontSize: 15,
                  color: selected
                      ? Colors.white
                      : const Color(0xFF55606B),
                ),
              ),
              if (preOrder) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE7DB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Pre-order only',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF9A3412),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final rows = <Widget>[];

    for (int i = 0; i < opts.length; i += cols) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              for (int j = 0; j < cols; j++) ...[
                if (j > 0) const SizedBox(width: 12),
                Expanded(
                  child: i + j < opts.length
                      ? card(i + j)
                      : const SizedBox(),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildQtyRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('quantity'),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _navy,
              ),
            ),
            Text(
              context
                  .tr('maxPerItemN')
                  .replaceAll('{n}', '${_dish.maxPerItem}'),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFE6DFD3),
            ),
          ),
          child: Row(
            children: [
              _stepBtn(
                Icons.remove,
                _qty > 1,
                () => setState(() => _qty--),
              ),
              SizedBox(
                width: 44,
                child: Center(
                  child: Text(
                    '$_qty',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _navy,
                    ),
                  ),
                ),
              ),
              _stepBtn(
                Icons.add,
                _qty < _dish.maxPerItem,
                () => setState(() => _qty++),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepBtn(
    IconData icon,
    bool enabled,
    VoidCallback onTap,
  ) {
    return TapCursor(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: enabled ? _navy : const Color(0xFFF1ECE3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: enabled
              ? Colors.white
              : const Color(0xFFC9C3B8),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final canAdd = !_variantsLoading && _hasSelectedOption;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFEFE8DC)),
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr('total'),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                rupees(_total),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _navy,
                ),
              ),
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
                  disabledBackgroundColor: Colors.grey.shade400,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: !canAdd
                    ? null
                    : () {
                        context.read<CartProvider>().add(
                              _dish,
                              _option,
                              _qty,
                            );
                        Navigator.pop(context);
                      },
                child: Text(
                  _variantsLoading
                      ? 'Loading sizes...'
                      : context.tr('addToCart'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
