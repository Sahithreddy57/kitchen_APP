

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_core.dart';
import '../core/validators.dart';
import '../services/auth_service.dart';
import '../providers/language_provider.dart';
import '../widgets/checkout_widgets.dart';
import '../widgets/gender_picker.dart';

class NameScreen extends StatefulWidget {
  final String phone;
  final String initialName;

  /// When supplied, verify the OTP/profile before closing this screen.
  final Future<VerifyResult> Function(ProfileDetails profile)? onSubmitProfile;

  const NameScreen({
  super.key,
  required this.phone,
  this.initialName = '',
  this.onSubmitProfile,
});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();

  String _gender = '';
  bool _showErrors = false;
  bool _submitting = false;
  String? _emailServerError;
  String? _generalError;

  @override
  void initState() {
    super.initState();
    _name.text = widget.initialName;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  bool get _emailOk => _email.text.trim().isEmpty || isValidEmail(_email.text);

  Future<void> _save() async {
    if (_submitting) return;

    if (_name.text.trim().isEmpty || !_emailOk) {
      setState(() => _showErrors = true);
      return;
    }

    final profile = ProfileDetails(
      name: _name.text.trim(),
      gender: _gender,
      email: _email.text.trim(),
    );

    // Preserve the original behaviour if no verification callback is given.
    if (widget.onSubmitProfile == null) {
      Navigator.pop(context, profile);
      return;
    }

    setState(() {
      _submitting = true;
      _emailServerError = null;
      _generalError = null;
    });

    try {
      final result = await widget.onSubmitProfile!(profile);

      if (!mounted) return;

      if (result.ok) {
        Navigator.pop(context, profile);
        return;
      }

      final message = result.message?.trim() ?? '';
      final lower = message.toLowerCase();

      setState(() {
        _submitting = false;

        if (lower.contains('email') &&
            (lower.contains('already registered') ||
                lower.contains('already exists') ||
                lower.contains('already in use'))) {
          _emailServerError =
              'This email address is already registered. '
              'Please enter a different email address.';
        } else {
          _generalError = message.isNotEmpty
              ? message
              : 'Verification failed. Please try again.';
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _submitting = false;
        _generalError = 'Something went wrong. Please try again.';
      });
    }
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
                    onPressed: _submitting
                        ? null
                        : () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.chevron_left,
                      size: 30,
                      color: kNavy,
                    ),
                  ),
                  Text(
                    context.tr('verified'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: kNavy,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.verified, color: Color(0xFF2E9E57)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  Text(
                    context.tr('nameTitle'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: kNavy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.tr('nameSub'),
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF55606B),
                    ),
                  ),
                  const SizedBox(height: 22),
                  LabeledField(
                    label: context.tr('name'),
                    hint: context.tr('nameHint'),
                    controller: _name,
                    capitalization: TextCapitalization.words,
                    error: _showErrors && _name.text.trim().isEmpty
                        ? context.tr('reqName')
                        : null,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '+91 ${widget.phone}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 18),
                  GenderPicker(
                    value: _gender,
                    onChanged: (g) => setState(() => _gender = g),
                  ),
                  const SizedBox(height: 18),

                  LabeledField(
                    label: context.tr('email'),
                    hint: 'name@example.com',
                    controller: _email,
                    keyboard: TextInputType.emailAddress,
                    error:
                        _emailServerError ??
                        (_showErrors && !_emailOk
                            ? context.tr('errEmail')
                            : null),
                    onChanged: (_) {
                      setState(() {
                        _emailServerError = null;
                        _generalError = null;
                      });
                    },
                  ),

                  if (_generalError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _generalError!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                14,
                20,
                MediaQuery.of(context).padding.bottom + 14,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEFE8DC))),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _submitting ? null : _save,
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          context.tr('save'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
                                                                                                                                                                                                                  