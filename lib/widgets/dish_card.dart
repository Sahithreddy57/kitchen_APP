import 'package:flutter/material.dart';
import 'tap_cursor.dart';
import 'package:provider/provider.dart';
import '../core/app_core.dart';
import '../models/dish.dart';
import '../providers/language_provider.dart';
import 'dish_photo.dart';

class DishCard extends StatelessWidget {
  final Dish dish;
  final VoidCallback onTap; // opens the product detail page
  final bool showDescription; // Menu page shows description instead of category
  const DishCard({
    super.key,
    required this.dish,
    required this.onTap,
    this.showDescription = false,
  });

  @override
  Widget build(BuildContext context) {
    final isTe = context.watch<LanguageProvider>().isTelugu;

    return TapCursor(
      onTap: dish.hasPrice ? onTap : null, // no price from backend yet -> not orderable
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEFE8DC)),
        ),
        child: Row(
          children: [
            DishImage(url: dish.imageUrl, label: dish.name, size: 84),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isTe ? dish.nameTe : dish.name,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text(
                      showDescription
                          ? (isTe ? dish.descriptionTe : dish.description)
                          : context.trCategory(dish.category, dish.categoryName),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(
                      dish.hasPrice
                          ? '${context.tr('from')} ${rupees(dish.startPrice)}'
                          : context.tr('priceSoon'),
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: dish.hasPrice
                              ? AppColors.textDark
                              : AppColors.textMuted)),
                ],
              ),
            ),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: dish.hasPrice
                    ? AppColors.primary
                    : const Color(0xFFD9D2C5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dish photo (asset or link) with the beige placeholder as fallback.
class DishImage extends StatelessWidget {
  final String? url;
  final String label;
  final double size;
  const DishImage(
      {super.key, required this.url, required this.label, required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: DishPhoto(url: url, label: label, width: size, height: size),
    );
  }
}