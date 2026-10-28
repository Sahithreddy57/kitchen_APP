
import 'dart:async';

import '../widgets/tap_cursor.dart';

import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_core.dart';
import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/kitchen_hours_service.dart';
import '../services/payment_service.dart';
import '../widgets/checkout_widgets.dart';
import 'add_address_screen.dart';
import 'processing_screen.dart';
import 'name_screen.dart';

const kPackingFee = 30;
const kDeliveryFee = 40;

enum _Otp { idle, sending, sent, verifying }

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _authService = AuthService();

  // 1. details
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  _Otp _otpState = _Otp.idle;
  String? _otpError;
  String _verifiedPhone = '';
  Timer? _timer;
  int _resendIn = 0;
  bool _phoneTried = false;
  bool _nameTried = false; // tapped Verify before typing a name

  // 2. how
  bool _delivery = false;
  

  // 3. when
  bool _orderNow = true;
  late DateTime _date;
  DateTime? _customDate;
  final _dateScroll = ScrollController();
  int? _slot; // start of the chosen 1-hour slot, in minutes since midnight

  // kitchen hours for the selected date (from the API)
  final _hoursService = KitchenHoursService();
  KitchenHours? _hours;
  bool _hoursLoading = false;
  String? _hoursError;
  int _hoursToken = 0; // ignores late answers for a date the user already left

  // 4. payment
  int _payTab = 0; // 0 UPI, 1 Card, 2 Netbanking
  String? _upiApp;
  String? _bank;
  final _upiId = TextEditingController();
  final _cardNo = TextEditingController();
  final _cardName = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();

  bool _showErrors = false;
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    final a = context.read<AuthProvider>();
    _name.text = a.name;
    _phone.text = a.phone;
    if (a.isVerified) _verifiedPhone = a.phone;
    _date = DateUtils.dateOnly(DateTime.now());
    final cart = context.read<CartProvider>();
    if (cart.hasPreOrderOnlyItems) {
      // Hundi and preorder-only options must use Pre-order.
      _orderNow = false;

      // Do not automatically move Hundi orders to tomorrow.
      // The two-hour minimum will be applied to today's time slots.

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadHours();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dateScroll.dispose();
    for (final c in [
      _name,
      _phone,
      _otp,
      _upiId,
      _cardNo,
      _cardName,
      _expiry,
      _cvv,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // Safe to call from build AND from button handlers.
  String _t(String k) =>
      AppStrings.get(k, context.read<LanguageProvider>().isTelugu);

  // ---------------- validation helpers ----------------
  bool get _phoneValid => RegExp(r'^[6-9]\d{9}$').hasMatch(_phone.text);

  /// Any preorder-only size forces preorder. Hundi alone requires tomorrow.
 bool get _preOnly =>
    context.read<CartProvider>().hasPreOrderOnlyItems;
  bool get _hundiInCart => context.read<CartProvider>().hasHundiItem;
  bool get _preOrderOnlyInCart =>
      context.read<CartProvider>().hasPreOrderOnlyItems;
  int get _chipCount => _preOnly ? 7 : 6; // visible date chips
  bool get _verified =>
      _verifiedPhone.isNotEmpty && _verifiedPhone == _phone.text;
  bool get _expiryValid {
    final m = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(_expiry.text);
    if (m == null) return false;
    final month = int.parse(m.group(1)!);
    return month >= 1 && month <= 12;
  }

  bool get _paymentValid {
    switch (_payTab) {
      case 0:
        if (_upiApp == null) return false;
        if (_upiApp == 'other') {
          return RegExp(r'^[\w.\-]{2,}@[a-zA-Z]{2,}$')
              .hasMatch(_upiId.text.trim());
        }
        return true;
      case 1:
        return _cardNo.text.length == 16 &&
            _cardName.text.trim().isNotEmpty &&
            _expiryValid &&
            _cvv.text.length == 3;
      default:
        return _bank != null;
    }
  }

  String? _firstError() {
    if (_name.text.trim().isEmpty) return 'reqName';
    if (!_phoneValid) return 'reqPhone';
    if (!_verified) return 'reqVerify';
    if (_delivery && context.read<AuthProvider>().selectedAddress == null) {
      return 'reqAddress';
    }
    if (!_orderNow) {
      if (_hoursLoading || _hoursError != null || _hours == null)
        return 'reqSlot';
      if (!_hours!.isOpen) return 'kitchenClosed';
      if (_slot == null) return 'reqSlot';
    }
    if (!_paymentValid) return 'reqPayment';
    return null;
  }

  // ---------------- OTP ----------------
  void _startTimer() {
    _timer?.cancel();
    _resendIn = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _resendIn--);
      if (_resendIn <= 0) t.cancel();
    });
  }

  void _toast(String key) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(_t(key))));
  }

 Future<void> _sendOtp() async {
  FocusScope.of(context).unfocus();

  if (!_phoneValid) {
    setState(() => _phoneTried = true);
    return;
  }

  setState(() {
    _otpState = _Otp.sending;
    _otpError = null;
  });

  try {
    await _authService.sendOtp(_phone.text.trim());
  } on ApiException catch (e) {
    if (!mounted) return;

    setState(() => _otpState = _Otp.idle);
    _toast(e.status == 429 ? 'tooManyAttempts' : 'otpSendFailed');
    return;
  } catch (e) {
    if (!mounted) return;

    debugPrint('Checkout OTP send failed: $e');
    setState(() => _otpState = _Otp.idle);
    _toast('otpSendFailed');
    return;
  }

  if (!mounted) return;

  _otp.clear();
  _startTimer();

  setState(() {
    _otpState = _Otp.sent;
    _otpError = null;
  });
}
  
