class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final int totalPoints;
  final String? avatarUrl;
  final String? addressDefault;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.totalPoints,
    this.avatarUrl,
    this.addressDefault,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      totalPoints: json['total_points'] as int? ?? 0,
      avatarUrl: json['avatar_url'] as String?,
      addressDefault: json['address_default'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'total_points': totalPoints,
      'avatar_url': avatarUrl,
      'address_default': addressDefault,
    };
  }
}
