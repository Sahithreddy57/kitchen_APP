
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_core.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../providers/orders_provider.dart';
import '../widgets/checkout_widgets.dart';
import '../widgets/phone_verifier.dart';

/// New number -> SMS code -> verified -> the account moves to the new number.
class ChangeNumberScreen extends StatelessWidget {
  const ChangeNumberScreen({super.key});

  /// Runs BEFORE the OTP is sent.
  String? _check(BuildContext context, String phone) {
    final auth = context.read<AuthProvider>();
    final isTe = context.read<LanguageProvider>().isTelugu;

    if (phone == auth.phone) {
      return AppStrings.get('sameNumber', isTe);
    }

    if (auth.hasAccount(phone)) {
      return AppStrings.get('numberExists', isTe);
    }

    return null;
  }

  /// Runs after the new mobile number is verified.
  Future<void> _verified(
    BuildContext context,
    String newPhone,
  ) async {
    final auth = context.read<AuthProvider>();
    final isTe = context.read<LanguageProvider>().isTelugu;

    // Keep locally saved orders under the new number.
    context.read<OrdersProvider>().reassignPhone(
          auth.phone,
          newPhone,
        );

    // Update the customer's mobile number.
    auth.changePhone(newPhone);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.get('numberChanged', isTe),
          ),
        ),
      );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.chevron_left,
                      size: 30,
                      color: kNavy,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      context.tr('changeMobileTitle'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: kNavy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  Text(
                    context.tr('changeMobileSub'),
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF55606B),
                    ),
                  ),
                  const SizedBox(height: 22),
                  PhoneVerifier(
                    isChangingMobile: true,
                    phoneCheck: (phone) => _check(context, phone),
                    onVerified: (newMobile) =>
                        _verified(context, newMobile),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
