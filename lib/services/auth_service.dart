
import 'package:flutter/foundation.dart';

import '../core/api_config.dart';
import 'api_client.dart';

class ProfileDetails {
  final String name;
  final String gender;
  final String email;

  const ProfileDetails({
    required this.name,
    this.gender = '',
    this.email = '',
  });
}

enum VerifyStatus {
  ok,
  needsProfile,
  wrongCode,
  tooMany,
  cancelled,
  error,
}

class VerifyResult {
  final VerifyStatus status;
  final String? token;
  final String? customerId;
  final String? name;
  final String? gender;
  final String? email;
  final String? message;
  final String? code;

  const VerifyResult(
    this.status, {
    this.token,
    this.customerId,
    this.name,
    this.gender,
    this.email,
    this.message,
    this.code,
  });

  bool get ok => status == VerifyStatus.ok;

  VerifyResult withProfile(ProfileDetails profile) {
    return VerifyResult(
      status,
      token: token,
      customerId: customerId,
      name: name == null || name!.isEmpty ? profile.name : name,
      gender: gender == null || gender!.isEmpty
          ? profile.gender
          : gender,
      email: email == null || email!.isEmpty
          ? profile.email
          : email,
      message: message,
      code: code,
    );
  }
}

class AuthService {
  AuthService({bool? mock}) : isMock = mock ?? kUseMockAuth;

  final bool isMock;

  static const String mobileAlreadyUsedCode =
      'MOBILE_NUMBER_ALREADY_USED';

  String _apiGender(String gender) {
    final value = gender.trim();
    if (value.isEmpty) return '';

    return value.toLowerCase();
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }

  Map<String, dynamic> _responseData(
    Map<String, dynamic> body,
  ) {
    final data = _asMap(body['data']);
    return data.isNotEmpty ? data : body;
  }

  String? _extractId(Map<String, dynamic> customer) {
    final value = customer['id'] ??
        customer['_id'] ??
        customer['customerId'] ??
        customer['customer_id'];

    if (value is Map) {
      final nestedId = value['_id'] ?? value['id'];
      final id = nestedId?.toString().trim();
      return id == null || id.isEmpty ? null : id;
    }

    final id = value?.toString().trim();
    return id == null || id.isEmpty ? null : id;
  }

  /// Supports common response structures:
  /// data.customer, data.user, data.profile, or direct data.
  Map<String, dynamic> _extractCustomer(
    Map<String, dynamic> body,
  ) {
    final data = _asMap(body['data']);

    final candidates = <Map<String, dynamic>>[
      _asMap(data['customer']),
      _asMap(data['user']),
      _asMap(data['profile']),
      _asMap(body['customer']),
      _asMap(body['user']),
      _asMap(body['profile']),
      data,
      body,
    ];

    for (final candidate in candidates) {
      if (_extractId(candidate) != null) {
        return candidate;
      }
    }

    for (final candidate in candidates) {
      if (candidate.isNotEmpty) return candidate;
    }

    return <String, dynamic>{};
  }

  String? _extractToken(Map<String, dynamic> body) {
    final data = _responseData(body);

    final value = data['token'] ??
        data['accessToken'] ??
        data['access_token'] ??
        data['customerToken'] ??
        data['customer_token'] ??
        body['token'] ??
        body['accessToken'] ??
        body['access_token'];

    final token = value?.toString().trim();
    return token == null || token.isEmpty ? null : token;
  }

  void _acceptToken(
    String? token, {
    required String source,
  }) {
    if (token == null || token.isEmpty) {
      if (kDebugMode) {
        debugPrint('$source: no token returned by the server.');
      }
      return;
    }

    ApiClient.setCustomerToken(token);

    if (kDebugMode) {
      debugPrint('$source: customer token received.');
    }
  }

  /// Sends OTP for registration or login.
  Future<void> sendOtp(
    String mobile, {
    bool isRegistration = false,
  }) async {
    final phone = mobile.trim();

    if (phone.isEmpty) {
      throw ApiException('Please enter your mobile number.');
    }

    if (isMock) {
      await Future.delayed(const Duration(milliseconds: 700));

      if (kDebugMode) {
        debugPrint('Mock OTP mode enabled.');
      }
      return;
    }

    final path = isRegistration
        ? kRegisterSendOtpPath
        : kLoginSendOtpPath;

    final res = await ApiClient.postJson(
      path,
      {'mobile': phone},
    );

    if (!res.ok) {
      if (kDebugMode) {
        debugPrint('Send OTP failed: HTTP ${res.status}');
      }

      throw ApiException(
        res.message.isEmpty ? 'Could not send the code' : res.message,
        res.status,
        res.code,
      );
    }
  }