Future<void> _checkOtp() async {
  if (_otpState == _Otp.verifying) return;

  final phone = _phone.text.trim();
  final otp = _otp.text.trim();

  if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
    setState(() => _phoneTried = true);
    return;
  }

  if (otp.length != 4) return;

  FocusScope.of(context).unfocus();

  setState(() {
    _otpState = _Otp.verifying;
    _otpError = null;
  });

  try {
    // First, try verifying the OTP for an existing customer.
    var result = await _authService.verifyOtp(phone, otp);

    if (!mounted) return;

    // A new customer needs to provide their profile details.
    if (result.status == VerifyStatus.needsProfile) {
      VerifyResult? profileVerification;

      final profile = await Navigator.push<ProfileDetails>(
        context,
        MaterialPageRoute(
          builder: (_) => NameScreen(
  phone: phone,
  initialName: _name.text.trim(),
  onSubmitProfile: (profile) async {
            final verification = await _authService.verifyOtp(
  phone,
  otp,
  name: profile.name.trim(),
  gender: profile.gender,
  email: profile.email,
  isRegistration: true,
);

              profileVerification = verification;
              return verification;
            },
          ),
        ),
      );

      if (!mounted) return;

      // The user cancelled profile registration.
      if (profile == null) {
        setState(() {
          _otpState = _Otp.sent;
          _otpError = null;
        });
        return;
      }

      // Use the result returned by the profile verification callback.
      result = profileVerification ??
          const VerifyResult(
            VerifyStatus.error,
            message: 'Verification failed. Please try again.',
          );

      if (result.ok) {
        result = result.withProfile(profile);
      }
    }

    if (!mounted) return;

if (result.ok) {
  _timer?.cancel();

  final auth = context.read<AuthProvider>();

  // Prefer the name returned by the backend.
  // If it is empty, reuse the name entered during checkout.
 final checkoutName = _name.text.trim();

final verifiedName = (result.name?.trim().isNotEmpty ?? false)
    ? result.name!.trim()
    : checkoutName;

if (verifiedName.isEmpty) {
  setState(() {
    _otpState = _Otp.sent;
    _otpError = 'Please enter your name.';
  });
  return;
}
debugPrint(
  'OTP result has customer ID: '
  '${result.customerId?.isNotEmpty == true}',
);
debugPrint(
  'OTP result has token: '
  '${result.token?.isNotEmpty == true}',
);
  // Save the authenticated customer and backend token.
  auth.register(
    verifiedName,
    phone,
    gender: result.gender ?? '',
    email: result.email ?? '',
    token: result.token,
     customerId: result.customerId,
  );

debugPrint(
  'AuthProvider has customer ID: '
  '${auth.customerId.isNotEmpty}',
);
debugPrint(
  'AuthProvider has token: '
  '${auth.token.isNotEmpty}',
);

  setState(() {
    _name.text = verifiedName;
    _verifiedPhone = phone;
    _otpState = _Otp.idle;
    _otpError = null;
  });

  FocusScope.of(context).unfocus();
}
else {
      // Preserve a useful backend message rather than hiding it.
      final message = result.message?.trim() ?? '';

      setState(() {
        _otpState = _Otp.sent;
        _otpError = message.isNotEmpty
            ? message
            : _t(
                result.status == VerifyStatus.tooMany
                    ? 'tooManyAttempts'
                    : result.status == VerifyStatus.wrongCode
                        ? 'wrongCode'
                        : 'otpVerifyFailed',
              );
      });
    }
  } on ApiException catch (e) {
    if (!mounted) return;

    debugPrint('Checkout OTP API error: ${e.status ?? 'unknown'}');

    setState(() {
      _otpState = _Otp.sent;
      _otpError = e.status == 429
          ? _t('tooManyAttempts')
          : (e.message.isNotEmpty
              ? e.message
              : _t('otpVerifyFailed'));
    });
  } catch (e) {
    if (!mounted) return;

    // Do not print OTPs or authentication tokens.
    debugPrint('Checkout OTP verification failed: $e');

    setState(() {
      _otpState = _Otp.sent;
      _otpError = _t('otpVerifyFailed');
    });
  }
}

  // ---------------- schedule ----------------
  /// 840 -> "2 PM", 870 -> "2:30 PM" (used inside slot labels)
  String _fmtSlot(int m) {
    final mm = m % 1440;
    final h24 = mm ~/ 60;
    final min = mm % 60;
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    final mer = h24 < 12 ? 'AM' : 'PM';
    return min == 0
        ? '$h12 $mer'
        : '$h12:${min.toString().padLeft(2, '0')} $mer';
  }

  /// 840 -> "2:00 PM" (used in "Kitchen is open 2:00 PM – 10:00 PM")
  String _fmtClock(int m) {
    final mm = m % 1440;
    final h24 = mm ~/ 60;
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    return '$h12:${(mm % 60).toString().padLeft(2, '0')} ${h24 < 12 ? 'AM' : 'PM'}';
  }

  /// Slot starting at [startMin] -> "3 PM–4 PM", "11 AM–12 PM"
  String _slotLabel(int startMin) =>
      '${_fmtSlot(startMin)}–${_fmtSlot(startMin + 60)}';

  /// 1-hour slots between the configured kitchen opening and closing times.
  /// Normal preorder uses the existing 45-minute lead time. A preorder-only
  /// size must start at least 2 hours from now. Hundi is date-restricted to
  /// tomorrow or later, so the same-day lead-time rule doesn't apply to it.

  /// Generate 1-hour slots using backend kitchen hours.
  /// For today, preorder-only items (including Hundi) require
  /// at least 2 hours' notice. Normal preorder keeps 45 minutes.
 
