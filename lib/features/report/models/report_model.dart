// ============================================================
// REPORT MODEL
// ============================================================

class ReportModel {
  final String id;
  final String reporterId;
  final String title;
  final String description;
  final String address;
  final double lat;
  final double lon;
  final String severity;
  final String status;
  final List<String> photoUrls;
  final String? adminNotes;
  final DateTime createdAt;

  ReportModel({
    required this.id,
    required this.reporterId,
    required this.title,
    required this.description,
    required this.address,
    required this.lat,
    required this.lon,
    required this.severity,
    required this.status,
    this.photoUrls = const [],
    this.adminNotes,
    required this.createdAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] ?? '',
      reporterId: json['reporter_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      lat: (json['lat'] ?? 0).toDouble(),
      lon: (json['lon'] ?? 0).toDouble(),
      severity: json['severity'] ?? 'medium',
      status: json['status'] ?? 'new',
      photoUrls: List<String>.from(json['photo_urls'] ?? []),
      adminNotes: json['admin_notes'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}
