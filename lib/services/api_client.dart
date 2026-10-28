

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/api_config.dart';

class ApiException implements Exception {
  final int? status;
  final String message;

  ApiException(this.message, [this.status]);

  @override
  String toString() => 'ApiException(${status ?? '-'}): $message';
}

class ApiResponse {
  final int status;
  final Map<String, dynamic> body;

  const ApiResponse(this.status, this.body);

  bool get ok =>
      status >= 200 && status < 300 && body['success'] != false;

  String get message =>
      (body['message'] ?? body['error'] ?? '').toString().toLowerCase();
}

class ApiClient {
  /// Customer session token returned by the login/verification API.
  static String? customerToken;

  static void setCustomerToken(String token) {
    customerToken = token;
  }

  static void clearCustomerToken() {
    customerToken = null;
  }

static Map<String, String> _headers({
  bool authenticated = false,
}) {
  final String? token;

  if (authenticated) {
    token = customerToken;
  } else {
    token = kDevApiToken.isNotEmpty ? kDevApiToken : null;
  }

  return {
    'Accept': 'application/json',
    if (token != null && token.isNotEmpty)
      'Authorization': 'Bearer $token',
  };
}

  static Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
    bool logBody = false,
    bool authenticated = false,
  }) async {
    final uri = Uri.parse('$apiBaseUrl$path')
        .replace(queryParameters: query);

    final http.Response res;

    try {
      res = await http
          .get(
            uri,
            headers: _headers(authenticated: authenticated),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('GET $uri failed: $e');
      throw ApiException('Could not reach the server');
    }

    if (kDebugMode) {
      debugPrint('GET $uri -> ${res.statusCode}');

      if (logBody) {
        // Do not enable this for endpoints that return tokens or private data.
        final text = utf8.decode(res.bodyBytes);
        debugPrint(
          text.length > 700 ? '${text.substring(0, 700)}...' : text,
        );
      }
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException('HTTP ${res.statusCode}', res.statusCode);
    }

    final decoded = jsonDecode(utf8.decode(res.bodyBytes));

    if (decoded is! Map) {
      throw ApiException('Unexpected response format');
    }

    final body = Map<String, dynamic>.from(decoded);

    if (body['success'] == false) {
      throw ApiException(
        (body['message'] ?? 'Request failed').toString(),
        res.statusCode,
      );
    }

    return body;
  }

  /// POST JSON. OTP values and authorization headers are never logged.
 

/// POST JSON. Never log OTPs, tokens, or request bodies.
static Future<ApiResponse> postJson(
  String path,
  Map<String, dynamic> body, {
  bool authenticated = false,
}) async {
  final uri = Uri.parse('$apiBaseUrl$path');
  final http.Response res;

  try {
    res = await http
        .post(
          uri,
          headers: {
            ..._headers(authenticated: authenticated),
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
  } on Exception catch (e) {
    debugPrint('POST $uri failed: $e');
    throw ApiException('Could not reach the server');
  }

  final responseText = utf8.decode(res.bodyBytes);

  if (kDebugMode) {
    debugPrint('POST $uri -> ${res.statusCode}');
    debugPrint(
      'Response: ${responseText.length > 1000 ? responseText.substring(0, 1000) : responseText}',
    );
  }

  Map<String, dynamic> parsed = {};

  try {
    final decoded = jsonDecode(responseText);
    if (decoded is Map) {
      parsed = Map<String, dynamic>.from(decoded);
    }
  } catch (_) {
    // The server may return a non-JSON error page.
  }

  return ApiResponse(res.statusCode, parsed);
}

  /// PUT JSON.
  static Future<ApiResponse> putJson(
    String path,
    Map<String, dynamic> body, {
    bool authenticated = false,
  }) async {
    final uri = Uri.parse('$apiBaseUrl$path');
    final http.Response res;

    try {
      res = await http
          .put(
            uri,
            headers: {
              ..._headers(authenticated: authenticated),
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('PUT $uri failed: $e');
      throw ApiException('Could not reach the server');
    }

    if (kDebugMode) {
      debugPrint('PUT $uri -> ${res.statusCode}');
    }

    return _parseResponse(res);
  }

  /// DELETE JSON.
  static Future<ApiResponse> deleteJson(
    String path, {
    bool authenticated = false,
  }) async {
    final uri = Uri.parse('$apiBaseUrl$path');
    final http.Response res;

    try {
      res = await http
          .delete(
            uri,
            headers: _headers(authenticated: authenticated),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('DELETE $uri failed: $e');
      throw ApiException('Could not reach the server');
    }

    if (kDebugMode) {
      debugPrint('DELETE $uri -> ${res.statusCode}');
    }

    return _parseResponse(res);
  }

  /// Decode a response without throwing for HTTP error statuses.
  static ApiResponse _parseResponse(http.Response res) {
    Map<String, dynamic> parsed = {};

    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));

      if (decoded is Map) {
        parsed = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Some endpoints return an empty response.
    }

    return ApiResponse(res.statusCode, parsed);
  }

  static String? absoluteUrl(dynamic url) {
    final value = url?.toString().trim() ?? '';

    if (value.isEmpty) return null;

    if (value.startsWith('http://') ||
        value.startsWith('https://')) {
      return value;
    }

    return '$apiBaseUrl${value.startsWith('/') ? '' : '/'}$value';
  }

  static List listFrom(dynamic data, List<String> keys) {
    if (data is List) return data;

    if (data is Map) {
      for (final key in keys) {
        if (data[key] is List) {
          return data[key] as List;
        }
      }

      for (final value in data.values) {
        if (value is List) return value;
      }
    }

    return const [];
  }

  static Map<String, dynamic>? firstMap(
    dynamic data,
    List<String> keys,
  ) {
    Map<String, dynamic>? asMap(dynamic value) =>
        value is Map ? Map<String, dynamic>.from(value) : null;

    if (data is List) {
      return data.isEmpty ? null : asMap(data.first);
    }

    if (data is Map) {
      for (final key in keys) {
        final value = data[key];

        if (value is List) {
          return value.isEmpty ? null : asMap(value.first);
        }

        if (value is Map) return asMap(value);
      }

      if (data.containsKey('name') || data.containsKey('_id')) {
        return asMap(data);
      }

      for (final value in data.values) {
        if (value is List) {
          return value.isEmpty ? null : asMap(value.first);
        }
      }
    }

    return null;
  }
}


