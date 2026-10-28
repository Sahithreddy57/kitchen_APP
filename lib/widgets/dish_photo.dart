import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/app_core.dart';

/// Shows a dish photo from EITHER:
///  - a hosted link (cached on the phone):  'https://.../chicken_curry.jpg'
///  - a file in your project:               'assets/images/dishes/chicken_curry.jpg'
/// Hosted photos are downloaded once and then loaded from the phone's cache,
/// so repeat visits are instant and use no data.
/// If the image is missing, loading or fails, the beige box shows.
class DishPhoto extends StatelessWidget {
  final String? url;
  final String label; // text shown on the beige box
  final double? width;
  final double? height;
  final double labelSize;

  const DishPhoto({
    super.key,
    required this.url,
    required this.label,
    this.width,
    this.height,
    this.labelSize = 9,
  });

  Widget _placeholder() => Container(
        width: width,
        height: height,
        alignment: Alignment.bottomLeft,
        padding: const EdgeInsets.all(6),
        color: AppColors.placeholder,
        child: Text(label.toLowerCase(),
            style: TextStyle(fontSize: labelSize, color: AppColors.textMuted)),
      );

  @override
  Widget build(BuildContext context) {
    final u = url;
    if (u == null || u.trim().isEmpty) return _placeholder();

    if (u.startsWith('assets/')) {
      return Image.asset(
        u,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    // Decode at the size we actually show (saves memory + speeds up lists).
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final w = width;
    final cacheW = (w != null && w.isFinite) ? (w * dpr).round() : 1000;

    return CachedNetworkImage(
      imageUrl: u,
      width: width,
      height: height,
      fit: BoxFit.cover,
      memCacheWidth: cacheW,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (_, __) => _placeholder(),
      errorWidget: (_, __, ___) => _placeholder(),
    );
  }
}