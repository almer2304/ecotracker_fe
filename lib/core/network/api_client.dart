import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onError: _onError,
    ));
  }

  // Inject token ke setiap request
  Future<void> _onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: ApiConstants.keyAccessToken);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  // Handle 401 → auto refresh token
  Future<void> _onError(DioException error, ErrorInterceptorHandler handler) async {
    if (error.response?.statusCode == 401) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        // Ulangi request dengan token baru
        final token = await _storage.read(key: ApiConstants.keyAccessToken);
        error.requestOptions.headers['Authorization'] = 'Bearer $token';
        final response = await _dio.fetch(error.requestOptions);
        handler.resolve(response);
        return;
      }
      // Refresh gagal → clear token
      await clearTokens();
    }
    handler.next(error);
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: ApiConstants.keyRefreshToken);
      if (refreshToken == null) return false;

      final response = await Dio().post(
        '${ApiConstants.baseUrl}${ApiConstants.refresh}',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        await _storage.write(key: ApiConstants.keyAccessToken, value: data['access_token']);
        await _storage.write(key: ApiConstants.keyRefreshToken, value: data['refresh_token']);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: ApiConstants.keyAccessToken, value: accessToken);
    await _storage.write(key: ApiConstants.keyRefreshToken, value: refreshToken);
  }

  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }

  Future<String?> getAccessToken() => _storage.read(key: ApiConstants.keyAccessToken);

  Dio get dio => _dio;
}
