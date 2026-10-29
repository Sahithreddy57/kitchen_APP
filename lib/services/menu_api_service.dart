
// import 'package:flutter/foundation.dart';
// import '../core/api_config.dart';
// import '../core/checkout_strings.dart';
// import '../models/category.dart';
// import '../models/dish.dart';
// import 'api_client.dart';

// class MenuApiService {
//   // remember the last answers for 30 s so Home doesn't call the API twice
//   static List<Dish>? _cache;
//   static DateTime? _cacheAt;
//   static List<MenuCategory>? _catCache;
//   static DateTime? _catCacheAt;
//   static List<Dish>? _hundiCache;
//   static DateTime? _hundiCacheAt;

//   static bool _fresh(DateTime? at) =>
//       at != null && DateTime.now().difference(at) < const Duration(seconds: 30);

//   /// Home "Popular this week".
//   Future<List<Dish>> fetchPopularDishes() async {
//     if (kUseMockMenu) return _mockPopular();
//     final all = await _fetchProducts();
//     // TODO: the backend has no "popular" flag yet -> first 6 by display order.
//     return all.take(6).toList();
//   }

//   /// Full menu: all products + the hundi packages (so the Hundi chip has dishes).
//   Future<List<Dish>> fetchMenu() =>
//       kUseMockMenu ? _mockMenu() : _fetchMenuWithHundi();

//  Future<List<Dish>> fetchWeekendHundis() async {
//   if (kUseMockMenu) {
//     final products = await _mockMenu();

//     return products
//         .where((dish) => dish.isHundi && dish.hasPrice)
//         .toList();
//   }

//   final products = await _fetchProducts();

//   return products
//       .where((dish) => dish.isHundi && dish.hasPrice)
//       .toList();
// }
//   /// Category chips. Falls back to the 5 standard ones if the API fails.
//   Future<List<MenuCategory>> fetchCategories() async {
//     if (kUseMockMenu) return MenuCategory.standard;
//     final cached = _catCache;
//     if (cached != null && _fresh(_catCacheAt)) return cached;

//     final body = await ApiClient.getJson(kCategoriesPath,
//         query: {'status': 'active', 'page': '1', 'limit': '100'},
//         logBody: true);
//     final list = ApiClient.listFrom(body['data'], ['categories', 'items', 'list']);

//     final ordered = <MapEntry<int, MenuCategory>>[];
//     for (final c in list) {
//       if (c is! Map) continue;
//       final m = Map<String, dynamic>.from(c);
//       if (m['status'] != null && m['status'] != 'active') continue;
//       final name = (m['name'] ?? '').toString().trim();
//       if (name.isEmpty) continue;
//       ordered.add(MapEntry(
//         (m['display_order'] as num?)?.toInt() ?? 9999,
//         MenuCategory(
//           id: (m['_id'] ?? m['id'] ?? '').toString(),
//           key: name.toLowerCase(),
//           name: name,
//         ),
//       ));
//     }
//     ordered.sort((a, b) => a.key.compareTo(b.key));
//     // Chip order is FIXED: Curries, Fry, Biryani, Hundi, Specials.
//     // All five always exist (Hundi has its own API, so it isn't in the category
//     // list). Any other category the kitchen creates in the admin panel comes
//     // after these five, in the API's display order.
//     final fromApi = {for (final e in ordered) e.value.key: e.value};
//     final result = <MenuCategory>[
//       for (final std in MenuCategory.standard) fromApi[std.key] ?? std,
//       for (final e in ordered)
//         if (!MenuCategory.standard.any((x) => x.key == e.value.key)) e.value,
//     ];
//     _catCache = result;
//     _catCacheAt = DateTime.now();
//     return result;
//   }

//   // ---------------- WEEKEND HUNDI ----------------
//   // The hundi API returns one row per SIZE:
//   //   { name: "MuttonHundi", member_count: 10, price: 500, status, display_order }
//   // Rows with the same name are the sizes of ONE hundi ("5 people", "10 people").

//   /// "Mutton Curry" -> "muttoncurry" (how dish text is looked up in checkout_strings.dart)
//   String _slug(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

//   String? _teName(String name) => checkoutStrings['dish_${_slug(name)}']?['te'];
//   String? _teDesc(String name) => checkoutStrings['dishdesc_${_slug(name)}']?['te'];

//   /// "MuttonHundi" -> "Mutton Hundi"
//   String _prettyName(String n) => n
//       .replaceAll('_', ' ')
//       .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
//       .trim();

//   /// Every weekend hundi (pre-order only). Empty list = none available.
//   Future<List<Dish>> fetchWeekendHundis() async {
//     if (kUseMockMenu) {
//       final all = await fetchMenu();
//       return all.where((d) => d.preOrderOnly && d.hasPrice).toList();
//     }

