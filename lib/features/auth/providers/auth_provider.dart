import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/user_model.dart';
import '../models/auth_response.dart' as auth_models;  // ✅ Add alias

class AuthProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  UserModel? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Check if user is authenticated on app start
  Future<void> checkAuthStatus() async {
    print('[AUTH] Checking auth status...');
    
    final token = await _apiClient.getToken();
    print('[AUTH] Token exists: ${token != null}');

    if (token != null && token.isNotEmpty) {
      try {
        print('[AUTH] Fetching user profile...');
        await getProfile();
        
        if (_user != null) {
          _isAuthenticated = true;
          print('[AUTH] ✓ User authenticated: ${_user!.email} (${_user!.role})');
        } else {
          print('[AUTH] ✗ Profile fetch returned null');
          _isAuthenticated = false;
          await _apiClient.clearToken();
        }
      } catch (e) {
        print('[AUTH] ✗ Token invalid or expired: $e');
        _isAuthenticated = false;
        _user = null;
        await _apiClient.clearToken();
      }
    } else {
      print('[AUTH] No token found');
      _isAuthenticated = false;
      _user = null;
    }

    notifyListeners();
  }

  /// Login user
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('[AUTH] Attempting login: $email');

      final response = await _apiClient.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      print('[AUTH] Login response: ${response.statusCode}');

      if (response.statusCode == 200) {
        // ✅ Use alias
        final authResponse = auth_models.AuthResponse.fromJson(response.data['data']);
        
        _user = authResponse.profile;
        await _apiClient.saveToken(authResponse.token);
        _isAuthenticated = true;
        
        print('[AUTH] ✓ Login success!');
        print('[AUTH] User: ${_user!.name}');
        print('[AUTH] Email: ${_user!.email}');
        print('[AUTH] Role: ${_user!.role}');
        
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = response.data['error'] ?? 'Login failed';
      print('[AUTH] ✗ Login failed: $_error');
    } catch (e) {
      _error = 'Login error';
      print('[AUTH] ✗ Login exception: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Register user
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('[AUTH] Attempting registration: $email');

      final response = await _apiClient.post(
        ApiConstants.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'phone': phone ?? '',
          'role': 'user',
        },
      );

      print('[AUTH] Register response: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        // ✅ Use alias
        final authResponse = auth_models.AuthResponse.fromJson(response.data['data']);
        
        _user = authResponse.profile;
        await _apiClient.saveToken(authResponse.token);
        _isAuthenticated = true;
        
        print('[AUTH] ✓ Registration success: ${_user!.email}');
        
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = response.data['error'] ?? 'Registration failed';
      print('[AUTH] ✗ Registration failed: $_error');
    } catch (e) {
      _error = 'Registration error';
      print('[AUTH] ✗ Registration exception: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Get user profile
  Future<void> getProfile() async {
    try {
      print('[AUTH] Fetching profile...');
      
      final response = await _apiClient.get(ApiConstants.profile);

      print('[AUTH] Profile response: ${response.statusCode}');

      if (response.statusCode == 200) {
        _user = UserModel.fromJson(response.data['data']);
        print('[AUTH] ✓ Profile loaded: ${_user!.email} (${_user!.role})');
        notifyListeners();
      } else {
        print('[AUTH] ✗ Profile fetch failed: ${response.statusCode}');
        throw Exception('Failed to fetch profile');
      }
    } catch (e) {
      print('[AUTH] ✗ Profile exception: $e');
      rethrow;
    }
  }

  /// Logout user
  Future<void> logout() async {
    print('[AUTH] Logging out...');
    
    // Clear token
    await _apiClient.clearToken();
    
    // Clear user data
    _user = null;
    _isAuthenticated = false;
    _error = null;
    
    print('[AUTH] ✓ Logged out successfully');
    
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}