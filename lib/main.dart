import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/app_core.dart';
import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';
import 'providers/orders_provider.dart';
import 'screens/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance(); // saved accounts + orders

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider(prefs)),
        // Orders follow the logged-in number automatically
        ChangeNotifierProxyProvider<AuthProvider, OrdersProvider>(
          create: (_) => OrdersProvider(prefs),
          update: (_, auth, orders) =>
              orders!..setPhone(auth.isLoggedIn ? auth.phone : ''),
        ),
      ],
      child: const DrkApp(),
    ),
  );
}

/// Lets mouse / trackpad drag-scroll too (useful when testing in Chrome).
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
       @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Completely disable Android overscroll/stretch effect.
    return child;
  }
}

class DrkApp extends StatelessWidget {
  const DrkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DRK Kitchen',
      debugShowCheckedModeBanner: false,
      scrollBehavior: AppScrollBehavior(),
      builder: (context, child) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: child!,
        );

      },
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        
      ),
      home: const MainShell(),
    );
  }
}