//     final hc = _hundiCache;
//     if (hc != null && _fresh(_hundiCacheAt)) return hc;

//     final body = await ApiClient.getJson(kHundiPath, logBody: true);
//     final list = ApiClient.listFrom(body['data'], ['hundi', 'hundis', 'items', 'products']);

//     // group the size rows by hundi name
//     final groups = <String, List<Map<String, dynamic>>>{};
//     for (final e in list) {
//       if (e is! Map) continue;
//       final m = Map<String, dynamic>.from(e);
//       if (m['status'] != null && m['status'] != 'active') continue;
//       if (m['availability'] == false) continue;
//       final name = (m['name'] ?? '').toString().trim();
//       if (name.isEmpty) continue;
//       groups.putIfAbsent(name, () => []).add(m);
//     }

//     int people(Map<String, dynamic> m) {
//       final v = m['member_count'] ?? m['members'] ?? m['people'] ?? m['serves'];
//       return v is num ? v.toInt() : (int.tryParse('$v') ?? 0);
//     }

//     final dishes = <MapEntry<int, Dish>>[];
//     num orderOf(Map<String, dynamic> m) => (m['display_order'] as num?) ?? 9999;

//     groups.forEach((name, rows) {
//       // smallest group first; for the same people count the lower display_order wins
//       rows.sort((a, b) {
//         final c = people(a).compareTo(people(b));
//         return c != 0 ? c : orderOf(a).compareTo(orderOf(b));
//       });
//       final options = <DishOption>[];
//       final seenCounts = <int>{};
//       for (final r in rows) {
//         final n = people(r);
//         if (!seenCounts.add(n)) continue; // two active rows with the same people count
//         final raw = r['price'];
//         final price = raw is num ? raw : num.tryParse('$raw');
//         if (n <= 0 || price == null) continue;
        
// final packageId = (r['_id'] ?? r['id'] ?? '').toString();

// if (packageId.isEmpty) {
//   debugPrint('Skipping Hundi package without MongoDB ID: $name');
//   continue;
// }

// options.add(
//   DishOption(
//     '$n people',
//     price.toInt(),
//     id: packageId,
//     preOrderOnly: true,
//     orderType: 'preorder',
//   ),
// );

//       }
//       if (options.isEmpty) return;

//       final order = rows
//           .map((r) => (r['display_order'] as num?)?.toInt() ?? 9999)
//           .reduce((a, b) => a < b ? a : b);
//       final pretty = _prettyName(name);
      
// final rawType = (rows.first['item_type'] ??
//         rows.first['itemType'] ??
//         rows.first['hundi_type'] ??
//         rows.first['type'] ??
//         '')
//     .toString()
//     .trim()
//     .toUpperCase();

// final itemType = rawType == 'WEEKLY_HUNDI' ||
//         rawType == 'WEEKLY'
//     ? 'WEEKLY_HUNDI'
//     : 'HUNDI';


//       // each size row has its own image; use the first one that has a photo
//       String? image;
//       for (final r in rows) {
//         final u = r['image_url'] ?? r['image'];
//         if (u != null && '$u'.trim().isNotEmpty) {
//           image = ApiClient.absoluteUrl(u);
//           break;
//         }
//       }
//       dishes.add(MapEntry(
//         order,
//         Dish(
//           id: 'hundi-${name.toLowerCase()}',
//           itemType: itemType,
//           name: pretty,
//           nameTe: _teName(pretty) ?? pretty, // TODO: backend should send name_te
//           description: checkoutStrings['dishdesc_hundi']!['en']!,
//           descriptionTe: checkoutStrings['dishdesc_hundi']!['te']!,
//           category: 'hundi',
//           categoryName: 'Hundi',
//           imageUrl: image,
//           preOrderOnly: true, // cooked to order: tomorrow or later
//           options: options,
//         ),
//       ));
//     });
//     dishes.sort((a, b) => a.key.compareTo(b.key));
//     final result = dishes.map((e) => e.value).toList();
//     _hundiCache = result;
//     _hundiCacheAt = DateTime.now();
//     return result;
//   }

//   // ---------------- REAL BACKEND: products + variants ----------------

//   /// "500g" -> "0.5 KG", "1000g" -> "1 KG", "5" -> "5 people".
//   /// Any other name (e.g. "Half plate") is shown exactly as the kitchen wrote it.
//   String _variantLabel(Map e) {
//     final name = (e['variant_name'] ?? e['label'] ?? e['name'] ?? e['title'] ??
//             e['size'] ?? e['people'] ?? e['persons'] ?? e['serves'] ?? '')
//         .toString()
//         .trim();
//     if (name.isEmpty) return '';
//     if (RegExp(r'^\d+$').hasMatch(name)) return '$name people';

