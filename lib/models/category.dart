/// A menu category (chip). [key] is the lower-case name, e.g. "curries";
/// dishes are matched to chips by this key.
class MenuCategory {
  final String id;
  final String key;
  final String name; // as written in the admin panel, e.g. "Curries"

  const MenuCategory({required this.id, required this.key, required this.name});

  /// The 5 standard categories, in the FIXED tab order. Always shown first,
  /// and used until the categories load or if the API fails / returns nothing.
  static const List<MenuCategory> standard = [
    MenuCategory(id: '', key: 'curries', name: 'Curries'),
    MenuCategory(id: '', key: 'fry', name: 'Fry'),
    MenuCategory(id: '', key: 'biryani', name: 'Biryani'),
    MenuCategory(id: '', key: 'hundi', name: 'Hundi'),
    MenuCategory(id: '', key: 'specials', name: 'Specials'),
  ];
}