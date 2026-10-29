
// class DishOption {
//   final String label;
//   final int price;
//   final String id;
//   final bool preOrderOnly;
//   final String orderType;

//   const DishOption(
//     this.label,
//     this.price, {
//     this.id = '',
//     this.preOrderOnly = false,
//     this.orderType = 'instock',
//   });

//   factory DishOption.fromJson(Map<String, dynamic> j) {
//     final orderType = (j['order_type'] ??
//             j['orderType'] ??
//             'instock')
//         .toString()
//         .trim()
//         .toLowerCase();

//     final requiresPreorder = orderType == 'preorder' ||
//         j['pre_order_only'] == true ||
//         j['preOrderOnly'] == true ||
//         j['requires_preorder'] == true;

//     return DishOption(
//       (j['variant_name'] ?? j['label'] ?? '').toString(),
//       (j['price'] as num?)?.toInt() ?? 0,
//       id: (j['_id'] ?? j['id'] ?? '').toString(),
//       orderType: requiresPreorder ? 'preorder' : orderType,
//       preOrderOnly: requiresPreorder,
//     );
//   }

//   Map<String, dynamic> toJson() => {
//         'id': id,
//         'label': label,
//         'price': price,
//         'order_type': orderType,
//         'pre_order_only': preOrderOnly,
//       };
// }

// class Dish {
//   final String id;
//   final String name;
//   final String nameTe;
//   final String description;
//   final String descriptionTe;
//   final String category;
//   final String categoryName;
//   final List<DishOption> options;
//   final String? imageUrl;
//   final bool preOrderOnly;
//   final int maxPerItem;

//   const Dish({
//     required this.id,
//     required this.name,
//     required this.nameTe,
//     this.description = '',
//     this.descriptionTe = '',
//     required this.category,
//     this.categoryName = '',
//     required this.options,
//     this.imageUrl,
//     this.preOrderOnly = false,
//     this.maxPerItem = 10,
//   });

//   int get startPrice {
//     if (options.isEmpty) return 0;

//     return options
//         .map((option) => option.price)
//         .reduce((a, b) => a < b ? a : b);
//   }

//   bool get hasPrice => options.isNotEmpty;

//   /// Hundi products must always be preorder-only.
//   bool get isHundi =>
//       category.trim().toLowerCase() == 'hundi' ||
//       categoryName.trim().toLowerCase() == 'hundi';

//   /// True when the product itself requires preorder.
//   bool get requiresPreOrder => preOrderOnly || isHundi;

//   factory Dish.fromJson(Map<String, dynamic> j) {
//     final cat = j['category'] ?? j['category_id'];

//     final catName = cat is Map
//         ? (cat['name'] ?? '').toString()
//         : (cat ?? '').toString();

//     final normalizedCategory = catName.trim().toLowerCase();
//     final name = (j['name'] ?? '').toString();

//     final productRequiresPreorder =
//         j['pre_order_only'] == true ||
//         j['preOrderOnly'] == true ||
//         j['requires_preorder'] == true ||
//         normalizedCategory == 'hundi';

//     final rawOptions = j['options'] as List? ?? const [];

//     return Dish(
//       id: (j['id'] ?? j['_id'] ?? '').toString(),
//       name: name,
//       nameTe: (j['name_te'] ?? name).toString(),
//       description: (j['description'] ?? '').toString(),
//       descriptionTe:
//           (j['description_te'] ?? j['description'] ?? '').toString(),
//       category: normalizedCategory,
//       categoryName: catName.trim(),
//       imageUrl: j['image_url']?.toString(),
//       preOrderOnly: productRequiresPreorder,
//       maxPerItem: (j['max_per_item'] as num?)?.toInt() ?? 10,
//       options: [
//         for (final option in rawOptions)
//           if (option is Map)
//             DishOption.fromJson(
//               Map<String, dynamic>.from(option),
//             ),
//       ],
//     );
//   }

//   Map<String, dynamic> toJson() => {
//         'id': id,
//         'name': name,
//         'name_te': nameTe,
//         'description': description,
//         'description_te': descriptionTe,
//         'category': category,
//         'image_url': imageUrl,
//         'pre_order_only': preOrderOnly,
//         'max_per_item': maxPerItem,
//         'options': options.map((option) => option.toJson()).toList(),
//       };
// }

class DishOption {
  final String label;
  final int price;

  /// For Hundi, this must be the actual package MongoDB _id.
  /// For normal products, this is the variant MongoDB _id.
  final String id;

  final bool preOrderOnly;
  final String orderType;

  const DishOption(
    this.label,
    this.price, {
    this.id = '',
    this.preOrderOnly = false,
    this.orderType = 'instock',
  });

