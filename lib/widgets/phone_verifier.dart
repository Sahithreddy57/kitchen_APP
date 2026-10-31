
// import 'dart:async';

// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:provider/provider.dart';

// import 'tap_cursor.dart';
// import '../core/app_core.dart';
// import '../providers/language_provider.dart';
// import '../services/api_client.dart';
// import '../services/auth_service.dart';
// import 'checkout_widgets.dart';

// enum _Otp { idle, sending, sent, verifying }

// class PhoneVerifier extends StatefulWidget {
//   final Future<void> Function(String phone) onVerified;

//   /// Optional validation before sending OTP.
//   /// Return an error message to prevent sending, or null to continue.
//   final String? Function(String phone)? phoneCheck;

//   /// Optional custom verification logic.
//   final Future<VerifyResult> Function(String phone, String otp)? onVerify;

//   /// Optional AuthService instance.
//   final AuthService? service;

//   /// false = normal login APIs
//   /// true  = change-mobile APIs
//   final bool isChangingMobile;

//   const PhoneVerifier({
//     super.key,
//     required this.onVerified,
//     this.phoneCheck,
//     this.onVerify,
//     this.service,
//     this.isChangingMobile = false,
//   });

//   @override
//   State<PhoneVerifier> createState() => _PhoneVerifierState();
// }

// class _PhoneVerifierState extends State<PhoneVerifier> {
//   late final AuthService _service = widget.service ?? AuthService();

//   final TextEditingController _phone = TextEditingController();
//   final TextEditingController _otp = TextEditingController();

//   _Otp _state = _Otp.idle;

//   String? _error;
//   String? _customError;

//   bool _tried = false;
//   bool _verified = false;

//   Timer? _timer;
//   int _resendIn = 0;

//   static const String _mobileAlreadyUsedCode =
//       'MOBILE_NUMBER_ALREADY_USED';

//   static const String _legacyMobileAlreadyRegistered =
//       'This mobile number is already registered';

//   @override
//   void dispose() {
//     _timer?.cancel();
//     _phone.dispose();
//     _otp.dispose();
//     super.dispose();
//   }

//   String _t(String key) =>
//       AppStrings.get(key, context.read<LanguageProvider>().isTelugu);

//   bool get _phoneValid =>
//       RegExp(r'^[6-9]\d{9}$').hasMatch(_phone.text.trim());

//   void _startTimer() {
//     _timer?.cancel();

//     setState(() {
//       _resendIn = 30;
//     });

//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (!mounted) {
//         timer.cancel();
//         return;
//       }

//       if (_resendIn <= 1) {
//         timer.cancel();
//         setState(() {
//           _resendIn = 0;
//         });
//       } else {
//         setState(() {
//           _resendIn--;
//         });
//       }
//     });
//   }

//   /// Sends OTP using the appropriate API.
//   Future<void> _send() async {
//     FocusScope.of(context).unfocus();

//     final phone = _phone.text.trim();

//     if (!_phoneValid) {
//       setState(() {
//         _tried = true;
//         _customError = null;
//       });
//       return;
//     }

//     final refused = widget.phoneCheck?.call(phone);

//     if (refused != null) {
//       setState(() {
//         _customError = refused;
//       });
//       return;
//     }

//     setState(() {
//       _state = _Otp.sending;
//       _customError = null;
//       _error = null;
//     });

//     try {
//       if (widget.isChangingMobile) {
//         await _service.sendChangeMobileOtp(phone);
//       } else {
//         await _service.sendOtp(phone);
//       }
//     } on ApiException catch (e) {
//       if (!mounted) return;

//       final isPreviouslyUsed =
//           e.code == _mobileAlreadyUsedCode;

//       final isLegacyDuplicate =
//           widget.isChangingMobile &&
//           e.status == 409 &&
//           e.message == _legacyMobileAlreadyRegistered;

//       setState(() {
//         _state = _Otp.idle;