//     final w = RegExp(r'^(\d+(?:\.\d+)?)\s*(kgs?|kilos?|gms?|grams?|g)$',
//             caseSensitive: false)
//         .firstMatch(name);
//     if (w != null) {
//       final n = double.parse(w.group(1)!);
//       final grams = w.group(2)!.toLowerCase().startsWith('k') ? n * 1000 : n;
//       final kg = grams / 1000;
//       final txt = kg == kg.roundToDouble() ? '${kg.toInt()}' : '$kg';
//       return '$txt KG';
//     }
//     return name;
//   }

//   /// Turns a list of variants / options into [{id, label, price}], cheapest
//   /// size first. Skips inactive, unavailable and other products' variants.
//   List<Map<String, dynamic>> _optionMaps(List v, {String? productId}) {
//     final rows = <MapEntry<num, Map<String, dynamic>>>[];
//     for (final e in v) {
//       if (e is! Map) continue;
//       // a variant that belongs to a different product is not ours
//       final owner = e['product_id'];
//       if (productId != null && owner != null && owner.toString() != productId) {
//         continue;
//       }
//       if (e['status'] != null && e['status'] != 'active') continue;
//       if (e['availability'] == false) continue;

//       final label = _variantLabel(e);
//       final rawPrice = e['price'] ?? e['amount'] ?? e['cost'];
//       final price = rawPrice is num ? rawPrice : num.tryParse('$rawPrice');
//       if (label.isEmpty || price == null) continue;

//       final sortBy = e['quantity_value'] is num ? e['quantity_value'] as num : price;
//       rows.add(MapEntry(sortBy, {
//         'id': (e['_id'] ?? e['id'] ?? '').toString(),
//         'label': label,
//         'price': price,
//         'pre_order_only': e['pre_order_only'] == true ||
//             e['preOrderOnly'] == true ||
//             e['requires_preorder'] == true,
//       }));
//     }
//     rows.sort((a, b) => a.key.compareTo(b.key));
//     return rows.map((r) => r.value).toList();
//   }

//   /// Sizes/prices already INSIDE the product (if the backend ever embeds them).
//   List<Map<String, dynamic>> _optionsFrom(Map<String, dynamic> m) {
//     for (final k in const [
//       'options', 'variants', 'sizes', 'people_options', 'servings', 'pricing', 'prices'
//     ]) {
//       final v = m[k];
//       if (v is! List || v.isEmpty) continue;
//       final out = _optionMaps(v, productId: m['_id']?.toString());
//       if (out.isNotEmpty) return out;
//     }
//     return const [];
//   }

//   /// GET /api/admin/products/{id}/variants
//   Future<List<Map<String, dynamic>>> _fetchVariants(String productId) async {
//     final body = await ApiClient.getJson('$kProductsPath/$productId/variants');
//     final list = ApiClient.listFrom(body['data'], ['variants', 'items']);
//     return _optionMaps(list, productId: productId);
//   }

//   Future<List<Dish>> _fetchProducts() async {
//     final c = _cache;
//     if (c != null && _fresh(_cacheAt)) return c;

//     // 1) all active products (paged)
//     final rows = <Map<String, dynamic>>[];
//     var page = 1;
//     var fetched = 0;
//     var total = 0;
//     do {
//       // ASSUMPTION: the API accepts ?page= and ?limit= (it returns page + limit).
//       final body = await ApiClient.getJson(kProductsPath, query: {
//         'status': 'active', // the server hides inactive products
//         'page': '$page',
//         'limit': '100',
//       });
//       final data = body['data'] as Map<String, dynamic>;
//       final list = (data['products'] as List?) ?? const [];
//       total = (data['total'] as num?)?.toInt() ?? list.length;
//       fetched += list.length;

//       for (final p in list) {
//         final m = Map<String, dynamic>.from(p as Map);
//         if (m['status'] != null && m['status'] != 'active') continue;
//         if (m['availability'] == false) continue; // sold out / hidden
//         m['image_url'] = ApiClient.absoluteUrl(m['image_url']);

//         // Telugu: the API's name_te / description_te win; otherwise the
//         // temporary text in core/checkout_strings.dart (matched by dish name)
//         final nm = (m['name'] ?? '').toString();
//         if ('${m['name_te'] ?? ''}'.trim().isEmpty) {
//           final t = _teName(nm);
//           if (t != null) m['name_te'] = t;
//         }
//         if ('${m['description_te'] ?? ''}'.trim().isEmpty) {
//           final t = _teDesc(nm);
//           if (t != null) m['description_te'] = t;
//         }
//         rows.add(m);
//       }
//       if (list.isEmpty) break;
//       page++;
//     } while (fetched < total);

