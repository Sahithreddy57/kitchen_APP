
// import 'dart:async';
// import 'dart:convert';

// import 'package:flutter/foundation.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import '../services/api_client.dart';
// import '../models/address.dart';
// import '../services/address_service.dart';

// class _Account {
//   String name;
//   String gender;
//   String email;
//   String customerId;
//   final List<Address> addresses;

//   _Account(
//     this.name,
//     this.addresses, {
//     this.gender = '',
//     this.email = '',
//      this.customerId = '',
//   });
// }

// class AuthProvider extends ChangeNotifier {
//   AuthProvider(this._prefs) {
//     _load();
//   }

//   final SharedPreferences _prefs;
//   final AddressService _addressService = AddressService();

//   String name = '';
//   String phone = '';
//   String gender = '';
//   String email = '';
//   String token = '';
//   String customerId = '';
//   bool isVerified = false;

//   bool get isLoggedIn => isVerified;
//   bool isLoadingAddresses = false;

//   String? addressError;

//   final Map<String, _Account> _db = {};

//   List<Address> _addresses = [];
//   int? selectedAddress;

//   List<Address> get addresses => List.unmodifiable(_addresses);

//   bool hasAccount(String phone) => _db.containsKey(phone);

//   // ---------------- Saving and loading ----------------

//   void _load() {
//     try {
//       final raw = _prefs.getString('accounts');

//       if (raw != null) {
//         final decoded = jsonDecode(raw) as Map<String, dynamic>;

//         decoded.forEach((p, value) {
//           final account = Map<String, dynamic>.from(value as Map);

//           _db[p] = _Account(
//             (account['name'] ?? '').toString(),
//             [
//               for (final item
//                   in (account['addresses'] as List? ?? []))
//                 Address.fromJson(
//                   Map<String, dynamic>.from(item as Map),
//                 ),
//             ],
//             gender: (account['gender'] ?? '').toString(),
//             email: (account['email'] ?? '').toString(),
//             customerId: (account['customerId'] ?? '').toString(),
//           );
//         });
//       }
//     } catch (e) {
//       debugPrint('Could not read saved accounts: $e');
//     }

//     final session = _prefs.getString('session_phone');

//     if (session != null && _db.containsKey(session)) {
//       _applyAccount(session);

//       token = _prefs.getString('session_token') ?? '';

//       if (token.isNotEmpty) {
//         ApiClient.setCustomerToken(token);

//         // Refresh backend addresses after the saved session is restored.
//         unawaited(_refreshSilently());
//       }
//     }
//   }
// /// Saves the name entered during checkout temporarily,
// /// so the profile screen can reuse it after OTP verification.
// void savePendingName(String checkoutName) {
//   final enteredName = checkoutName.trim();

//   if (enteredName.isEmpty) return;

//   name = enteredName;
//   notifyListeners();
// }

//   void _applyAccount(String p) {
//     final account = _db[p]!;

//     phone = p;
//     name = account.name;
//     gender = account.gender;
//     email = account.email;
//     isVerified = true;
//     _addresses = account.addresses;
//   }

//   void _save() {
//     _prefs.setString(
//       'accounts',
//       jsonEncode({
//         for (final entry in _db.entries)
//           entry.key: {
//             'name': entry.value.name,
//             'gender': entry.value.gender,
//             'email': entry.value.email,
//             'addresses':
//                 entry.value.addresses.map((a) => a.toJson()).toList(),
//           },
//       }),
//     );

//     if (isVerified) {
//       _prefs.setString('session_phone', phone);
//       _prefs.setString('session_token', token);
//     } else {
//       _prefs.remove('session_phone');
//       _prefs.remove('session_token');
//     }
//   }

//   // ---------------- Backend address loading ----------------

//   Future<void> refreshAddressesFromBackend() async {
//     if (!isLoggedIn || token.isEmpty) {
//       return;
//     }

//     isLoadingAddresses = true;
//     addressError = null;
//     notifyListeners();

//     try {
//       final backendAddresses =
//           await _addressService.getAddresses();

//       // Preserve local guest addresses that have not yet been uploaded.
//       final localOnly = _addresses
//           .where((address) => address.id == null)
//           .toList();

//       final merged = [...backendAddresses];

//       for (final local in localOnly) {
//         if (!merged.any((item) => item.line == local.line)) {
//           merged.add(local);
//         }
//       }

//       final account = _db[phone];

//       if (account != null) {
//         account.addresses
//           ..clear()
//           ..addAll(merged);

//         _addresses = account.addresses;
//       } else {
//         _addresses = merged;
//       }

