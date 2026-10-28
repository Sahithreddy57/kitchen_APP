import 'package:flutter/material.dart';
import '../core/app_core.dart';
import '../core/app_nav.dart';
import '../widgets/cart_bar.dart';
import 'home_screen.dart';
import 'menu_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = mainTab.value;

  @override
  void initState() {
    super.initState();
    mainTab.addListener(_sync);
  }

  @override
  void dispose() {
    mainTab.removeListener(_sync);
    super.dispose();
  }

  void _sync() => setState(() => _index = mainTab.value);
  void _goTo(int i) => mainTab.value = i;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onSeeMenu: () => _goTo(1)), // "See menu" opens Menu tab
          const MenuScreen(),
          const OrdersScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CartBar(),
          _buildNav(context),
        ],
      ),
    );
  }

  Widget _buildNav(BuildContext context) {
    return NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goTo,
        backgroundColor: Colors.white,
        indicatorColor: Colors.transparent,
        destinations: [
          _dest(Icons.home_outlined, Icons.home, context.tr('home')),
          _dest(Icons.menu, Icons.menu, context.tr('menu')),
          _dest(Icons.receipt_long_outlined, Icons.receipt_long, context.tr('orders')),
          _dest(Icons.person_outline, Icons.person, context.tr('profile')),
        ],
    );
  }

  NavigationDestination _dest(IconData icon, IconData selected, String label) =>
      NavigationDestination(
        icon: Icon(icon, color: AppColors.textMuted),
        selectedIcon: Icon(selected, color: AppColors.primary),
        label: label,
      );
}

class _Placeholder extends StatelessWidget {
  final String title;
  const _Placeholder({required this.title});

  @override
  Widget build(BuildContext context) =>
      Center(child: Text('$title page – coming next'));
}