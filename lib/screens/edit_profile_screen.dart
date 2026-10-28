import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_core.dart';
import '../core/validators.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../widgets/checkout_widgets.dart';
import '../widgets/gender_picker.dart';
import 'change_number_screen.dart';

/// Edit name, gender, email. The mobile number has its own "Change" button,
/// because a NEW number must be verified with a code first.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  String _gender = '';
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    final a = context.read<AuthProvider>();
    _name.text = a.name;
    _email.text = a.email;
    _gender = a.gender;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  bool get _emailOk => _email.text.trim().isEmpty || isValidEmail(_email.text);

  void _save() {
    if (_name.text.trim().isEmpty || !_emailOk) {
      setState(() => _showErrors = true);
      return;
    }
    context.read<AuthProvider>().updateProfile(
          name: _name.text.trim(),
          gender: _gender,
          email: _email.text.trim(),
        );
    final isTe = context.read<LanguageProvider>().isTelugu;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
          SnackBar(content: Text(AppStrings.get('profileUpdated', isTe))));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final auth = context.watch<AuthProvider>(); // phone changes show up here
    final phoneText = auth.phone.length == 10
        ? '+91 ${auth.phone.substring(0, 5)} ${auth.phone.substring(5)}'
        : '+91 ${auth.phone}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 20, 8),
              child: Row(children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.chevron_left, size: 30, color: kNavy),
                ),
                Text(context.tr('editProfile'),
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: kNavy)),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
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
                  const SizedBox(height: 18),

                  // mobile: shown, changed through a verification screen
                  Text(context.tr('mobile'),
                      style: const TextStyle(
                          fontSize: 12.5, color: Color(0xFF55606B))),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 52,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: kBorder, width: 1.3),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(phoneText,
                                    style: const TextStyle(
                                        fontSize: 16, color: kNavy)),
                              ),
                              const Icon(Icons.verified,
                                  size: 18, color: Color(0xFF2E9E57)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kNavy,
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: kNavy, width: 1.2),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 18),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ChangeNumberScreen())),
                          child: Text(context.tr('changeNumber'),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  GenderPicker(
                      value: _gender,
                      onChanged: (g) => setState(() => _gender = g)),
                  const SizedBox(height: 18),
                  LabeledField(
                   label: context.tr('email'),
                    hint: 'name@example.com',
                    controller: _email,
                    keyboard: TextInputType.emailAddress,
                    error: _showErrors && !_emailOk ? context.tr('errEmail') : null,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                  20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
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
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _save,
                  child: Text(context.tr('save'),
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}