import 'dart:async';
import 'package:dio/dio.dart';
import 'package:dio/browser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import 'websocket_service.dart';

/// Singleton Dio instance with auth + CSRF interceptor.
class ApiClient {
  ApiClient._();
  static final ApiClient _instance = ApiClient._();
  static ApiClient get instance => _instance;

  final _unauthorizedController = StreamController<void>.broadcast();
  Stream<void> get unauthorizedEvents => _unauthorizedController.stream;

  bool _isClearingSession = false;

  late final Dio dio = _createDio();

  Dio _createDio() {
    final client = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    (client.httpClientAdapter as BrowserHttpClientAdapter).withCredentials =
        true;
    client.interceptors.add(_AuthInterceptor(this));
    return client;
  }

  Future<void> clearStoredSession() async {
    if (_isClearingSession) return;
    _isClearingSession = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.tokenKey);
      await prefs.remove(AppConstants.csrfTokenKey);
      await prefs.remove(AppConstants.authModeKey);
      await prefs.remove(AppConstants.usernameKey);
      await prefs.remove(AppConstants.roleKey);
      await prefs.remove(AppConstants.adminIdKey);
      WebSocketService.instance.disconnect();
      _unauthorizedController.add(null);
    } finally {
      _isClearingSession = false;
    }
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._client);

  final ApiClient _client;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey)?.trim();
    if (token != null && token.isNotEmpty && token != 'cookie-session') {
      options.headers['Authorization'] = 'Bearer $token';
    }
    final csrfToken = prefs.getString(AppConstants.csrfTokenKey)?.trim();
    if (csrfToken != null && csrfToken.isNotEmpty) {
      options.headers['X-CSRF-Token'] = csrfToken;
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await _client.clearStoredSession();
    }
    handler.next(err);
  }
}

/// Convenience getter used throughout the app.
Dio get dio => ApiClient.instance.dio;