//         if (isPreviouslyUsed || isLegacyDuplicate) {
//           // Display the exact backend message.
//           _customError = e.message;
//         } else {
//           _customError = _t(
//             e.status == 429 ? 'tooManyAttempts' : 'otpSendFailed',
//           );
//         }
//       });

//       // Do not display the OTP box when the backend rejects the number.
//       return;
//     } catch (_) {
//       if (!mounted) return;

//       setState(() {
//         _state = _Otp.idle;
//         _customError = _t('otpSendFailed');
//       });
//       return;
//     }

//     if (!mounted) return;

//     _otp.clear();
//     _error = null;

//     _startTimer();

//     setState(() {
//       _state = _Otp.sent;
//     });
//   }

//   /// Verifies OTP using the appropriate API.
//   Future<void> _check() async {
//     if (_state == _Otp.verifying || _verified) return;

//     final phone = _phone.text.trim();
//     final otp = _otp.text.trim();

//     if (otp.length != 4) return;

//     FocusScope.of(context).unfocus();

//     setState(() {
//       _state = _Otp.verifying;
//       _error = null;
//     });

//     VerifyResult result;

//     try {
//       if (widget.onVerify != null) {
//         result = await widget.onVerify!(phone, otp);
//       } else if (widget.isChangingMobile) {
//         result = await _service.verifyChangeMobileOtp(phone, otp);
//       } else {
//         result = await _service.verifyOtp(phone, otp);
//       }
//     } catch (e) {
//       result = VerifyResult(
//         VerifyStatus.error,
//         message: e is ApiException ? e.message : null,
//       );
//     }

//     if (!mounted) return;

//     if (result.ok) {
//       _timer?.cancel();

//       setState(() {
//         _verified = true;
//         _state = _Otp.idle;
//         _error = null;
//         _customError = null;
//       });

//       await Future.delayed(const Duration(milliseconds: 700));

//       if (mounted) {
//         await widget.onVerified(phone);
//       }

//       return;
//     }

//     _otp.clear();

//     setState(() {
//     if (result.status == VerifyStatus.error &&
//     result.code == 'MOBILE_NUMBER_ALREADY_USED' &&
//     result.message != null &&
//     result.message!.isNotEmpty) {
//         _state = _Otp.idle;
//         _customError = result.message;
//         _error = null;
//         _timer?.cancel();
//         _resendIn = 0;
//       } else {
//         _state = _Otp.sent;
//         _customError = null;

//         switch (result.status) {
//           case VerifyStatus.cancelled:
//             _error = null;
//             break;

//           case VerifyStatus.tooMany:
//             _error = _t('tooManyAttempts');
//             break;

//           case VerifyStatus.needsProfile:
//             _error = _t('otpVerifyFailed');
//             break;

//           default:
//             _error = _t('wrongCode');
//         }
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     context.watch<LanguageProvider>();

//     final Widget action;

//     if (_verified) {
//       action = Container(
//         height: 52,
//         padding: const EdgeInsets.symmetric(horizontal: 12),
//         decoration: BoxDecoration(
//           color: const Color(0xFFE3F4E8),
//           borderRadius: BorderRadius.circular(14),
//         ),
//         child: const Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               Icons.verified,
//               color: Color(0xFF2E9E57),
//               size: 20,
//             ),
//             SizedBox(width: 6),
//             Text(
//               'Verified',
//               style: TextStyle(
//                 color: Color(0xFF2E9E57),
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//           ],
//         ),
//       );
//     } else {
//       action = SizedBox(
//         height: 52,
//         child: ElevatedButton(
//           style: ElevatedButton.styleFrom(
//             backgroundColor: kNavy,
//             foregroundColor: Colors.white,
//             elevation: 0,
//             padding: const EdgeInsets.symmetric(horizontal: 18),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(14),
//             ),
//           ),
//           onPressed: _state == _Otp.sending ? null : _send,
//           child: _state == _Otp.sending
//               ? const SizedBox(
//                   width: 18,
//                   height: 18,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     color: Colors.white,
//                   ),
//                 )
//               : Text(
//                   _t('verify'),
//                   style: const TextStyle(fontWeight: FontWeight.w700),
//                 ),
//         ),
//       );
//     }