//       // Prefer the backend's default address.
//       final defaultIndex =
//           _addresses.indexWhere((address) => address.isDefault);

//       if (defaultIndex >= 0) {
//         selectedAddress = defaultIndex;
//       } else if (selectedAddress != null &&
//           selectedAddress! >= _addresses.length) {
//         selectedAddress = null;
//       }

//       _save();
//     } catch (e) {
//       addressError = e.toString();
//       debugPrint('Could not load backend addresses: $e');
//       rethrow;
//     } finally {
//       isLoadingAddresses = false;
//       notifyListeners();
//     }
//   }

//   Future<void> _refreshSilently() async {
//     try {
//       await refreshAddressesFromBackend();
//     } catch (_) {
//       // Keep locally saved addresses if the backend is unavailable.
//     }
//   }

//   // ---------------- Account actions ----------------

//   void register(
//     String name,
//     String phone, {
//     String gender = '',
//     String email = '',
//     String? token,
//   }) {
//     final guestAddresses = List<Address>.from(_addresses);
//     final account = _db[phone] ?? _Account(name, []);

//     if (name.isNotEmpty) account.name = name;
//     if (gender.isNotEmpty) account.gender = gender;
//     if (email.isNotEmpty) account.email = email;

//     for (final address in guestAddresses) {
//       if (!account.addresses.any((item) => item.line == address.line)) {
//         account.addresses.add(address);
//       }
//     }

//     _db[phone] = account;
//     _applyAccount(phone);

//     if (token != null && token.isNotEmpty) {
//       this.token = token;
//       ApiClient.setCustomerToken(token);
//     }

//     _save();
//     notifyListeners();

//     if (this.token.isNotEmpty) {
//       unawaited(_refreshSilently());
//     }
//   }

//   void login(String phone) {
//     if (!_db.containsKey(phone)) {
//       debugPrint('No locally saved account for $phone');
//       return;
//     }

//     _applyAccount(phone);
//     selectedAddress = null;

//     if (token.isNotEmpty) {
//       ApiClient.setCustomerToken(token);
//     }

//     _save();
//     notifyListeners();

//     if (token.isNotEmpty) {
//       unawaited(_refreshSilently());
//     }
//   }

//   void updateProfile({
//     required String name,
//     required String gender,
//     required String email,
//   }) {
//     this.name = name;
//     this.gender = gender;
//     this.email = email;

//     final account = _db[phone];

//     if (account != null) {
//       account.name = name;
//       account.gender = gender;
//       account.email = email;
//     }

//     _save();
//     notifyListeners();
//   }

//   void changePhone(String newPhone) {
//     final account = _db.remove(phone);

//     if (account == null) return;

//     _db[newPhone] = account;
//     phone = newPhone;

//     _save();
//     notifyListeners();
//   }

//   void logout() {
//     name = '';
//     phone = '';
//     gender = '';
//     email = '';
//     token = '';
//     isVerified = false;
//     _addresses = [];
//     selectedAddress = null;
//     addressError = null;

//     ApiClient.clearCustomerToken();

//     _save();
//     notifyListeners();
//   }

//   // ---------------- Address actions ----------------

//   Future<void> addAddress(Address address) async {
//     Address savedAddress = address;

//     if (isLoggedIn && token.isNotEmpty) {
//       savedAddress =
//           await _addressService.addAddress(address);
//     }

//     _addresses.add(savedAddress);
//     selectedAddress = _addresses.length - 1;

//     _save();
//     notifyListeners();
//   }

//   Future<void> updateAddress(int index, Address address) async {
//     if (index < 0 || index >= _addresses.length) {
//       return;
//     }

//     Address savedAddress = address;

//     if (isLoggedIn && token.isNotEmpty) {
//       if (address.id != null && address.id!.isNotEmpty) {
//         savedAddress =
//             await _addressService.updateAddress(address);
//       } else {
//         // A local guest address has no backend ID yet.
//         savedAddress =
//             await _addressService.addAddress(address);
//       }
//     }

//     _addresses[index] = savedAddress;

//     _save();
//     notifyListeners();
//   }

//   Future<void> removeAddress(int index) async {
//     if (index < 0 || index >= _addresses.length) {
//       return;
//     }

//     final address = _addresses[index];

//     // Delete remotely before removing it from the UI.
//     if (isLoggedIn &&
//         token.isNotEmpty &&
//         address.id != null &&
//         address.id!.isNotEmpty) {
//       await _addressService.deleteAddress(address.id!);
//     }

//     _addresses.removeAt(index);

