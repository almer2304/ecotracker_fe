import 'dart:async';
import 'package:flutter/material.dart';
import '../network/websocket_service.dart';

// WsPickupProvider mengelola notifikasi pickup real-time
// Digunakan di Collector Dashboard untuk terima pickup baru
// Digunakan di User My Pickups untuk update status
class WsPickupProvider extends ChangeNotifier {
  final WebSocketService _wsService;
  StreamSubscription? _newPickupSub;
  StreamSubscription? _statusSub;

  // Pickup baru yang belum dilihat collector (badge notification)
  int _newPickupCount = 0;
  Map<String, dynamic>? _latestNewPickup;

  // Status update terbaru per pickup
  final Map<String, String> _pickupStatuses = {};

  int get newPickupCount => _newPickupCount;
  Map<String, dynamic>? get latestNewPickup => _latestNewPickup;

  WsPickupProvider(this._wsService) {
    _listenToEvents();
  }

  void _listenToEvents() {
    // Listen ke pickup baru (untuk collector)
    _newPickupSub = _wsService.onNewPickup.listen((data) {
      _latestNewPickup = data;
      _newPickupCount++;
      notifyListeners();
      debugPrint('[WsPickup] Pickup baru: ${data['pickup_id']}');
    });

    // Listen ke status update (untuk user)
    _statusSub = _wsService.onPickupStatus.listen((data) {
      final pickupId = data['pickup_id'] as String?;
      final status = data['status'] as String?;
      if (pickupId != null && status != null) {
        _pickupStatuses[pickupId] = status;
        notifyListeners();
        debugPrint('[WsPickup] Status update: $pickupId → $status');
      }
    });
  }

  // Ambil status terbaru untuk pickup tertentu (jika ada dari WS)
  String? getRealtimeStatus(String pickupId) {
    return _pickupStatuses[pickupId];
  }

  // Subscribe ke update pickup tertentu
  void subscribeToPickup(String pickupId) {
    _wsService.subscribePickup(pickupId);
  }

  // Clear badge count setelah dilihat
  void clearNewPickupCount() {
    _newPickupCount = 0;
    _latestNewPickup = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _newPickupSub?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }
}
