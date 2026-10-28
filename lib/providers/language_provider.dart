import 'package:flutter/foundation.dart';
import '../models/dish.dart';


class LanguageProvider extends ChangeNotifier {
  bool _isTelugu = false;
  bool get isTelugu => _isTelugu;

  void toggle() {
    _isTelugu = !_isTelugu;
    notifyListeners();
  }
}

class CartItem {
  final Dish dish;
  final DishOption option;
  int qty;
  CartItem(this.dish, this.option, this.qty);

  int get lineTotal => option.price * qty;
  bool get preOrderOnly => dish.preOrderOnly || option.preOrderOnly;
  bool get isHundi => dish.category.toLowerCase() == 'hundi';
}


class CartProvider extends ChangeNotifier {
  static const maxPerItem = 10;
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalItems => _items.fold(0, (s, i) => s + i.qty);

  int get totalPrice => _items.fold(0, (s, i) => s + i.lineTotal);

  /// True when any selected product or size option requires pre-order.
  bool get hasPreOrderItem => _items.any((i) => i.preOrderOnly);

  /// Hundi items always require pre-order.
  /// Other items require pre-order when their selected option is marked so.
  bool get hasPreOrderOnlyItems =>
      _items.any((i) => i.isHundi || i.preOrderOnly);

  /// True when the cart contains any Hundi item.
  bool get hasHundiItem => _items.any((i) => i.isHundi);

  /// Same dish + same size merges into one line (capped at the dish limit).
  void add(Dish dish, DishOption option, int qty) {
    final i = _items.indexWhere(
      (c) => c.dish.id == dish.id && c.option.label == option.label,
    );

    if (i >= 0) {
      _items[i].qty =
          (_items[i].qty + qty).clamp(1, dish.maxPerItem);
    } else {
      _items.add(CartItem(dish, option, qty));
    }

    notifyListeners();
  }

  void increment(CartItem item) {
    if (item.qty < item.dish.maxPerItem) {
      item.qty++;
      notifyListeners();
    }
  }

  /// Going below 1 removes the line from the cart.
  void decrement(CartItem item) {
    if (item.qty > 1) {
      item.qty--;
    } else {
      _items.remove(item);
    }

    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
