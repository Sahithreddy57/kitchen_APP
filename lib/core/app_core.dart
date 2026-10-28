import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import 'checkout_strings.dart';

class AppColors {
  static const primary = Color(0xFFDD5A24);
  static const background = Color(0xFFF8F3EB);
  static const card = Colors.white;
  static const textDark = Color(0xFF2B2A33);
  static const textMuted = Color(0xFF8A8791);
  static const placeholder = Color(0xFFEDE3D3);
}

/// All UI text lives here. Add a key once, give it both languages.
class AppStrings {
  static const Map<String, Map<String, String>> _t = {
    'welcome': {'en': 'Welcome to DRK Kitchen', 'te': 'DRK కిచెన్‌కు స్వాగతం'},
    'craving': {'en': 'What are you craving today?', 'te': 'ఈరోజు మీకు ఏం తినాలని ఉంది?'},
    'search': {'en': 'Search curries, biryani, hundi…', 'te': 'కూరలు, బిర్యానీ, హండి వెతకండి…'},
    'popular': {'en': 'Popular this week', 'te': 'ఈ వారం ప్రసిద్ధి'},
    'seeMenu': {'en': 'See menu', 'te': 'మెనూ చూడండి'},
    'from': {'en': 'From', 'te': 'ప్రారంభ ధర'},
    'added': {'en': 'added to cart', 'te': 'కార్ట్‌కు జోడించబడింది'},
    'retry': {'en': 'Retry', 'te': 'మళ్ళీ ప్రయత్నించండి'},
    'error': {'en': 'Could not load dishes', 'te': 'వంటకాలను లోడ్ చేయలేకపోయాము'},
    'noResults': {'en': 'No dishes found', 'te': 'వంటకాలు కనబడలేదు'},
    'chooseQty': {'en': 'Choose quantity', 'te': 'పరిమాణం ఎంచుకోండి'},
    'quantity': {'en': 'Quantity', 'te': 'సంఖ్య'},
    'maxPerItem': {'en': 'Max 10 per item', 'te': 'ఒక్కో ఐటమ్‌కు గరిష్టంగా 10'},
    'total': {'en': 'Total', 'te': 'మొత్తం'},
    'addToCart': {'en': 'Add to cart', 'te': 'కార్ట్‌కు జోడించండి'},
    'items': {'en': 'items', 'te': 'ఐటమ్స్'},
    'item': {'en': 'item', 'te': 'ఐటమ్'},
    'viewCart': {'en': 'View cart', 'te': 'కార్ట్ చూడండి'},
    'all': {'en': 'All', 'te': 'అన్నీ'},
    'myCart': {'en': 'My cart', 'te': 'నా కార్ట్'},
    'addMore': {'en': '+ Add more items', 'te': '+ మరిన్ని ఐటమ్స్ జోడించండి'},
    'subtotal': {'en': 'Subtotal', 'te': 'ఉప మొత్తం'},
    'packingNote': {'en': 'Packing and delivery charges are shown at checkout.', 'te': 'ప్యాకింగ్, డెలివరీ ఛార్జీలు చెక్అవుట్‌లో చూపబడతాయి.'},
    'checkout': {'en': 'Checkout', 'te': 'చెక్అవుట్'},
    'emptyCart': {'en': 'Your cart is empty', 'te': 'మీ కార్ట్ ఖాళీగా ఉంది'},
    // categories
    'curries': {'en': 'Curries', 'te': 'కూరలు'},
    'fry': {'en': 'Fry', 'te': 'వేపుడు'},
    'biryani': {'en': 'Biryani', 'te': 'బిర్యానీ'},
    'hundi': {'en': 'Hundi', 'te': 'హండి'},
    'specials': {'en': 'Specials', 'te': 'స్పెషల్స్'},
    // bottom nav
    'home': {'en': 'Home', 'te': 'హోమ్'},
    'menu': {'en': 'Menu', 'te': 'మెనూ'},
    'orders': {'en': 'Orders', 'te': 'ఆర్డర్లు'},
    'profile': {'en': 'Profile', 'te': 'ప్రొఫైల్'},
  };

  static String get(String key, bool isTelugu) =>
      (_t[key] ?? checkoutStrings[key])?[isTelugu ? 'te' : 'en'] ?? key;
}

/// Usage in any widget: context.tr('welcome')
const _standardCategories = {'curries', 'fry', 'biryani', 'hundi', 'specials'};

extension TrX on BuildContext {
  String tr(String key) =>
      AppStrings.get(key, watch<LanguageProvider>().isTelugu);

  /// The 5 standard categories are translated; any category the kitchen adds
  /// in the admin panel shows its own name.
  String trCategory(String key, [String name = '']) =>
      _standardCategories.contains(key) ? tr(key) : (name.isNotEmpty ? name : key);
}

/// 1350 -> ₹1,350
String rupees(int v) =>
    '₹${v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';