//     if (selectedAddress == index) {
//       selectedAddress = null;
//     } else if (selectedAddress != null &&
//         selectedAddress! > index) {
//       selectedAddress = selectedAddress! - 1;
//     }

//     _save();
//     notifyListeners();
//   }

//   void selectAddress(int index) {
//     if (index < 0 || index >= _addresses.length) {
//       return;
//     }

//     selectedAddress = index;
//     notifyListeners();
//   }
// }

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';
import '../models/address.dart';
import '../services/address_service.dart';

class _Account {
  String name;
  String gender;
  String email;
  String customerId;
  final List<Address> addresses;

  _Account(
    this.name,
    this.addresses, {
    this.gender = '',
    this.email = '',
    this.customerId = '',
  });
}

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;
  final AddressService _addressService = AddressService();

  String name = '';
  String phone = '';
  String gender = '';
  String email = '';
  String token = '';
  String customerId = '';
  bool isVerified = false;

  bool get isLoggedIn => isVerified;
  bool isLoadingAddresses = false;

  String? addressError;

  final Map<String, _Account> _db = {};

  List<Address> _addresses = [];
  int? selectedAddress;

  List<Address> get addresses => List.unmodifiable(_addresses);

  bool hasAccount(String phone) => _db.containsKey(phone);

  // ---------------- Saving and loading ----------------

  void _load() {
    try {
      final raw = _prefs.getString('accounts');

      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;

        decoded.forEach((p, value) {
          final account = Map<String, dynamic>.from(value as Map);

          _db[p] = _Account(
            (account['name'] ?? '').toString(),
            [
              for (final item
                  in (account['addresses'] as List? ?? []))
                Address.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
            ],
            gender: (account['gender'] ?? '').toString(),
            email: (account['email'] ?? '').toString(),
            customerId: (
              account['customerId'] ??
              account['customer_id'] ??
              ''
            ).toString(),
          );
        });
      }
    } catch (e) {
      debugPrint('Could not read saved accounts: $e');
    }

    final session = _prefs.getString('session_phone');

    if (session != null && _db.containsKey(session)) {
      _applyAccount(session);

      token = _prefs.getString('session_token') ?? '';

      if (token.isNotEmpty) {
        ApiClient.setCustomerToken(token);
        unawaited(_refreshSilently());
      }
    }
  }

  void savePendingName(String checkoutName) {
    final enteredName = checkoutName.trim();

    if (enteredName.isEmpty) return;

    name = enteredName;
    notifyListeners();
  }

  void _applyAccount(String p) {
    final account = _db[p]!;

    phone = p;
    name = account.name;
    gender = account.gender;
    email = account.email;
    customerId = account.customerId;
    isVerified = true;
    _addresses = account.addresses;
  }

  void _save() {
    _prefs.setString(
      'accounts',
      jsonEncode({
        for (final entry in _db.entries)
          entry.key: {
            'name': entry.value.name,
            'gender': entry.value.gender,
            'email': entry.value.email,
            'customerId': entry.value.customerId,
            'addresses':
                entry.value.addresses.map((a) => a.toJson()).toList(),
          },
      }),
    );

    if (isVerified) {
      _prefs.setString('session_phone', phone);
      _prefs.setString('session_token', token);
    } else {
      _prefs.remove('session_phone');
      _prefs.remove('session_token');
    }
  }

  // ---------------- Backend address loading ----------------

  Future<void> refreshAddressesFromBackend() async {
    if (!isLoggedIn || token.isEmpty) return;

    isLoadingAddresses = true;
    addressError = null;
    notifyListeners();

    try {
      final backendAddresses =
          await _addressService.getAddresses();

      final localOnly = _addresses
          .where((address) => address.id == null)
          .toList();

      final merged = [...backendAddresses];

      for (final local in localOnly) {
        if (!merged.any((item) => item.line == local.line)) {
          merged.add(local);
        }
      }

      final account = _db[phone];

      if (account != null) {
        account.addresses
          ..clear()
          ..addAll(merged);

        _addresses = account.addresses;
      } else {
        _addresses = merged;
      }

      final defaultIndex =
          _addresses.indexWhere((address) => address.isDefault);

      if (defaultIndex >= 0) {
        selectedAddress = defaultIndex;
      } else if (selectedAddress != null &&
          selectedAddress! >= _addresses.length) {
        selectedAddress = null;
      }

      _save();
    } catch (e) {
      addressError = e.toString();
      debugPrint('Could not load backend addresses: $e');
      rethrow;
    } finally {
      isLoadingAddresses = false;
      notifyListeners();
    }
  }

  Future<void> _refreshSilently() async {
    try {
      await refreshAddressesFromBackend();
    } catch (_) {
      // Keep locally saved addresses if the backend is unavailable.
    }
  }

  // ---------------- Account actions ----------------

  void register(
    String name,
    String phone, {
    String gender = '',
    String email = '',
    String? token,
    String? customerId,
  }) {
    final normalizedPhone = phone.trim();
    final guestAddresses = List<Address>.from(_addresses);

    final account = _db[normalizedPhone] ??
        _Account(name, []);

    if (name.trim().isNotEmpty) {
      account.name = name.trim();
    }
    if (gender.trim().isNotEmpty) {
      account.gender = gender.trim();
    }
    if (email.trim().isNotEmpty) {
      account.email = email.trim();
    }

    // Preserve a previously saved ID if the current response
    // doesn't provide one. Never invent a database customer ID.
    final incomingId = customerId?.trim() ?? '';
    if (incomingId.isNotEmpty) {
      account.customerId = incomingId;
    }

    for (final address in guestAddresses) {
      if (!account.addresses.any((item) => item.line == address.line)) {
        account.addresses.add(address);
      }
    }

    _db[normalizedPhone] = account;
    _applyAccount(normalizedPhone);

    final incomingToken = token?.trim() ?? '';
    if (incomingToken.isNotEmpty) {
      this.token = incomingToken;
      ApiClient.setCustomerToken(incomingToken);
    }

    _save();
    notifyListeners();

    if (this.token.isNotEmpty) {
      unawaited(_refreshSilently());
    }

    if (kDebugMode) {
      debugPrint(
        'AuthProvider customer ID saved: '
        '${this.customerId.isNotEmpty}',
      );
    }
  }

  void login(String phone) {
    if (!_db.containsKey(phone)) {
      debugPrint('No locally saved account for this phone.');
      return;
    }

    _applyAccount(phone);
    selectedAddress = null;

    if (token.isNotEmpty) {
      ApiClient.setCustomerToken(token);
    }

    _save();
    notifyListeners();

    if (token.isNotEmpty) {
      unawaited(_refreshSilently());
    }
  }

  void updateProfile({
    required String name,
    required String gender,
    required String email,
  }) {
    this.name = name;
    this.gender = gender;
    this.email = email;

    final account = _db[phone];

    if (account != null) {
      account.name = name;
      account.gender = gender;
      account.email = email;
    }

    _save();
    notifyListeners();
  }

  void changePhone(String newPhone) {
    final normalizedPhone = newPhone.trim();
    final account = _db.remove(phone);

    if (account == null) return;

    _db[normalizedPhone] = account;
    phone = normalizedPhone;

    _save();
    notifyListeners();
  }

  void logout() {
    name = '';
    phone = '';
    gender = '';
    email = '';
    token = '';
    customerId = '';
    isVerified = false;
    _addresses = [];
    selectedAddress = null;
    addressError = null;

    ApiClient.clearCustomerToken();

    _save();
    notifyListeners();
  }

  // ---------------- Address actions ----------------

  Future<void> addAddress(Address address) async {
    Address savedAddress = address;

    if (isLoggedIn && token.isNotEmpty) {
      savedAddress = await _addressService.addAddress(address);
    }

    _addresses.add(savedAddress);
    selectedAddress = _addresses.length - 1;

    _save();
    notifyListeners();
  }

  Future<void> updateAddress(int index, Address address) async {
    if (index < 0 || index >= _addresses.length) return;

    Address savedAddress = address;

    if (isLoggedIn && token.isNotEmpty) {
      if (address.id != null && address.id!.isNotEmpty) {
        savedAddress = await _addressService.updateAddress(address);
      } else {
        savedAddress = await _addressService.addAddress(address);
      }
    }

    _addresses[index] = savedAddress;

    _save();
    notifyListeners();
  }

  Future<void> removeAddress(int index) async {
    if (index < 0 || index >= _addresses.length) return;

    final address = _addresses[index];

    if (isLoggedIn &&
        token.isNotEmpty &&
        address.id != null &&
        address.id!.isNotEmpty) {
      await _addressService.deleteAddress(address.id!);
    }

    _addresses.removeAt(index);

    if (selectedAddress == index) {
      selectedAddress = null;
    } else if (selectedAddress != null &&
        selectedAddress! > index) {
      selectedAddress = selectedAddress! - 1;
    }

    _save();
    notifyListeners();
  }

  void selectAddress(int index) {
    if (index < 0 || index >= _addresses.length) return;

    selectedAddress = index;
    notifyListeners();
  }
}