  /// Verifies OTP for registration or login.
  ///
  /// Registration sends mobile, otp, name, email and gender.
  /// Login sends only mobile and otp.
  Future<VerifyResult> verifyOtp(
    String mobile,
    String otp, {
    String? name,
    String? gender,
    String? email,
    bool isRegistration = false,
  }) async {
    final phone = mobile.trim();
    final code = otp.trim();

    if (phone.isEmpty || code.isEmpty) {
      return const VerifyResult(
        VerifyStatus.error,
        message: 'Enter your mobile number and OTP.',
      );
    }

    if (isRegistration && (name == null || name.trim().isEmpty)) {
      return const VerifyResult(
        VerifyStatus.error,
        message: 'Please enter your name to register.',
      );
    }

    if (isMock) {
      await Future.delayed(const Duration(milliseconds: 700));

      if (code != '1234') {
        return const VerifyResult(
          VerifyStatus.wrongCode,
          message: 'Incorrect OTP. Please try again.',
        );
      }

      return VerifyResult(
        VerifyStatus.ok,
        name: name,
        gender: gender?.toLowerCase(),
        email: email,
      );
    }

    final path = isRegistration
        ? kRegisterVerifyOtpPath
        : kLoginVerifyOtpPath;

    final requestBody = <String, dynamic>{
      'mobile': phone,
      'otp': code,
      if (isRegistration) 'name': name!.trim(),
      if (isRegistration &&
          gender != null &&
          gender.trim().isNotEmpty)
        'gender': _apiGender(gender),
      if (isRegistration &&
          email != null &&
          email.trim().isNotEmpty)
        'email': email.trim(),
    };

    ApiResponse res;

    try {
      res = await ApiClient.postJson(path, requestBody);
    } on ApiException catch (e) {
      final message = e.message.trim();
      final lowerMessage = message.toLowerCase();

      if (kDebugMode) {
        debugPrint('OTP verification request failed.');
        debugPrint('HTTP status: ${e.status ?? 'unknown'}');
        debugPrint('Error code: ${e.code ?? 'unknown'}');
      }

      // Check the backend error code, not HTTP 409 alone.
      if (e.code == mobileAlreadyUsedCode) {
        return VerifyResult(
          VerifyStatus.error,
          message: message,
          code: e.code,
        );
      }

      if (e.status == 429) {
        return const VerifyResult(
          VerifyStatus.tooMany,
          message: 'Too many attempts. Please try again later.',
        );
      }

      if (_isDuplicateEmail(lowerMessage)) {
        return const VerifyResult(
          VerifyStatus.error,
          message: 'This email address is already registered. '
              'Please enter a different email address.',
        );
      }

      if (_needsProfile(lowerMessage)) {
        return VerifyResult(
          VerifyStatus.needsProfile,
          message: message,
        );
      }

      if (_isWrongOtp(lowerMessage)) {
        return const VerifyResult(
          VerifyStatus.wrongCode,
          message: 'Incorrect or expired OTP. Please try again.',
        );
      }

      return VerifyResult(
        VerifyStatus.error,
        message: message.isNotEmpty
            ? message
            : 'Verification failed. Please try again.',
      );
    }

    if (kDebugMode) {
      debugPrint(
        '${isRegistration ? 'Registration' : 'Login'} '
        'verification HTTP status: ${res.status}',
      );
    }

    if (res.ok) {
      final customer = _extractCustomer(res.body);
      final customerId = _extractId(customer);
      final token = _extractToken(res.body);

      _acceptToken(
        token,
        source: isRegistration ? 'REGISTER' : 'LOGIN',
      );

      if (kDebugMode) {
        debugPrint(
          '${isRegistration ? 'REGISTER' : 'LOGIN'} '
          'customer ID found: ${customerId != null}',
        );
      }

      return VerifyResult(
        VerifyStatus.ok,
        token: token,
        customerId: customerId,
        name: customer['name']?.toString() ?? name,
        gender: customer['gender']?.toString().toLowerCase() ??
            gender?.toLowerCase(),
        email: customer['email']?.toString() ?? email,
      );
    }

    final message = res.message.trim();
    final lowerMessage = message.toLowerCase();

    // Handle this code before generic status/message handling.
    if (res.code == mobileAlreadyUsedCode) {
      return VerifyResult(
        VerifyStatus.error,
        message: message,
        code: res.code,
      );
    }

    if (res.status == 429) {
      return const VerifyResult(
        VerifyStatus.tooMany,
        message: 'Too many attempts. Please try again later.',
      );
    }

    if (_isDuplicateEmail(lowerMessage)) {
      return const VerifyResult(
        VerifyStatus.error,
        message: 'This email address is already registered. '
            'Please enter a different email address.',
      );
    }

    if (_needsProfile(lowerMessage)) {
      return VerifyResult(
        VerifyStatus.needsProfile,
        message: message,
      );
    }

    if (_isWrongOtp(lowerMessage) ||
        [400, 401, 404, 422].contains(res.status)) {
      return VerifyResult(
        VerifyStatus.wrongCode,
        message: message.isNotEmpty
            ? message
            : 'Incorrect or expired OTP. Please try again.',
      );
    }

    return VerifyResult(
      VerifyStatus.error,
      message: message.isNotEmpty
          ? message
          : 'Unable to verify OTP. Please try again.',
    );
  }

