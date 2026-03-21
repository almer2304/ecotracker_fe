import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../pickup/models/pickup_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class CollectorProvider extends ChangeNotifier {
  PickupModel? _assignedPickup;
  List<WasteCategory> _categories = [];
  bool _isLoading = false;
  bool _isUpdatingStatus = false;
  String? _error;

  PickupModel? get assignedPickup => _assignedPickup;
  List<WasteCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isUpdatingStatus => _isUpdatingStatus;
  String? get error => _error;

  final ApiClient _api = ApiClient();

  Future<void> loadAssignedPickup() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.dio.get(ApiConstants.collectorAssigned);
      if (res.data['success'] == true) {
        final data = res.data['data'];
        _assignedPickup = data != null ? PickupModel.fromJson(data) : null;
        _error = null;
      }
    } on DioException catch (e) {
      _error = e.response?.data['error'] ?? 'Gagal memuat pickup';
    } finally {
      _isLoading = false;
      notifyListeners();
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

  Future<bool> updateStatus(bool isOnline) async {
    _isUpdatingStatus = true;
    notifyListeners();
    try {
      final res = await _api.dio.put(ApiConstants.collectorStatus, data: {'is_online': isOnline});
      if (res.data['success'] == true) return true;
    } on DioException catch (_) {}
    finally {
      _isUpdatingStatus = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> updateLocation(double lat, double lon) async {
    try {
      final res = await _api.dio.put(ApiConstants.collectorLocation, data: {'lat': lat, 'lon': lon});
      return res.data['success'] == true;
    } catch (_) { return false; }
  }

  Future<bool> acceptPickup(String pickupId) async {
    try {
      final res = await _api.dio.post('${ApiConstants.pickups.replaceAll('/pickups', '/collector/pickups')}/$pickupId/accept');
      if (res.data['success'] == true) {
        await loadAssignedPickup();
        return true;
      }
    } on DioException catch (e) {
      _error = e.response?.data['error'] ?? 'Gagal menerima pickup';
      notifyListeners();
    }
    return false;
  }

  Future<bool> startPickup(String pickupId) async {
    try {
      final res = await _api.dio.post('/collector/pickups/$pickupId/start');
      if (res.data['success'] == true) { await loadAssignedPickup(); return true; }
    } on DioException catch (e) {
      _error = e.response?.data['error'] ?? 'Gagal memulai pickup';
      notifyListeners();
    }
    return false;
  }

  Future<bool> arriveAtPickup(String pickupId) async {
    try {
      final res = await _api.dio.post('/collector/pickups/$pickupId/arrive');
      if (res.data['success'] == true) { await loadAssignedPickup(); return true; }
    } on DioException catch (e) {
      _error = e.response?.data['error'] ?? 'Gagal update status tiba';
      notifyListeners();
    }
    return false;
  }

  Future<bool> completePickup(String pickupId, List<Map<String, dynamic>> items) async {
    try {
      final res = await _api.dio.post('/collector/pickups/$pickupId/complete', data: {'items': items});
      if (res.data['success'] == true) {
        _assignedPickup = null;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      _error = e.response?.data['error'] ?? 'Gagal menyelesaikan pickup';
      notifyListeners();
    }
    return false;
  }

  void clearError() { _error = null; notifyListeners(); }
}
