class PickupModel {
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

  PickupModel({
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
  });

  factory PickupModel.fromJson(Map<String, dynamic> json) {
    return PickupModel(
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
    );
  }
}
