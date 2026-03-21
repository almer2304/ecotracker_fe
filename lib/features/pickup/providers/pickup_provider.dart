import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/pickup_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class PickupProvider extends ChangeNotifier {
  List<PickupModel> _pickups = [];
  List<WasteCategory> _categories = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  int _total = 0;
  int _page = 1;
  bool _hasMore = true;

  List<PickupModel> get pickups => _pickups;
  List<WasteCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  bool get hasMore => _hasMore;

  final ApiClient _api = ApiClient();

  Future<void> loadMyPickups({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _hasMore = true;
      _pickups = [];
    }
    if (!_hasMore || _isLoading) return;
    _setLoading(true);
    try {
      final res = await _api.dio.get(ApiConstants.myPickups, queryParameters: {
        'page': _page,
        'limit': 20,
      });
      if (res.data['success'] == true) {
        final data = res.data['data'];
        final List list = data['data'] ?? [];
        final newPickups = list.map((e) => PickupModel.fromJson(e)).toList();
        _total = data['total'] ?? 0;
        _pickups = refresh ? newPickups : [..._pickups, ...newPickups];
        _hasMore = _pickups.length < _total;
        _page++;
        _error = null;
      }
    } on DioException catch (e) {
      _error = e.response?.data['error'] ?? 'Gagal memuat pickup';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadCategories() async {
    if (_categories.isNotEmpty) return;
    try {
      final res = await _api.dio.get(ApiConstants.categories);
      if (res.data['success'] == true) {
        final List list = res.data['data'] ?? [];
        _categories = list.map((e) => WasteCategory.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<PickupModel?> createPickup({
    required String address,
    required double lat,
    required double lon,
    String? notes,
    String? photoPath,
    void Function(double)? onProgress,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      final formData = FormData.fromMap({
        'address': address,
        'lat': lat.toString(),
        'lon': lon.toString(),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (photoPath != null)
          'photo': await MultipartFile.fromFile(photoPath, filename: 'photo.jpg'),
      });

      final res = await _api.dio.post(
        ApiConstants.pickups,
        data: formData,
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            onProgress(sent / total);
          }
        },
      );

      if (res.data['success'] == true) {
        final pickup = PickupModel.fromJson(res.data['data']);
        _pickups.insert(0, pickup);
        notifyListeners();
        return pickup;
      }
      _error = res.data['error'] ?? 'Gagal membuat pickup';
    } on DioException catch (e) {
      _error = e.response?.data['error'] ?? 'Koneksi gagal';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
    return null;
  }

  Future<PickupModel?> getPickupDetail(String id) async {
    try {
      final res = await _api.dio.get('${ApiConstants.pickups}/$id');
      if (res.data['success'] == true) {
        return PickupModel.fromJson(res.data['data']);
      }
    } catch (_) {}
    return null;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
