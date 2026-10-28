import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_core.dart';
import '../core/app_nav.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../widgets/checkout_widgets.dart';
import 'legal_screen.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'order_actions.dart';
import 'saved_addresses_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _push(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  Future<void> _confirmLogout(BuildContext context) async {
    final isTe = context.read<LanguageProvider>().isTelugu;
    String t(String k) => AppStrings.get(k, isTe);

    final out = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t('logoutTitle'),
            style: const TextStyle(fontWeight: FontWeight.w800, color: kNavy)),
        content: Text(t('logoutBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: Text(t('stay'),
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: kNavy)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(d, true),
            child: Text(t('logOut'),
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: Color(0xFFC0392B))),
          ),
        ],
      ),
    );

    if (out != true || !context.mounted) return;
    context.read<AuthProvider>().logout();
    context.read<CartProvider>().clear();
    mainTab.value = 0; // back to the app's Home
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(t('loggedOut'))));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final lang = context.watch<LanguageProvider>();
    final loggedIn = auth.isLoggedIn;

    Widget rowItem(String label, Widget trailing, VoidCallback onTap,
            {bool last = false}) =>
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            decoration: BoxDecoration(
              border: last
                  ? null
                  : const Border(
                      bottom: BorderSide(color: Color(0xFFEFE8DC))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 16, color: kNavy)),
                trailing,
              ],
            ),
          ),
        );

    Widget muted(String t) => Text(t,
        style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF7A8490)));

    const chevron = Icon(Icons.chevron_right, size: 20, color: Color(0xFF7A8490));

    Widget link(String text, VoidCallback onTap) => InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(text,
                style: const TextStyle(
                    fontSize: 15.5, color: Color(0xFF55606B))),
          ),
        );

    final phoneText = auth.phone.length == 10
        ? '+91 ${auth.phone.substring(0, 5)} ${auth.phone.substring(5)}'
        : '+91 ${auth.phone}';

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
        children: [
          Text(context.tr('profile'),
              style: const TextStyle(
                  fontSize: 32, fontWeight: FontWeight.w800, color: kNavy)),
          const SizedBox(height: 18),

          if (!loggedIn)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kNavy,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('guestTitle'),
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(context.tr('guestBody'),
                      style: const TextStyle(
                          fontSize: 15, height: 1.4, color: Colors.white)),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 26, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => _push(context, const LoginScreen()),
                    child: Text(context.tr('logIn'),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                      color: kNavy, shape: BoxShape.circle),
                  child: Text(
                      auth.name.isEmpty
                          ? '?'
                          : String.fromCharCode(auth.name.runes.first)
                              .toUpperCase(),
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(auth.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: kNavy)),
                      const SizedBox(height: 2),
                      Text(phoneText,
                          style: const TextStyle(
                              fontSize: 14.5, color: Color(0xFF55606B))),
                      if (auth.email.isNotEmpty)
                        Text(auth.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13.5, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kNavy,
                    side: const BorderSide(color: kBorder, width: 1.3),
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _push(context, const EditProfileScreen()),
                  child: Text(context.tr('edit'),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          const SizedBox(height: 18),

          // settings card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEFE8DC)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                if (loggedIn)
                  rowItem(
                    context.tr('savedAddresses'),
                    muted('${auth.addresses.length}'),
                    () => _push(context, const SavedAddressesScreen()),
                  ),
                rowItem(
                  context.tr('language'),
                  muted(lang.isTelugu ? 'తెలుగు → English' : 'English → తెలుగు'),
                  lang.toggle,
                ),
                rowItem(
                  context.tr('helpSupport'),
                  chevron,
                  () => showHelpSheet(context, lang.isTelugu),
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          link(context.tr('terms'),
              () => _push(context, const LegalScreen(keyName: 'terms'))),
          link(context.tr('privacy'),
              () => _push(context, const LegalScreen(keyName: 'privacy'))),
          link(context.tr('refund'),
              () => _push(context, const LegalScreen(keyName: 'refund'))),

          if (loggedIn)
            InkWell(
              onTap: () => _confirmLogout(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(context.tr('logOut'),
                    style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFC0392B))),
              ),
            ),
        ],
      ),
    );
  }
}