// badge_model.dart
class BadgeModel {
  final String id;
  final String code;
  final String name;
  final String? description;
  final String? iconUrl;
  final String? colorHex;
  final String criteriaType;
  final int criteriaValue;
  final int displayOrder;
  final bool? isUnlocked;
  final DateTime? awardedAt;

  BadgeModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.iconUrl,
    this.colorHex,
    required this.criteriaType,
    required this.criteriaValue,
    required this.displayOrder,
    this.isUnlocked,
    this.awardedAt,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      iconUrl: json['icon_url'],
      colorHex: json['color_hex'],
      criteriaType: json['criteria_type'] ?? 'pickups',
      criteriaValue: json['criteria_value'] ?? 0,
      displayOrder: json['display_order'] ?? 0,
      isUnlocked: json['is_unlocked'],
      awardedAt: json['awarded_at'] != null ? DateTime.parse(json['awarded_at']) : null,
    );
  }

  String get emoji {
    switch (code) {
      case 'first_pickup': return '🥇';
      case 'eco_warrior': return '🌿';
      case 'eco_champion': return '🌳';
      case 'eco_legend': return '🏆';
      case 'point_master': return '💎';
      case 'point_legend': return '👑';
      case 'reporter_hero': return '📢';
      case 'community_guardian': return '🛡️';
      default: return '🎖️';
    }
  }
}
