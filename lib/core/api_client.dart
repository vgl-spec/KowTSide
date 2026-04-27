import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

/// Singleton Dio instance with auth + CSRF interceptor.
class ApiClient {
  ApiClient._();
  static final ApiClient _instance = ApiClient._();
  static ApiClient get instance => _instance;

  late final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  )..interceptors.add(_AuthInterceptor());
}

class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    if (token != null && token != 'cookie-session') {
      options.headers['Authorization'] = 'Bearer $token';
    }
    final method = options.method.toUpperCase();
    if (method == 'POST' || method == 'PUT' || method == 'PATCH' || method == 'DELETE') {
      final csrfToken = prefs.getString(AppConstants.csrfTokenKey);
      if (csrfToken != null && csrfToken.isNotEmpty) {
        options.headers['X-CSRF-Token'] = csrfToken;
      }
    }
    options.extra['withCredentials'] = true;
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 401 means token expired — callers handle redirect to login
    handler.next(err);
  }
}

/// Convenience getter used throughout the app.
Dio get dio => ApiClient.instance.dio;