List<int> _slotsFor(KitchenHours h) {
  final open = h.openMinutes;
  final close = h.closeMinutes;

  if (!h.isOpen || open == null || close == null || close <= open) {
    return const [];
  }

  final now = DateTime.now();
  final isToday = DateUtils.isSameDay(_date, now);

  // Only today's slots need a minimum lead time.
  final int leadMinutes = _preOrderOnlyInCart ? 120 : 0;

  final int earliest;
  if (isToday) {
    final nowMinutes = now.hour * 60 + now.minute;
    final requiredMinutes = nowMinutes + leadMinutes;

    // Round UP to the next full-hour slot boundary.
    earliest = ((requiredMinutes + 59) ~/ 60) * 60;
  } else {
    earliest = open;
  }

  final slots = <int>[];

  // Generate complete one-hour slots within kitchen hours.
  for (int start = open; start + 60 <= close; start += 60) {
    if (start < earliest) continue;
    slots.add(start);
  }

  return slots;
}


  /// Fetch the kitchen hours for the selected date. Clears the chosen slot.
  Future<void> _loadHours() async {
    final date = _date;
    final token = ++_hoursToken;
    setState(() {
      _hoursLoading = true;
      _hoursError = null;
      _hours = null;
      _slot = null;
    });
    try {
      final h = await _hoursService.fetch(date);
      if (!mounted || token != _hoursToken) return;
      setState(() {
        _hours = h;
        _hoursLoading = false;
      });
    } catch (_) {
      if (!mounted || token != _hoursToken) return;
      setState(() {
        _hoursError = _t('hoursError');
        _hoursLoading = false;
      });
    }
  }

  /// "Today" / "Tomorrow" / "Sat" for the date cards
  String _chipTitle(DateTime d) {
    final diff = d.difference(DateUtils.dateOnly(DateTime.now())).inDays;
    if (diff == 0) return _t('today');
    if (diff == 1) return _t('tomorrow');
    return _t('weekdaysShort').split(',')[d.weekday - 1];
  }

  /// "Today" / "Tomorrow" / "Wednesday"
  String _dayTitle(DateTime d) {
    final today = DateUtils.dateOnly(DateTime.now());
    final diff = d.difference(today).inDays;
    if (diff == 0) return _t('today');
    if (diff == 1) return _t('tomorrow');
    return _t('weekdays').split(',')[d.weekday - 1];
  }

  /// "5 Oct"
  String _dayDate(DateTime d) =>
      '${d.day} ${_t('months').split(',')[d.month - 1]}';

  /// Used in the order summary: "Today" or "Wednesday 7 Oct"
  String _dayLabel(DateTime d) {
    final diff = d.difference(DateUtils.dateOnly(DateTime.now())).inDays;
    return diff <= 1 ? _dayTitle(d) : '${_dayTitle(d)} ${_dayDate(d)}';
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(today) ? today : _date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 90)),
    );

    if (picked == null) return;

    final d = DateUtils.dateOnly(picked);

    setState(() {
      _date = d;
      _slot = null;
      _customDate = d.difference(today).inDays > _chipCount - 1 ? d : null;
    });

    _loadHours();
  }

  // ---------------- pay ----------------
  String _whenText() => _orderNow
      ? '${_t('today')} · ${_t('inMin')}'
      : '${_dayLabel(_date)} · ${_slot == null ? '—' : _slotLabel(_slot!)}';

  /// When the food should be ready: now + 40 min, or the START of the chosen slot.
  DateTime _scheduledAt() {
    if (_orderNow) return DateTime.now().add(const Duration(minutes: 40));
    if (_slot == null) return _date;
    return DateTime(
      _date.year,
      _date.month,
      _date.day,
      _slot! ~/ 60,
      _slot! % 60,
    );
  }

  Future<void> _pay() async {
    FocusScope.of(context).unfocus();
    final err = _firstError();
    if (err != null) {
      setState(() => _showErrors = true);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_t(err))));
      return;
    }

    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();
    final fee = _delivery ? kDeliveryFee : 0;
    final total = cart.totalPrice + kPackingFee + fee;
    

    const upiNames = {
      'gpay': 'Google Pay',
      'phonepe': 'PhonePe',
      'paytm': 'Paytm',
      'other': 'UPI',
    };
    final String method, detail;
    if (_payTab == 0) {
      method = 'upi';
      detail = upiNames[_upiApp] ?? 'UPI';
    } else if (_payTab == 1) {
      method = 'card';
      detail = _cardNo.text.substring(12); // last 4 digits only
    } else {
      method = 'netbanking';
      detail = _bank ?? '';
    }

