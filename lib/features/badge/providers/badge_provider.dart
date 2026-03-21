import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/badge_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class BadgeProvider extends ChangeNotifier {
  List<BadgeModel> _badges = [];
  bool _isLoading = false;
  String? _error;

  List<BadgeModel> get badges => _badges;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unlockedCount => _badges.where((b) => b.isUnlocked == true).length;

  final ApiClient _api = ApiClient();

  Future<void> loadMyBadges() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.dio.get(ApiConstants.myBadges);
      if (res.data['success'] == true) {
        final List list = res.data['data'] ?? [];
        _badges = list.map((e) => BadgeModel.fromJson(e)).toList();
        _error = null;
      }
    } on DioException catch (e) {
      _error = e.response?.data['error'] ?? 'Gagal memuat badge';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
