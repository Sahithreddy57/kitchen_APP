import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_core.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../services/auth_service.dart';
import '../widgets/checkout_widgets.dart';
import '../widgets/phone_verifier.dart';
import 'name_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _service = AuthService();

  VerifyResult? _result;

  Future<VerifyResult> _verify(String phone, String otp) async {
    final auth = context.read<AuthProvider>();

    var result = await _service.verifyOtp(phone, otp);

    // Mock mode only: simulate registration for a new customer.
    if (_service.isMock && result.ok && !auth.hasAccount(phone)) {
      result = const VerifyResult(VerifyStatus.needsProfile);
    }

    if (result.status == VerifyStatus.needsProfile) {
      if (!mounted) {
        return const VerifyResult(VerifyStatus.cancelled);
      }

      final profile = await Navigator.push<ProfileDetails>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              NameScreen(phone: phone, initialName: '', onSubmitProfile: null),
        ),
      );

      if (profile == null) {
        return const VerifyResult(VerifyStatus.cancelled);
      }

      result = await _service.verifyOtp(
        phone,
        otp,
        name: profile.name,
        gender: profile.gender,
        email: profile.email,
        isRegistration: true,
      );

      if (result.ok) {
        result = result.withProfile(profile);
      }
    }

    if (result.ok) {
      _result = result;
    }

    return result;
  }

  void _verified(String phone) {
    final result = _result;

    if (result == null) return;

    context.read<AuthProvider>().register(
      result.name ?? '',
      phone,
      gender: result.gender ?? '',
      email: result.email ?? '',
      token: result.token,
      customerId: result.customerId,
    );

    Navigator.popUntil(context, (route) => route.isFirst);
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
                  Text(
                    context.tr('logIn'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: kNavy,
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
                    context.tr('loginSub'),
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF55606B),
                    ),
                  ),
                  const SizedBox(height: 22),
                  PhoneVerifier(
                    service: _service,
                    onVerify: _verify,
                    onVerified: _verified,
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