  factory DishOption.fromJson(Map<String, dynamic> j) {
    final orderType = (j['order_type'] ??
            j['orderType'] ??
            'instock')
        .toString()
        .trim()
        .toLowerCase();

    final requiresPreorder = orderType == 'preorder' ||
        j['pre_order_only'] == true ||
        j['preOrderOnly'] == true ||
        j['requires_preorder'] == true;

    return DishOption(
      (j['variant_name'] ?? j['label'] ?? '').toString(),
      (j['price'] as num?)?.toInt() ?? 0,
      id: (j['_id'] ?? j['id'] ?? '').toString(),
      orderType: requiresPreorder ? 'preorder' : orderType,
      preOrderOnly: requiresPreorder,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'price': price,
        'order_type': orderType,
        'pre_order_only': preOrderOnly,
      };
}

class Dish {
  final String id;
  final String name;
  final String nameTe;
  final String description;
  final String descriptionTe;
  final String category;
  final String categoryName;
  final List<DishOption> options;
  final String? imageUrl;
  final bool preOrderOnly;
  final int maxPerItem;

  /// Supported values:
  /// product, HUNDI, WEEKLY_HUNDI
  ///
  /// Normal products default to product.
  final String itemType;

  const Dish({
    required this.id,
    required this.name,
    required this.nameTe,
    this.description = '',
    this.descriptionTe = '',
    required this.category,
    this.categoryName = '',
    required this.options,
    this.imageUrl,
    this.preOrderOnly = false,
    this.maxPerItem = 10,
    this.itemType = 'product',
  });

  int get startPrice {
    if (options.isEmpty) return 0;

    return options
        .map((option) => option.price)
        .reduce((a, b) => a < b ? a : b);
  }

  bool get hasPrice => options.isNotEmpty;

  bool get isHundi {
    final type = itemType.trim().toUpperCase();

    return type == 'HUNDI' ||
        type == 'WEEKLY_HUNDI' ||
        category.trim().toLowerCase() == 'hundi' ||
        categoryName.trim().toLowerCase() == 'hundi';
  }

  /// Determines the item type sent to the order API.
  ///
  /// The menu API should explicitly set itemType for Weekly Hundi.
  /// The name fallback supports existing menu data whose name includes
  /// "Weekly Hundi".
  String get orderItemType {
    final type = itemType.trim().toUpperCase();

    if (type == 'WEEKLY_HUNDI') {
      return 'WEEKLY_HUNDI';
    }

    if (type == 'HUNDI') {
      return 'HUNDI';
    }

    if (isHundi) {
      return name.toLowerCase().contains('weekly')
          ? 'WEEKLY_HUNDI'
          : 'HUNDI';
    }

    return 'PRODUCT';
  }

  /// Hundi always requires preorder.
  bool get requiresPreOrder => preOrderOnly || isHundi;

  factory Dish.fromJson(Map<String, dynamic> j) {
    final cat = j['category'] ?? j['category_id'];

    final catName = cat is Map
        ? (cat['name'] ?? '').toString()
        : (cat ?? '').toString();

    final normalizedCategory = catName.trim().toLowerCase();
    final name = (j['name'] ?? '').toString();

    final rawItemType =
        (j['item_type'] ?? j['itemType'] ?? 'product')
            .toString()
            .trim()
            .toUpperCase();

    final productRequiresPreorder =
        j['pre_order_only'] == true ||
        j['preOrderOnly'] == true ||
        j['requires_preorder'] == true ||
        normalizedCategory == 'hundi' ||
        rawItemType == 'HUNDI' ||
        rawItemType == 'WEEKLY_HUNDI';

    final rawOptions = j['options'] as List? ?? const [];

    return Dish(
      id: (j['id'] ?? j['_id'] ?? '').toString(),
      name: name,
      nameTe: (j['name_te'] ?? name).toString(),
      description: (j['description'] ?? '').toString(),
      descriptionTe:
          (j['description_te'] ?? j['description'] ?? '').toString(),
      category: normalizedCategory,
      categoryName: catName.trim(),
      imageUrl: j['image_url']?.toString(),
      preOrderOnly: productRequiresPreorder,
      maxPerItem: (j['max_per_item'] as num?)?.toInt() ?? 10,
      itemType: rawItemType,
      options: [
        for (final option in rawOptions)
          if (option is Map)
            DishOption.fromJson(
              Map<String, dynamic>.from(option),
            ),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'name_te': nameTe,
        'description': description,
        'description_te': descriptionTe,
        'category': category,
        'image_url': imageUrl,
        'pre_order_only': preOrderOnly,
        'max_per_item': maxPerItem,
        'item_type': itemType,
        'options': options.map((option) => option.toJson()).toList(),
      };
}