final draft = Order(
  id: '', // Filled in once the kitchen confirms
  orderNumber: '', // Assigned when the order number is available

  lines: [
    for (final it in cart.items)
      OrderLine(
        dish: it.dish,
        option: it.option,
        qty: it.qty,
      ),
  ],

  subtotal: cart.totalPrice,
  packing: kPackingFee,
  deliveryFee: fee,
  total: total,

  // Pickup or delivery
  isDelivery: _delivery,

  // Order Now or Pre-order
  isOrderNow: _orderNow,

  whenText: _whenText(),
  scheduledAt: _scheduledAt(),

  // Include the saved address ID only for delivery
  address: _delivery
      ? auth.addresses[auth.selectedAddress!].line
      : null,
  deliveryAddressId: _delivery
      ? auth.addresses[auth.selectedAddress!].id
      : null,

  customerName: _name.text.trim(),
  phone: _phone.text,
  paymentLabel: '$method · $detail',
  createdAt: DateTime.now(),
);

    final failed = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => ProcessingScreen(
          request: PaymentRequest(
            amount: total,
            method: method,
            detail: detail,
          ),
          draft: draft,
        ),
      ),
    );

    // Only reached if the payment failed (success replaces all screens).
    if (failed != null && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_t('payFailed'))));
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>(); // rebuild on language change
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();
    final total =
        cart.totalPrice + kPackingFee + (_delivery ? kDeliveryFee : 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 20, 0),
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
                    _t('checkout'),
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  SectionHeader(number: 1, title: _t('yourDetails')),
                  _detailsSection(),
                  SectionHeader(number: 2, title: _t('howWant')),
                  _howSection(auth),
                  SectionHeader(number: 3, title: _t('when')),
                  _whenSection(),
                  SectionHeader(number: 4, title: _t('payWith')),
                  _paySection(),
                  SectionHeader(number: 5, title: _t('orderSummary')),
                  _summary(cart, total),
                ],
              ),
            ),
            _payBar(total),
          ],
        ),
      ),
    );
  }

  // ---- 1. details ----
  Widget _detailsSection() {
    final phoneError = (_showErrors || _phoneTried) && !_phoneValid
        ? _t('reqPhone')
        : null;

    Widget verifyBtn;
    if (_verified) {
      verifyBtn = Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F4E8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified, color: Color(0xFF2E9E57), size: 20),
            const SizedBox(width: 6),
            Text(
              _t('verified'),
              style: const TextStyle(
                color: Color(0xFF2E9E57),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    } else {
      verifyBtn = SizedBox(
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: kNavy,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: _otpState == _Otp.sending ? null : _sendOtp,
          child: _otpState == _Otp.sending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  _t('verify'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabeledField(
          label: _t('name'),
          hint: _t('nameHint'),
          controller: _name,
          capitalization: TextCapitalization.words,
          error: (_showErrors || _nameTried) && _name.text.trim().isEmpty
              ? _t('reqName')
              : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: _t('mobile'),
          hint: '98XXXXXXXX',
          controller: _phone,
          prefixText: '+91',
          keyboard: TextInputType.phone,
          formatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          error: phoneError,
          trailing: verifyBtn,
          onChanged: (_) {
            // editing the number cancels any pending / finished verification
            if (_otpState != _Otp.idle && _otpState != _Otp.sending) {
              _timer?.cancel();
              _otpState = _Otp.idle;
            }
            setState(() {});
          },
        ),
        if (_otpState == _Otp.sent || _otpState == _Otp.verifying)
          _otpPanel()
        else if (!_verified)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 2),
            child: Text(
              _t('otpNote'),
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
      ],
    );
  }

  Widget _otpPanel() {
    final busy = _otpState == _Otp.verifying;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_t('codeSentTo')} +91 ${_phone.text}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kNavy,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _otp,
            autofocus: true,
            enabled: !busy,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            style: const TextStyle(
              fontSize: 26,
              letterSpacing: 16,
              fontWeight: FontWeight.w800,
              color: kNavy,
            ),
            decoration: InputDecoration(
              hintText: '••••',
              counterText: '',
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) {
              if (_otpError != null) setState(() => _otpError = null);
              if (v.length == 4) _checkOtp(); // auto-verify
            },
          ),
          if (_otpError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _otpError!,
                style: const TextStyle(color: kErrorRed, fontSize: 13),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              else if (_resendIn > 0)
                Text(
                  '${_t('resendIn')} ${_resendIn}s',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                )
              else
                TapCursor(
                  onTap: _sendOtp,
                  child: Text(
                    _t('resend'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              if (kDebugMode && _authService.isMock)
                const Text(
                  'Test code: 1234',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- 2. pickup / delivery ----
  Widget _howSection(AuthProvider auth) {
    const labelKeys = {
      'home': 'addrHome',
      'work': 'addrWork',
      'other': 'other',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OptionCard(
          selected: !_delivery,
          title: _t('pickup'),
          subtitle: _t('pickupSub'),
          onTap: () => setState(() => _delivery = false),
        ),
        OptionCard(
          selected: _delivery,
          title: _t('delivery'),
          subtitle: _t('deliverySub'),
          onTap: () => setState(() => _delivery = true),
        ),
        if (_delivery) ...[
          const SizedBox(height: 6),
          Text(
            _t('selectAddress'),
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF55606B)),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < auth.addresses.length; i++)
            OptionCard(
              selected: auth.selectedAddress == i,
              title: _t(labelKeys[auth.addresses[i].label] ?? 'other'),
              subtitle: auth.addresses[i].line,
              onTap: () => auth.selectAddress(i),
            ),
          DashedButton(
            label: _t('addAddress'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddAddressScreen()),
            ),
          ),
          if (_showErrors && auth.selectedAddress == null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 2),
              child: Text(
                _t('reqAddress'),
                style: const TextStyle(color: kErrorRed, fontSize: 13),
              ),
            ),
        ],
      ],
    );
  }

  // ---- 3. when ----
  /// Tap-to-scroll arrow for the date row (works even where dragging doesn't).
  Widget _scrollArrow(IconData icon, int dir) => TapCursor(
    behavior: HitTestBehavior.opaque,
    onTap: () {
      if (!_dateScroll.hasClients) return;
      final pos = _dateScroll.position;
      final target = (pos.pixels + dir * 180.0)
          .clamp(pos.minScrollExtent, pos.maxScrollExtent)
          .toDouble();
      _dateScroll.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    },
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: kBorder),
      ),
      child: Icon(icon, size: 20, color: kNavy),
    ),
  );

  Widget _whenSection() {
    final today = DateUtils.dateOnly(DateTime.now());
    final days = List.generate(_chipCount, (i) => today.add(Duration(days: i)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_preOnly) PreOrderNote(text: _t('preOrderNote')),
        OptionCard(
          selected: _orderNow,
          enabled: !_preOnly,
          title: _t('orderNow'),
          subtitle: _preOnly ? _t('preOrderOnlyNoOrderNow') : _t('orderNowSub'),
          onTap: () => setState(() => _orderNow = true),
        ),
        OptionCard(
          selected: !_orderNow,
          title: _t('preorder'),
          subtitle: _t('preorderSub'),
          onTap: () {
            setState(() => _orderNow = false);
            if (_hours == null && !_hoursLoading) _loadHours();
          },
        ),
        if (!_orderNow) ...[
          const SizedBox(height: 4),
          // 6 days: swipe/drag OR tap the arrows. Then a Calendar button for later dates.
          SizedBox(
            height: 72,
            child: Row(
              children: [
                _scrollArrow(Icons.chevron_left, -1),
                const SizedBox(width: 6),
                Expanded(
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.trackpad,
                      },
                    ),
                    child: SingleChildScrollView(
                      controller: _dateScroll,
                      scrollDirection: Axis.horizontal,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: ClampingScrollPhysics(),
                      ),
                      child: Row(
                        children: [
                          for (final d in days) ...[
                            DateChip(
                              title: _chipTitle(d),
                              subtitle: '${d.day}',
                              disabled: false,
                              selected: DateUtils.isSameDay(_date, d),
                              onTap: () {
                                setState(() {
                                  _date = d;
                                  _customDate = null;
                                });
                                _loadHours();
                              },
                            ),
                            const SizedBox(width: 10),
                          ],
                          if (_customDate != null) ...[
                            DateChip(
                              title:
                                  '${_chipTitle(_customDate!)}, ${_t('months').split(',')[_customDate!.month - 1]}',
                              subtitle: '${_customDate!.day}',
                              selected: true,
                              onTap: _pickDate,
                            ),
                            const SizedBox(width: 10),
                          ],
                          DateChip(
                            title: _t('pickDate'),
                            icon: Icons.calendar_month,
                            selected: false,
                            onTap: _pickDate,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _scrollArrow(Icons.chevron_right, 1),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _timeSection(),
        ],
      ],
    );
  }

  /// Small coloured message box (closed / error).
  Widget _notice({
    required IconData icon,
    required String text,
    Color bg = const Color(0xFFFDE8DD),
    Color fg = const Color(0xFF9A3412),
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(fontSize: 13.5, height: 1.35, color: fg),
                ),
              ),
            ],
          ),
          if (action != null) ...[const SizedBox(height: 6), action],
        ],
      ),
    );
  }

  /// Everything under the date row: loading / error + retry / closed / slots.
  Widget _timeSection() {
    // 1) loading
    if (_hoursLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _t('hoursLoading'),
              style: const TextStyle(fontSize: 14, color: Color(0xFF55606B)),
            ),
          ],
        ),
      );
    }

    // 2) error + retry
    if (_hoursError != null) {
      return _notice(
        icon: Icons.wifi_off_outlined,
        text: _hoursError!,
        action: TextButton.icon(
          onPressed: _loadHours,
          icon: const Icon(Icons.refresh, size: 18),
          label: Text(
            _t('retry'),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 36),
            alignment: Alignment.centerLeft,
          ),
        ),
      );
    }

    final h = _hours;
    if (h == null) return const SizedBox.shrink();

    // 3) closed on this date -> no slots
    if (!h.isOpen) {
      return _notice(
        icon: Icons.event_busy_outlined,
        text: _t('kitchenClosed'),
      );
    }

    // 4) open -> kitchen hours, info, slots
    final open = h.openMinutes;
    final close = h.closeMinutes;
    final slots = _slotsFor(h);
    final hasMinutes = slots.any((s) => s % 60 != 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (open != null && close != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(Icons.schedule, size: 18, color: kNavy),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                   'Kitchen is open ${_fmtClock(open)} – ${_fmtClock(close)}',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: kNavy,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEAEFF4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _t('slotInfo'),
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.35,
              color: Color(0xFF4A5A6A),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _t('selectTime'),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: kNavy,
          ),
        ),
        const SizedBox(height: 10),
        if (slots.isEmpty)
          Text(
            _t('noSlots'),
            style: const TextStyle(color: AppColors.textMuted),
          )
        else
          ChipGrid(
            columns: hasMinutes ? 2 : 3, // wider chips when labels have minutes
            chips: [
              for (final start in slots)
                SelectChip(
                  label: _slotLabel(start),
                  fontSize: 12.5,
                  selected: _slot == start,
                  onTap: () => setState(() => _slot = start),
                ),
            ],
          ),
        if (_showErrors && _slot == null && slots.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 2),
            child: Text(
              _t('reqSlot'),
              style: const TextStyle(color: kErrorRed, fontSize: 13),
            ),
          ),
      ],
    );
  }

  // ---- 4. payment ----
  Widget _paySection() {
    final tabs = ['upi', 'card', 'netbanking'];

    Widget content;
    if (_payTab == 0) {
      final apps = [
        ['gpay', 'googlePay'],
        ['phonepe', 'phonePe'],
        ['paytm', 'paytm'],
        ['other', 'otherUpi'],
      ];
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChipGrid(
            columns: 2,
            chips: [
              for (final a in apps)
                SelectChip(
                  label: _t(a[1]),
                  selected: _upiApp == a[0],
                  onTap: () => setState(() => _upiApp = a[0]),
                ),
            ],
          ),
          if (_upiApp == 'other')
            LabeledField(
              label: _t('upiId'),
              hint: 'name@bank',
              controller: _upiId,
              keyboard: TextInputType.emailAddress,
              error: _showErrors && !_paymentValid ? _t('errUpi') : null,
              onChanged: (_) => setState(() {}),
            ),
        ],
      );
    } else if (_payTab == 1) {
      content = Column(
        children: [
          LabeledField(
            label: _t('cardNumber'),
            hint: '1234 5678 9012 3456',
            controller: _cardNo,
            keyboard: TextInputType.number,
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
            ],
            error: _showErrors && _cardNo.text.length != 16
                ? _t('errRequired')
                : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: _t('cardName'),
            controller: _cardName,
            capitalization: TextCapitalization.characters,
            error: _showErrors && _cardName.text.trim().isEmpty
                ? _t('errRequired')
                : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LabeledField(
                  label: _t('expiry'),
                  hint: 'MM/YY',
                  controller: _expiry,
                  keyboard: TextInputType.number,
                  formatters: [_ExpiryFormatter()],
                  error: _showErrors && !_expiryValid
                      ? _t('errRequired')
                      : null,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LabeledField(
                  label: _t('cvv'),
                  hint: '•••',
                  controller: _cvv,
                  obscure: true,
                  keyboard: TextInputType.number,
                  formatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  error: _showErrors && _cvv.text.length != 3
                      ? _t('errRequired')
                      : null,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      const banks = ['SBI', 'HDFC', 'ICICI', 'Axis', 'Kotak', 'other'];
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('chooseBank'),
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF55606B)),
          ),
          const SizedBox(height: 10),
          ChipGrid(
            chips: [
              for (final b in banks)
                SelectChip(
                  label: b == 'other' ? _t('other') : b,
                  selected: _bank == b,
                  onTap: () => setState(() => _bank = b),
                ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (int i = 0; i < tabs.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: SelectChip(
                  label: _t(tabs[i]),
                  selected: _payTab == i,
                  onTap: () => setState(() => _payTab = i),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        content,
        if (_showErrors &&
            !_paymentValid &&
            _payTab != 1 &&
            !(_payTab == 0 && _upiApp == 'other'))
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 2),
            child: Text(
              _t('reqPayment'),
              style: const TextStyle(color: kErrorRed, fontSize: 13),
            ),
          ),
      ],
    );
  }

  // ---- 5. summary ----
  Widget _summary(CartProvider cart, int total) {
    final isTe = context.read<LanguageProvider>().isTelugu;
    final whenText = _whenText();

    Widget row(String l, String v, {bool big = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l,
            style: TextStyle(
              fontSize: big ? 19 : 14.5,
              fontWeight: big ? FontWeight.w800 : FontWeight.w400,
              color: big ? kNavy : const Color(0xFF55606B),
            ),
          ),
          Text(
            v,
            style: TextStyle(
              fontSize: big ? 21 : 14.5,
              fontWeight: big ? FontWeight.w800 : FontWeight.w500,
              color: kNavy,
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFE8DC)),
      ),
      child: Column(
        children: [
          for (final it in cart.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTe ? it.dish.nameTe : it.dish.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: kNavy,
                          ),
                        ),
                        Text(
                          '${it.option.label} × ${it.qty}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF55606B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    rupees(it.lineTotal),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: kNavy,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 18, color: Color(0xFFEFE8DC)),
          row(_t('subtotal'), rupees(cart.totalPrice)),
          row(_t('packing'), rupees(kPackingFee)),
          if (_delivery) row(_t('deliveryFee'), rupees(kDeliveryFee)),
          const SizedBox(height: 4),
          row(_t('total'), rupees(total), big: true),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _t('when'),
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textMuted,
                  ),
                ),
                Flexible(
                  child: Text(
                    whenText,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: kNavy,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- bottom pay bar ----
  Widget _payBar(int total) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEFE8DC))),
      ),
      child: Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _paying ? null : _pay,
          child: SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: _paying
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _t('pay'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          rupees(total),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Types "1228" -> "12/28"
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var d = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (d.length > 4) d = d.substring(0, 4);
    final t = d.length > 2 ? '${d.substring(0, 2)}/${d.substring(2)}' : d;
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