//     // 2) sizes + prices: use them if the product already has them, otherwise
//     //    ask /products/{id}/variants (8 at a time).
//     final needVariants = <Map<String, dynamic>>[];
//     for (final m in rows) {
//       final inline = _optionsFrom(m);
//       m['options'] = inline;
//       if (inline.isEmpty && m['_id'] != null) needVariants.add(m);
//     }
//     const batch = 8;
//     for (var i = 0; i < needVariants.length; i += batch) {
//       final slice = needVariants.skip(i).take(batch).toList();
//       await Future.wait(slice.map((m) async {
//         try {
//           m['options'] = await _fetchVariants(m['_id'].toString());
//         } catch (e) {
//           // one product failing must not break the whole menu
//           debugPrint('Variants failed for ${m['name']}: $e');
//         }
//       }));
//     }

//     // 3) build dishes in display order
//     final ordered = <MapEntry<int, Dish>>[
//       for (final m in rows)
//         MapEntry((m['display_order'] as num?)?.toInt() ?? 9999, Dish.fromJson(m)),
//     ];
//     ordered.sort((a, b) => a.key.compareTo(b.key));
//     final dishes = ordered.map((e) => e.value).toList();
//     _cache = dishes;
//     _cacheAt = DateTime.now();
//     return dishes;
//   }

//   // ---------------- SAMPLE MENU (kUseMockMenu = true) ----------------
//   Future<List<Dish>> _mockPopular() async {
//     // --- REAL API (uncomment when backend is ready) ---
//     // final res = await http.get(Uri.parse('https://your-api.com/dishes/popular'));
//     // if (res.statusCode != 200) throw Exception('Failed: ${res.statusCode}');
//     // final List data = jsonDecode(res.body);
//     // return data.map((e) => Dish.fromJson(e)).toList();

//     // --- MOCK DATA ---
//     await Future.delayed(const Duration(milliseconds: 800));
//     return const [
//       Dish(
//         id: '1', name: 'Chicken Curry', nameTe: 'చికెన్ కర్రీ', category: 'curries',
//         description: 'Home-style chicken curry cooked in a rich onion and spice gravy.',
//         descriptionTe: 'ఉల్లిపాయ, మసాలాలతో ఇంటి రుచిలో వండిన చికెన్ కర్రీ.',
//         options: [
//           DishOption('0.5 KG', 450),
//           DishOption('1 KG', 850),
//           DishOption('1.5 KG', 1250),
//           DishOption('2 KG', 1650),
//           DishOption('5 KG', 4000, preOrderOnly: true),
//           DishOption('10 KG', 7800, preOrderOnly: true),
//         ],
//       ),
//       Dish(
//         id: '2', name: 'Mutton Fry', nameTe: 'మటన్ ఫ్రై', category: 'fry',
//         description: 'Pan-roasted mutton with black pepper and coconut.',
//         descriptionTe: 'మిరియాలు, కొబ్బరితో వేయించిన మటన్ ఫ్రై.',
//         options: [DishOption('0.5 KG', 700), DishOption('1 KG', 1350)],
//       ),
//       Dish(
//         id: '3', name: 'Chicken Dum Biryani', nameTe: 'చికెన్ దమ్ బిర్యానీ', category: 'biryani',
//         description: 'Slow-cooked dum biryani with tender chicken and aged basmati.',
//         descriptionTe: 'మెత్తని చికెన్, బాస్మతీ బియ్యంతో దమ్‌లో వండిన బిర్యానీ.',
//         options: [DishOption('0.5 KG', 750), DishOption('1 KG', 1400)],
//       ),
//       Dish(
//         id: '4', name: 'Chicken Hundi', nameTe: 'చికెన్ హండి', category: 'hundi',
//         description: 'Pot-sealed dum feast for the family.',
//         descriptionTe: 'కుటుంబం కోసం కుండలో సీల్ చేసి దమ్‌లో వండిన విందు.',
//         preOrderOnly: true, // cooked to order: tomorrow or later
//         options: [
//           DishOption('5 people', 1800),
//           DishOption('10 people', 3400),
//           DishOption('15 people', 4900),
//           DishOption('25 people', 7900),
//         ],
//       ),
//       // Specials
//       Dish(
//         id: '5', name: 'Natu Kodi Pulusu', nameTe: 'నాటుకోడి పులుసు', category: 'specials',
//         description: 'Country chicken stew in a tangy, spicy tamarind gravy.',
//         descriptionTe: 'పుల్లని, కారమైన చింతపండు గ్రేవీలో నాటుకోడి పులుసు.',
//         options: [DishOption('0.5 KG', 900), DishOption('1 KG', 1700)],
//       ),
//       Dish(
//         id: '6', name: 'Mutton Dum Biryani', nameTe: 'మటన్ దమ్ బిర్యానీ', category: 'specials',
//         description: 'Juicy mutton layered with basmati and sealed for dum cooking.',
//         descriptionTe: 'బాస్మతీతో పొరలుగా వండిన రసవంతమైన మటన్ దమ్ బిర్యానీ.',
//         options: [DishOption('0.5 KG', 950), DishOption('1 KG', 1800)],
//       ),
//       Dish(
//         id: '7', name: 'Prawns Masala', nameTe: 'రొయ్యల మసాలా', category: 'specials',
//         description: 'Fresh prawns tossed in a thick, spicy masala.',
//         descriptionTe: 'చిక్కని, కారమైన మసాలాలో వండిన తాజా రొయ్యలు.',
//         options: [DishOption('0.5 KG', 850), DishOption('1 KG', 1600)],
//       ),
//       Dish(
//         id: '8', name: 'Paya Soup', nameTe: 'పాయా సూప్', category: 'specials',
//         description: 'Slow-simmered trotter soup, warm and full of flavour.',
//         descriptionTe: 'గంటల తరబడి ఉడికించిన రుచికరమైన పాయా సూప్.',
//         options: [DishOption('0.5 L', 350), DishOption('1 L', 650)],
//       ),
//     ];
//   }