  bool _isDuplicateEmail(String message) {
    return message.contains('email') &&
        (message.contains('already registered') ||
            message.contains('already exists') ||
            message.contains('already in use'));
  }

  bool _needsProfile(String message) {
    return message.contains('name is required') ||
        message.contains('email is required') ||
        message.contains('gender is required') ||
        message.contains('profile is required') ||
        message.contains('complete your profile') ||
        message.contains('profile details required');
  }

  bool _isWrongOtp(String message) {
    return message.contains('invalid otp') ||
        message.contains('incorrect otp') ||
        message.contains('wrong otp') ||
        message.contains('expired otp') ||
        message.contains('invalid code') ||
        message.contains('incorrect code');
  }

  /// Sends OTP to a new mobile number for an authenticated customer.
  Future<void> sendChangeMobileOtp(String newMobile) async {
    final phone = newMobile.trim();

    if (phone.isEmpty) {
      throw ApiException('Please enter the new mobile number.');
    }

    if (isMock) {
      await Future.delayed(const Duration(milliseconds: 700));
      return;
    }

    if (ApiClient.customerToken == null ||
        ApiClient.customerToken!.isEmpty) {
      throw ApiException(
        'Please log in before changing your number.',
      );
    }

    final res = await ApiClient.postJson(
      kChangeMobileSendOtpPath,
      {'mobile': phone},
      authenticated: true,
    );

    if (!res.ok) {
      throw ApiException(
        res.message.isEmpty
            ? 'Could not send the new number OTP'
            : res.message,
        res.status,
        res.code,
      );
    }
  }

  /// Verifies the change-mobile OTP.
  Future<VerifyResult> verifyChangeMobileOtp(
    String newMobile,
    String otp,
  ) async {
    final phone = newMobile.trim();
    final code = otp.trim();

    if (isMock) {
      await Future.delayed(const Duration(milliseconds: 700));

      return code == '1234'
          ? const VerifyResult(VerifyStatus.ok)
          : const VerifyResult(
              VerifyStatus.wrongCode,
              message: 'Incorrect OTP. Please try again.',
            );
    }

    if (ApiClient.customerToken == null ||
        ApiClient.customerToken!.isEmpty) {
      return const VerifyResult(
        VerifyStatus.error,
        message: 'Please log in before changing your number.',
      );
    }

    ApiResponse res;

    try {
      res = await ApiClient.postJson(
        kChangeMobileVerifyOtpPath,
        {
          'mobile': phone,
          'otp': code,
        },
        authenticated: true,
      );
    } on ApiException catch (e) {
      if (kDebugMode) {
        debugPrint('Change-mobile verification request failed.');
        debugPrint('HTTP status: ${e.status ?? 'unknown'}');
        debugPrint('Error code: ${e.code ?? 'unknown'}');
      }

      if (e.code == mobileAlreadyUsedCode) {
        return VerifyResult(
          VerifyStatus.error,
          message: e.message,
          code: e.code,
        );
      }

      if (e.status == 429) {
        return const VerifyResult(
          VerifyStatus.tooMany,
          message: 'Too many attempts. Please try again later.',
        );
      }

      return VerifyResult(
        VerifyStatus.error,
        message: e.message.isNotEmpty
            ? e.message
            : 'Could not verify the new number.',
      );
    }

    if (res.ok) {
      final token = _extractToken(res.body);

      if (token != null) {
        _acceptToken(token, source: 'CHANGE MOBILE');
      }

      final customer = _extractCustomer(res.body);

      return VerifyResult(
        VerifyStatus.ok,
        token: token ?? ApiClient.customerToken,
        customerId: _extractId(customer),
        name: customer['name']?.toString(),
        gender: customer['gender']?.toString().toLowerCase(),
        email: customer['email']?.toString(),
      );
    }

    final message = res.message.trim();
    final lowerMessage = message.toLowerCase();

    if (res.code == mobileAlreadyUsedCode) {
      return VerifyResult(
        VerifyStatus.error,
        message: message,
        code: res.code,
      );
    }

    if (res.status == 429) {
      return const VerifyResult(
        VerifyStatus.tooMany,
        message: 'Too many attempts. Please try again later.',
      );
    }

    if (_isWrongOtp(lowerMessage) ||
        [400, 401, 404, 422].contains(res.status)) {
      return VerifyResult(
        VerifyStatus.wrongCode,
        message: message.isNotEmpty
            ? message
            : 'Incorrect or expired OTP. Please try again.',
      );
    }

    return VerifyResult(
      VerifyStatus.error,
      message: message.isNotEmpty
          ? message
          : 'Could not verify the new number.',
    );
  }
}
