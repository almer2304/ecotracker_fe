class ApiConstants {
  // Ganti dengan URL server kamu
  // static const String baseUrl = 'http://10.0.2.2:8080/api/v1'; // Android emulator
  // static const String baseUrl = 'http://localhost:8080/api/v1'; // iOS simulator
  static const String baseUrl = 'https://abortively-proexecutive-graham.ngrok-free.dev/api/v1'; // ngrok

  static const String adminSecret = 'ecotracker-admin-secret-2026';

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String profile = '/auth/profile';
  static const String registerAdmin = '/auth/register-admin';
  static const String registerCollector = '/auth/register-collector';

  // Categories
  static const String categories = '/categories';

  // Pickups
  static const String pickups = '/pickups';
  static const String myPickups = '/pickups/my';

  // Collector
  static const String collectorStatus = '/collector/status';
  static const String collectorLocation = '/collector/location';
  static const String collectorAssigned = '/collector/assigned';

  // Badges
  static const String badges = '/badges';
  static const String myBadges = '/badges/my';

  // Reports
  static const String reports = '/reports';
  static const String myReports = '/reports/my';

  // Feedback
  static const String feedback = '/feedback';
  static const String myFeedback = '/feedback/my';

  // Admin
  static const String adminDashboard = '/admin/dashboard';
  static const String adminCollectors = '/admin/collectors';
  static const String adminPickups = '/admin/pickups';
  static const String adminReports = '/admin/reports';
  static const String adminFeedback = '/admin/feedback';

  // Storage keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserRole = 'user_role';
  static const String keyUserName = 'user_name';

  // Timeouts
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
}