//   Future<List<Dish>> _mockMenu() async {
//     // --- REAL API: http.get('https://your-api.com/menu') -> List<Dish> ---
//     final popular = await _mockPopular();
//     const more = [
//       Dish(
//         id: '9', name: 'Fish Pulusu', nameTe: 'చేపల పులుసు', category: 'specials',
//         description: 'Murrel fish simmered in tangy tamarind gravy.',
//         descriptionTe: 'పుల్లని చింతపండు గ్రేవీలో ఉడికించిన కొరమీను చేప.',
//         options: [DishOption('0.5 KG', 550), DishOption('1 KG', 1050)],
//       ),
//       Dish(
//         id: '10', name: 'Mutton Curry', nameTe: 'మటన్ కర్రీ', category: 'curries',
//         description: 'Tender mutton in a thick, spicy home-style gravy.',
//         descriptionTe: 'చిక్కని, కారమైన ఇంటి గ్రేవీలో మెత్తని మటన్.',
//         options: [DishOption('0.5 KG', 650), DishOption('1 KG', 1250)],
//       ),
//       Dish(
//         id: '11', name: 'Chicken Fry', nameTe: 'చికెన్ ఫ్రై', category: 'fry',
//         description: 'Crispy dry-fried chicken tossed with curry leaves.',
//         descriptionTe: 'కరివేపాకుతో కరకరలాడే చికెన్ ఫ్రై.',
//         options: [DishOption('0.5 KG', 400), DishOption('1 KG', 760)],
//       ),
//       Dish(
//         id: '12', name: 'Mutton Dum Biryani', nameTe: 'మటన్ దమ్ బిర్యానీ', category: 'biryani',
//         description: 'Juicy mutton layered with basmati, dum cooked.',
//         descriptionTe: 'బాస్మతీతో దమ్‌లో వండిన రసవంతమైన మటన్ బిర్యానీ.',
//         options: [DishOption('0.5 KG', 950), DishOption('1 KG', 1800)],
//       ),
//     ];
//     return [...popular, ...more];
//   }
// }


import 'package:flutter/foundation.dart';
import '../core/api_config.dart';
import '../core/checkout_strings.dart';
import '../models/category.dart';
import '../models/dish.dart';
import 'api_client.dart';

class MenuApiService {
  // remember the last answers for 30 s so Home doesn't call the API twice
  static List<Dish>? _cache;
  static DateTime? _cacheAt;
  static List<MenuCategory>? _catCache;
  static DateTime? _catCacheAt;

  static bool _fresh(DateTime? at) =>
      at != null && DateTime.now().difference(at) < const Duration(seconds: 30);

  /// Home "Popular this week".
  Future<List<Dish>> fetchPopularDishes() async {
    if (kUseMockMenu) return _mockPopular();
    final all = await _fetchProducts();
    // TODO: the backend has no "popular" flag yet -> first 6 by display order.
    return all.take(6).toList();
  }

  /// Full menu: use only the Products API. Hundi-category products are included.
  Future<List<Dish>> fetchMenu() =>
      kUseMockMenu ? _mockMenu() : _fetchProducts();

  /// Weekend Hundi uses the same product records as the regular Hundi category.
  /// No request is made to /api/admin/hundi/active.
  Future<List<Dish>> fetchWeekendHundis() async {
    final products = kUseMockMenu ? await _mockMenu() : await _fetchProducts();
    return products.where((dish) => dish.isHundi && dish.hasPrice).toList();
  }

