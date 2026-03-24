import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../core/constants/api_constants.dart';

// Tipe pesan WebSocket (harus sama dengan backend)
class WsMessageType {
  static const String newPickup         = 'new_pickup';
  static const String pickupAssigned    = 'pickup_assigned';
  static const String pickupAccepted    = 'pickup_accepted';
  static const String pickupStarted     = 'pickup_started';
  static const String pickupArrived     = 'pickup_arrived';
  static const String pickupCompleted   = 'pickup_completed';
  static const String collectorLocation = 'collector_location';
  static const String pong              = 'pong';
  static const String ping              = 'ping';
  static const String collectorOnline   = 'collector_online';
  static const String collectorOffline  = 'collector_offline';
  static const String subscribePickup   = 'subscribe_pickup';
}

class WsMessage {
  final String type;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  WsMessage({required this.type, this.data, required this.timestamp});

  factory WsMessage.fromJson(Map<String, dynamic> json) {
    return WsMessage(
      type: json['type'] ?? '',
      data: json['data'] != null
          ? (json['data'] is Map ? Map<String, dynamic>.from(json['data']) : null)
          : null,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

// WebSocketService mengelola koneksi WS ke backend
class WebSocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  bool _isConnected = false;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  // Stream controllers untuk berbagai event
  final _newPickupController     = StreamController<Map<String, dynamic>>.broadcast();
  final _pickupStatusController  = StreamController<Map<String, dynamic>>.broadcast();
  final _locationController      = StreamController<Map<String, dynamic>>.broadcast();

  // Streams yang bisa di-listen oleh UI
  Stream<Map<String, dynamic>> get onNewPickup     => _newPickupController.stream;
  Stream<Map<String, dynamic>> get onPickupStatus  => _pickupStatusController.stream;
  Stream<Map<String, dynamic>> get onLocation      => _locationController.stream;

  bool get isConnected => _isConnected;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Connect ke WebSocket server
  Future<void> connect() async {
    if (_isConnected || _isConnecting) return;

    _isConnecting = true;
    notifyListeners();

    try {
      final token = await _storage.read(key: ApiConstants.keyAccessToken);
      if (token == null) {
        debugPrint('[WS] Tidak ada token, skip connect');
        _isConnecting = false;
        return;
      }

      // URL WebSocket dengan token
      final wsUrl = ApiConstants.baseUrl
          .replaceFirst('http://', 'ws://')
          .replaceFirst('https://', 'wss://')
          .replaceFirst('/api/v1', '');

      final uri = Uri.parse('$wsUrl/ws?token=$token');
      debugPrint('[WS] Connecting ke $wsUrl/ws');

      _channel = WebSocketChannel.connect(uri);

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      notifyListeners();

      // Start ping timer
      _startPing();

      debugPrint('[WS] ✅ Terhubung ke WebSocket');
    } catch (e) {
      debugPrint('[WS] ❌ Gagal connect: $e');
      _isConnected = false;
      _isConnecting = false;
      notifyListeners();
      _scheduleReconnect();
    }
  }

  // Disconnect dari WebSocket
  void disconnect() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _reconnectAttempts = 0;
    notifyListeners();
    debugPrint('[WS] Disconnected');
  }

  // Kirim pesan ke server
  void send(String type, [Map<String, dynamic>? data]) {
    if (!_isConnected || _channel == null) return;

    final msg = {
      'type': type,
      'timestamp': DateTime.now().toIso8601String(),
      if (data != null) 'data': data,
    };

    try {
      _channel!.sink.add(jsonEncode(msg));
    } catch (e) {
      debugPrint('[WS] Error kirim pesan: $e');
    }
  }

  // Subscribe ke update pickup tertentu
  void subscribePickup(String pickupId) {
    send(WsMessageType.subscribePickup, {'pickup_id': pickupId});
    debugPrint('[WS] Subscribe ke pickup $pickupId');
  }

  // Set collector online/offline via WS
  void setCollectorOnline(bool isOnline) {
    send(isOnline ? WsMessageType.collectorOnline : WsMessageType.collectorOffline);
  }

  // Handle pesan masuk dari server
  void _onMessage(dynamic message) {
    try {
      // Handle multiple messages dalam satu frame (dipisah newline)
      final messages = message.toString().trim().split('\n');
      for (final msgStr in messages) {
        if (msgStr.trim().isEmpty) continue;
        final json = jsonDecode(msgStr) as Map<String, dynamic>;
        final wsMsg = WsMessage.fromJson(json);
        _routeMessage(wsMsg);
      }
    } catch (e) {
      debugPrint('[WS] Error parse pesan: $e');
    }
  }

  // Route pesan ke stream yang tepat
  void _routeMessage(WsMessage msg) {
    debugPrint('[WS] Pesan masuk: ${msg.type}');

    switch (msg.type) {
      case WsMessageType.newPickup:
        // Ada pickup baru untuk collector
        if (msg.data != null) {
          _newPickupController.add(msg.data!);
        }
        break;

      case WsMessageType.pickupAssigned:
      case WsMessageType.pickupAccepted:
      case WsMessageType.pickupStarted:
      case WsMessageType.pickupArrived:
      case WsMessageType.pickupCompleted:
        // Update status pickup
        if (msg.data != null) {
          final data = Map<String, dynamic>.from(msg.data!);
          data['type'] = msg.type; // tambahkan type untuk identifikasi
          _pickupStatusController.add(data);
        }
        break;

      case WsMessageType.collectorLocation:
        // Update lokasi collector
        if (msg.data != null) {
          _locationController.add(msg.data!);
        }
        break;

      case WsMessageType.pong:
        debugPrint('[WS] Pong diterima');
        break;
    }
  }

  void _onError(dynamic error) {
    debugPrint('[WS] Error: $error');
    _isConnected = false;
    notifyListeners();
    _scheduleReconnect();
  }

  void _onDone() {
    debugPrint('[WS] Koneksi ditutup');
    _isConnected = false;
    notifyListeners();
    _scheduleReconnect();
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      send(WsMessageType.ping);
    });
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('[WS] Maks reconnect tercapai, berhenti');
      return;
    }

    _reconnectTimer?.cancel();
    final delay = Duration(seconds: (2 * (_reconnectAttempts + 1)).clamp(2, 30));
    _reconnectAttempts++;

    debugPrint('[WS] Reconnect dalam ${delay.inSeconds}s (attempt $_reconnectAttempts)');
    _reconnectTimer = Timer(delay, connect);
  }

  @override
  void dispose() {
    disconnect();
    _newPickupController.close();
    _pickupStatusController.close();
    _locationController.close();
    super.dispose();
  }
}
