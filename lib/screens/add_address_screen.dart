
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/app_core.dart';
import '../models/address.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../widgets/checkout_widgets.dart';

class AddAddressScreen extends StatefulWidget {
  final Address? existing;
  final int? index;

  const AddAddressScreen({
    super.key,
    this.existing,
    this.index,
  });

  bool get isEdit => existing != null && index != null;

  @override
  State<AddAddressScreen> createState() =>
      _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _house = TextEditingController();
  final _street = TextEditingController();
  final _landmark = TextEditingController();
  final _pin = TextEditingController();

  String _label = 'home';
  bool _showErrors = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final address = widget.existing;
    if (address != null) {
      _label = address.label.toLowerCase();
      _house.text = address.house;
      _street.text = address.street;
      _landmark.text = address.landmark;
      _pin.text = address.pincode;
    }
  }

  @override
  void dispose() {
    _house.dispose();
    _street.dispose();
    _landmark.dispose();
    _pin.dispose();
    super.dispose();
  }

  String _t(String key) => AppStrings.get(
        key,
        context.read<LanguageProvider>().isTelugu,
      );

  String? _req(TextEditingController controller) =>
      _showErrors && controller.text.trim().isEmpty
          ? _t('errRequired')
          : null;

  Future<void> _save() async {
    final house = _house.text.trim();
    final street = _street.text.trim();
    final pin = _pin.text.trim();

    final pinOk = RegExp(r'^\d{6}$').hasMatch(pin);

    if (house.isEmpty || street.isEmpty || !pinOk) {
      setState(() => _showErrors = true);
      return;
    }

    if (_saving) return;

    setState(() => _saving = true);

    final auth = context.read<AuthProvider>();

    final address = Address(
      id: widget.existing?.id,
      label: _label,
      house: house,
      street: street,
      landmark: _landmark.text.trim(),
      pincode: pin,
      isDefault: widget.existing?.isDefault ?? false,
    );

    try {
      if (widget.isEdit) {
        await auth.updateAddress(widget.index!, address);
      } else {
        await auth.addAddress(address);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _t(widget.isEdit ? 'addressUpdated' : 'addressSaved'),
            ),
          ),
        );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Could not save address: $e'),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
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
              padding: const EdgeInsets.fromLTRB(12, 16, 20, 4),
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
                      _t(widget.isEdit
                          ? 'editAddress'
                          : 'newAddress'),
                      style: const TextStyle(
                        fontSize: 24,
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
                padding:
                    const EdgeInsets.fromLTRB(20, 12, 20, 24),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  Row(
                    children: [
                      for (final item in const [
                        ['home', 'addrHome'],
                        ['work', 'addrWork'],
                        ['other', 'other'],
                      ])
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: item[0] == 'other' ? 0 : 10,
                            ),
                            child: SelectChip(
                              label: _t(item[1]),
                              selected: _label == item[0],
                              onTap: () => setState(
                                () => _label = item[0],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  LabeledField(
                    label: _t('houseNo'),
                    controller: _house,
                    error: _req(_house),
                    capitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  LabeledField(
                    label: _t('street'),
                    controller: _street,
                    error: _req(_street),
                    capitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  LabeledField(
                    label: _t('landmark'),
                    controller: _landmark,
                    capitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  LabeledField(
                    label: _t('pincode'),
                    controller: _pin,
                    keyboard: TextInputType.number,
                    formatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    error: _showErrors &&
                            !RegExp(r'^\d{6}$').hasMatch(_pin.text)
                        ? _t('errPincode')
                        : null,
                    onChanged: (_) => setState(() {}),
                  ),
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
                border: Border(
                  top: BorderSide(color: Color(0xFFEFE8DC)),
                ),
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
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 23,
                          height: 23,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _t('saveAddress'),
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