//     final bool busy = _state == _Otp.verifying;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         LabeledField(
//           label: _t('mobile'),
//           hint: '98XXXXXXXX',
//           controller: _phone,
//           enabled: !_verified,
//           prefixText: '+91',
//           keyboard: TextInputType.phone,
//           formatters: [
//             FilteringTextInputFormatter.digitsOnly,
//             LengthLimitingTextInputFormatter(10),
//           ],
//           error: _customError ??
//               (_tried && !_phoneValid ? _t('reqPhone') : null),
//           trailing: action,
//           onChanged: (_) {
//             setState(() {
//               _customError = null;
//               _tried = false;

//               if (_state == _Otp.sent ||
//                   _state == _Otp.verifying) {
//                 _timer?.cancel();
//                 _resendIn = 0;
//                 _state = _Otp.idle;
//                 _otp.clear();
//                 _error = null;
//               }
//             });
//           },
//         ),

//         if (_state == _Otp.sent || _state == _Otp.verifying)
//           Container(
//             margin: const EdgeInsets.only(top: 12),
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(16),
//               border: Border.all(color: kBorder),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   '${_t('codeSentTo')} +91 ${_phone.text}',
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                     color: kNavy,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 TextField(
//                   controller: _otp,
//                   autofocus: true,
//                   enabled: !busy,
//                   textAlign: TextAlign.center,
//                   keyboardType: TextInputType.number,
//                   inputFormatters: [
//                     FilteringTextInputFormatter.digitsOnly,
//                     LengthLimitingTextInputFormatter(4),
//                   ],
//                   style: const TextStyle(
//                     fontSize: 26,
//                     letterSpacing: 16,
//                     fontWeight: FontWeight.w800,
//                     color: kNavy,
//                   ),
//                   decoration: InputDecoration(
//                     hintText: '••••',
//                     filled: true,
//                     fillColor: AppColors.background,
//                     contentPadding:
//                         const EdgeInsets.symmetric(vertical: 14),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: BorderSide.none,
//                     ),
//                   ),
//                   onChanged: (value) {
//                     if (_error != null) {
//                       setState(() {
//                         _error = null;
//                       });
//                     }

//                     if (value.length == 4 &&
//                         _state == _Otp.sent) {
//                       _check();
//                     }
//                   },
//                 ),
//                 if (_error != null)
//                   Padding(
//                     padding: const EdgeInsets.only(top: 8),
//                     child: Text(
//                       _error!,
//                       style: const TextStyle(
//                         color: kErrorRed,
//                         fontSize: 13,
//                       ),
//                     ),
//                   ),
//                 const SizedBox(height: 10),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     if (busy)
//                       const SizedBox(
//                         width: 18,
//                         height: 18,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           color: AppColors.primary,
//                         ),
//                       )
//                     else if (_resendIn > 0)
//                       Text(
//                         '${_t('resendIn')} ${_resendIn}s',
//                         style: const TextStyle(
//                           fontSize: 13,
//                           color: AppColors.textMuted,
//                         ),
//                       )
//                     else
//                       TapCursor(
//                         onTap: _send,
//                         child: Text(
//                           _t('resend'),
//                           style: const TextStyle(
//                             fontSize: 13,
//                             fontWeight: FontWeight.w700,
//                             color: AppColors.primary,
//                           ),
//                         ),
//                       ),
//                     if (kDebugMode && _service.isMock)
//                       const Text(
//                         'Test code: 1234',
//                         style: TextStyle(
//                           fontSize: 11,
//                           color: AppColors.textMuted,
//                         ),
//                       ),
//                   ],
//                 ),
//               ],
//             ),
//           )
//         else if (!_verified)
//           Padding(
//             padding: const EdgeInsets.only(top: 8, left: 2),
//             child: Text(
//               _t('otpNote'),
//               style: const TextStyle(
//                 fontSize: 12,
//                 color: AppColors.textMuted,
//               ),
//             ),
//           ),
//       ],
//     );
//   }
// }


import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'tap_cursor.dart';
import '../core/app_core.dart';
import '../providers/language_provider.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import 'checkout_widgets.dart';

enum _Otp { idle, sending, sent, verifying }

class PhoneVerifier extends StatefulWidget {
  final Future<void> Function(String phone) onVerified;

  /// Optional validation before sending OTP.
  /// Return an error message to prevent sending, or null to continue.
  final String? Function(String phone)? phoneCheck;

  /// Optional custom verification logic.
  final Future<VerifyResult> Function(String phone, String otp)? onVerify;

  /// Optional AuthService instance.
  final AuthService? service;

  /// false = normal login APIs
  /// true  = change-mobile APIs
  final bool isChangingMobile;

  const PhoneVerifier({
    super.key,
    required this.onVerified,
    this.phoneCheck,
    this.onVerify,
    this.service,
    this.isChangingMobile = false,
  });

  @override
  State<PhoneVerifier> createState() => _PhoneVerifierState();
}

class _PhoneVerifierState extends State<PhoneVerifier> {
  late final AuthService _service = widget.service ?? AuthService();

  final TextEditingController _phone = TextEditingController();
  final TextEditingController _otp = TextEditingController();

  _Otp _state = _Otp.idle;

  String? _error;
  String? _customError;

  bool _tried = false;
  bool _verified = false;

  Timer? _timer;
  int _resendIn = 0;

  static const String _mobileAlreadyUsedCode =
      'MOBILE_NUMBER_ALREADY_USED';

  static const String _legacyMobileAlreadyRegistered =
      'This mobile number is already registered';

  @override
  void dispose() {
    _timer?.cancel();
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  String _t(String key) =>
      AppStrings.get(key, context.read<LanguageProvider>().isTelugu);

  bool get _phoneValid =>
      RegExp(r'^[6-9]\d{9}$').hasMatch(_phone.text.trim());

  void _startTimer() {
    _timer?.cancel();

    setState(() {
      _resendIn = 30;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_resendIn <= 1) {
        timer.cancel();
        setState(() {
          _resendIn = 0;
        });
      } else {
        setState(() {
          _resendIn--;
        });
      }
    });
  }

  /// Sends OTP using the appropriate API.
  Future<void> _send() async {
    FocusScope.of(context).unfocus();

    final phone = _phone.text.trim();

    if (!_phoneValid) {
      setState(() {
        _tried = true;
        _customError = null;
      });
      return;
    }

    final refused = widget.phoneCheck?.call(phone);

    if (refused != null) {
      setState(() {
        _customError = refused;
      });
      return;
    }

    setState(() {
      _state = _Otp.sending;
      _customError = null;
      _error = null;
    });

    try {
      if (widget.isChangingMobile) {
        await _service.sendChangeMobileOtp(phone);
      } else {
        await _service.sendOtp(phone);
      }
    } on ApiException catch (e) {
      if (!mounted) return;

      final isPreviouslyUsed =
          e.code == _mobileAlreadyUsedCode;

      final isLegacyDuplicate =
          widget.isChangingMobile &&
          e.status == 409 &&
          e.message == _legacyMobileAlreadyRegistered;

      setState(() {
        _state = _Otp.idle;

        if (isPreviouslyUsed || isLegacyDuplicate) {
          // Display the exact backend message.
          _customError = e.message;
        } else {
          _customError = _t(
            e.status == 429 ? 'tooManyAttempts' : 'otpSendFailed',
          );
        }
      });

      // Do not display the OTP box when the backend rejects the number.
      return;
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _state = _Otp.idle;
        _customError = _t('otpSendFailed');
      });
      return;
    }

    if (!mounted) return;

    _otp.clear();
    _error = null;

    _startTimer();

    setState(() {
      _state = _Otp.sent;
    });
  }

  /// Verifies OTP using the appropriate API.
  Future<void> _check() async {
    if (_state == _Otp.verifying || _verified) return;

    final phone = _phone.text.trim();
    final otp = _otp.text.trim();

    if (otp.length != 4) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _state = _Otp.verifying;
      _error = null;
    });

    VerifyResult result;

    try {
      if (widget.onVerify != null) {
        result = await widget.onVerify!(phone, otp);
      } else if (widget.isChangingMobile) {
        result = await _service.verifyChangeMobileOtp(phone, otp);
      } else {
        result = await _service.verifyOtp(phone, otp);
      }
    } catch (e) {
      result = VerifyResult(
        VerifyStatus.error,
        message: e is ApiException ? e.message : null,
      );
    }

    if (!mounted) return;

    if (result.ok) {
      _timer?.cancel();

      setState(() {
        _verified = true;
        _state = _Otp.idle;
        _error = null;
        _customError = null;
      });

      await Future.delayed(const Duration(milliseconds: 700));

      if (mounted) {
        await widget.onVerified(phone);
      }

      return;
    }

    _otp.clear();

    setState(() {
    if (result.status == VerifyStatus.error &&
    result.code == 'MOBILE_NUMBER_ALREADY_USED' &&
    result.message != null &&
    result.message!.isNotEmpty) {
        _state = _Otp.idle;
        _customError = result.message;
        _error = null;
        _timer?.cancel();
        _resendIn = 0;
      } else {
        _state = _Otp.sent;
        _customError = null;

        switch (result.status) {
          case VerifyStatus.cancelled:
            _error = null;
            break;

          case VerifyStatus.tooMany:
            _error = _t('tooManyAttempts');
            break;

          case VerifyStatus.needsProfile:
            _error = _t('otpVerifyFailed');
            break;

          default:
            _error = _t('wrongCode');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();

    final Widget action;

    if (_verified) {
      action = Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F4E8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified,
              color: Color(0xFF2E9E57),
              size: 20,
            ),
            SizedBox(width: 6),
            Text(
              'Verified',
              style: TextStyle(
                color: Color(0xFF2E9E57),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    } else {
      action = SizedBox(
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
          onPressed: _state == _Otp.sending ? null : _send,
          child: _state == _Otp.sending
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

    final bool busy = _state == _Otp.verifying;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabeledField(
          label: _t('mobile'),
          hint: '98XXXXXXXX',
          controller: _phone,
          enabled: !_verified,
          prefixText: '+91',
          keyboard: TextInputType.phone,
          formatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          // Keep field-level validation here. Backend messages are shown
          // separately below so long messages are not clipped by LabeledField.
          error: _tried && !_phoneValid ? _t('reqPhone') : null,
          trailing: action,
          onChanged: (_) {
            setState(() {
              _customError = null;
              _tried = false;

              if (_state == _Otp.sent ||
                  _state == _Otp.verifying) {
                _timer?.cancel();
                _resendIn = 0;
                _state = _Otp.idle;
                _otp.clear();
                _error = null;
              }
            });
          },
        ),

        // Full-width backend error message (e.g. previously used /
        // already registered mobile number). It wraps instead of truncating.
        if (_customError != null && _customError!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                _customError!,
                textAlign: TextAlign.left,
                softWrap: true,
                maxLines: null,
                overflow: TextOverflow.visible,
                style: const TextStyle(
                  color: kErrorRed,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ),

        if (_state == _Otp.sent || _state == _Otp.verifying)
          Container(
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
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    if (_error != null) {
                      setState(() {
                        _error = null;
                      });
                    }

                    if (value.length == 4 &&
                        _state == _Otp.sent) {
                      _check();
                    }
                  },
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: kErrorRed,
                        fontSize: 13,
                      ),
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
                        onTap: _send,
                        child: Text(
                          _t('resend'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    if (kDebugMode && _service.isMock)
                      const Text(
                        'Test code: 1234',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          )
        else if (!_verified)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 2),
            child: Text(
              _t('otpNote'),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ),
      ],
    );
  }
}



