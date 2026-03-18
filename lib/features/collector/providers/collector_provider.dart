import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/pickup_with_distance_model.dart';
import '../../pickup/models/pickup_model.dart';
import 'dart:async';

class CollectorProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  List<PickupWithDistanceModel> _pendingPickups = [];
  List<PickupModel> _myTasks = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  
  // Pagination state
  int _totalPickups = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  
  // Cache
  DateTime? _lastFetch;
  static const _cacheValidDuration = Duration(minutes: 2);
  
  // Location cache for consistency
  Position? _cachedPosition;
  DateTime? _cachedPositionTime;
  static const _locationCacheDuration = Duration(minutes: 5);

  // Getters
  List<PickupWithDistanceModel> get pendingPickups => _pendingPickups;
  List<PickupModel> get myTasks => _myTasks;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  int get totalPickups => _totalPickups;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get hasMore => _currentPage < _totalPages;

  /// Get user location with caching for consistency
  Future<Position> _getUserLocation() async {
    print('[COLLECTOR] Getting user location...');
    
    // Check if cached position is still valid
    if (_cachedPosition != null && 
        _cachedPositionTime != null &&
        DateTime.now().difference(_cachedPositionTime!) < _locationCacheDuration) {
      print('[COLLECTOR] Using cached position: ${_cachedPosition!.latitude}, ${_cachedPosition!.longitude}');
      print('[COLLECTOR] Cached ${DateTime.now().difference(_cachedPositionTime!).inSeconds}s ago');
      return _cachedPosition!;
    }

    // Get fresh location
    try {
      var status = await Permission.location.status;
      
      if (!status.isGranted) {
        print('[COLLECTOR] Requesting location permission...');
        status = await Permission.location.request();
      }
      
      if (status.isGranted) {
        print('[COLLECTOR] Getting fresh location...');
        
        // Try last known location first (faster & more stable)
        Position? position = await Geolocator.getLastKnownPosition();
        
        if (position != null) {
          final age = DateTime.now().difference(position.timestamp);
          if (age.inMinutes < 10) {
            print('[COLLECTOR] Using last known position (${age.inMinutes}min old)');
            _cachedPosition = position;
            _cachedPositionTime = DateTime.now();
            return position;
          }
        }
        
        // Get current position if last known is too old
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 5),
        ).timeout(
          const Duration(seconds: 8),
        );
        
        print('[COLLECTOR] Got fresh position: ${position.latitude}, ${position.longitude}');
        print('[COLLECTOR] Accuracy: ${position.accuracy}m');
        
        // Cache the position
        _cachedPosition = position;
        _cachedPositionTime = DateTime.now();
        
        return position;
      }
    } catch (e) {
      print('[COLLECTOR] Location error: $e');
    }

    // Fallback to default Jakarta location
    print('[COLLECTOR] Using default location: Jakarta');
    final defaultPosition = Position(
      latitude: -6.2088,
      longitude: 106.8456,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
    
    // Cache default position too
    _cachedPosition = defaultPosition;
    _cachedPositionTime = DateTime.now();
    
    return defaultPosition;
  }

  /// Fetch pending pickups with pagination and infinite scroll support
  Future<bool> fetchPendingPickups({
    int page = 1,
    int limit = 20,
    bool append = false,
    bool forceRefresh = false,
  }) async {
    // Check cache (only for first page, not append)
    if (!forceRefresh && 
        !append && 
        page == 1 && 
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheValidDuration &&
        _pendingPickups.isNotEmpty) {
      print('[COLLECTOR] Using cached data (${_pendingPickups.length} pickups)');
      return hasMore;
    }

    // Set loading state
    if (append) {
      _isLoadingMore = true;
    } else {
      _isLoading = true;
      _error = null;
    }
    notifyListeners();

    try {
      print('[COLLECTOR] Fetching page $page (limit: $limit, append: $append)');
      
      // Get location with caching
      final position = await _getUserLocation();
      final lat = position.latitude;
      final lon = position.longitude;

      print('[COLLECTOR] Using location: $lat, $lon');
      print('[COLLECTOR] Calling API...');
      
      final response = await _apiClient.get(
        ApiConstants.collectorPendingPickups,
        queryParameters: {
          'lat': lat.toString(),
          'lon': lon.toString(),
          'page': page.toString(),
          'limit': limit.toString(),
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('[COLLECTOR] API timeout');
          throw TimeoutException('API timeout');
        },
      );

      print('[COLLECTOR] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data['data'];
        
        // Handle response structure
        List<dynamic> pickupsData;
        Map<String, dynamic>? pagination;
        
        if (responseData is List) {
          // Old API format (no pagination)
          print('[COLLECTOR] API returned list (no pagination)');
          pickupsData = responseData;
          _totalPickups = pickupsData.length;
          _currentPage = 1;
          _totalPages = 1;
        } else if (responseData is Map<String, dynamic>) {
          // New API format (with pagination)
          print('[COLLECTOR] API returned paginated data');
          pickupsData = responseData['pickups'] as List? ?? [];
          pagination = responseData['pagination'] as Map<String, dynamic>?;
          
          if (pagination != null) {
            _totalPickups = pagination['total'] as int? ?? 0;
            _currentPage = pagination['page'] as int? ?? page;
            _totalPages = pagination['total_pages'] as int? ?? 1;
            print('[COLLECTOR] Pagination: page $_currentPage/$_totalPages, total: $_totalPickups');
          }
        } else {
          print('[COLLECTOR] Unexpected response format');
          pickupsData = [];
        }

        // Parse pickups
        final newPickups = pickupsData
            .map((json) => PickupWithDistanceModel.fromJson(json as Map<String, dynamic>))
            .toList();

        print('[COLLECTOR] Parsed ${newPickups.length} pickups');

        // Update list
        if (append) {
          _pendingPickups.addAll(newPickups);
          print('[COLLECTOR] Appended pickups. Total now: ${_pendingPickups.length}');
        } else {
          _pendingPickups = newPickups;
          print('[COLLECTOR] Replaced pickups. Total: ${_pendingPickups.length}');
        }

        // Update cache timestamp
        _lastFetch = DateTime.now();

        return hasMore;
      } else {
        print('[COLLECTOR] API error: ${response.statusCode}');
        _error = 'API_ERROR';
        if (!append) {
          _pendingPickups = [];
        }
        return false;
      }
    } on TimeoutException catch (e) {
      print('[COLLECTOR ERROR] Timeout: $e');
      _error = 'TIMEOUT';
      if (!append) {
        _pendingPickups = [];
      }
      return false;
    } catch (e, stackTrace) {
      print('[COLLECTOR ERROR] Exception: $e');
      print('[COLLECTOR ERROR] Stack trace: $stackTrace');
      _error = 'FETCH_ERROR';
      if (!append) {
        _pendingPickups = [];
      }
      return false;
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
      print('[COLLECTOR] Fetch completed. Total pickups: ${_pendingPickups.length}, HasMore: $hasMore');
    }
  }

  /// Load next page (for infinite scroll)
  Future<bool> loadMorePickups() async {
    if (!hasMore || _isLoadingMore) {
      print('[COLLECTOR] Cannot load more (hasMore: $hasMore, isLoadingMore: $_isLoadingMore)');
      return false;
    }

    final nextPage = _currentPage + 1;
    print('[COLLECTOR] Loading page $nextPage...');
    
    return await fetchPendingPickups(
      page: nextPage,
      limit: 20,
      append: true,
    );
  }

  /// Refresh pickups (pull-to-refresh)
  Future<void> refreshPickups() async {
    print('[COLLECTOR] Refreshing pickups...');
    _currentPage = 1;
    _lastFetch = null; // Clear data cache
    
    // Clear location cache to get fresh GPS
    _cachedPosition = null;
    _cachedPositionTime = null;
    print('[COLLECTOR] Location cache cleared - will get fresh GPS');
    
    await fetchPendingPickups(
      page: 1,
      limit: 20,
      append: false,
      forceRefresh: true,
    );
  }

  /// Fetch my tasks (pickups assigned to me)
  Future<void> fetchMyTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('[COLLECTOR] Fetching my tasks...');
      
      final response = await _apiClient.get(ApiConstants.collectorMyTasks);

      print('[COLLECTOR] My tasks response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data['data'];
        
        if (data is List) {
          _myTasks = data
              .map((json) => PickupModel.fromJson(json as Map<String, dynamic>))
              .toList();
          print('[COLLECTOR] Loaded ${_myTasks.length} tasks');
        } else {
          _myTasks = [];
          print('[COLLECTOR] No tasks found');
        }
      } else {
        print('[COLLECTOR] API error: ${response.statusCode}');
        _myTasks = [];
      }
    } catch (e) {
      print('[COLLECTOR ERROR] Fetch tasks: $e');
      _error = 'FETCH_TASKS_ERROR';
      _myTasks = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Take a pickup task
  Future<bool> takeTask(String pickupId) async {
    try {
      print('[COLLECTOR] Taking task: $pickupId');
      
      final response = await _apiClient.post(
        ApiConstants.collectorTakeTask(pickupId),
      );

      print('[COLLECTOR] Take task response: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('[COLLECTOR] Task taken successfully');
        // Invalidate caches
        _lastFetch = null;
        return true;
      }

      print('[COLLECTOR] Take task failed: ${response.data}');
      _error = response.data['error'] ?? 'Failed to take task';
      return false;
    } catch (e) {
      print('[COLLECTOR ERROR] Take task: $e');
      _error = 'TAKE_TASK_ERROR';
      return false;
    }
  }

  /// Complete a pickup task
  Future<Map<String, dynamic>?> completeTask(
    String pickupId,
    List<Map<String, dynamic>> items,
  ) async {
    try {
      print('[COLLECTOR] Completing task: $pickupId');
      print('[COLLECTOR] Items: $items');
      
      final response = await _apiClient.post(
        ApiConstants.collectorCompleteTask(pickupId),
        data: {'items': items},
      );

      print('[COLLECTOR] Complete task response: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('[COLLECTOR] Task completed successfully');
        print('[COLLECTOR] Response: ${response.data}');
        return response.data['data'] as Map<String, dynamic>;
      }

      print('[COLLECTOR] Complete task failed: ${response.data}');
      _error = response.data['error'] ?? 'Failed to complete task';
      return null;
    } catch (e) {
      print('[COLLECTOR ERROR] Complete task: $e');
      _error = 'COMPLETE_TASK_ERROR';
      return null;
    }
  }

  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear all caches (data + location)
  void clearCache() {
    _lastFetch = null;
    _cachedPosition = null;
    _cachedPositionTime = null;
    print('[COLLECTOR] All caches cleared');
  }

  /// Clear only location cache (force fresh GPS next fetch)
  void clearLocationCache() {
    _cachedPosition = null;
    _cachedPositionTime = null;
    print('[COLLECTOR] Location cache cleared');
  }
}