  /// Category chips. Falls back to the 5 standard ones if the API fails.
  Future<List<MenuCategory>> fetchCategories() async {
    if (kUseMockMenu) return MenuCategory.standard;
    final cached = _catCache;
    if (cached != null && _fresh(_catCacheAt)) return cached;

    final body = await ApiClient.getJson(kCategoriesPath,
        query: {'status': 'active', 'page': '1', 'limit': '100'},
        logBody: true);
    final list = ApiClient.listFrom(body['data'], ['categories', 'items', 'list']);

    final ordered = <MapEntry<int, MenuCategory>>[];
    for (final c in list) {
      if (c is! Map) continue;
      final m = Map<String, dynamic>.from(c);
      if (m['status'] != null && m['status'] != 'active') continue;
      final name = (m['name'] ?? '').toString().trim();
      if (name.isEmpty) continue;
      ordered.add(MapEntry(
        (m['display_order'] as num?)?.toInt() ?? 9999,
        MenuCategory(
          id: (m['_id'] ?? m['id'] ?? '').toString(),
          key: name.toLowerCase(),
          name: name,
        ),
      ));
    }
    ordered.sort((a, b) => a.key.compareTo(b.key));
    // Keep the five standard category chips. Hundi products themselves are
    // loaded from the Products API, just like every other product.
    final fromApi = {for (final e in ordered) e.value.key: e.value};
    final result = <MenuCategory>[
      for (final std in MenuCategory.standard) fromApi[std.key] ?? std,
      for (final e in ordered)
        if (!MenuCategory.standard.any((x) => x.key == e.value.key)) e.value,
    ];
    _catCache = result;
    _catCacheAt = DateTime.now();
    return result;
  }

  // ---------------- PRODUCT TEXT HELPERS ----------------

