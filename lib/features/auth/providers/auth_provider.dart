import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../auth/models/user_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isCollector => _user?.isCollector ?? false;

  final ApiClient _api = ApiClient();

  // Auto-login saat app start
  Future<bool> tryAutoLogin() async {
    final token = await _api.getAccessToken();
    if (token == null) return false;
    try {
      final res = await _api.dio.get(ApiConstants.profile);
      if (res.data['success'] == true) {
        _user = UserModel.fromJson(res.data['data']);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final res = await _api.dio.post(ApiConstants.login, data: {
        'email': email,
        'password': password,
      });
      if (res.data['success'] == true) {
        final auth = AuthResponse.fromJson(res.data['data']);
        await _api.saveTokens(auth.accessToken, auth.refreshToken);
        _user = auth.user;
        _error = null;
        notifyListeners();
        return true;
      }
      _error = res.data['error'] ?? 'Login gagal';
    } on DioException catch (e) {
      _error = e.response?.data['error'] ?? 'Koneksi gagal, coba lagi';
    } finally {
      _setLoading(false);
    }
    return false;
  }

  Future<bool> register(String name, String email, String password, String phone) async {
    _setLoading(true);
    try {
      final res = await _api.dio.post(ApiConstants.register, data: {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
      });
      if (res.data['success'] == true) {
        final auth = AuthResponse.fromJson(res.data['data']);
        await _api.saveTokens(auth.accessToken, auth.refreshToken);
        _user = auth.user;
        _error = null;
        notifyListeners();
        return true;
      }
      _error = res.data['error'] ?? 'Registrasi gagal';
    } on DioException catch (e) {
      _error = e.response?.data['error'] ?? 'Koneksi gagal, coba lagi';
    } finally {
      _setLoading(false);
    }
    return false;
  }

  Future<void> refreshProfile() async {
    try {
      final res = await _api.dio.get(ApiConstants.profile);
      if (res.data['success'] == true) {
        _user = UserModel.fromJson(res.data['data']);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> logout() async {
    await _api.clearTokens();
    _user = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
