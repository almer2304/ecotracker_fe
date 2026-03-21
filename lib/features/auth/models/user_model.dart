class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? avatarUrl;
  final int totalPoints;
  final int totalPickupsCompleted;
  final int totalReportsSubmitted;
  final bool isOnline;
  final bool isBusy;
  final double averageRating;
  final int totalRatings;
  final double totalWeightCollected;
  final double? lastLat;
  final double? lastLon;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.avatarUrl,
    this.totalPoints = 0,
    this.totalPickupsCompleted = 0,
    this.totalReportsSubmitted = 0,
    this.isOnline = false,
    this.isBusy = false,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.totalWeightCollected = 0.0,
    this.lastLat,
    this.lastLon,
    required this.createdAt,
  });

  bool get isUser => role == 'user';
  bool get isCollector => role == 'collector';
  bool get isAdmin => role == 'admin';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'user',
      avatarUrl: json['avatar_url'],
      totalPoints: json['total_points'] ?? 0,
      totalPickupsCompleted: json['total_pickups_completed'] ?? 0,
      totalReportsSubmitted: json['total_reports_submitted'] ?? 0,
      isOnline: json['is_online'] ?? false,
      isBusy: json['is_busy'] ?? false,
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      totalRatings: json['total_ratings'] ?? 0,
      totalWeightCollected: (json['total_weight_collected'] ?? 0).toDouble(),
      lastLat: json['last_lat']?.toDouble(),
      lastLon: json['last_lon']?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final UserModel user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      expiresIn: json['expires_in'] ?? 900,
      user: UserModel.fromJson(json['user'] ?? {}),
    );
  }
}
