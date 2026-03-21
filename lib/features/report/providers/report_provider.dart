import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/report_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class ReportProvider extends ChangeNotifier {
  List<ReportModel> _reports = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;
  int _total = 0;

  List<ReportModel> get reports => _reports;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  bool get hasMore => _hasMore;

  final ApiClient _api = ApiClient();

  Future<void> loadMyReports({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _hasMore = true;
      _reports = [];
    }
    if (!_hasMore || _isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.dio.get(ApiConstants.myReports,
          queryParameters: {'page': _page, 'limit': 20});
      if (res.data['success'] == true) {
        final data = res.data['data'];
        final List list = data['data'] ?? [];
        final newItems = list.map((e) => ReportModel.fromJson(e)).toList();
        _total = data['total'] ?? 0;
        _reports = refresh ? newItems : [..._reports, ...newItems];
        _hasMore = _reports.length < _total;
        _page++;
        _error = null;
      }
    } on DioException catch (e) {
      _error = e.response?.data['error'] ?? 'Gagal memuat laporan';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createReport({
    required String title,
    required String description,
    required String address,
    required double lat,
    required double lon,
    required String severity,
    List<String> photoPaths = const [],
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      final fields = <String, dynamic>{
        'title': title,
        'description': description,
        'address': address,
        'lat': lat.toString(),
        'lon': lon.toString(),
        'severity': severity,
      };

      for (int i = 0; i < photoPaths.length; i++) {
        fields['photos'] = await MultipartFile.fromFile(photoPaths[i], filename: 'photo_$i.jpg');
      }

      final res = await _api.dio.post(
        ApiConstants.reports,
        data: FormData.fromMap(fields),
      );

      if (res.data['success'] == true) {
        final report = ReportModel.fromJson(res.data['data']);
        _reports.insert(0, report);
        notifyListeners();
        return true;
      }
      _error = res.data['error'] ?? 'Gagal membuat laporan';
    } on DioException catch (e) {
      _error = e.response?.data['error'] ?? 'Koneksi gagal';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
    return false;
  }
}
