import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/pickup_model.dart';

class PickupProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  List<PickupModel> _pickups = [];
  bool _isLoading = false;
  String? _error;

  List<PickupModel> get pickups => _pickups;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> createPickup({
    required String address,
    required double latitude,
    required double longitude,
    String? notes,
    String? photoPath,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      FormData formData = FormData.fromMap({
        'address': address,
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (photoPath != null)
          'photo': await MultipartFile.fromFile(
            photoPath,
            filename: photoPath.split('/').last,
          ),
      });

      final response = await _apiClient.postFormData(
        ApiConstants.pickups,
        formData,
      );

      _isLoading = false;
      notifyListeners();
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchMyPickups();
        return true;
      }
      
      _error = response.data['error'] ?? 'Failed to create pickup';
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchMyPickups() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiConstants.myPickups);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] as List<dynamic>;
        _pickups = data.map((json) => PickupModel.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
