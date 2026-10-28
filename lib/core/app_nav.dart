import 'package:flutter/foundation.dart';

/// Which bottom-nav tab is showing (0 Home, 1 Menu, 2 Orders, 3 Profile).
/// Set `mainTab.value = 0;` from anywhere to jump back to Home.
final ValueNotifier<int> mainTab = ValueNotifier<int>(0);