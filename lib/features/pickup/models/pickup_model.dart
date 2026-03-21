class PickupModel {
  final String id;
  final String userId;
  final String? collectorId;
  final String address;
  final double lat;
  final double lon;
  final String? photoUrl;
  final String? notes;
  final String status;
  final int reassignmentCount;
  final DateTime? assignedAt;
  final DateTime? assignmentTimeout;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? arrivedAt;
  final DateTime? completedAt;
  final double? totalWeight;
  final int? totalPointsAwarded;
  final DateTime createdAt;
  final CollectorInfo? collector;
  final UserInfo? user;
  final List<PickupItem> items;

  PickupModel({
    required this.id,
    required this.userId,
    this.collectorId,
    required this.address,
    required this.lat,
    required this.lon,
    this.photoUrl,
    this.notes,
    required this.status,
    this.reassignmentCount = 0,
    this.assignedAt,
    this.assignmentTimeout,
    this.acceptedAt,
    this.startedAt,
    this.arrivedAt,
    this.completedAt,
    this.totalWeight,
    this.totalPointsAwarded,
    required this.createdAt,
    this.collector,
    this.user,
    this.items = const [],
  });

  bool get isPending => status == 'pending';
  bool get isAssigned => status == 'assigned' || status == 'accepted';
  bool get isInProgress => status == 'in_progress';
  bool get isArrived => status == 'arrived';
  bool get isCompleted => status == 'completed';
  bool get isActive => ['assigned', 'accepted', 'in_progress', 'arrived'].contains(status);

  factory PickupModel.fromJson(Map<String, dynamic> json) {
    return PickupModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      collectorId: json['collector_id'],
      address: json['address'] ?? '',
      lat: (json['lat'] ?? 0).toDouble(),
      lon: (json['lon'] ?? 0).toDouble(),
      photoUrl: json['photo_url'],
      notes: json['notes'],
      status: json['status'] ?? 'pending',
      reassignmentCount: json['reassignment_count'] ?? 0,
      assignedAt: json['assigned_at'] != null ? DateTime.parse(json['assigned_at']) : null,
      assignmentTimeout: json['assignment_timeout'] != null ? DateTime.parse(json['assignment_timeout']) : null,
      acceptedAt: json['accepted_at'] != null ? DateTime.parse(json['accepted_at']) : null,
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      arrivedAt: json['arrived_at'] != null ? DateTime.parse(json['arrived_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      totalWeight: json['total_weight']?.toDouble(),
      totalPointsAwarded: json['total_points_awarded'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      collector: json['collector'] != null ? CollectorInfo.fromJson(json['collector']) : null,
      user: json['user'] != null ? UserInfo.fromJson(json['user']) : null,
      items: (json['items'] as List<dynamic>?)?.map((e) => PickupItem.fromJson(e)).toList() ?? [],
    );
  }
}

class CollectorInfo {
  final String id;
  final String name;
  final String? phone;
  final double averageRating;

  CollectorInfo({required this.id, required this.name, this.phone, this.averageRating = 0.0});

  factory CollectorInfo.fromJson(Map<String, dynamic> json) {
    return CollectorInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      averageRating: (json['average_rating'] ?? 0).toDouble(),
    );
  }
}

class UserInfo {
  final String id;
  final String name;
  final String? phone;

  UserInfo({required this.id, required this.name, this.phone});

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
    );
  }
}

class PickupItem {
  final String id;
  final String pickupId;
  final String categoryId;
  final double weightKg;
  final int pointsAwarded;
  final CategoryInfo? category;

  PickupItem({
    required this.id,
    required this.pickupId,
    required this.categoryId,
    required this.weightKg,
    required this.pointsAwarded,
    this.category,
  });

  factory PickupItem.fromJson(Map<String, dynamic> json) {
    return PickupItem(
      id: json['id'] ?? '',
      pickupId: json['pickup_id'] ?? '',
      categoryId: json['category_id'] ?? '',
      weightKg: (json['weight_kg'] ?? 0).toDouble(),
      pointsAwarded: json['points_awarded'] ?? 0,
      category: json['category'] != null ? CategoryInfo.fromJson(json['category']) : null,
    );
  }
}

class CategoryInfo {
  final String id;
  final String name;
  final int pointsPerKg;
  final String? colorHex;

  CategoryInfo({required this.id, required this.name, required this.pointsPerKg, this.colorHex});

  factory CategoryInfo.fromJson(Map<String, dynamic> json) {
    return CategoryInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      pointsPerKg: json['points_per_kg'] ?? 10,
      colorHex: json['color_hex'],
    );
  }
}

class WasteCategory {
  final String id;
  final String name;
  final String? description;
  final int pointsPerKg;
  final String? colorHex;

  WasteCategory({
    required this.id,
    required this.name,
    this.description,
    required this.pointsPerKg,
    this.colorHex,
  });

  factory WasteCategory.fromJson(Map<String, dynamic> json) {
    return WasteCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      pointsPerKg: json['points_per_kg'] ?? 10,
      colorHex: json['color_hex'],
    );
  }
}
