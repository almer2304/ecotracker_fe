class PickupWithDistanceModel {
  final String id;
  final String userId;
  final String? collectorId;
  final String status;
  final String address;
  final double latitude;
  final double longitude;
  final String? photoUrl;
  final String? notes;
  final String createdAt;
  final double distanceKm;

  PickupWithDistanceModel({
    required this.id,
    required this.userId,
    this.collectorId,
    required this.status,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.photoUrl,
    this.notes,
    required this.createdAt,
    required this.distanceKm,
  });

  factory PickupWithDistanceModel.fromJson(Map<String, dynamic> json) {
    return PickupWithDistanceModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      collectorId: json['collector_id'] as String?,
      status: json['status'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      photoUrl: json['photo_url'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String,
      distanceKm: (json['distance_km'] as num).toDouble(),
    );
  }

  /// ✅ Get rounded distance text for consistent display
  String getDistanceText() {
    // Round to 1 decimal place for consistency
    final rounded = (distanceKm * 10).round() / 10;
    
    if (rounded < 1) {
      // Show in meters if < 1km
      final meters = (rounded * 1000).round();
      return '$meters m';
    }
    
    // Show in km with 1 decimal
    return '${rounded.toStringAsFixed(1)} km';
  }
}