  /// "Mutton Curry" -> "muttoncurry" (lookup key in checkout_strings.dart).
  String _slug(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  String? _teName(String name) => checkoutStrings['dish_${_slug(name)}']?['te'];
  String? _teDesc(String name) => checkoutStrings['dishdesc_${_slug(name)}']?['te'];

  // ---------------- REAL BACKEND: products + variants ----------------

  /// "500g" -> "0.5 KG", "1000g" -> "1 KG", "5" -> "5 people".
  /// Any other name (e.g. "Half plate") is shown exactly as the kitchen wrote it.
  String _variantLabel(Map e) {
    final name = (e['variant_name'] ?? e['label'] ?? e['name'] ?? e['title'] ??
            e['size'] ?? e['people'] ?? e['persons'] ?? e['serves'] ?? '')
        .toString()
        .trim();
    if (name.isEmpty) return '';
    if (RegExp(r'^\d+$').hasMatch(name)) return '$name people';

    final w = RegExp(r'^(\d+(?:\.\d+)?)\s*(kgs?|kilos?|gms?|grams?|g)$',
            caseSensitive: false)
        .firstMatch(name);
    if (w != null) {
      final n = double.parse(w.group(1)!);
      final grams = w.group(2)!.toLowerCase().startsWith('k') ? n * 1000 : n;
      final kg = grams / 1000;
      final txt = kg == kg.roundToDouble() ? '${kg.toInt()}' : '$kg';
      return '$txt KG';
    }
    return name;
  }

  /// Turns a list of variants / options into [{id, label, price}], cheapest
  /// size first. Skips inactive, unavailable and other products' variants.
  List<Map<String, dynamic>> _optionMaps(List v, {String? productId}) {
    final rows = <MapEntry<num, Map<String, dynamic>>>[];
    for (final e in v) {
      if (e is! Map) continue;
      // a variant that belongs to a different product is not ours
      final owner = e['product_id'];
      if (productId != null && owner != null && owner.toString() != productId) {
        continue;
      }
      if (e['status'] != null && e['status'] != 'active') continue;
      if (e['availability'] == false) continue;

      final label = _variantLabel(e);
      final rawPrice = e['price'] ?? e['amount'] ?? e['cost'];
      final price = rawPrice is num ? rawPrice : num.tryParse('$rawPrice');
      if (label.isEmpty || price == null) continue;

      final sortBy = e['quantity_value'] is num ? e['quantity_value'] as num : price;
      rows.add(MapEntry(sortBy, {
        'id': (e['_id'] ?? e['id'] ?? '').toString(),
        'label': label,
        'price': price,
        'pre_order_only': e['pre_order_only'] == true ||
            e['preOrderOnly'] == true ||
            e['requires_preorder'] == true,
      }));
    }
    rows.sort((a, b) => a.key.compareTo(b.key));
    return rows.map((r) => r.value).toList();
  }

  /// Sizes/prices already INSIDE the product (if the backend ever embeds them).
  List<Map<String, dynamic>> _optionsFrom(Map<String, dynamic> m) {
    for (final k in const [
      'options', 'variants', 'sizes', 'people_options', 'servings', 'pricing', 'prices'
    ]) {
      final v = m[k];
      if (v is! List || v.isEmpty) continue;
      final out = _optionMaps(v, productId: m['_id']?.toString());
      if (out.isNotEmpty) return out;
    }
    return const [];
  }

  /// GET /api/admin/products/{id}/variants
  Future<List<Map<String, dynamic>>> _fetchVariants(String productId) async {
    final body = await ApiClient.getJson('$kProductsPath/$productId/variants');
    final list = ApiClient.listFrom(body['data'], ['variants', 'items']);
    return _optionMaps(list, productId: productId);
  }

  Future<List<Dish>> _fetchProducts() async {
    final c = _cache;
    if (c != null && _fresh(_cacheAt)) return c;

    // 1) all active products (paged)
    final rows = <Map<String, dynamic>>[];
    var page = 1;
    var fetched = 0;
    var total = 0;
    do {
      // ASSUMPTION: the API accepts ?page= and ?limit= (it returns page + limit).
      final body = await ApiClient.getJson(kProductsPath, query: {
        'status': 'active', // the server hides inactive products
        'page': '$page',
        'limit': '100',
      });
      final data = body['data'] as Map<String, dynamic>;
      final list = (data['products'] as List?) ?? const [];
      total = (data['total'] as num?)?.toInt() ?? list.length;
      fetched += list.length;

      for (final p in list) {
        final m = Map<String, dynamic>.from(p as Map);
        if (m['status'] != null && m['status'] != 'active') continue;
        if (m['availability'] == false) continue; // sold out / hidden
        m['image_url'] = ApiClient.absoluteUrl(m['image_url']);

        // Telugu: the API's name_te / description_te win; otherwise the
        // temporary text in core/checkout_strings.dart (matched by dish name)
        final nm = (m['name'] ?? '').toString();
        if ('${m['name_te'] ?? ''}'.trim().isEmpty) {
          final t = _teName(nm);
          if (t != null) m['name_te'] = t;
        }
        if ('${m['description_te'] ?? ''}'.trim().isEmpty) {
          final t = _teDesc(nm);
          if (t != null) m['description_te'] = t;
        }
        rows.add(m);
      }
      if (list.isEmpty) break;
      page++;
    } while (fetched < total);

    // 2) sizes + prices: use them if the product already has them, otherwise
    //    ask /products/{id}/variants (8 at a time).
    final needVariants = <Map<String, dynamic>>[];
    for (final m in rows) {
      final inline = _optionsFrom(m);
      m['options'] = inline;
      if (inline.isEmpty && m['_id'] != null) needVariants.add(m);
    }
    const batch = 8;
    for (var i = 0; i < needVariants.length; i += batch) {
      final slice = needVariants.skip(i).take(batch).toList();
      await Future.wait(slice.map((m) async {
        try {
          m['options'] = await _fetchVariants(m['_id'].toString());
        } catch (e) {
          // one product failing must not break the whole menu
          debugPrint('Variants failed for ${m['name']}: $e');
        }
      }));
    }

    // 3) build dishes in display order
    final ordered = <MapEntry<int, Dish>>[
      for (final m in rows)
        MapEntry((m['display_order'] as num?)?.toInt() ?? 9999, Dish.fromJson(m)),
    ];
    ordered.sort((a, b) => a.key.compareTo(b.key));
    final dishes = ordered.map((e) => e.value).toList();
    _cache = dishes;
    _cacheAt = DateTime.now();
    return dishes;
  }

  // ---------------- SAMPLE MENU (kUseMockMenu = true) ----------------
  Future<List<Dish>> _mockPopular() async {
    // --- REAL API (uncomment when backend is ready) ---
    // final res = await http.get(Uri.parse('https://your-api.com/dishes/popular'));
    // if (res.statusCode != 200) throw Exception('Failed: ${res.statusCode}');
    // final List data = jsonDecode(res.body);
    // return data.map((e) => Dish.fromJson(e)).toList();

    // --- MOCK DATA ---
    await Future.delayed(const Duration(milliseconds: 800));
    return const [
      Dish(
        id: '1', name: 'Chicken Curry', nameTe: 'చికెన్ కర్రీ', category: 'curries',
        description: 'Home-style chicken curry cooked in a rich onion and spice gravy.',
        descriptionTe: 'ఉల్లిపాయ, మసాలాలతో ఇంటి రుచిలో వండిన చికెన్ కర్రీ.',
        options: [
          DishOption('0.5 KG', 450),
          DishOption('1 KG', 850),
          DishOption('1.5 KG', 1250),
          DishOption('2 KG', 1650),
          DishOption('5 KG', 4000, preOrderOnly: true),
          DishOption('10 KG', 7800, preOrderOnly: true),
        ],
      ),
      Dish(
        id: '2', name: 'Mutton Fry', nameTe: 'మటన్ ఫ్రై', category: 'fry',
        description: 'Pan-roasted mutton with black pepper and coconut.',
        descriptionTe: 'మిరియాలు, కొబ్బరితో వేయించిన మటన్ ఫ్రై.',
        options: [DishOption('0.5 KG', 700), DishOption('1 KG', 1350)],
      ),
      Dish(
        id: '3', name: 'Chicken Dum Biryani', nameTe: 'చికెన్ దమ్ బిర్యానీ', category: 'biryani',
        description: 'Slow-cooked dum biryani with tender chicken and aged basmati.',
        descriptionTe: 'మెత్తని చికెన్, బాస్మతీ బియ్యంతో దమ్‌లో వండిన బిర్యానీ.',
        options: [DishOption('0.5 KG', 750), DishOption('1 KG', 1400)],
      ),
      Dish(
        id: '4', name: 'Chicken Hundi', nameTe: 'చికెన్ హండి', category: 'hundi',
        description: 'Pot-sealed dum feast for the family.',
        descriptionTe: 'కుటుంబం కోసం కుండలో సీల్ చేసి దమ్‌లో వండిన విందు.',
        preOrderOnly: true, // cooked to order: tomorrow or later
        options: [
          DishOption('5 people', 1800),
          DishOption('10 people', 3400),
          DishOption('15 people', 4900),
          DishOption('25 people', 7900),
        ],
      ),
      // Specials
      Dish(
        id: '5', name: 'Natu Kodi Pulusu', nameTe: 'నాటుకోడి పులుసు', category: 'specials',
        description: 'Country chicken stew in a tangy, spicy tamarind gravy.',
        descriptionTe: 'పుల్లని, కారమైన చింతపండు గ్రేవీలో నాటుకోడి పులుసు.',
        options: [DishOption('0.5 KG', 900), DishOption('1 KG', 1700)],
      ),
      Dish(
        id: '6', name: 'Mutton Dum Biryani', nameTe: 'మటన్ దమ్ బిర్యానీ', category: 'specials',
        description: 'Juicy mutton layered with basmati and sealed for dum cooking.',
        descriptionTe: 'బాస్మతీతో పొరలుగా వండిన రసవంతమైన మటన్ దమ్ బిర్యానీ.',
        options: [DishOption('0.5 KG', 950), DishOption('1 KG', 1800)],
      ),
      Dish(
        id: '7', name: 'Prawns Masala', nameTe: 'రొయ్యల మసాలా', category: 'specials',
        description: 'Fresh prawns tossed in a thick, spicy masala.',
        descriptionTe: 'చిక్కని, కారమైన మసాలాలో వండిన తాజా రొయ్యలు.',
        options: [DishOption('0.5 KG', 850), DishOption('1 KG', 1600)],
      ),
      Dish(
        id: '8', name: 'Paya Soup', nameTe: 'పాయా సూప్', category: 'specials',
        description: 'Slow-simmered trotter soup, warm and full of flavour.',
        descriptionTe: 'గంటల తరబడి ఉడికించిన రుచికరమైన పాయా సూప్.',
        options: [DishOption('0.5 L', 350), DishOption('1 L', 650)],
      ),
    ];
  }

  Future<List<Dish>> _mockMenu() async {
    // --- REAL API: http.get('https://your-api.com/menu') -> List<Dish> ---
    final popular = await _mockPopular();
    const more = [
      Dish(
        id: '9', name: 'Fish Pulusu', nameTe: 'చేపల పులుసు', category: 'specials',
        description: 'Murrel fish simmered in tangy tamarind gravy.',
        descriptionTe: 'పుల్లని చింతపండు గ్రేవీలో ఉడికించిన కొరమీను చేప.',
        options: [DishOption('0.5 KG', 550), DishOption('1 KG', 1050)],
      ),
      Dish(
        id: '10', name: 'Mutton Curry', nameTe: 'మటన్ కర్రీ', category: 'curries',
        description: 'Tender mutton in a thick, spicy home-style gravy.',
        descriptionTe: 'చిక్కని, కారమైన ఇంటి గ్రేవీలో మెత్తని మటన్.',
        options: [DishOption('0.5 KG', 650), DishOption('1 KG', 1250)],
      ),
      Dish(
        id: '11', name: 'Chicken Fry', nameTe: 'చికెన్ ఫ్రై', category: 'fry',
        description: 'Crispy dry-fried chicken tossed with curry leaves.',
        descriptionTe: 'కరివేపాకుతో కరకరలాడే చికెన్ ఫ్రై.',
        options: [DishOption('0.5 KG', 400), DishOption('1 KG', 760)],
      ),
      Dish(
        id: '12', name: 'Mutton Dum Biryani', nameTe: 'మటన్ దమ్ బిర్యానీ', category: 'biryani',
        description: 'Juicy mutton layered with basmati, dum cooked.',
        descriptionTe: 'బాస్మతీతో దమ్‌లో వండిన రసవంతమైన మటన్ బిర్యానీ.',
        options: [DishOption('0.5 KG', 950), DishOption('1 KG', 1800)],
      ),
    ];
    return [...popular, ...more];
  }
}