import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'constants.dart';
import 'role_utils.dart';

class AuthResult {
  final bool success;
  final String? error;
  const AuthResult.ok() : success = true, error = null;
  const AuthResult.fail(this.error) : success = false;
}

/// Handles login/logout and session persistence.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  Future<AuthResult> login(String username, String password) async {
    try {
      final resp = await dio.post(
        ApiConstants.adminLogin,
        data: {'username': username, 'password': password},
      );
      final rawData = _asMap(resp.data);
      final data = _asMap(rawData['data']).isNotEmpty
          ? _asMap(rawData['data'])
          : _asMap(rawData['result']).isNotEmpty
          ? _asMap(rawData['result'])
          : rawData;

      final prefs = await SharedPreferences.getInstance();
      final token = _asString(data['token']) ?? _asString(data['jwt']);
      final authMode =
          _asString(data['auth_mode']) ??
          (token == null ? 'session' : 'legacy_bearer');
      final csrfToken = _asString(data['csrf_token']);
      final sessionMarker = token?.trim().isNotEmpty == true
          ? token!.trim()
          : 'cookie-session';

      await prefs.setString(AppConstants.tokenKey, sessionMarker);
      await prefs.setString(AppConstants.authModeKey, authMode);
      if (csrfToken != null && csrfToken.isNotEmpty) {
        await prefs.setString(AppConstants.csrfTokenKey, csrfToken);
      } else {
        await prefs.remove(AppConstants.csrfTokenKey);
      }
      await prefs.setString(
        AppConstants.usernameKey,
        _asString(data['username']) ?? username,
      );
      await prefs.setString(
        AppConstants.roleKey,
        normalizeAdminRole(_asString(data['role']) ?? 'teacher'),
      );
      await prefs.setInt(
        AppConstants.adminIdKey,
        _asInt(data['admin_id']) ?? _asInt(data['adminId']) ?? 0,
      );
      return const AuthResult.ok();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return const AuthResult.fail(
          'Cannot reach API at ${ApiConstants.baseUrl}. Start backend or use the production API build.',
        );
      }
      final responseMap = _asMap(e.response?.data);
      final msg =
          _asString(responseMap['error']) ??
          _asString(responseMap['message']) ??
          _asString(_asMap(responseMap['data'])['error']);
      return AuthResult.fail(msg ?? 'Login failed. Check credentials.');
    } catch (_) {
      return const AuthResult.fail('Login failed. Please try again.');
    }
  }

  Future<void> logout() async {
    if (!ApiConstants.frontendOnly) {
      try {
        await dio.post(ApiConstants.adminLogout);
      } catch (_) {
        // Local logout should still clear browser state if the API is offline.
      }
    }
    await ApiClient.instance.clearStoredSession();
  }

  Future<StoredSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey)?.trim();
    if (token == null || token.isEmpty) {
      if (ApiConstants.frontendOnly && ApiConstants.autoLogin) {
        await prefs.setString(AppConstants.tokenKey, 'mock-auto-login-token');
        await prefs.setString(AppConstants.authModeKey, 'legacy_bearer');
        await prefs.setString(AppConstants.usernameKey, 'kow_admin');
        await prefs.setString(AppConstants.roleKey, 'superadmin');
        await prefs.setInt(AppConstants.adminIdKey, 1);
      } else {
        return null;
      }
    }

    final resolvedToken = prefs.getString(AppConstants.tokenKey)?.trim() ?? '';
    final authMode = prefs.getString(AppConstants.authModeKey) ?? '';
    if (resolvedToken != 'cookie-session' && _isTokenExpired(resolvedToken)) {
      await logout();
      return null;
    }

    return StoredSession(
      token: resolvedToken,
      authMode: authMode,
      username: prefs.getString(AppConstants.usernameKey) ?? '',
      role: normalizeAdminRole(
        prefs.getString(AppConstants.roleKey) ?? 'superadmin',
      ),
      adminId: prefs.getInt(AppConstants.adminIdKey) ?? 0,
    );
  }

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payloadPart = parts[1];
      final normalized = base64Url.normalize(payloadPart);
      final payload =
          jsonDecode(utf8.decode(base64Url.decode(normalized)))
              as Map<String, dynamic>;
      final exp = _asInt(payload['exp']);
      if (exp == null) return false;
      final nowEpochSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return nowEpochSeconds >= exp;
    } catch (_) {
      return true;
    }
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return const <String, dynamic>{};
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class StoredSession {
  final String token;
  final String authMode;
  final String username;
  final String role;
  final int adminId;
  const StoredSession({
    required this.token,
    required this.authMode,
    required this.username,
    required this.role,
    required this.adminId,
  });
}
