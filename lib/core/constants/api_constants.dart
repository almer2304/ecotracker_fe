class ApiConstants {
  // GANTI URL INI DENGAN NGROK URL KAMU!
  static const String baseUrl = 'https://abortively-proexecutive-graham.ngrok-free.dev';
  
  static const String apiV1 = '$baseUrl/api/v1';

  // Auth endpoints
  static const String register = '$apiV1/auth/register';
  static const String login = '$apiV1/auth/login';
  static const String profile = '$apiV1/auth/profile';

  // User Pickup endpoints
  static const String pickups = '$apiV1/pickups';
  static const String myPickups = '$apiV1/pickups/my';
  static String pickupDetail(String id) => '$apiV1/pickups/$id';

  // Collector endpoints
  static const String collectorPendingPickups = '$apiV1/collector/pickups/pending';
  static const String collectorMyTasks = '$apiV1/collector/pickups/my-tasks';
  static String collectorTakeTask(String pickupId) => '$apiV1/collector/pickups/$pickupId/take';
  static String collectorCompleteTask(String pickupId) => '$apiV1/collector/pickups/$pickupId/complete';

  // Categories
  static const String categories = '$apiV1/categories';

  // Points
  static const String pointLogs = '$apiV1/points/logs';

  // Vouchers
  static const String vouchers = '$apiV1/vouchers';
  static const String myVouchers = '$apiV1/vouchers/my';
  static String claimVoucher(String id) => '$apiV1/vouchers/$id/claim';

  // Admin endpoints (for future admin web dashboard)
  static const String adminCollectors = '$apiV1/admin/collectors';
  static const String adminStats = '$apiV1/admin/stats';
  static const String adminPickups = '$apiV1/admin/pickups';
  static String adminDeleteCollector(String id) => '$apiV1/admin/collectors/$id';
}
