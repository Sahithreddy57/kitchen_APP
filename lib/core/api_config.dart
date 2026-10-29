
import 'package:flutter/foundation.dart';

/// true  = use the built-in sample menu (no backend needed)
/// false = load the menu from your backend
const bool kUseMockMenu = false;
///flutter run --dart-define=DEV_API_TOKEN=paste_your_token_here

///flutter run --dart-define=DEV_API_TOKEN=paste_your_token_here
/// Testing on a REAL phone? Put your computer's Wi-Fi IP here.
/// Phone and computer must be on the same Wi-Fi.
const String kApiHostOverride = '192.168.1.65';

const int kApiPort = 5000;

/// Backend URL configuration
/// Android emulator: use 10.0.2.2 if no host override is configured.
/// Chrome / Windows: use localhost if no host override is configured.
String get apiBaseUrl {
  final host = kApiHostOverride.isNotEmpty
      ? kApiHostOverride
      : (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
          ? '10.0.2.2'
          : 'localhost';

  return 'http://$host:$kApiPort';
}

/// Products API
/// TODO: Replace with a public customer menu endpoint when available.
const String kProductsPath = '/api/admin/products';

/// Kitchen hours API
const String kHoursPath = '/api/admin/settings/hours';
const String kPreorderScheduleDayPath =
    '/api/admin/preorder-schedule/day';

/// Use sample kitchen hours when true.
const bool kUseMockHours = false;

/// Hundi packages API
// const String kHundiBase = '/api/admin/hundi';
// const String kHundiPath = '$kHundiBase/active';

/// Categories API
const String kCategoriesPath = '/api/admin/categories';

/// DEVELOPMENT ONLY.
/// Run with:
/// flutter run --dart-define=DEV_API_TOKEN=your_token
///
/// Never include an admin token in a production APK.
const String kDevApiToken = String.fromEnvironment('DEV_API_TOKEN');

/// Customer authentication base path
const String kCustomerAuthBase = '/api/customer/auth';

/// Common OTP endpoint used for both login and registration.
///
/// POST /api/customer/auth/send-otp
const String kRegisterSendOtpPath =
    '$kCustomerAuthBase/send-otp';

const String kLoginSendOtpPath =
    '$kCustomerAuthBase/send-otp';

/// Common OTP verification endpoint used for both login and registration.
///
/// POST /api/customer/auth/verify-otp
const String kRegisterVerifyOtpPath =
    '$kCustomerAuthBase/verify-otp';

const String kLoginVerifyOtpPath =
    '$kCustomerAuthBase/verify-otp';

/// Change mobile endpoints
const String kChangeMobileSendOtpPath =
    '$kCustomerAuthBase/change-mobile/send-otp';

const String kChangeMobileVerifyOtpPath =
    '$kCustomerAuthBase/change-mobile/verify-otp';

/// Customer order creation endpoint
const String kCreateOrderPath = '/api/customer/orders';

/// Use real backend authentication, not mock OTP.
const bool kUseMockAuth = false;
/// Customer order cancellation endpoint
/// POST /api/customer/orders/:id/cancel
const String kCancelOrderPath = '/api/customer/orders';
